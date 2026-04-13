import { useEffect, useState } from 'react';
import api from '../api/axios';

interface DashboardData {
  total_students: number;
  total_teachers: number;
  total_parents: number;
  total_sections: number;
  today_attendance_rate: number;
  pending_complaints: number;
  upcoming_assessments: number;
  recent_payments: number;
}

export default function Dashboard() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/admin/dashboard')
      .then((res) => setData(res.data))
      .catch(() => setData(null))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="page-loading">Loading...</div>;
  if (!data) return <div className="page-error">Failed to load dashboard data.</div>;

  const cards = [
    { label: 'Students', value: data.total_students, icon: '🎓' },
    { label: 'Teachers', value: data.total_teachers, icon: '👨‍🏫' },
    { label: 'Parents', value: data.total_parents, icon: '👨‍👩‍👧' },
    { label: 'Sections', value: data.total_sections, icon: '🏫' },
    { label: 'Attendance Rate', value: `${data.today_attendance_rate}%`, icon: '📊' },
    { label: 'Pending Complaints', value: data.pending_complaints, icon: '📋' },
    { label: 'Upcoming Assessments', value: data.upcoming_assessments, icon: '📝' },
    { label: 'Recent Payments', value: data.recent_payments, icon: '💰' },
  ];

  return (
    <div className="dashboard">
      <h1>Dashboard</h1>
      <div className="stats-grid">
        {cards.map((card) => (
          <div key={card.label} className="stat-card">
            <span className="stat-icon">{card.icon}</span>
            <div className="stat-info">
              <span className="stat-value">{card.value}</span>
              <span className="stat-label">{card.label}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
