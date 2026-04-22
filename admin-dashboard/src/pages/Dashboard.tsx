import { useEffect, useState } from 'react';
import {
  Row,
  Col,
  Card,
  Statistic,
  Table,
  Tag,
  Spin,
  Typography,
  Progress,
  Space,
  Button,
  Empty,
} from 'antd';
import {
  TeamOutlined,
  UserOutlined,
  CheckCircleOutlined,
  WarningOutlined,
  SmileOutlined,
  FrownOutlined,
  MessageOutlined,
  BookOutlined,
  ArrowUpOutlined,
  ArrowDownOutlined,
  ReloadOutlined,
} from '@ant-design/icons';
import { Pie } from '@ant-design/charts';
import api from '../api/axios';

const { Title, Text } = Typography;

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

function StatCard({
  title,
  value,
  suffix,
  icon,
  tint,
  footer,
  valueColor,
}: {
  title: string;
  value: number | string;
  suffix?: string;
  icon: React.ReactNode;
  tint: string;
  footer?: React.ReactNode;
  valueColor?: string;
}) {
  return (
    <Card variant="outlined" style={{ height: '100%' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div style={{ flex: 1 }}>
          <Text type="secondary" style={{ fontSize: 13, fontWeight: 500 }}>
            {title}
          </Text>
          <div
            style={{
              fontSize: 26,
              fontWeight: 700,
              marginTop: 6,
              color: valueColor ?? '#0f172a',
              lineHeight: 1.1,
            }}
          >
            {value}
            {suffix && (
              <span style={{ fontSize: 15, fontWeight: 500, marginLeft: 4, color: '#64748b' }}>
                {suffix}
              </span>
            )}
          </div>
          {footer && <div style={{ marginTop: 10 }}>{footer}</div>}
        </div>
        <div
          style={{
            width: 44,
            height: 44,
            borderRadius: 10,
            background: tint,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
          }}
        >
          {icon}
        </div>
      </div>
    </Card>
  );
}

export default function Dashboard() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  const fetch = () => {
    setLoading(true);
    api
      .get('/admin/dashboard')
      .then((res) => setData(res.data))
      .catch(() => setData(null))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetch();
  }, []);

  if (loading)
    return (
      <div style={{ textAlign: 'center', padding: 100 }}>
        <Spin size="large" />
      </div>
    );
  if (!data)
    return (
      <Card>
        <Empty description="Failed to load dashboard data." />
      </Card>
    );

  const attendancePct = data.today_attendance.percentage ?? 0;
  const behaviorTotal = data.behavior_this_week.total || 1;
  const positivePct = Math.round((data.behavior_this_week.positive / behaviorTotal) * 100);

  const attendanceBreakdown = [
    { type: 'Present', value: data.today_attendance.present, color: '#16a34a' },
    { type: 'Absent', value: data.today_attendance.absent, color: '#dc2626' },
    { type: 'Late', value: data.today_attendance.late, color: '#f59e0b' },
    { type: 'Excused', value: data.today_attendance.excused, color: '#6366f1' },
  ].filter((d) => d.value > 0);

  return (
    <div>
      {/* Header */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 20,
        }}
      >
        <div>
          <Title level={3} style={{ margin: 0 }}>
            Welcome back 👋
          </Title>
          <Text type="secondary">Here’s what’s happening across the school today.</Text>
        </div>
        <Button icon={<ReloadOutlined />} onClick={fetch}>
          Refresh
        </Button>
      </div>

      {/* Top row — People */}
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="Total Students"
            value={data.users.total_students}
            tint="rgba(99,102,241,0.1)"
            icon={<TeamOutlined style={{ color: '#6366f1', fontSize: 20 }} />}
            footer={
              <Text type="success" style={{ fontSize: 12 }}>
                <ArrowUpOutlined /> {data.users.active_students} active
              </Text>
            }
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="Total Teachers"
            value={data.users.total_teachers}
            tint="rgba(16,185,129,0.1)"
            icon={<UserOutlined style={{ color: '#10b981', fontSize: 20 }} />}
            footer={
              <Text type="success" style={{ fontSize: 12 }}>
                <ArrowUpOutlined /> {data.users.active_teachers} active
              </Text>
            }
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="Total Parents"
            value={data.users.total_parents}
            tint="rgba(139,92,246,0.1)"
            icon={<TeamOutlined style={{ color: '#8b5cf6', fontSize: 20 }} />}
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="Active Enrollments"
            value={data.enrollments.active}
            tint="rgba(245,158,11,0.12)"
            icon={<BookOutlined style={{ color: '#f59e0b', fontSize: 20 }} />}
          />
        </Col>
      </Row>

      {/* Mid row — KPIs */}
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} md={12} lg={8}>
          <Card title="Today's Attendance" variant="outlined" style={{ height: '100%' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
              <Progress
                type="dashboard"
                percent={Number(attendancePct.toFixed(0))}
                size={120}
                strokeColor={
                  attendancePct >= 80 ? '#16a34a' : attendancePct >= 60 ? '#f59e0b' : '#dc2626'
                }
              />
              <Space direction="vertical" size={2}>
                <div>
                  <Tag color="green">{data.today_attendance.present}</Tag> Present
                </div>
                <div>
                  <Tag color="red">{data.today_attendance.absent}</Tag> Absent
                </div>
                <div>
                  <Tag color="orange">{data.today_attendance.late}</Tag> Late
                </div>
                <div>
                  <Tag color="blue">{data.today_attendance.excused}</Tag> Excused
                </div>
              </Space>
            </div>
          </Card>
        </Col>

        <Col xs={24} md={12} lg={8}>
          <Card title="Attendance Breakdown" variant="outlined" style={{ height: '100%' }}>
            {attendanceBreakdown.length > 0 ? (
              <Pie
                data={attendanceBreakdown}
                angleField="value"
                colorField="type"
                radius={0.9}
                innerRadius={0.55}
                height={200}
                legend={{ color: { position: 'bottom' } }}
                label={false}
                scale={{
                  color: {
                    range: attendanceBreakdown.map((d) => d.color),
                  },
                }}
              />
            ) : (
              <Empty description="No records yet today" />
            )}
          </Card>
        </Col>

        <Col xs={24} md={24} lg={8}>
          <Card title="Behavior This Week" variant="outlined" style={{ height: '100%' }}>
            <Row gutter={16}>
              <Col span={12}>
                <Statistic
                  title="Positive"
                  value={data.behavior_this_week.positive}
                  prefix={<SmileOutlined />}
                  valueStyle={{ color: '#16a34a' }}
                />
              </Col>
              <Col span={12}>
                <Statistic
                  title="Negative"
                  value={data.behavior_this_week.negative}
                  prefix={<FrownOutlined />}
                  valueStyle={{ color: '#dc2626' }}
                />
              </Col>
            </Row>
            <div style={{ marginTop: 18 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                <Text type="secondary" style={{ fontSize: 12 }}>
                  Positive share
                </Text>
                <Text style={{ fontSize: 12, fontWeight: 600 }}>{positivePct}%</Text>
              </div>
              <Progress
                percent={positivePct}
                strokeColor={{ from: '#16a34a', to: '#22c55e' }}
                showInfo={false}
              />
            </div>
          </Card>
        </Col>
      </Row>

      {/* Complaints summary */}
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="Open Complaints"
            value={data.complaints.open}
            valueColor={data.complaints.open > 0 ? '#dc2626' : '#16a34a'}
            tint="rgba(220,38,38,0.1)"
            icon={<WarningOutlined style={{ color: '#dc2626', fontSize: 20 }} />}
            footer={
              <Text type="secondary" style={{ fontSize: 12 }}>
                {data.complaints.in_review} in review
              </Text>
            }
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="This Month"
            value={data.complaints.this_month}
            tint="rgba(99,102,241,0.1)"
            icon={<MessageOutlined style={{ color: '#6366f1', fontSize: 20 }} />}
            footer={
              <Text type="secondary" style={{ fontSize: 12 }}>
                total complaints received
              </Text>
            }
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="Present Rate"
            value={attendancePct.toFixed(0)}
            suffix="%"
            valueColor={attendancePct >= 80 ? '#16a34a' : '#dc2626'}
            tint="rgba(22,163,74,0.1)"
            icon={<CheckCircleOutlined style={{ color: '#16a34a', fontSize: 20 }} />}
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="Behavior Events"
            value={data.behavior_this_week.total}
            tint="rgba(245,158,11,0.12)"
            icon={
              data.behavior_this_week.positive >= data.behavior_this_week.negative ? (
                <ArrowUpOutlined style={{ color: '#16a34a', fontSize: 20 }} />
              ) : (
                <ArrowDownOutlined style={{ color: '#dc2626', fontSize: 20 }} />
              )
            }
            footer={
              <Text type="secondary" style={{ fontSize: 12 }}>
                logged this week
              </Text>
            }
          />
        </Col>
      </Row>

      {/* Recent Complaints */}
      <Card
        title={
          <Space>
            <MessageOutlined />
            Recent Complaints
          </Space>
        }
        style={{ marginTop: 24 }}
        variant="outlined"
      >
        <Table
          dataSource={data.recent_complaints}
          columns={complaintColumns}
          rowKey="complaint_id"
          pagination={false}
          size="middle"
          locale={{ emptyText: <Empty description="No recent complaints" /> }}
        />
      </Card>
    </div>
  );
}
