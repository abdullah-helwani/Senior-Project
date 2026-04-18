import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, Input, Card, Typography,
  Row, Col, Space, Tag, Descriptions, Switch, message,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined, VideoCameraOutlined } from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

interface Camera {
  camera_id: number;
  location: string;
  isactive: boolean;
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

  useEffect(() => { fetchCameras(); }, [fetchCameras]);

  const openCreate = () => {
    setEditing(null);
    form.resetFields();
    form.setFieldsValue({ isactive: true });
    setModalOpen(true);
  };
  const openEdit = (c: Camera) => {
    setEditing(c);
    form.setFieldsValue({ location: c.location, isactive: c.isactive });
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

  const columns = [
    { title: 'Camera ID', dataIndex: 'camera_id', key: 'id', width: 100 },
    {
      title: 'Location', dataIndex: 'location', key: 'location',
      render: (loc: string) => <Space><VideoCameraOutlined />{loc}</Space>,
    },
    {
      title: 'Status', dataIndex: 'isactive', key: 'status', width: 100,
      render: (a: boolean) => <Tag color={a ? 'green' : 'default'}>{a ? 'Active' : 'Inactive'}</Tag>,
    },
    {
      title: 'Actions', key: 'actions', width: 160,
      render: (_: unknown, r: Camera) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r.camera_id)} />
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.camera_id)} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Cameras</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Add Camera</Button></Col>
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
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} cameras` }}
          size="small"
        />
      </Card>

      <Modal title={editing ? 'Edit Camera' : 'Add Camera'} open={modalOpen}
        onCancel={() => { setModalOpen(false); setEditing(null); }} footer={null} width={450}>
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          <Form.Item name="location" label="Location" rules={[{ required: true }]}>
            <Input placeholder="e.g. Main Entrance" />
          </Form.Item>
          <Form.Item name="isactive" label="Active" valuePropName="checked">
            <Switch />
          </Form.Item>
          <Button type="primary" htmlType="submit" loading={modalLoading} block>
            {editing ? 'Save Changes' : 'Add'}
          </Button>
        </Form>
      </Modal>

      <Modal title="Camera Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setSelected(null); }} footer={null} width={450}>
        {selected && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Camera ID">{selected.camera_id}</Descriptions.Item>
            <Descriptions.Item label="Location">{selected.location}</Descriptions.Item>
            <Descriptions.Item label="Status">
              <Tag color={selected.isactive ? 'green' : 'default'}>{selected.isactive ? 'Active' : 'Inactive'}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="Events Recorded">{selected.events_count ?? 0}</Descriptions.Item>
          </Descriptions>
        )}
      </Modal>
    </div>
  );
}
