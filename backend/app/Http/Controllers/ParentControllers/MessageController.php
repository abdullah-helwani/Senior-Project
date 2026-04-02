<?php

namespace App\Http\Controllers\ParentControllers;

use App\Http\Controllers\Controller;
use App\Models\Guardian;
use App\Models\Message;
use App\Models\Teacher;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    /**
     * GET /parent/{parentId}/messages
     *
     * List all messages (sent and received) for this parent.
     */
    public function index(int $parentId, Request $request)
    {
        $guardian = Guardian::findOrFail($parentId);

        $query = Message::where('sender_id', $guardian->user_id)
            ->orWhere('receiver_id', $guardian->user_id);

        $messages = $query->with(['sender', 'receiver', 'student.user'])
            ->orderByDesc('created_at')
            ->paginate($request->input('per_page', 20));

        return response()->json($messages);
    }

    /**
     * POST /parent/{parentId}/messages
     *
     * Send a message to a teacher.
     */
    public function send(int $parentId, Request $request)
    {
        $guardian = Guardian::findOrFail($parentId);

        $request->validate([
            'teacher_id' => 'required|exists:teachers,id',
            'student_id' => 'nullable|integer',
            'subject'    => 'required|string|max:255',
            'body'       => 'required|string',
        ]);

        $teacher = Teacher::with('user')->findOrFail($request->teacher_id);

        $message = Message::create([
            'sender_id'   => $guardian->user_id,
            'receiver_id' => $teacher->user_id,
            'student_id'  => $request->student_id,
            'subject'     => $request->subject,
            'body'        => $request->body,
        ]);

        return response()->json($message->load(['sender', 'receiver', 'student.user']), 201);
    }

    /**
     * GET /parent/{parentId}/messages/{id}
     */
    public function show(int $parentId, int $id)
    {
        $guardian = Guardian::findOrFail($parentId);

        $message = Message::where('id', $id)
            ->where(fn ($q) => $q->where('sender_id', $guardian->user_id)->orWhere('receiver_id', $guardian->user_id))
            ->with(['sender', 'receiver', 'student.user'])
            ->firstOrFail();

        // Mark as read if the parent is the receiver and hasn't read it yet
        if ($message->receiver_id === $guardian->user_id && ! $message->read_at) {
            $message->update(['read_at' => now()]);
        }

        return response()->json($message);
    }
}
