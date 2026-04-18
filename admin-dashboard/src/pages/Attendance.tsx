import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Card, Typography, Row, Col, Space,
  Tag, Statistic, DatePicker, Descriptions, message,
} from 'antd';
import { EyeOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs, { Dayjs } from 'dayjs';

const { Title } = Typography;
const { RangePicker } = DatePicker;

const STATUS_COLORS: Record<string, string> = {
  present: 'green', absent: 'red', late: 'orange', excused: 'blue',
};

interface Session {
  session_id: number;
  section_id: number;
  date: string;
  section?: { section_id: number; name: string; schoolClass?: { name: string } };
}

interface AttendanceRecord {
  attendance_id: number;
  student_id: number;
  name: string;
  status: string;
}

interface SessionDetail {
  session: Session;
  summary: { present: number; absent: number; late: number; excused: number };
  students: AttendanceRecord[];
}

interface StudentSummary {
  student_id: number;
  total_sessions: number;
  present: number;
  absent: number;
  late: number;
  excused: number;
  percentage: number;
}

interface Section { section_id: number; name: string; school_class?: { name: string } }

export default function Attendance() {
  const [sessions, setSessions] = useState<Session[]>([]);
  const [sections, setSections] = useState<Section[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [sectionFilter, setSectionFilter] = useState<number | undefined>();
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs] | null>(null);

  // Detail modal
  const [detailOpen, setDetailOpen] = useState(false);
  const [detailData, setDetailData] = useState<SessionDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);

  // Edit status modal
  const [editOpen, setEditOpen] = useState(false);
  const [editRecord, setEditRecord] = useState<AttendanceRecord | null>(null);
  const [editStatus, setEditStatus] = useState('');
  const [editSessionId, setEditSessionId] = useState<number | null>(null);
  const [editLoading, setEditLoading] = useState(false);

  const fetchSections = async () => {
    try {
      const res = await api.get('/admin/sections');
      setSections(res.data);
    } catch { /* ignore */ }
  };

  const fetchSessions = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (sectionFilter) params.section_id = sectionFilter;
      if (dateRange) { params.from = dateRange[0].format('YYYY-MM-DD'); params.to = dateRange[1].format('YYYY-MM-DD'); }
      const res = await api.get('/admin/attendance', { params });
      const d = res.data.data || res.data;
      setSessions(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load attendance'); }
    finally { setLoading(false); }
  }, [sectionFilter, dateRange, page]);

  useEffect(() => { fetchSections(); }, []);
  useEffect(() => { fetchSessions(); }, [fetchSessions]);

  const openDetail = async (sessionId: number) => {
    setDetailLoading(true); setDetailOpen(true);
    try {
      const res = await api.get(`/admin/attendance/${sessionId}`);
      setDetailData(res.data);
    } catch { message.error('Failed to load session'); setDetailOpen(false); }
    finally { setDetailLoading(false); }
  };

  const openEdit = (record: AttendanceRecord, sessionId: number) => {
    setEditRecord(record); setEditStatus(record.status);
    setEditSessionId(sessionId); setEditOpen(true);
  };

  const handleEditSave = async () => {
    if (!editRecord || !editSessionId) return;
    setEditLoading(true);
    try {
      await api.put(`/admin/attendance/${editSessionId}/records/${editRecord.attendance_id}`, { status: editStatus });
      message.success('Status updated');
      setEditOpen(false);
      // Refresh detail if open
      if (detailOpen && detailData) {
        const res = await api.get(`/admin/attendance/${editSessionId}`);
        setDetailData(res.data);
      }
    } catch { message.error('Failed to update'); }
    finally { setEditLoading(false); }
  };

  const handleDelete = (sessionId: number) => {
    Modal.confirm({
      title: 'Delete this attendance session?',
      content: 'All student records in this session will be removed.',
      okType: 'danger',
      onOk: async () => {
        try {
          await api.delete(`/admin/attendance/${sessionId}`);
          message.success('Session deleted'); fetchSessions();
        } catch { message.error('Failed to delete'); }
      },
    });
  };

  const columns = [
    {
      title: 'Date', dataIndex: 'date', key: 'date', width: 120,
      render: (d: string) => dayjs(d).format('YYYY-MM-DD'),
    },
    {
      title: 'Section', key: 'section',
      render: (_: unknown, r: Session) =>
        `${r.section?.schoolClass?.name || r.section?.school_class?.name || ''} — ${r.section?.name || ''}`,
    },
    {
      title: 'Actions', key: 'actions', width: 160,
      render: (_: unknown, r: Session) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r.session_id)}>View</Button>
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.session_id)} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Attendance</Title></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Select placeholder="Section" style={{ width: 260 }} allowClear showSearch optionFilterProp="label"
            value={sectionFilter} onChange={(v) => { setSectionFilter(v); setPage(1); }}
            options={sections.map((s) => ({ value: s.section_id, label: `${s.school_class?.name || ''} — ${s.name}` }))}
          />
          <RangePicker
            value={dateRange}
            onChange={(v) => { setDateRange(v as [Dayjs, Dayjs] | null); setPage(1); }}
          />
        </Space>
      </Card>

      <Card>
        <Table
          dataSource={sessions} columns={columns} rowKey="session_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} sessions` }}
          size="small"
        />
      </Card>

      {/* Session Detail Modal */}
      <Modal title="Attendance Session" open={detailOpen} onCancel={() => setDetailOpen(false)} footer={null} width={700}>
        {detailLoading ? <div>Loading...</div> : detailData && (
          <>
            <Descriptions column={2} size="small" bordered style={{ marginBottom: 16 }}>
              <Descriptions.Item label="Date">{dayjs(detailData.session.date).format('YYYY-MM-DD')}</Descriptions.Item>
              <Descriptions.Item label="Section">
                {`${detailData.session.section?.schoolClass?.name || ''} — ${detailData.session.section?.name || ''}`}
              </Descriptions.Item>
            </Descriptions>

            <Row gutter={12} style={{ marginBottom: 16 }}>
              {(['present', 'absent', 'late', 'excused'] as const).map((s) => (
                <Col span={6} key={s}>
                  <Card size="small">
                    <Statistic title={s.charAt(0).toUpperCase() + s.slice(1)} value={detailData.summary[s]} valueStyle={{ color: STATUS_COLORS[s] }} />
                  </Card>
                </Col>
              ))}
            </Row>

            <Table
              dataSource={detailData.students} rowKey="attendance_id" pagination={false} size="small"
              columns={[
                { title: 'Student', dataIndex: 'name' },
                {
                  title: 'Status', dataIndex: 'status',
                  render: (s: string) => <Tag color={STATUS_COLORS[s]}>{s.toUpperCase()}</Tag>,
                },
                {
                  title: '', key: 'edit', width: 60,
                  render: (_: unknown, r: AttendanceRecord) => (
                    <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r, detailData.session.session_id)} />
                  ),
                },
              ]}
            />
          </>
        )}
      </Modal>

      {/* Edit Status Modal */}
      <Modal title="Change Status" open={editOpen} onCancel={() => setEditOpen(false)}
        onOk={handleEditSave} okText="Save" confirmLoading={editLoading} width={320}>
        <div style={{ marginBottom: 8 }}><strong>{editRecord?.name}</strong></div>
        <Select value={editStatus} onChange={setEditStatus} style={{ width: '100%' }}
          options={['present', 'absent', 'late', 'excused'].map((s) => ({
            value: s, label: s.charAt(0).toUpperCase() + s.slice(1),
          }))}
        />
      </Modal>
    </div>
  );
}
