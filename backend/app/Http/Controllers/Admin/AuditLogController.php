<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\Request;

class AuditLogController extends Controller
{
    /**
     * GET /admin/audit-logs
     *
     * List audit logs with filters.
     * Filters: user_id, role, action (POST|PUT|DELETE), resource, resource_id, from, to
     */
    public function index(Request $request)
    {
        $query = AuditLog::query();

        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        if ($request->filled('action')) {
            $query->where('action', strtoupper($request->action));
        }

        if ($request->filled('resource')) {
            $query->where('resource', $request->resource);
        }

        if ($request->filled('resource_id')) {
            $query->where('resource_id', $request->resource_id);
        }

        if ($request->filled('from')) {
            $query->where('performed_at', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->where('performed_at', '<=', $request->to);
        }

        if ($request->filled('search')) {
            $query->where('user_name', 'ilike', "%{$request->search}%");
        }

        $logs = $query->orderByDesc('performed_at')
            ->paginate($request->input('per_page', 30));

        return response()->json($logs);
    }

    /**
     * GET /admin/audit-logs/{id}
     */
    public function show(int $id)
    {
        $log = AuditLog::findOrFail($id);

        return response()->json($log);
    }

    /**
     * GET /admin/audit-logs/user/{userId}
     *
     * View all actions performed by a specific user.
     */
    public function userHistory(int $userId, Request $request)
    {
        $logs = AuditLog::where('user_id', $userId)
            ->orderByDesc('performed_at')
            ->paginate($request->input('per_page', 30));

        return response()->json($logs);
    }

    /**
     * GET /admin/audit-logs/resource/{resource}/{resourceId}
     *
     * View the full change history of a specific resource (e.g. students/5).
     */
    public function resourceHistory(string $resource, string $resourceId, Request $request)
    {
        $logs = AuditLog::where('resource', $resource)
            ->where('resource_id', $resourceId)
            ->orderByDesc('performed_at')
            ->paginate($request->input('per_page', 30));

        return response()->json($logs);
    }
}
