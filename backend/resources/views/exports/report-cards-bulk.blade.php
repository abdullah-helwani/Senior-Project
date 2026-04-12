<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Report Cards — {{ $section_name }} ({{ $class_name }})</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, sans-serif; font-size: 11px; color: #333; padding: 30px; }
        .page-break { page-break-after: always; }
        .header { text-align: center; margin-bottom: 25px; border-bottom: 3px solid #2c3e50; padding-bottom: 15px; }
        .header h1 { font-size: 22px; color: #2c3e50; margin-bottom: 4px; }
        .header h2 { font-size: 14px; color: #666; font-weight: normal; }
        .student-info { margin-bottom: 20px; }
        .student-info table { width: 100%; }
        .student-info td { padding: 3px 8px; }
        .student-info .label { font-weight: bold; width: 120px; color: #555; }
        .section-title { font-size: 14px; color: #2c3e50; margin: 18px 0 8px; padding-bottom: 4px; border-bottom: 2px solid #3498db; }
        table.grades { width: 100%; border-collapse: collapse; margin-bottom: 15px; }
        table.grades th { background: #2c3e50; color: #fff; padding: 6px 8px; text-align: left; font-size: 10px; }
        table.grades td { padding: 5px 8px; border-bottom: 1px solid #ddd; font-size: 10px; }
        table.grades tr:nth-child(even) { background: #f9f9f9; }
        .score-high { color: #27ae60; font-weight: bold; }
        .score-mid  { color: #f39c12; font-weight: bold; }
        .score-low  { color: #e74c3c; font-weight: bold; }
        .overall { text-align: center; margin: 20px 0; padding: 15px; background: #ecf0f1; border-radius: 5px; }
        .overall .grade { font-size: 36px; font-weight: bold; }
        .overall .avg { font-size: 16px; color: #666; }
        .footer { margin-top: 30px; text-align: center; font-size: 9px; color: #999; border-top: 1px solid #ddd; padding-top: 10px; }
        .behavior-positive { color: #27ae60; }
        .behavior-negative { color: #e74c3c; }
    </style>
</head>
<body>
@foreach($students as $index => $student)
    <div class="header">
        <h1>Student Report Card</h1>
        <h2>{{ $term }} | {{ $from }} to {{ $to }}</h2>
    </div>

    <div class="student-info">
        <table>
            <tr>
                <td class="label">Student Name:</td>
                <td>{{ $student['name'] }}</td>
                <td class="label">Class:</td>
                <td>{{ $student['class'] ?? '-' }}</td>
            </tr>
            <tr>
                <td class="label">Section:</td>
                <td>{{ $student['section'] ?? '-' }}</td>
                <td class="label">School Year:</td>
                <td>{{ $student['school_year'] ?? '-' }}</td>
            </tr>
        </table>
    </div>

    <div class="section-title">Academic Performance</div>

    @foreach($student['subjects'] as $subject)
        <table class="grades">
            <thead>
                <tr>
                    <th colspan="4">{{ $subject['subject'] }} — Average: {{ $subject['average'] }}%</th>
                </tr>
                <tr>
                    <th>Assessment</th>
                    <th>Type</th>
                    <th>Score</th>
                    <th>Percentage</th>
                </tr>
            </thead>
            <tbody>
                @foreach($subject['assessments'] as $a)
                    <tr>
                        <td>{{ $a['title'] }}</td>
                        <td>{{ $a['type'] }}</td>
                        <td>{{ $a['score'] }} / {{ $a['max_score'] }}</td>
                        <td class="{{ $a['percentage'] >= 70 ? 'score-high' : ($a['percentage'] >= 50 ? 'score-mid' : 'score-low') }}">{{ $a['percentage'] }}%</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @endforeach

    @if(collect($student['subjects'])->isEmpty())
        <p style="color: #999; text-align: center; padding: 10px;">No assessment results for this term.</p>
    @endif

    <div class="overall">
        <div class="avg">Overall Average</div>
        <div class="grade {{ ($student['overall_average'] ?? 0) >= 70 ? 'score-high' : (($student['overall_average'] ?? 0) >= 50 ? 'score-mid' : 'score-low') }}">{{ $student['overall_average'] ?? '-' }}%</div>
    </div>

    <table style="width: 100%;">
        <tr>
            <td style="width: 50%; vertical-align: top; padding-right: 10px;">
                <div class="section-title">Attendance</div>
                <table style="width: 100%;">
                    <tr><td style="font-weight:bold; background:#f0f0f0; padding:4px 8px;">Total Days</td><td style="padding:4px 8px;">{{ $student['attendance']['total_days'] }}</td></tr>
                    <tr><td style="font-weight:bold; background:#f0f0f0; padding:4px 8px;">Present</td><td style="padding:4px 8px;">{{ $student['attendance']['present'] }}</td></tr>
                    <tr><td style="font-weight:bold; background:#f0f0f0; padding:4px 8px;">Absent</td><td style="padding:4px 8px;">{{ $student['attendance']['absent'] }}</td></tr>
                    <tr><td style="font-weight:bold; background:#f0f0f0; padding:4px 8px;">Late</td><td style="padding:4px 8px;">{{ $student['attendance']['late'] }}</td></tr>
                    <tr><td style="font-weight:bold; background:#f0f0f0; padding:4px 8px;">Excused</td><td style="padding:4px 8px;">{{ $student['attendance']['excused'] }}</td></tr>
                    <tr><td style="font-weight:bold; background:#f0f0f0; padding:4px 8px;">Rate</td><td style="padding:4px 8px;">{{ $student['attendance']['rate'] ?? '-' }}%</td></tr>
                </table>
            </td>
            <td style="width: 50%; vertical-align: top; padding-left: 10px;">
                <div class="section-title">Behavior</div>
                <table style="width: 100%;">
                    <tr><td style="font-weight:bold; background:#f0f0f0; padding:4px 8px;">Positive</td><td class="behavior-positive" style="padding:4px 8px;">{{ $student['behavior']['positive'] }}</td></tr>
                    <tr><td style="font-weight:bold; background:#f0f0f0; padding:4px 8px;">Negative</td><td class="behavior-negative" style="padding:4px 8px;">{{ $student['behavior']['negative'] }}</td></tr>
                    <tr><td style="font-weight:bold; background:#f0f0f0; padding:4px 8px;">Neutral</td><td style="padding:4px 8px;">{{ $student['behavior']['neutral'] }}</td></tr>
                </table>
            </td>
        </tr>
    </table>

    <div class="footer">
        Generated on {{ $date }} | This is an official school report card.
    </div>

    @if($index < count($students) - 1)
        <div class="page-break"></div>
    @endif
@endforeach
</body>
</html>
