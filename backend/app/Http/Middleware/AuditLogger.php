<?php

namespace App\Http\Middleware;

use App\Models\AuditLog;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AuditLogger
{
    /**
     * Log all state-changing requests (POST, PUT, DELETE) automatically.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        if (! in_array($request->method(), ['POST', 'PUT', 'PATCH', 'DELETE'])) {
            return $response;
        }

        // Only log successful mutations (2xx status)
        if ($response->getStatusCode() < 200 || $response->getStatusCode() >= 300) {
            return $response;
        }

        $user = $request->user();
        $path = $request->path(); // e.g. "api/admin/students/5"

        // Extract resource and resource_id from the URL
        [$resource, $resourceId] = $this->parseResource($path);

        // Determine what changed
        $newValues = null;
        $responseData = json_decode($response->getContent(), true);

        if ($request->method() === 'DELETE') {
            $newValues = null;
        } elseif (is_array($responseData)) {
            // Filter out sensitive fields
            $newValues = collect($responseData)
                ->except(['password', 'remember_token', 'token', 'abilities'])
                ->toArray();
        }

        // Sanitize request input (what was sent)
        $inputValues = collect($request->except([
            'password', 'new_password', 'current_password', 'password_confirmation',
            'profile_picture', 'file',
        ]))->toArray();

        AuditLog::create([
            'user_id'      => $user?->id,
            'user_name'    => $user?->name,
            'role'         => $user?->role_type,
            'action'       => $request->method(),
            'endpoint'     => '/' . $path,
            'resource'     => $resource,
            'resource_id'  => $resourceId,
            'old_values'   => $request->method() !== 'POST' ? $inputValues : null,
            'new_values'   => $request->method() !== 'DELETE' ? $newValues : null,
            'ip_address'   => $request->ip(),
            'performed_at' => now(),
        ]);

        return $response;
    }

    /**
     * Extract a resource name and optional ID from the request path.
     * e.g. "api/admin/students/5" → ["students", "5"]
     *      "api/admin/attendance" → ["attendance", null]
     */
    private function parseResource(string $path): array
    {
        // Remove "api/" prefix and role prefix (admin/, teacher/123/, etc.)
        $segments = collect(explode('/', $path))
            ->filter(fn ($s) => $s !== '' && $s !== 'api')
            ->values();

        // Skip the role prefix (admin, teacher, student, parent, driver, ai)
        $rolePrefixes = ['admin', 'teacher', 'student', 'parent', 'driver', 'ai'];
        if ($segments->isNotEmpty() && in_array($segments[0], $rolePrefixes)) {
            $segments = $segments->slice(1)->values();

            // If next segment is numeric (e.g. teacher/5/homework), skip it
            if ($segments->isNotEmpty() && is_numeric($segments[0])) {
                $segments = $segments->slice(1)->values();
            }
        }

        $resource = $segments->first();
        $resourceId = null;

        // Find the first numeric segment after resource name
        if ($segments->count() > 1 && is_numeric($segments[1])) {
            $resourceId = $segments[1];
        }

        return [$resource, $resourceId];
    }
}
