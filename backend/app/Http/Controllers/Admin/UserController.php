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
use Illuminate\Support\Facades\Storage;
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

    /**
     * PUT /admin/users/{id}/reset-password
     *
     * Admin resets a user's password.
     */
    public function resetPassword(int $id, Request $request)
    {
        $user = User::findOrFail($id);

        $request->validate([
            'new_password' => ['required', Password::min(8)],
        ]);

        $user->update(['password' => Hash::make($request->new_password)]);

        // Revoke all tokens so the user has to login with the new password
        $user->tokens()->delete();

        return response()->json(['message' => 'Password reset successfully. User has been logged out of all sessions.']);
    }

    /**
     * PUT /admin/users/{id}/toggle-active
     *
     * Deactivate or reactivate a user account.
     */
    public function toggleActive(int $id)
    {
        $user = User::findOrFail($id);

        $user->update(['is_active' => !$user->is_active]);

        // If deactivated, revoke all tokens to force logout
        if (!$user->is_active) {
            $user->tokens()->delete();
        }

        return response()->json([
            'message'   => $user->is_active ? 'User reactivated successfully.' : 'User deactivated successfully.',
            'is_active' => $user->is_active,
        ]);
    }

    /**
     * POST /admin/users/{id}/profile-picture
     *
     * Upload or replace a user's profile picture.
     */
    public function updateProfilePicture(int $id, Request $request)
    {
        $user = User::findOrFail($id);

        $request->validate([
            'profile_picture' => 'required|image|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        if ($user->profile_picture) {
            Storage::disk('public')->delete($user->profile_picture);
        }

        $path = $request->file('profile_picture')->store(
            "profile-pictures/{$user->id}",
            'public'
        );

        $user->update(['profile_picture' => $path]);

        return response()->json([
            'message'         => 'Profile picture updated successfully.',
            'profile_picture' => $path,
        ]);
    }

    /**
     * DELETE /admin/users/{id}/profile-picture
     *
     * Remove a user's profile picture.
     */
    public function deleteProfilePicture(int $id)
    {
        $user = User::findOrFail($id);

        if ($user->profile_picture) {
            Storage::disk('public')->delete($user->profile_picture);
            $user->update(['profile_picture' => null]);
        }

        return response()->json(['message' => 'Profile picture removed successfully.']);
    }
}
