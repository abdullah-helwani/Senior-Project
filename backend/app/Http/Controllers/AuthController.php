<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        if (! Auth::attempt($request->only('email', 'password'))) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $user = Auth::user();

        if (! $user->is_active) {
            Auth::logout();
            return response()->json(['message' => 'Your account is deactivated.'], 403);
        }

        $token = $user->createToken('auth_token', [$user->role_type])->plainTextToken;

        return response()->json([
            'token'     => $token,
            'role'      => $user->role_type,
            'user'      => [
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
            ],
        ]);
    }

    public function me(Request $request)
    {
        $user = $request->user();

        $profile = [
            'id'        => $user->id,
            'name'      => $user->name,
            'email'     => $user->email,
            'phone'     => $user->phone,
            'role'      => $user->role_type,
            'is_active' => $user->is_active,
        ];

        match ($user->role_type) {
            'student' => $profile['student'] = $user->student()
                ->with('activeEnrollment.section.schoolClass.schoolYear')
                ->first(),

            'teacher' => $profile['teacher'] = $user->teacher()
                ->with('assignments.section.schoolClass', 'assignments.subject')
                ->first(),

            'parent' => $profile['parent'] = $user->guardian()
                ->with('studentLinks.student.user')
                ->first(),

            'admin' => $profile['admin'] = $user->admin,
        };

        return response()->json($profile);
    }

    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password'     => ['required', 'confirmed', Password::min(8)],
        ]);

        $user = $request->user();

        if (! Hash::check($request->current_password, $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['The current password is incorrect.'],
            ]);
        }

        $user->update(['password' => Hash::make($request->new_password)]);

        return response()->json(['message' => 'Password changed successfully.']);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out successfully.']);
    }
}
