<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SchoolClass;
use Illuminate\Http\Request;

class SchoolClassController extends Controller
{
    public function index(Request $request)
    {
        $query = SchoolClass::with('schoolYear');

        if ($request->filled('schoolyearid')) {
            $query->where('schoolyearid', $request->schoolyearid);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'name'        => 'required|string|max:100',
            'schoolyearid' => 'required|exists:schoolyear,schoolyearid',
        ]);

        $class = SchoolClass::create($request->only(['name', 'schoolyearid']));

        return response()->json($class->load('schoolYear'), 201);
    }

    public function show(int $id)
    {
        return response()->json(SchoolClass::with(['schoolYear', 'sections'])->findOrFail($id));
    }

    public function update(Request $request, int $id)
    {
        $class = SchoolClass::findOrFail($id);

        $request->validate([
            'name'         => 'sometimes|string|max:100',
            'schoolyearid' => 'sometimes|exists:schoolyear,schoolyearid',
        ]);

        $class->update($request->only(['name', 'schoolyearid']));

        return response()->json($class->load('schoolYear'));
    }

    public function destroy(int $id)
    {
        SchoolClass::findOrFail($id)->delete();

        return response()->json(['message' => 'Class deleted successfully.']);
    }
}
