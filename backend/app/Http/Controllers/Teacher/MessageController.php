<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Message;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    /**
     * List all messages sent by this teacher.
     *
     * Query params:
     *   receiver_id - filter by specific parent
     *   student_id  - filter by student the message is about
     */
    public function sent(int $teacherId, Request $request)
    {
        $teacher = Teacher::with('user')->findOrFail($teacherId);

        $query = Message::with(['receiver', 'student.user'])
            ->where('sender_id', $teacher->user_id);

        if ($request->filled('receiver_id')) {
            $query->where('receiver_id', $request->receiver_id);
        }

        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        return response()->json(
            $query->latest()->paginate($request->input('per_page', 15))
        );
    }

    /**
     * Send a message from this teacher to a parent.
     *
     * Body:
     * {
     *   "receiver_id": 5,       -- user_id of the parent
     *   "student_id": 3,        -- (optional) which student this is about
     *   "subject": "Behaviour", -- (optional)
     *   "body": "..."
     * }
     */
    public function send(int $teacherId, Request $request)
    {
        $teacher = Teacher::with('user')->findOrFail($teacherId);

        $request->validate([
            'receiver_id' => 'required|exists:users,id',
            'student_id'  => 'nullable|exists:students,id',
            'subject'     => 'nullable|string|max:255',
            'body'        => 'required|string',
        ]);

        // Ensure receiver is a parent
        $receiver = User::findOrFail($request->receiver_id);
        if ($receiver->role_type !== 'parent') {
            return response()->json(['message' => 'Messages can only be sent to parents.'], 422);
        }

        $message = Message::create([
            'sender_id'   => $teacher->user_id,
            'receiver_id' => $request->receiver_id,
            'student_id'  => $request->student_id,
            'subject'     => $request->subject,
            'body'        => $request->body,
        ]);

        return response()->json($message->load(['receiver', 'student.user']), 201);
    }

    /**
     * Show a single sent message.
     */
    public function show(int $teacherId, int $messageId)
    {
        $teacher = Teacher::findOrFail($teacherId);

        $message = Message::with(['receiver', 'student.user'])
            ->where('sender_id', $teacher->user_id)
            ->findOrFail($messageId);

        return response()->json($message);
    }
}
