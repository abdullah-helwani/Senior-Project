<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Camera;
use Illuminate\Http\Request;

class CameraController extends Controller
{
    /**
     * GET /admin/cameras
     *
     * List all cameras. Filters: isactive (true/false), search (location)
     */
    public function index(Request $request)
    {
        $query = Camera::query();

        if ($request->filled('isactive')) {
            $query->where('isactive', filter_var($request->isactive, FILTER_VALIDATE_BOOLEAN));
        }

        if ($request->filled('search')) {
            $query->where('location', 'ilike', "%{$request->search}%");
        }

        $cameras = $query->orderBy('camera_id')
            ->paginate($request->input('per_page', 20));

        return response()->json($cameras);
    }

    /**
     * POST /admin/cameras
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'location' => 'required|string|max:255',
            'isactive' => 'sometimes|boolean',
        ]);

        $camera = Camera::create([
            'location' => $data['location'],
            'isactive' => $data['isactive'] ?? true,
        ]);

        return response()->json($camera, 201);
    }

    /**
     * GET /admin/cameras/{id}
     */
    public function show(int $id)
    {
        $camera = Camera::where('camera_id', $id)
            ->withCount('events')
            ->firstOrFail();

        return response()->json($camera);
    }

    /**
     * PUT /admin/cameras/{id}
     */
    public function update(int $id, Request $request)
    {
        $camera = Camera::where('camera_id', $id)->firstOrFail();

        $data = $request->validate([
            'location' => 'sometimes|string|max:255',
            'isactive' => 'sometimes|boolean',
        ]);

        $camera->update($data);

        return response()->json($camera);
    }

    /**
     * DELETE /admin/cameras/{id}
     */
    public function destroy(int $id)
    {
        Camera::where('camera_id', $id)->firstOrFail()->delete();

        return response()->json(['message' => 'Camera deleted successfully.']);
    }
}
