<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BusRoute;
use Illuminate\Http\Request;

class BusRouteController extends Controller
{
    /**
     * List all routes with their stops.
     */
    public function index(Request $request)
    {
        $query = BusRoute::with('stops');

        if ($search = $request->search) {
            $query->where('name', 'like', "%{$search}%");
        }

        $perPage = $request->input('per_page', 15);

        return response()->json($query->orderBy('name')->paginate($perPage));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:100|unique:route,name',
        ]);

        $route = BusRoute::create($request->only('name'));

        return response()->json($route, 201);
    }

    public function show(int $id)
    {
        return response()->json(
            BusRoute::with('stops')->findOrFail($id)
        );
    }

    public function update(Request $request, int $id)
    {
        $route = BusRoute::findOrFail($id);

        $request->validate([
            'name' => "sometimes|string|max:100|unique:route,name,{$id},route_id",
        ]);

        $route->update($request->only('name'));

        return response()->json($route);
    }

    public function destroy(int $id)
    {
        BusRoute::findOrFail($id)->delete();

        return response()->json(['message' => 'Route deleted successfully.']);
    }
}
