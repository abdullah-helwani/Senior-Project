import { useEffect, useState } from 'react';
import { Row, Col, Card, Statistic, Table, Tag, Spin, Typography } from 'antd';
import {
  TeamOutlined,
  UserOutlined,
  CheckCircleOutlined,
  WarningOutlined,
  SmileOutlined,
  FrownOutlined,
  MessageOutlined,
  BookOutlined,
} from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

interface DashboardData {
  users: {
    total_students: number;
    active_students: number;
    total_teachers: number;
    active_teachers: number;
    total_parents: number;
  };
  enrollments: { active: number };
  today_attendance: {
    total_records: number;
    present: number;
    absent: number;
    late: number;
    excused: number;
    percentage: number | null;
  };
  complaints: {
    open: number;
    in_review: number;
    this_month: number;
  };
  behavior_this_week: {
    positive: number;
    negative: number;
    total: number;
  };
  recent_complaints: Array<{
    complaint_id: number;
    subject: string;
    status: string;
    parent: string;
    student: string;
    created_at: string;
  }>;
}

const complaintColumns = [
  { title: 'Subject', dataIndex: 'subject', key: 'subject', ellipsis: true },
  { title: 'Parent', dataIndex: 'parent', key: 'parent' },
  { title: 'Student', dataIndex: 'student', key: 'student' },
  {
    title: 'Status',
    dataIndex: 'status',
    key: 'status',
    render: (status: string) => {
      const color = status === 'open' ? 'red' : status === 'in_review' ? 'orange' : 'green';
      return <Tag color={color}>{status.replace('_', ' ')}</Tag>;
    },
  },
  {
    title: 'Date',
    dataIndex: 'created_at',
    key: 'created_at',
    render: (d: string) => new Date(d).toLocaleDateString(),
  },
];

export default function Dashboard() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/admin/dashboard')
      .then((res) => setData(res.data))
      .catch(() => setData(null))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div style={{ textAlign: 'center', padding: 100 }}><Spin size="large" /></div>;
  if (!data) return <Card>Failed to load dashboard data.</Card>;

  return (
    <div>
      <Title level={4} style={{ marginBottom: 24 }}>Dashboard</Title>

      {/* User Stats */}
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Total Students" value={data.users.total_students} prefix={<TeamOutlined />} />
            <div style={{ color: '#8c8c8c', fontSize: 13, marginTop: 4 }}>{data.users.active_students} active</div>
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Total Teachers" value={data.users.total_teachers} prefix={<UserOutlined />} />
            <div style={{ color: '#8c8c8c', fontSize: 13, marginTop: 4 }}>{data.users.active_teachers} active</div>
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Total Parents" value={data.users.total_parents} prefix={<TeamOutlined />} />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Active Enrollments" value={data.enrollments.active} prefix={<BookOutlined />} />
          </Card>
        </Col>
      </Row>

      {/* Attendance & Behavior */}
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Today's Attendance"
              value={data.today_attendance.percentage ?? '--'}
              suffix="%"
              prefix={<CheckCircleOutlined />}
              valueStyle={{ color: (data.today_attendance.percentage ?? 0) >= 80 ? '#3f8600' : '#cf1322' }}
            />
            <div style={{ color: '#8c8c8c', fontSize: 13, marginTop: 4 }}>
              {data.today_attendance.present} present / {data.today_attendance.total_records} total
            </div>
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Open Complaints" value={data.complaints.open} prefix={<WarningOutlined />} valueStyle={{ color: data.complaints.open > 0 ? '#cf1322' : '#3f8600' }} />
            <div style={{ color: '#8c8c8c', fontSize: 13, marginTop: 4 }}>{data.complaints.in_review} in review</div>
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Positive Behavior" value={data.behavior_this_week.positive} prefix={<SmileOutlined />} valueStyle={{ color: '#3f8600' }} />
            <div style={{ color: '#8c8c8c', fontSize: 13, marginTop: 4 }}>this week</div>
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Negative Behavior" value={data.behavior_this_week.negative} prefix={<FrownOutlined />} valueStyle={{ color: '#cf1322' }} />
            <div style={{ color: '#8c8c8c', fontSize: 13, marginTop: 4 }}>this week</div>
          </Card>
        </Col>
      </Row>

      {/* Recent Complaints */}
      <Card title={<><MessageOutlined /> Recent Complaints</>} style={{ marginTop: 24 }}>
        <Table
          dataSource={data.recent_complaints}
          columns={complaintColumns}
          rowKey="complaint_id"
          pagination={false}
          size="small"
        />
      </Card>
    </div>
  );
}
