<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\NotificationRecipient;
use Illuminate\Support\Collection;

class NotificationService
{
    /**
     * Create a notification and dispatch it to a list of user IDs.
     *
     * @param  array  $data  { title, createdbyuserid, channel? }
     * @param  Collection|array  $userIds
     */
    public function send(array $data, Collection|array $userIds): Notification
    {
        $notification = Notification::create([
            'title'          => $data['title'],
            'createdbyuserid' => $data['createdbyuserid'],
            'channel'        => $data['channel'] ?? 'app',
        ]);

        $recipients = collect($userIds)->unique()->map(fn ($userId) => [
            'notification_id' => $notification->notification_id,
            'user_id'         => $userId,
            'status'          => 'unread',
            'deliveredat'     => now(),
        ])->toArray();

        NotificationRecipient::insert($recipients);

        return $notification;
    }

    /**
     * Notify all students actively enrolled in a given section.
     */
    public function notifySection(int $sectionId, array $data): Notification
    {
        $userIds = \App\Models\Enrollment::with('student')
            ->where('section_id', $sectionId)
            ->where('status', 'active')
            ->get()
            ->map(fn ($e) => $e->student->user_id);

        return $this->send($data, $userIds);
    }
}
