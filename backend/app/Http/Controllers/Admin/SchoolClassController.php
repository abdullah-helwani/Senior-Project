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

        if ($request->filled('school_year_id')) {
            $query->where('school_year_id', $request->school_year_id);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'name'           => 'required|string|max:100',
            'school_year_id' => 'required|exists:school_years,id',
        ]);

        $class = SchoolClass::create($request->only(['name', 'school_year_id']));

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
            'name'           => 'sometimes|string|max:100',
            'school_year_id' => 'sometimes|exists:school_years,id',
        ]);

        $class->update($request->only(['name', 'school_year_id']));

        return response()->json($class->load('schoolYear'));
    }

    public function destroy(int $id)
    {
        SchoolClass::findOrFail($id)->delete();

        return response()->json(['message' => 'Class deleted successfully.']);
    }
}
