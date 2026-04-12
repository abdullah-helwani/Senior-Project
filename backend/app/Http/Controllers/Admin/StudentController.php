<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class StudentController extends Controller
{
    /**
     * List all students with search and filter.
     *
     * Query params:
     *   search         - searches name, email, phone
     *   status         - active | graduated | transferred | withdrawn
     *   graduation_year - integer (e.g. 2024)
     *   class_id       - filter by school_class id (current active enrollment)
     *   section_id     - filter by section id (current active enrollment)
     *   per_page       - results per page (default 15)
     */
    public function index(Request $request)
    {
        $query = Student::with([
            'user',
            'activeEnrollment.section.schoolClass.schoolYear',
        ]);

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

        if ($request->filled('graduation_year')) {
            $query->where('graduation_year', $request->graduation_year);
        }

        if ($request->filled('class_id')) {
            $query->whereHas('enrollments', function ($q) use ($request) {
                $q->where('status', 'active')
                  ->whereHas('section', function ($q2) use ($request) {
                      $q2->where('school_class_id', $request->class_id);
                  });
            });
        }

        if ($request->filled('section_id')) {
            $query->whereHas('enrollments', function ($q) use ($request) {
                $q->where('status', 'active')
                  ->where('section_id', $request->section_id);
            });
        }

        $perPage = $request->input('per_page', 15);

        return response()->json($query->paginate($perPage));
    }

    /**
     * Show a single student's full profile.
     */
    public function show(int $id)
    {
        $student = Student::with([
            'user',
            'enrollments.section.schoolClass.schoolYear',
        ])->findOrFail($id);

        return response()->json($student);
    }

    /**
     * Create a new student account.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name'            => 'required|string|max:255',
            'email'           => 'required|email|unique:users,email',
            'phone'           => 'nullable|string|max:20',
            'password'        => ['required', Password::min(8)],
            'date_of_birth'   => 'nullable|date',
            'gender'          => 'nullable|in:male,female,other',
            'address'         => 'nullable|string',
            'enrollment_date' => 'nullable|date',
            'graduation_year' => 'nullable|integer|min:1900|max:2100',
            'status'          => 'nullable|in:active,graduated,transferred,withdrawn',
        ]);

        $student = DB::transaction(function () use ($request) {
            $user = User::create([
                'name'      => $request->name,
                'email'     => $request->email,
                'phone'     => $request->phone,
                'password'  => Hash::make($request->password),
                'role_type' => 'student',
                'is_active' => true,
            ]);

            return Student::create([
                'user_id'         => $user->id,
                'date_of_birth'   => $request->date_of_birth,
                'gender'          => $request->gender,
                'address'         => $request->address,
                'enrollment_date' => $request->enrollment_date ?? now()->toDateString(),
                'graduation_year' => $request->graduation_year,
                'status'          => $request->status ?? 'active',
            ]);
        });

        return response()->json($student->load('user'), 201);
    }

    /**
     * Update a student's profile (user fields + student fields).
     */
    public function update(Request $request, int $id)
    {
        $student = Student::with('user')->findOrFail($id);

        $request->validate([
            'name'            => 'sometimes|string|max:255',
            'email'           => "sometimes|email|unique:users,email,{$student->user_id}",
            'phone'           => 'nullable|string|max:20',
            'date_of_birth'   => 'nullable|date',
            'gender'          => 'nullable|in:male,female,other',
            'address'         => 'nullable|string',
            'enrollment_date' => 'nullable|date',
            'graduation_year' => 'nullable|integer|min:1900|max:2100',
            'status'          => 'nullable|in:active,graduated,transferred,withdrawn',
            'is_active'       => 'nullable|boolean',
        ]);

        DB::transaction(function () use ($request, $student) {
            $student->user->update($request->only(['name', 'email', 'phone', 'is_active']));

            $student->update($request->only([
                'date_of_birth',
                'gender',
                'address',
                'enrollment_date',
                'graduation_year',
                'status',
            ]));
        });

        return response()->json($student->load('user'));
    }

    /**
     * Delete a student and their user account.
     */
    public function destroy(int $id)
    {
        $student = Student::with('user')->findOrFail($id);

        DB::transaction(function () use ($student) {
            // Cascade handles student record; deleting user cascades via FK
            $student->user->delete();
        });

        return response()->json(['message' => 'Student deleted successfully.']);
    }
}
