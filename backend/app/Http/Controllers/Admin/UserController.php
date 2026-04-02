<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\Guardian;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class UserController extends Controller
{
    /**
     * Create a new user account (admin, student, teacher, or parent).
     */
    public function store(Request $request)
    {
        $request->validate([
            'name'            => 'required|string|max:255',
            'email'           => 'required|email|unique:users,email',
            'phone'           => 'nullable|string|max:20',
            'password'        => ['required', Password::min(8)],
            'role_type'       => 'required|in:admin,student,teacher,parent',

            // Student-specific fields
            'date_of_birth'   => 'nullable|date',
            'gender'          => 'nullable|in:male,female,other',
            'address'         => 'nullable|string',
            'enrollment_date' => 'nullable|date',
            'graduation_year' => 'nullable|integer|min:1900|max:2100',

            // Teacher-specific fields
            'hire_date'       => 'nullable|date',
        ]);

        $user = DB::transaction(function () use ($request) {
            $user = User::create([
                'name'      => $request->name,
                'email'     => $request->email,
                'phone'     => $request->phone,
                'password'  => Hash::make($request->password),
                'role_type' => $request->role_type,
                'is_active' => true,
            ]);

            match ($request->role_type) {
                'student' => Student::create([
                    'user_id'         => $user->id,
                    'date_of_birth'   => $request->date_of_birth,
                    'gender'          => $request->gender,
                    'address'         => $request->address,
                    'enrollment_date' => $request->enrollment_date ?? now()->toDateString(),
                    'graduation_year' => $request->graduation_year,
                    'status'          => 'active',
                ]),
                'teacher' => Teacher::create([
                    'user_id'       => $user->id,
                    'date_of_birth' => $request->date_of_birth,
                    'gender'        => $request->gender,
                    'address'       => $request->address,
                    'hire_date'     => $request->hire_date ?? now()->toDateString(),
                    'status'        => 'active',
                ]),
                'parent'  => Guardian::create(['user_id' => $user->id]),
                'admin'   => Admin::create(['user_id' => $user->id]),
            };

            return $user;
        });

        $user->load($request->role_type === 'parent' ? 'guardian' : $request->role_type);

        return response()->json($user, 201);
    }
}
