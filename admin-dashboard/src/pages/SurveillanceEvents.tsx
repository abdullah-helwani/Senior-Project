import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Input, Card, Typography,
  Row, Col, Space, Tag, Descriptions, DatePicker, Statistic, message,
} from 'antd';
import { EyeOutlined, DeleteOutlined, BarChartOutlined, AlertOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs, { Dayjs } from 'dayjs';

const { Title } = Typography;
const { RangePicker } = DatePicker;

const SEVERITY_COLORS: Record<string, string> = {
  low: 'blue', medium: 'orange', high: 'red', critical: 'magenta',
};

interface SurveillanceEvent {
  survevent_id: number;
  camera_id: number;
  detectedtype: string;
  detectedat: string;
  severity: string;
  relatedstudent_id: number | null;
  relatedsection_id: number | null;
  relatedassessment_id: number | null;
  camera?: { camera_id: number; location: string };
  student?: { student_id: number; user?: { name: string } };
  section?: { section_id: number; name: string; schoolClass?: { name: string } };
  assessment?: { assessment_id: number; title: string };
}

interface Summary {
  period: { from: string; to: string };
  total: number;
  by_type: Record<string, number>;
  by_severity: Record<string, number>;
  by_camera: Record<string, number>;
}

interface Camera { camera_id: number; location: string }
interface Section { section_id: number; name: string; school_class?: { name: string } }

export default function SurveillanceEvents() {
  const [events, setEvents] = useState<SurveillanceEvent[]>([]);
  const [cameras, setCameras] = useState<Camera[]>([]);
  const [sections, setSections] = useState<Section[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);

  const [cameraFilter, setCameraFilter] = useState<number | undefined>();
  const [typeFilter, setTypeFilter] = useState<string | undefined>();
  const [severityFilter, setSeverityFilter] = useState<string | undefined>();
  const [sectionFilter, setSectionFilter] = useState<number | undefined>();
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs] | null>(null);

  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<SurveillanceEvent | null>(null);

  const [summaryOpen, setSummaryOpen] = useState(false);
  const [summary, setSummary] = useState<Summary | null>(null);
  const [summaryLoading, setSummaryLoading] = useState(false);
  const [summaryRange, setSummaryRange] = useState<[Dayjs, Dayjs]>(
    [dayjs().subtract(30, 'day'), dayjs()]
  );

  const fetchEvents = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (cameraFilter) params.camera_id = cameraFilter;
      if (typeFilter) params.detectedtype = typeFilter;
      if (severityFilter) params.severity = severityFilter;
      if (sectionFilter) params.section_id = sectionFilter;
      if (dateRange) { params.from = dateRange[0].format('YYYY-MM-DD'); params.to = dateRange[1].format('YYYY-MM-DD'); }
      const res = await api.get('/admin/surveillance-events', { params });
      const d = res.data.data || res.data;
      setEvents(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load events'); }
    finally { setLoading(false); }
  }, [cameraFilter, typeFilter, severityFilter, sectionFilter, dateRange, page]);

  const fetchOptions = async () => {
    try {
      const [cRes, sRes] = await Promise.all([
        api.get('/admin/cameras', { params: { per_page: 200 } }),
        api.get('/admin/sections'),
      ]);
      setCameras(cRes.data.data || cRes.data);
      setSections(sRes.data);
    } catch { /* ignore */ }
  };

  useEffect(() => { fetchOptions(); }, []);
  useEffect(() => { fetchEvents(); }, [fetchEvents]);

  const openDetail = async (id: number) => {
    try {
      const res = await api.get(`/admin/surveillance-events/${id}`);
      setSelected(res.data); setDetailOpen(true);
    } catch { message.error('Failed to load event'); }
  };

  const handleDelete = (id: number) => Modal.confirm({
    title: 'Delete this surveillance event?',
    okType: 'danger',
    onOk: async () => {
      try { await api.delete(`/admin/surveillance-events/${id}`); message.success('Deleted'); fetchEvents(); }
      catch { message.error('Failed to delete'); }
    },
  });

  const loadSummary = async () => {
    setSummaryLoading(true);
    try {
      const params: Record<string, string | number> = {
        from: summaryRange[0].format('YYYY-MM-DD'),
        to: summaryRange[1].format('YYYY-MM-DD'),
      };
      if (cameraFilter) params.camera_id = cameraFilter;
      const res = await api.get('/admin/surveillance-events/summary', { params });
      setSummary(res.data);
    } catch { message.error('Failed to load summary'); }
    finally { setSummaryLoading(false); }
  };

  const openSummary = () => { setSummaryOpen(true); loadSummary(); };

  const columns = [
    {
      title: 'Detected At', dataIndex: 'detectedat', key: 'at', width: 160,
      render: (d: string) => dayjs(d).format('YYYY-MM-DD HH:mm'),
    },
    {
      title: 'Camera', key: 'camera',
      render: (_: unknown, r: SurveillanceEvent) => r.camera?.location || `#${r.camera_id}`,
    },
    {
      title: 'Type', dataIndex: 'detectedtype', key: 'type',
      render: (t: string) => <Tag icon={<AlertOutlined />}>{t}</Tag>,
    },
    {
      title: 'Severity', dataIndex: 'severity', key: 'sev', width: 110,
      render: (s: string) => <Tag color={SEVERITY_COLORS[s]}>{s.toUpperCase()}</Tag>,
    },
    {
      title: 'Student', key: 'student',
      render: (_: unknown, r: SurveillanceEvent) => r.student?.user?.name || (r.relatedstudent_id ? `#${r.relatedstudent_id}` : '—'),
    },
    {
      title: 'Section', key: 'section',
      render: (_: unknown, r: SurveillanceEvent) => {
        if (!r.section) return r.relatedsection_id ? `#${r.relatedsection_id}` : '—';
        return `${r.section.schoolClass?.name || ''} — ${r.section.name}`;
      },
    },
    {
      title: 'Actions', key: 'actions', width: 120,
      render: (_: unknown, r: SurveillanceEvent) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r.survevent_id)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.survevent_id)} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Surveillance Events</Title></Col>
        <Col><Button icon={<BarChartOutlined />} onClick={openSummary}>View Summary</Button></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Select placeholder="Camera" style={{ width: 220 }} allowClear showSearch optionFilterProp="label"
            value={cameraFilter} onChange={(v) => { setCameraFilter(v); setPage(1); }}
            options={cameras.map((c) => ({ value: c.camera_id, label: c.location }))}
          />
          <Input placeholder="Type (e.g. cheating)" style={{ width: 180 }} allowClear
            value={typeFilter} onChange={(e) => { setTypeFilter(e.target.value || undefined); setPage(1); }}
          />
          <Select placeholder="Severity" style={{ width: 150 }} allowClear
            value={severityFilter} onChange={(v) => { setSeverityFilter(v); setPage(1); }}
            options={['low', 'medium', 'high', 'critical'].map((s) => ({
              value: s, label: s.charAt(0).toUpperCase() + s.slice(1),
            }))}
          />
          <Select placeholder="Section" style={{ width: 220 }} allowClear showSearch optionFilterProp="label"
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
          dataSource={events} columns={columns} rowKey="survevent_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} events` }}
          size="small"
        />
      </Card>

      {/* Detail Modal */}
      <Modal title="Event Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setSelected(null); }} footer={null} width={550}>
        {selected && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Event ID">{selected.survevent_id}</Descriptions.Item>
            <Descriptions.Item label="Detected At">{dayjs(selected.detectedat).format('YYYY-MM-DD HH:mm:ss')}</Descriptions.Item>
            <Descriptions.Item label="Camera">{selected.camera?.location || `#${selected.camera_id}`}</Descriptions.Item>
            <Descriptions.Item label="Type"><Tag icon={<AlertOutlined />}>{selected.detectedtype}</Tag></Descriptions.Item>
            <Descriptions.Item label="Severity">
              <Tag color={SEVERITY_COLORS[selected.severity]}>{selected.severity.toUpperCase()}</Tag>
            </Descriptions.Item>
            {selected.student && (
              <Descriptions.Item label="Student">{selected.student.user?.name || `#${selected.relatedstudent_id}`}</Descriptions.Item>
            )}
            {selected.section && (
              <Descriptions.Item label="Section">
                {selected.section.schoolClass?.name || ''} — {selected.section.name}
              </Descriptions.Item>
            )}
            {selected.assessment && (
              <Descriptions.Item label="Assessment">{selected.assessment.title}</Descriptions.Item>
            )}
          </Descriptions>
        )}
      </Modal>

      {/* Summary Modal */}
      <Modal title="Surveillance Summary" open={summaryOpen} onCancel={() => setSummaryOpen(false)} footer={null} width={700}>
        <Space style={{ marginBottom: 16 }}>
          <RangePicker value={summaryRange} onChange={(v) => v && setSummaryRange(v as [Dayjs, Dayjs])} />
          <Button type="primary" onClick={loadSummary} loading={summaryLoading}>Refresh</Button>
        </Space>

        {summary && (
          <>
            <Row gutter={16} style={{ marginBottom: 16 }}>
              <Col span={8}><Card size="small"><Statistic title="Total Events" value={summary.total} /></Card></Col>
              <Col span={8}><Card size="small"><Statistic title="From" value={summary.period.from} /></Card></Col>
              <Col span={8}><Card size="small"><Statistic title="To" value={summary.period.to} /></Card></Col>
            </Row>

            <Row gutter={16}>
              <Col span={12}>
                <Card size="small" title="By Severity">
                  {Object.entries(summary.by_severity).map(([k, v]) => (
                    <div key={k} style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0' }}>
                      <Tag color={SEVERITY_COLORS[k]}>{k.toUpperCase()}</Tag>
                      <strong>{v}</strong>
                    </div>
                  ))}
                </Card>
              </Col>
              <Col span={12}>
                <Card size="small" title="By Type">
                  {Object.entries(summary.by_type).map(([k, v]) => (
                    <div key={k} style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0' }}>
                      <span>{k}</span>
                      <strong>{v}</strong>
                    </div>
                  ))}
                </Card>
              </Col>
            </Row>

            <Card size="small" title="By Camera" style={{ marginTop: 16 }}>
              {Object.entries(summary.by_camera).map(([cameraId, count]) => {
                const cam = cameras.find((c) => c.camera_id === Number(cameraId));
                return (
                  <div key={cameraId} style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0' }}>
                    <span>{cam?.location || `Camera #${cameraId}`}</span>
                    <strong>{count}</strong>
                  </div>
                );
              })}
            </Card>
          </>
        )}
      </Modal>
    </div>
  );
}
