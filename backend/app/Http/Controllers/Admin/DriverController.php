<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class DriverController extends Controller
{
    /**
     * List all drivers. Supports ?search (name/email/phone) and ?per_page.
     */
    public function index(Request $request)
    {
        $query = Driver::with(['user', 'currentBus']);

        if ($search = $request->search) {
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        $perPage = $request->input('per_page', 15);

        return response()->json($query->paginate($perPage));
    }

    public function show(int $id)
    {
        $driver = Driver::with([
            'user',
            'assignments.bus',
        ])->findOrFail($id);

        return response()->json($driver);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'phone'    => 'nullable|string|max:20',
            'password' => ['required', Password::min(8)],
        ]);

        $driver = DB::transaction(function () use ($request) {
            $user = User::create([
                'name'      => $request->name,
                'email'     => $request->email,
                'phone'     => $request->phone,
                'password'  => Hash::make($request->password),
                'role_type' => 'driver',
                'is_active' => true,
            ]);

            return Driver::create(['user_id' => $user->id]);
        });

        return response()->json($driver->load('user'), 201);
    }

    public function update(Request $request, int $id)
    {
        $driver = Driver::with('user')->findOrFail($id);

        $request->validate([
            'name'      => 'sometimes|string|max:255',
            'email'     => "sometimes|email|unique:users,email,{$driver->user_id}",
            'phone'     => 'nullable|string|max:20',
            'is_active' => 'nullable|boolean',
        ]);

        $driver->user->update($request->only(['name', 'email', 'phone', 'is_active']));

        return response()->json($driver->load('user'));
    }

    public function destroy(int $id)
    {
        $driver = Driver::with('user')->findOrFail($id);

        DB::transaction(function () use ($driver) {
            // Deleting the user cascades via FK (once migration is run)
            $driver->user->delete();
        });

        return response()->json(['message' => 'Driver deleted successfully.']);
    }
}
