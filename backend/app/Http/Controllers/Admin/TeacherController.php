<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class TeacherController extends Controller
{
    /**
     * List all teachers with search and filter.
     *
     * Query params:
     *   search     - searches name, email, phone
     *   status     - active | inactive | resigned
     *   subject_id - filter by subject they are assigned to
     *   per_page   - results per page (default 15)
     */
    public function index(Request $request)
    {
        $query = Teacher::with(['user', 'subjects']);

        if ($search = $request->search) {
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('subject_id')) {
            $query->whereHas('assignments', function ($q) use ($request) {
                $q->where('subject_id', $request->subject_id);
            });
        }

        $perPage = $request->input('per_page', 15);

        return response()->json($query->paginate($perPage));
    }

    /**
     * Show a single teacher's full profile.
     */
    public function show(int $id)
    {
        $teacher = Teacher::with([
            'user',
            'assignments.subject',
            'assignments.section.schoolClass.schoolYear',
        ])->findOrFail($id);

        return response()->json($teacher);
    }

    /**
     * Create a new teacher account.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name'          => 'required|string|max:255',
            'email'         => 'required|email|unique:users,email',
            'phone'         => 'nullable|string|max:20',
            'password'      => ['required', Password::min(8)],
            'date_of_birth' => 'nullable|date',
            'gender'        => 'nullable|in:male,female,other',
            'address'       => 'nullable|string',
            'hire_date'     => 'nullable|date',
            'status'        => 'nullable|in:active,inactive,resigned',
        ]);

        $teacher = DB::transaction(function () use ($request) {
            $user = User::create([
                'name'      => $request->name,
                'email'     => $request->email,
                'phone'     => $request->phone,
                'password'  => Hash::make($request->password),
                'role_type' => 'teacher',
                'is_active' => true,
            ]);

            return Teacher::create([
                'user_id'       => $user->id,
                'date_of_birth' => $request->date_of_birth,
                'gender'        => $request->gender,
                'address'       => $request->address,
                'hire_date'     => $request->hire_date ?? now()->toDateString(),
                'status'        => $request->status ?? 'active',
            ]);
        });

        return response()->json($teacher->load('user'), 201);
    }

    /**
     * Update a teacher's profile (user fields + teacher fields).
     */
    public function update(Request $request, int $id)
    {
        $teacher = Teacher::with('user')->findOrFail($id);

        $request->validate([
            'name'          => 'sometimes|string|max:255',
            'email'         => "sometimes|email|unique:users,email,{$teacher->user_id}",
            'phone'         => 'nullable|string|max:20',
            'date_of_birth' => 'nullable|date',
            'gender'        => 'nullable|in:male,female,other',
            'address'       => 'nullable|string',
            'hire_date'     => 'nullable|date',
            'status'        => 'nullable|in:active,inactive,resigned',
            'is_active'     => 'nullable|boolean',
        ]);

        DB::transaction(function () use ($request, $teacher) {
            $teacher->user->update($request->only(['name', 'email', 'phone', 'is_active']));

            $teacher->update($request->only([
                'date_of_birth',
                'gender',
                'address',
                'hire_date',
                'status',
            ]));
        });

        return response()->json($teacher->load('user'));
    }

    /**
     * Delete a teacher and their user account.
     */
    public function destroy(int $id)
    {
        $teacher = Teacher::with('user')->findOrFail($id);

        DB::transaction(function () use ($teacher) {
            $teacher->user->delete();
        });

        return response()->json(['message' => 'Teacher deleted successfully.']);
    }
}
