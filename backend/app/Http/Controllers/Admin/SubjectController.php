<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Subject;
use Illuminate\Http\Request;

class SubjectController extends Controller
{
    public function index()
    {
        return response()->json(Subject::orderBy('name')->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:100',
            'code' => 'required|string|max:20|unique:subjects,code',
        ]);

        $subject = Subject::create($request->only(['name', 'code']));

        return response()->json($subject, 201);
    }

    public function show(int $id)
    {
        return response()->json(Subject::findOrFail($id));
    }

    public function update(Request $request, int $id)
    {
        $subject = Subject::findOrFail($id);

        $request->validate([
            'name' => 'sometimes|string|max:100',
            'code' => "sometimes|string|max:20|unique:subjects,code,{$id}",
        ]);

        $subject->update($request->only(['name', 'code']));

        return response()->json($subject);
    }

    public function destroy(int $id)
    {
        Subject::findOrFail($id)->delete();

        return response()->json(['message' => 'Subject deleted successfully.']);
    }
}
