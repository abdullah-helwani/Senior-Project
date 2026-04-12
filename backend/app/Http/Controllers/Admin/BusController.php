<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bus;
use Illuminate\Http\Request;

class BusController extends Controller
{
    /**
     * List all buses. Supports ?search=plate and ?per_page=15.
     */
    public function index(Request $request)
    {
        $query = Bus::query();

        if ($search = $request->search) {
            $query->where('plate_number', 'like', "%{$search}%");
        }

        $perPage = $request->input('per_page', 15);

        return response()->json($query->orderBy('bus_id')->paginate($perPage));
    }

    public function store(Request $request)
    {
        $request->validate([
            'plate_number' => 'required|string|max:50|unique:bus,plate_number',
        ]);

        $bus = Bus::create($request->only('plate_number'));

        return response()->json($bus, 201);
    }

    public function show(int $id)
    {
        $bus = Bus::with([
            'driverAssignments.driver.user',
            'studentAssignments.student.user',
        ])->findOrFail($id);

        return response()->json($bus);
    }

    public function update(Request $request, int $id)
    {
        $bus = Bus::findOrFail($id);

        $request->validate([
            'plate_number' => "sometimes|string|max:50|unique:bus,plate_number,{$id},bus_id",
        ]);

        $bus->update($request->only('plate_number'));

        return response()->json($bus);
    }

    public function destroy(int $id)
    {
        Bus::findOrFail($id)->delete();

        return response()->json(['message' => 'Bus deleted successfully.']);
    }
}
