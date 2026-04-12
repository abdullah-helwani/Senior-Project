<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SchoolYear;
use Illuminate\Http\Request;

class SchoolYearController extends Controller
{
    public function index()
    {
        return response()->json(SchoolYear::latest('schoolyearid')->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:50|unique:schoolyear,name',
        ]);

        $schoolYear = SchoolYear::create($request->only(['name']));

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
            'name' => "sometimes|string|max:50|unique:schoolyear,name,{$id},schoolyearid",
        ]);

        $schoolYear->update($request->only(['name']));

        return response()->json($schoolYear);
    }

    public function destroy(int $id)
    {
        SchoolYear::findOrFail($id)->delete();

        return response()->json(['message' => 'School year deleted successfully.']);
    }
}
