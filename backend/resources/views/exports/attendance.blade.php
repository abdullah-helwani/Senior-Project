<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Attendance Report</title>
    <style>
        body { font-family: Arial, sans-serif; font-size: 11px; color: #333; }
        h1 { font-size: 20px; margin-bottom: 2px; }
        .meta { color: #666; margin-bottom: 15px; }
        .summary { margin-bottom: 20px; }
        .summary td { padding: 4px 12px; }
        .summary .label { font-weight: bold; background: #f0f0f0; }
        table.data { width: 100%; border-collapse: collapse; }
        table.data th { background: #2c3e50; color: #fff; padding: 6px 8px; text-align: left; font-size: 10px; }
        table.data td { padding: 5px 8px; border-bottom: 1px solid #ddd; font-size: 10px; }
        table.data tr:nth-child(even) { background: #f9f9f9; }
        .present { color: #27ae60; }
        .absent { color: #e74c3c; }
        .late { color: #f39c12; }
        .excused { color: #3498db; }
    </style>
</head>
<body>
    <h1>Student Attendance Report</h1>
    <p class="meta">Period: {{ $from }} to {{ $to }} | Generated on {{ $date }}</p>

    <table class="summary">
        <tr>
            <td class="label">Total Records</td><td>{{ $summary['total_records'] }}</td>
            <td class="label">Present</td><td>{{ $summary['present'] }}</td>
            <td class="label">Absent</td><td>{{ $summary['absent'] }}</td>
            <td class="label">Late</td><td>{{ $summary['late'] }}</td>
            <td class="label">Excused</td><td>{{ $summary['excused'] }}</td>
            <td class="label">Rate</td><td>{{ $summary['attendance_rate'] ?? '-' }}%</td>
        </tr>
    </table>

    <table class="data">
        <thead>
            <tr>
                <th>Student</th>
                <th>Section</th>
                <th>Date</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            @forelse($rows as $row)
                <tr>
                    <td>{{ $row['student_name'] }}</td>
                    <td>{{ $row['section'] }}</td>
                    <td>{{ $row['date'] }}</td>
                    <td class="{{ $row['status'] }}">{{ ucfirst($row['status']) }}</td>
                </tr>
            @empty
                <tr><td colspan="4" style="text-align:center;">No attendance records found.</td></tr>
            @endforelse
        </tbody>
    </table>
</body>
</html>
