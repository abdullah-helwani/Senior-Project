import { useEffect, useState, useCallback } from 'react';
import {
  Tabs, Table, Button, Select, Modal, Form, Card, Typography,
  Row, Col, Space, Tag, Descriptions, DatePicker, Statistic, message,
} from 'antd';
import { PlusOutlined, EyeOutlined, DeleteOutlined, ReloadOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs, { Dayjs } from 'dayjs';

const { Title } = Typography;
const { RangePicker } = DatePicker;

const TYPE_COLORS: Record<string, string> = {
  attendance: 'blue', academic: 'green', behavior: 'purple',
};

interface Metric { metric_id: number; metricname: string; metricvalue: number | string; dimension?: string }
interface Report {
  report_id: number;
  reporttype: string;
  periodstart: string;
  periodend: string;
  generated_at: string;
  generatedbyadmin_id: number;
  metrics?: Metric[];
  generatedByAdmin?: { admin_id: number; user?: { name: string } };
}

interface LiveStats {
  period: { from: string; to: string };
  [key: string]: unknown;
}

interface Section { section_id: number; name: string; school_class?: { name: string } }
interface Subject { id: number; name: string }

function SavedReportsTab() {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [typeFilter, setTypeFilter] = useState<string | undefined>();
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs] | null>(null);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);

  const [modalOpen, setModalOpen] = useState(false);
  const [modalLoading, setModalLoading] = useState(false);
  const [form] = Form.useForm();

  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<Report | null>(null);

  const fetch = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (typeFilter) params.reporttype = typeFilter;
      if (dateRange) { params.from = dateRange[0].format('YYYY-MM-DD'); params.to = dateRange[1].format('YYYY-MM-DD'); }
      const res = await api.get('/admin/analytics/reports', { params });
      const d = res.data.data || res.data;
      setReports(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load reports'); }
    finally { setLoading(false); }
  }, [typeFilter, dateRange, page]);

  useEffect(() => { fetch(); }, [fetch]);

  const openCreate = () => { form.resetFields(); setModalOpen(true); };

  const onGenerate = async (values: Record<string, unknown>) => {
    setModalLoading(true);
    try {
      await api.post('/admin/analytics/reports', values);
      message.success('Report generated');
      setModalOpen(false); form.resetFields(); fetch();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to generate');
    } finally { setModalLoading(false); }
  };

  const openDetail = async (id: number) => {
    try {
      const res = await api.get(`/admin/analytics/reports/${id}`);
      setSelected(res.data); setDetailOpen(true);
    } catch { message.error('Failed to load'); }
  };

  const onDelete = (id: number) => Modal.confirm({
    title: 'Delete this report?', okType: 'danger',
    onOk: async () => {
      try { await api.delete(`/admin/analytics/reports/${id}`); message.success('Deleted'); fetch(); }
      catch { message.error('Failed to delete'); }
    },
  });

  return (
    <>
      <Row justify="space-between" style={{ marginBottom: 16 }}>
        <Col>
          <Space wrap>
            <Select placeholder="Type" style={{ width: 180 }} allowClear
              value={typeFilter} onChange={(v) => { setTypeFilter(v); setPage(1); }}
              options={['attendance', 'academic', 'behavior'].map((t) => ({
                value: t, label: t.charAt(0).toUpperCase() + t.slice(1),
              }))}
            />
            <RangePicker value={dateRange} onChange={(v) => { setDateRange(v as [Dayjs, Dayjs] | null); setPage(1); }} />
          </Space>
        </Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Generate Report</Button></Col>
      </Row>

      <Table size="small" loading={loading} dataSource={reports} rowKey="report_id"
        pagination={{ current: page, total, pageSize: 20, onChange: setPage }}
        columns={[
          {
            title: 'Type', dataIndex: 'reporttype', width: 130,
            render: (t: string) => <Tag color={TYPE_COLORS[t]}>{t.toUpperCase()}</Tag>,
          },
          { title: 'Period Start', dataIndex: 'periodstart', width: 120, render: (d: string) => dayjs(d).format('YYYY-MM-DD') },
          { title: 'Period End', dataIndex: 'periodend', width: 120, render: (d: string) => dayjs(d).format('YYYY-MM-DD') },
          { title: 'Generated At', dataIndex: 'generated_at', width: 160, render: (d: string) => dayjs(d).format('YYYY-MM-DD HH:mm') },
          {
            title: 'Actions', key: 'a', width: 110,
            render: (_: unknown, r: Report) => (
              <Space>
                <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r.report_id)} />
                <Button size="small" icon={<DeleteOutlined />} danger onClick={() => onDelete(r.report_id)} />
              </Space>
            ),
          },
        ]}
      />

      <Modal title="Generate Report" open={modalOpen} onCancel={() => setModalOpen(false)} footer={null} width={500}>
        <Form form={form} layout="vertical" onFinish={onGenerate}>
          <Form.Item name="reporttype" label="Report Type" rules={[{ required: true }]}>
            <Select options={['attendance', 'academic', 'behavior'].map((t) => ({
              value: t, label: t.charAt(0).toUpperCase() + t.slice(1),
            }))} />
          </Form.Item>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="periodstart" label="Period Start" rules={[{ required: true }]}>
                <input type="date" style={{ width: '100%', padding: 4 }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="periodend" label="Period End" rules={[{ required: true }]}>
                <input type="date" style={{ width: '100%', padding: 4 }} />
              </Form.Item>
            </Col>
          </Row>
          <Button type="primary" htmlType="submit" loading={modalLoading} block>Generate</Button>
        </Form>
      </Modal>

      <Modal title="Report Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setSelected(null); }} footer={null} width={650}>
        {selected && (
          <>
            <Descriptions column={2} bordered size="small" style={{ marginBottom: 16 }}>
              <Descriptions.Item label="Type">
                <Tag color={TYPE_COLORS[selected.reporttype]}>{selected.reporttype.toUpperCase()}</Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Generated By">
                {selected.generatedByAdmin?.user?.name || `Admin #${selected.generatedbyadmin_id}`}
              </Descriptions.Item>
              <Descriptions.Item label="Period Start">{dayjs(selected.periodstart).format('YYYY-MM-DD')}</Descriptions.Item>
              <Descriptions.Item label="Period End">{dayjs(selected.periodend).format('YYYY-MM-DD')}</Descriptions.Item>
              <Descriptions.Item label="Generated At" span={2}>
                {dayjs(selected.generated_at).format('YYYY-MM-DD HH:mm:ss')}
              </Descriptions.Item>
            </Descriptions>

            <Title level={5}>Metrics</Title>
            <Table size="small" dataSource={selected.metrics || []} rowKey="metric_id" pagination={false}
              columns={[
                { title: 'Metric', dataIndex: 'metricname' },
                { title: 'Value', dataIndex: 'metricvalue', width: 140 },
                { title: 'Dimension', dataIndex: 'dimension', width: 160, render: (v: string) => v || '—' },
              ]}
            />
          </>
        )}
      </Modal>
    </>
  );
}

