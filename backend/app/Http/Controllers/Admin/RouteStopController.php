<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\RouteStop;
use Illuminate\Http\Request;

class RouteStopController extends Controller
{
    /**
     * List stops. Filter by ?route_id to get a single route's stops.
     */
    public function index(Request $request)
    {
        $query = RouteStop::with('route');

        if ($request->filled('route_id')) {
            $query->where('route_id', $request->route_id);
        }

        return response()->json(
            $query->orderBy('route_id')->orderBy('stoporder')->get()
        );
    }

    public function store(Request $request)
    {
        $request->validate([
            'route_id'  => 'required|integer|exists:route,route_id',
            'name'      => 'required|string|max:100',
            'stoporder' => 'required|integer|min:1',
        ]);

        // Prevent duplicate stop order within the same route
        $clash = RouteStop::where('route_id', $request->route_id)
            ->where('stoporder', $request->stoporder)
            ->exists();

        if ($clash) {
            return response()->json([
                'message' => 'A stop with this order already exists on this route.',
            ], 422);
        }

        $stop = RouteStop::create($request->only('route_id', 'name', 'stoporder'));

        return response()->json($stop, 201);
    }

    public function show(int $id)
    {
        return response()->json(RouteStop::with('route')->findOrFail($id));
    }

    public function update(Request $request, int $id)
    {
        $stop = RouteStop::findOrFail($id);

        $request->validate([
            'name'      => 'sometimes|string|max:100',
            'stoporder' => 'sometimes|integer|min:1',
        ]);

        if ($request->filled('stoporder') && $request->stoporder != $stop->stoporder) {
            $clash = RouteStop::where('route_id', $stop->route_id)
                ->where('stoporder', $request->stoporder)
                ->where('stop_id', '!=', $id)
                ->exists();

            if ($clash) {
                return response()->json([
                    'message' => 'A stop with this order already exists on this route.',
                ], 422);
            }
        }

        $stop->update($request->only('name', 'stoporder'));

        return response()->json($stop);
    }

    public function destroy(int $id)
    {
        RouteStop::findOrFail($id)->delete();

        return response()->json(['message' => 'Stop deleted successfully.']);
    }
}
