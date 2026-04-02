<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SchoolYear;
use Illuminate\Http\Request;

class SchoolYearController extends Controller
{
    public function index()
    {
        return response()->json(SchoolYear::latest()->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'name'       => 'required|string|max:50|unique:school_years,name',
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after:start_date',
        ]);

        $schoolYear = SchoolYear::create($request->only(['name', 'start_date', 'end_date']));

        return response()->json($schoolYear, 201);
    }

    public function show(int $id)
    {
        return response()->json(SchoolYear::with('classes.sections')->findOrFail($id));
    }

    public function update(Request $request, int $id)
    {
        $schoolYear = SchoolYear::findOrFail($id);

        $request->validate([
            'name'       => "sometimes|string|max:50|unique:school_years,name,{$id}",
            'start_date' => 'sometimes|date',
            'end_date'   => 'sometimes|date|after:start_date',
        ]);

        $schoolYear->update($request->only(['name', 'start_date', 'end_date']));

        return response()->json($schoolYear);
    }

    public function destroy(int $id)
    {
        SchoolYear::findOrFail($id)->delete();

        return response()->json(['message' => 'School year deleted successfully.']);
    }
}
