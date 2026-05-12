import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, Input, Card, Typography,
  Row, Col, Space, Tag, Descriptions, Switch, message, Tooltip, Badge,
} from 'antd';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined,
  VideoCameraOutlined, PlayCircleOutlined, StopOutlined, ApiOutlined, SyncOutlined,
} from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

interface Camera {
  camera_id: number;
  location: string;
  isactive: boolean;
  code: string | null;
  stream_url: string | null;
  stream_id: string | null;
  events_count?: number;
}

export default function Cameras() {
  const [cameras, setCameras] = useState<Camera[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState('');
  const [activeFilter, setActiveFilter] = useState<boolean | undefined>();

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Camera | null>(null);
  const [modalLoading, setModalLoading] = useState(false);
  const [form] = Form.useForm();

  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<Camera | null>(null);

  const [streamModalOpen, setStreamModalOpen] = useState(false);
  const [streamCamera, setStreamCamera] = useState<Camera | null>(null);
  const [streamLoading, setStreamLoading] = useState(false);
  const [streamForm] = Form.useForm();

  const [kiraHealth, setKiraHealth] = useState<'ok' | 'down' | 'unknown'>('unknown');
  const [syncing, setSyncing] = useState(false);

  const fetchCameras = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number | boolean> = { page };
      if (search) params.search = search;
      if (activeFilter !== undefined) params.isactive = activeFilter;
      const res = await api.get('/admin/cameras', { params });
      const d = res.data.data || res.data;
      setCameras(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load cameras'); }
    finally { setLoading(false); }
  }, [search, activeFilter, page]);

  const checkKiraHealth = async () => {
    try {
      await api.get('/admin/ai-cameras/health');
      setKiraHealth('ok');
    } catch {
      setKiraHealth('down');
    }
  };

  const handleSync = async () => {
    setSyncing(true);
    try {
      const res = await api.post('/admin/ai-cameras/sync');
      message.success(res.data.message || 'Streams synced');
      fetchCameras();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Sync failed');
    } finally {
      setSyncing(false);
    }
  };

  useEffect(() => { fetchCameras(); }, [fetchCameras]);
  useEffect(() => { checkKiraHealth(); }, []);

  const openCreate = () => {
    setEditing(null);
    form.resetFields();
    form.setFieldsValue({ isactive: true });
    setModalOpen(true);
  };

  const openEdit = (c: Camera) => {
    setEditing(c);
    form.setFieldsValue({
      location: c.location,
      isactive: c.isactive,
      code: c.code,
      stream_url: c.stream_url,
    });
    setModalOpen(true);
  };

  const handleSubmit = async (values: Record<string, unknown>) => {
    setModalLoading(true);
    try {
      if (editing) {
        await api.put(`/admin/cameras/${editing.camera_id}`, values);
        message.success('Camera updated');
      } else {
        await api.post('/admin/cameras', values);
        message.success('Camera added');
      }
      setModalOpen(false); form.resetFields(); setEditing(null); fetchCameras();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to save');
    } finally { setModalLoading(false); }
  };

  const handleDelete = (id: number) => Modal.confirm({
    title: 'Delete this camera?',
    content: 'All associated surveillance events may be affected.',
    okType: 'danger',
    onOk: async () => {
      try { await api.delete(`/admin/cameras/${id}`); message.success('Deleted'); fetchCameras(); }
      catch { message.error('Failed to delete'); }
    },
  });

  const openDetail = async (id: number) => {
    try {
      const res = await api.get(`/admin/cameras/${id}`);
      setSelected(res.data); setDetailOpen(true);
    } catch { message.error('Failed to load'); }
  };

  const openStartStream = (c: Camera) => {
    setStreamCamera(c);
    streamForm.setFieldsValue({ camera_url: c.stream_url || '' });
    setStreamModalOpen(true);
  };

  const handleStartStream = async (values: { camera_url: string }) => {
    if (!streamCamera) return;
    setStreamLoading(true);
    try {
      await api.post(`/admin/ai-cameras/${streamCamera.camera_id}/start`, values);
      message.success(`Stream started for ${streamCamera.location}`);
      setStreamModalOpen(false);
      fetchCameras();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string; detail?: string } } };
      message.error(e.response?.data?.message || e.response?.data?.detail || 'Failed to start stream');
    } finally { setStreamLoading(false); }
  };

  const handleStopStream = (c: Camera) => Modal.confirm({
    title: `Stop stream for "${c.location}"?`,
    onOk: async () => {
      try {
        await api.post(`/admin/ai-cameras/${c.camera_id}/stop`);
        message.success('Stream stopped');
        fetchCameras();
      } catch (err: unknown) {
        const e = err as { response?: { data?: { message?: string } } };
        message.error(e.response?.data?.message || 'Failed to stop stream');
      }
    },
  });

  const columns = [
    { title: 'ID', dataIndex: 'camera_id', key: 'id', width: 60 },
    {
      title: 'Location', dataIndex: 'location', key: 'location',
      render: (loc: string) => <Space><VideoCameraOutlined />{loc}</Space>,
    },
    {
      title: 'Code (KIRA ID)', dataIndex: 'code', key: 'code', width: 160,
      render: (code: string | null) => code
        ? <Tag color="blue">{code}</Tag>
        : <span style={{ color: '#aaa' }}>—</span>,
    },
    {
      title: 'Status', dataIndex: 'isactive', key: 'status', width: 90,
      render: (a: boolean) => <Tag color={a ? 'green' : 'default'}>{a ? 'Active' : 'Inactive'}</Tag>,
    },
    {
      title: 'AI Stream', key: 'stream', width: 110,
      render: (_: unknown, r: Camera) => r.stream_id
        ? <Badge status="processing" text="Live" />
        : <Badge status="default" text="Off" />,
    },
    {
      title: 'Actions', key: 'actions', width: 200,
      render: (_: unknown, r: Camera) => (
        <Space>
          <Tooltip title="View detail">
            <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r.camera_id)} />
          </Tooltip>
          <Tooltip title="Edit">
            <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
          </Tooltip>
          {r.stream_id ? (
            <Tooltip title="Stop AI monitoring">
              <Button size="small" icon={<StopOutlined />} danger onClick={() => handleStopStream(r)} />
            </Tooltip>
          ) : (
            <Tooltip title="Start AI monitoring">
              <Button size="small" icon={<PlayCircleOutlined />} type="primary" onClick={() => openStartStream(r)} />
            </Tooltip>
          )}
          <Tooltip title="Delete">
            <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.camera_id)} />
          </Tooltip>
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col>
          <Space align="center">
            <Title level={4} style={{ margin: 0 }}>Cameras</Title>
            <Tooltip title="KIRA AI Service status">
              <Tag
                icon={<ApiOutlined />}
                color={kiraHealth === 'ok' ? 'green' : kiraHealth === 'down' ? 'red' : 'default'}
                style={{ cursor: 'pointer' }}
                onClick={checkKiraHealth}
              >
                KIRA {kiraHealth === 'ok' ? 'Online' : kiraHealth === 'down' ? 'Offline' : '…'}
              </Tag>
            </Tooltip>
          </Space>
        </Col>
        <Col>
          <Space>
            <Tooltip title="Sync stream status with KIRA — clears stale 'Live' badges after a KIRA restart">
              <Button icon={<SyncOutlined spin={syncing} />} loading={syncing} onClick={handleSync}>
                Sync Streams
              </Button>
            </Tooltip>
            <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Add Camera</Button>
          </Space>
        </Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Input.Search placeholder="Search by location" allowClear onSearch={(v) => { setSearch(v); setPage(1); }} style={{ width: 260 }} />
          <Select placeholder="Status" style={{ width: 150 }} allowClear
            value={activeFilter}
            onChange={(v) => { setActiveFilter(v); setPage(1); }}
            options={[
              { value: true, label: 'Active' },
              { value: false, label: 'Inactive' },
            ]}
          />
        </Space>
      </Card>

      <Card>
        <Table
          dataSource={cameras} columns={columns} rowKey="camera_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} cameras`, showSizeChanger: false }}
          size="small"
        />
      </Card>

      {/* Create / Edit Camera Modal */}
      <Modal title={editing ? 'Edit Camera' : 'Add Camera'} open={modalOpen}
        onCancel={() => { setModalOpen(false); setEditing(null); }} footer={null} width={480}>
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          <Form.Item name="location" label="Location" rules={[{ required: true }]}>
            <Input placeholder="e.g. Main Entrance" />
          </Form.Item>
          <Form.Item name="code" label="KIRA Camera ID" tooltip="The string ID used by the AI service, e.g. hallway-cam-01">
            <Input placeholder="e.g. hallway-cam-01" />
          </Form.Item>
          <Form.Item name="stream_url" label="Stream URL" tooltip="RTSP URL or '0' for USB webcam">
            <Input placeholder="rtsp://192.168.1.10:554/stream  or  0" />
          </Form.Item>
          <Form.Item name="isactive" label="Active" valuePropName="checked">
            <Switch />
          </Form.Item>
          <Button type="primary" htmlType="submit" loading={modalLoading} block>
            {editing ? 'Save Changes' : 'Add'}
          </Button>
        </Form>
      </Modal>

      {/* Start Stream Modal */}
      <Modal title={`Start AI Monitoring — ${streamCamera?.location}`} open={streamModalOpen}
        onCancel={() => setStreamModalOpen(false)} footer={null} width={480}>
        <Form form={streamForm} layout="vertical" onFinish={handleStartStream}>
          <Form.Item name="camera_url" label="Camera URL" rules={[{ required: true }]}
            tooltip="Use '0' for USB webcam, or an RTSP URL for IP cameras">
            <Input placeholder="0  (USB webcam)  or  rtsp://192.168.1.x:554/stream" />
          </Form.Item>
          <Button type="primary" icon={<PlayCircleOutlined />} htmlType="submit" loading={streamLoading} block>
            Start Monitoring
          </Button>
        </Form>
      </Modal>

      {/* Detail Modal */}
      <Modal title="Camera Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setSelected(null); }} footer={null} width={480}>
        {selected && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Camera ID">{selected.camera_id}</Descriptions.Item>
            <Descriptions.Item label="Location">{selected.location}</Descriptions.Item>
            <Descriptions.Item label="KIRA Code">{selected.code || '—'}</Descriptions.Item>
            <Descriptions.Item label="Stream URL">{selected.stream_url || '—'}</Descriptions.Item>
            <Descriptions.Item label="Status">
              <Tag color={selected.isactive ? 'green' : 'default'}>{selected.isactive ? 'Active' : 'Inactive'}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="AI Stream">
              {selected.stream_id
                ? <Badge status="processing" text={`Live — ${selected.stream_id}`} />
                : <Badge status="default" text="Not streaming" />}
            </Descriptions.Item>
            <Descriptions.Item label="Events Recorded">{selected.events_count ?? 0}</Descriptions.Item>
          </Descriptions>
        )}
      </Modal>
    </div>
  );
}
