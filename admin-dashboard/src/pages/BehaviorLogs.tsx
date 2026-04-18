import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Card, Typography, Row, Col, Space,
  Tag, DatePicker, Descriptions, message,
} from 'antd';
import { EyeOutlined, DeleteOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs, { Dayjs } from 'dayjs';

const { Title } = Typography;
const { RangePicker } = DatePicker;

const TYPE_COLORS: Record<string, string> = {
  positive: 'green', warning: 'orange', incident: 'red', note: 'blue',
};

interface BehaviorLog {
  log_id: number;
  student_id: number;
  teacher_id: number;
  section_id: number;
  type: string;
  title: string;
  description: string;
  date: string;
  notify_parent: boolean;
  student?: { student_id: number; user: { name: string } };
  teacher?: { teacher_id: number; user: { name: string } };
  section?: { section_id: number; name: string; schoolClass?: { name: string } };
}

interface Section { section_id: number; name: string; school_class?: { name: string } }

export default function BehaviorLogs() {
  const [logs, setLogs] = useState<BehaviorLog[]>([]);
  const [sections, setSections] = useState<Section[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [sectionFilter, setSectionFilter] = useState<number | undefined>();
  const [typeFilter, setTypeFilter] = useState<string | undefined>();
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs] | null>(null);

  // Detail modal
  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<BehaviorLog | null>(null);

  const fetchSections = async () => {
    try {
      const res = await api.get('/admin/sections');
      setSections(res.data);
    } catch { /* ignore */ }
  };

  const fetchLogs = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (sectionFilter) params.section_id = sectionFilter;
      if (typeFilter) params.type = typeFilter;
      if (dateRange) { params.from = dateRange[0].format('YYYY-MM-DD'); params.to = dateRange[1].format('YYYY-MM-DD'); }
      const res = await api.get('/admin/behavior-logs', { params });
      const d = res.data.data || res.data;
      setLogs(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load behavior logs'); }
    finally { setLoading(false); }
  }, [sectionFilter, typeFilter, dateRange, page]);

  useEffect(() => { fetchSections(); }, []);
  useEffect(() => { fetchLogs(); }, [fetchLogs]);

  const handleDelete = (id: number) => {
    Modal.confirm({
      title: 'Delete this behavior log?',
      okType: 'danger',
      onOk: async () => {
        try {
          await api.delete(`/admin/behavior-logs/${id}`);
          message.success('Log deleted'); fetchLogs();
        } catch { message.error('Failed to delete'); }
      },
    });
  };

  const openDetail = async (log: BehaviorLog) => {
    // Try to fetch full detail; fall back to list item
    try {
      const res = await api.get(`/admin/behavior-logs/${log.log_id}`);
      setSelected(res.data);
    } catch {
      setSelected(log);
    }
    setDetailOpen(true);
  };

  const typeColor = (t: string) => TYPE_COLORS[t?.toLowerCase()] || 'default';

  const columns = [
    {
      title: 'Date', dataIndex: 'date', key: 'date', width: 110,
      render: (d: string) => dayjs(d).format('YYYY-MM-DD'),
    },
    { title: 'Title', dataIndex: 'title', key: 'title' },
    {
      title: 'Type', dataIndex: 'type', key: 'type', width: 110,
      render: (t: string) => <Tag color={typeColor(t)}>{t}</Tag>,
    },
    {
      title: 'Student', key: 'student',
      render: (_: unknown, r: BehaviorLog) => r.student?.user?.name || `#${r.student_id}`,
    },
    {
      title: 'Teacher', key: 'teacher',
      render: (_: unknown, r: BehaviorLog) => r.teacher?.user?.name || `#${r.teacher_id}`,
    },
    {
      title: 'Section', key: 'section',
      render: (_: unknown, r: BehaviorLog) =>
        r.section ? `${r.section.schoolClass?.name || ''} — ${r.section.name}` : `#${r.section_id}`,
    },
    {
      title: 'Parent Notified', dataIndex: 'notify_parent', key: 'notify', width: 130,
      render: (v: boolean) => <Tag color={v ? 'green' : 'default'}>{v ? 'Yes' : 'No'}</Tag>,
    },
    {
      title: 'Actions', key: 'actions', width: 130,
      render: (_: unknown, r: BehaviorLog) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r)}>View</Button>
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.log_id)} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Behavior Logs</Title></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Select placeholder="Section" style={{ width: 260 }} allowClear showSearch optionFilterProp="label"
            value={sectionFilter} onChange={(v) => { setSectionFilter(v); setPage(1); }}
            options={sections.map((s) => ({ value: s.section_id, label: `${s.school_class?.name || ''} — ${s.name}` }))}
          />
          <Select placeholder="Type" style={{ width: 160 }} allowClear
            value={typeFilter} onChange={(v) => { setTypeFilter(v); setPage(1); }}
            options={['positive', 'warning', 'incident', 'note'].map((t) => ({
              value: t, label: t.charAt(0).toUpperCase() + t.slice(1),
            }))}
          />
          <RangePicker
            value={dateRange}
            onChange={(v) => { setDateRange(v as [Dayjs, Dayjs] | null); setPage(1); }}
          />
        </Space>
      </Card>

      <Card>
        <Table
          dataSource={logs} columns={columns} rowKey="log_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} logs` }}
          size="small"
        />
      </Card>

      {/* Detail Modal */}
      <Modal title="Behavior Log Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setSelected(null); }} footer={null} width={600}>
        {selected && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Date">{dayjs(selected.date).format('YYYY-MM-DD')}</Descriptions.Item>
            <Descriptions.Item label="Type"><Tag color={typeColor(selected.type)}>{selected.type}</Tag></Descriptions.Item>
            <Descriptions.Item label="Title">{selected.title}</Descriptions.Item>
            <Descriptions.Item label="Description" span={1}>
              <span style={{ whiteSpace: 'pre-wrap' }}>{selected.description}</span>
            </Descriptions.Item>
            <Descriptions.Item label="Student">{selected.student?.user?.name || `#${selected.student_id}`}</Descriptions.Item>
            <Descriptions.Item label="Teacher">{selected.teacher?.user?.name || `#${selected.teacher_id}`}</Descriptions.Item>
            <Descriptions.Item label="Section">
              {selected.section ? `${selected.section.schoolClass?.name || ''} — ${selected.section.name}` : `#${selected.section_id}`}
            </Descriptions.Item>
            <Descriptions.Item label="Parent Notified">
              <Tag color={selected.notify_parent ? 'green' : 'default'}>{selected.notify_parent ? 'Yes' : 'No'}</Tag>
            </Descriptions.Item>
          </Descriptions>
        )}
      </Modal>
    </div>
  );
}
