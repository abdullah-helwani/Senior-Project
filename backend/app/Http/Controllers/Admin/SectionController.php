<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Section;
use Illuminate\Http\Request;

class SectionController extends Controller
{
    public function index(Request $request)
    {
        $query = Section::with('schoolClass.schoolYear');

        if ($request->filled('class_id')) {
            $query->where('class_id', $request->class_id);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'class_id' => 'required|exists:class,class_id',
            'name'     => 'required|string|max:100',
        ]);

        $section = Section::create($request->only(['class_id', 'name']));

        return response()->json($section->load('schoolClass.schoolYear'), 201);
    }

    public function show(int $id)
    {
        return response()->json(Section::with('schoolClass.schoolYear')->findOrFail($id));
    }

    public function update(Request $request, int $id)
    {
        $section = Section::findOrFail($id);

        $request->validate([
            'class_id' => 'sometimes|exists:class,class_id',
            'name'     => 'sometimes|string|max:100',
        ]);

        $section->update($request->only(['class_id', 'name']));

        return response()->json($section->load('schoolClass.schoolYear'));
    }

    public function destroy(int $id)
    {
        Section::findOrFail($id)->delete();

        return response()->json(['message' => 'Section deleted successfully.']);
    }
}