function LiveStatsTab() {
  const [sections, setSections] = useState<Section[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [activeType, setActiveType] = useState<'attendance' | 'academic' | 'behavior'>('attendance');
  const [range, setRange] = useState<[Dayjs, Dayjs]>([dayjs().subtract(30, 'day'), dayjs()]);
  const [sectionId, setSectionId] = useState<number | undefined>();
  const [subjectId, setSubjectId] = useState<number | undefined>();
  const [stats, setStats] = useState<LiveStats | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const [sRes, subRes] = await Promise.all([
          api.get('/admin/sections'),
          api.get('/admin/subjects'),
        ]);
        setSections(sRes.data);
        setSubjects(subRes.data);
      } catch { /* ignore */ }
    })();
  }, []);

  const loadStats = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = {
        from: range[0].format('YYYY-MM-DD'),
        to: range[1].format('YYYY-MM-DD'),
      };
      if (sectionId) params.section_id = sectionId;
      if (activeType === 'academic' && subjectId) params.subject_id = subjectId;
      const res = await api.get(`/admin/analytics/live/${activeType}`, { params });
      setStats(res.data);
    } catch { message.error('Failed to load stats'); }
    finally { setLoading(false); }
  }, [activeType, range, sectionId, subjectId]);

  useEffect(() => { loadStats(); }, [loadStats]);

  const renderStats = () => {
    if (!stats) return null;
    if (activeType === 'attendance') {
      return (
        <Row gutter={16}>
          <Col span={6}><Card size="small"><Statistic title="Total Records" value={Number(stats.total_records || 0)} /></Card></Col>
          <Col span={6}><Card size="small"><Statistic title="Present" value={Number(stats.present || 0)} valueStyle={{ color: 'green' }} /></Card></Col>
          <Col span={6}><Card size="small"><Statistic title="Absent" value={Number(stats.absent || 0)} valueStyle={{ color: 'red' }} /></Card></Col>
          <Col span={6}><Card size="small"><Statistic title="Late" value={Number(stats.late || 0)} valueStyle={{ color: 'orange' }} /></Card></Col>
          <Col span={6} style={{ marginTop: 16 }}>
            <Card size="small"><Statistic title="Excused" value={Number(stats.excused || 0)} /></Card>
          </Col>
          <Col span={6} style={{ marginTop: 16 }}>
            <Card size="small"><Statistic title="Attendance Rate" value={Number(stats.attendance_rate || 0)} suffix="%" precision={1} /></Card>
          </Col>
        </Row>
      );
    }
    if (activeType === 'academic') {
      return (
        <Row gutter={16}>
          <Col span={6}><Card size="small"><Statistic title="Total Results" value={Number(stats.total_results || 0)} /></Card></Col>
          <Col span={6}><Card size="small"><Statistic title="Average Score" value={Number(stats.average_score || 0)} precision={1} /></Card></Col>
          <Col span={6}><Card size="small"><Statistic title="Highest" value={Number(stats.highest_score || 0)} /></Card></Col>
          <Col span={6}><Card size="small"><Statistic title="Lowest" value={Number(stats.lowest_score || 0)} /></Card></Col>
          <Col span={6} style={{ marginTop: 16 }}>
            <Card size="small"><Statistic title="Pass" value={Number(stats.pass_count || 0)} valueStyle={{ color: 'green' }} /></Card>
          </Col>
          <Col span={6} style={{ marginTop: 16 }}>
            <Card size="small"><Statistic title="Fail" value={Number(stats.fail_count || 0)} valueStyle={{ color: 'red' }} /></Card>
          </Col>
          <Col span={12} style={{ marginTop: 16 }}>
            <Card size="small"><Statistic title="Pass Rate" value={Number(stats.pass_rate || 0)} suffix="%" precision={1} /></Card>
          </Col>
        </Row>
      );
    }
    return (
      <Row gutter={16}>
        <Col span={6}><Card size="small"><Statistic title="Total" value={Number(stats.total || 0)} /></Card></Col>
        <Col span={6}><Card size="small"><Statistic title="Positive" value={Number(stats.positive || 0)} valueStyle={{ color: 'green' }} /></Card></Col>
        <Col span={6}><Card size="small"><Statistic title="Negative" value={Number(stats.negative || 0)} valueStyle={{ color: 'red' }} /></Card></Col>
        <Col span={6}><Card size="small"><Statistic title="Neutral" value={Number(stats.neutral || 0)} /></Card></Col>
      </Row>
    );
  };

  return (
    <>
      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Select value={activeType} onChange={(v) => setActiveType(v)} style={{ width: 160 }}
            options={[
              { value: 'attendance', label: 'Attendance' },
              { value: 'academic', label: 'Academic' },
              { value: 'behavior', label: 'Behavior' },
            ]}
          />
          <RangePicker value={range} onChange={(v) => v && setRange(v as [Dayjs, Dayjs])} />
          <Select placeholder="Section" style={{ width: 220 }} allowClear showSearch optionFilterProp="label"
            value={sectionId} onChange={setSectionId}
            options={sections.map((s) => ({ value: s.section_id, label: `${s.school_class?.name || ''} — ${s.name}` }))}
          />
          {activeType === 'academic' && (
            <Select placeholder="Subject" style={{ width: 180 }} allowClear showSearch optionFilterProp="label"
              value={subjectId} onChange={setSubjectId}
              options={subjects.map((s) => ({ value: s.id, label: s.name }))}
            />
          )}
          <Button icon={<ReloadOutlined />} onClick={loadStats} loading={loading}>Refresh</Button>
        </Space>
      </Card>
      {renderStats()}
    </>
  );
}

export default function AnalyticsReports() {
  return (
    <div>
      <Title level={4} style={{ marginBottom: 16 }}>Analytics</Title>
      <Card>
        <Tabs
          items={[
            { key: 'live', label: 'Live Stats', children: <LiveStatsTab /> },
            { key: 'saved', label: 'Saved Reports', children: <SavedReportsTab /> },
          ]}
        />
      </Card>
    </div>
  );
}
