<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Guardian;
use App\Models\StudentGuardian;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class ParentController extends Controller
{
    /**
     * GET /admin/parents
     *
     * List all parent accounts with their linked children.
     * Filters: search (name/email/phone)
     */
    public function index(Request $request)
    {
        $query = Guardian::with(['user', 'studentLinks.student.user']);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'ilike', "%{$search}%")
                  ->orWhere('email', 'ilike', "%{$search}%")
                  ->orWhere('phone', 'ilike', "%{$search}%");
            });
        }

        $parents = $query->paginate($request->input('per_page', 20));

        return response()->json($parents);
    }

    /**
     * POST /admin/parents
     *
     * Create a parent account and optionally link to children.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name'                      => 'required|string|max:255',
            'email'                     => 'required|email|unique:users,email',
            'phone'                     => 'nullable|string|max:20',
            'password'                  => ['required', Password::min(8)],
            'children'                  => 'sometimes|array',
            'children.*.student_id'     => 'required_with:children|exists:students,id',
            'children.*.relationship'   => 'required_with:children|string|max:50',
            'children.*.isprimary'      => 'sometimes|boolean',
        ]);

        $parent = DB::transaction(function () use ($request) {
            $user = User::create([
                'name'      => $request->name,
                'email'     => $request->email,
                'phone'     => $request->phone,
                'password'  => Hash::make($request->password),
                'role_type' => 'parent',
                'is_active' => true,
            ]);

            $guardian = Guardian::create(['user_id' => $user->id]);

            if ($request->filled('children')) {
                foreach ($request->children as $child) {
                    StudentGuardian::create([
                        'student_id'   => $child['student_id'],
                        'parent_id'    => $guardian->parent_id,
                        'relationship' => $child['relationship'],
                        'isprimary'    => $child['isprimary'] ?? false,
                    ]);
                }
            }

            return $guardian;
        });

        return response()->json(
            $parent->load(['user', 'studentLinks.student.user']),
            201
        );
    }

    /**
     * GET /admin/parents/{id}
     */
    public function show(int $id)
    {
        $parent = Guardian::where('parent_id', $id)
            ->with(['user', 'studentLinks.student.user'])
            ->firstOrFail();

        return response()->json($parent);
    }

    /**
     * PUT /admin/parents/{id}
     *
     * Update parent user info (name, email, phone, is_active).
     */
    public function update(int $id, Request $request)
    {
        $parent = Guardian::where('parent_id', $id)->firstOrFail();
        $user = User::findOrFail($parent->user_id);

        $request->validate([
            'name'      => 'sometimes|string|max:255',
            'email'     => 'sometimes|email|unique:users,email,' . $user->id,
            'phone'     => 'sometimes|nullable|string|max:20',
            'is_active' => 'sometimes|boolean',
        ]);

        $user->update($request->only(['name', 'email', 'phone', 'is_active']));

        return response()->json($parent->load(['user', 'studentLinks.student.user']));
    }

    /**
     * DELETE /admin/parents/{id}
     */
    public function destroy(int $id)
    {
        $parent = Guardian::where('parent_id', $id)->firstOrFail();

        // Deleting the user cascades to guardian + studentguardian via FK
        User::destroy($parent->user_id);

        return response()->json(['message' => 'Parent account deleted successfully.']);
    }

    /**
     * POST /admin/parents/{id}/children
     *
     * Link a child to this parent.
     */
    public function addChild(int $id, Request $request)
    {
        Guardian::where('parent_id', $id)->firstOrFail();

        $request->validate([
            'student_id'   => 'required|exists:students,id',
            'relationship' => 'required|string|max:50',
            'isprimary'    => 'sometimes|boolean',
        ]);

        // Prevent duplicate link
        $exists = StudentGuardian::where('parent_id', $id)
            ->where('student_id', $request->student_id)
            ->exists();

        if ($exists) {
            return response()->json(['message' => 'This child is already linked to this parent.'], 422);
        }

        $link = StudentGuardian::create([
            'student_id'   => $request->student_id,
            'parent_id'    => $id,
            'relationship' => $request->relationship,
            'isprimary'    => $request->boolean('isprimary', false),
        ]);

        return response()->json($link, 201);
    }

    /**
     * DELETE /admin/parents/{id}/children/{studentId}
     *
     * Unlink a child from this parent.
     */
    public function removeChild(int $id, int $studentId)
    {
        $link = StudentGuardian::where('parent_id', $id)
            ->where('student_id', $studentId)
            ->firstOrFail();

        $link->delete();

        return response()->json(['message' => 'Child unlinked successfully.']);
    }
}
