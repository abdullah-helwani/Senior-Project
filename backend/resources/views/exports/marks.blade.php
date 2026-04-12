<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Marks Report</title>
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
        .pass { color: #27ae60; }
        .fail { color: #e74c3c; }
    </style>
</head>
<body>
    <h1>Student Marks Report</h1>
    <p class="meta">Generated on {{ $date }}</p>

    <table class="summary">
        <tr>
            <td class="label">Total Results</td><td>{{ $summary['total_results'] }}</td>
            <td class="label">Average</td><td>{{ $summary['average_score'] ?? '-' }}%</td>
            <td class="label">Highest</td><td>{{ $summary['highest'] ?? '-' }}%</td>
            <td class="label">Lowest</td><td>{{ $summary['lowest'] ?? '-' }}%</td>
            <td class="label">Pass Rate</td><td>{{ $summary['pass_rate'] ?? '-' }}%</td>
        </tr>
    </table>

    <table class="data">
        <thead>
            <tr>
                <th>Student</th>
                <th>Assessment</th>
                <th>Subject</th>
                <th>Section</th>
                <th>Type</th>
                <th>Date</th>
                <th>Score</th>
                <th>Max</th>
                <th>%</th>
                <th>Grade</th>
            </tr>
        </thead>
        <tbody>
            @forelse($rows as $row)
                <tr>
                    <td>{{ $row['student_name'] }}</td>
                    <td>{{ $row['assessment'] }}</td>
                    <td>{{ $row['subject'] }}</td>
                    <td>{{ $row['section'] }}</td>
                    <td>{{ $row['type'] }}</td>
                    <td>{{ $row['date'] }}</td>
                    <td>{{ $row['score'] }}</td>
                    <td>{{ $row['max_score'] }}</td>
                    <td class="{{ $row['percentage'] >= 50 ? 'pass' : 'fail' }}">{{ $row['percentage'] }}%</td>
                    <td>{{ $row['grade'] }}</td>
                </tr>
            @empty
                <tr><td colspan="10" style="text-align:center;">No results found.</td></tr>
            @endforelse
        </tbody>
    </table>
</body>
</html>
