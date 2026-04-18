import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, Input, Card, Typography,
  Row, Col, Space, Tag, Descriptions, Statistic, Checkbox, message,
} from 'antd';
import { PlusOutlined, EyeOutlined, DeleteOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs from 'dayjs';

const { Title } = Typography;

const READ_COLOR: Record<string, string> = { read: 'green', unread: 'orange', delivered: 'blue' };

interface Notification {
  notification_id: number;
  title: string;
  createdbyuserid: number;
  channel: string;
  created_at: string;
  createdBy?: { id: number; name: string };
}

interface RecipientItem {
  recipient_id: number;
  user_id: number;
  name: string;
  role: string;
  status: string;
  readat: string | null;
}

interface NotificationDetail {
  notification: Notification;
  stats: { total: number; unread: number; read: number; delivered: number };
  recipients: RecipientItem[];
}

interface Section { section_id: number; name: string; school_class?: { name: string } }

export default function Notifications() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [sections, setSections] = useState<Section[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [channelFilter, setChannelFilter] = useState<string | undefined>();

  // Create modal
  const [createOpen, setCreateOpen] = useState(false);
  const [createLoading, setCreateLoading] = useState(false);
  const [form] = Form.useForm();
  const [targetMode, setTargetMode] = useState<'roles' | 'section'>('roles');

  // Detail modal
  const [detailOpen, setDetailOpen] = useState(false);
  const [detail, setDetail] = useState<NotificationDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);

  const fetchNotifications = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (channelFilter) params.channel = channelFilter;
      const res = await api.get('/admin/notifications', { params });
      const d = res.data.data || res.data;
      setNotifications(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load notifications'); }
    finally { setLoading(false); }
  }, [channelFilter, page]);

  const fetchSections = async () => {
    try {
      const res = await api.get('/admin/sections');
      setSections(res.data);
    } catch { /* ignore */ }
  };

  useEffect(() => { fetchSections(); }, []);
  useEffect(() => { fetchNotifications(); }, [fetchNotifications]);

  const openDetail = async (id: number) => {
    setDetailLoading(true); setDetailOpen(true);
    try {
      const res = await api.get(`/admin/notifications/${id}`);
      setDetail(res.data);
    } catch { message.error('Failed to load notification'); setDetailOpen(false); }
    finally { setDetailLoading(false); }
  };

  const handleDelete = (id: number) => {
    Modal.confirm({
      title: 'Delete this notification?',
      content: 'All recipient records will also be removed.',
      okType: 'danger',
      onOk: async () => {
        try {
          await api.delete(`/admin/notifications/${id}`);
          message.success('Notification deleted'); fetchNotifications();
        } catch { message.error('Failed to delete'); }
      },
    });
  };

  const handleCreate = async (values: Record<string, unknown>) => {
    setCreateLoading(true);
    try {
      const payload: Record<string, unknown> = { title: values.title, channel: values.channel };
      if (targetMode === 'section') {
        payload.section_id = values.section_id;
        payload.include_parents = values.include_parents || false;
      } else {
        payload.roles = values.roles;
      }
      const res = await api.post('/admin/notifications', payload);
      message.success(`Notification sent to ${res.data.recipients_count} recipients`);
      setCreateOpen(false); form.resetFields(); fetchNotifications();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to send');
    } finally { setCreateLoading(false); }
  };

  const columns = [
    {
      title: 'Date', dataIndex: 'created_at', key: 'date', width: 130,
      render: (d: string) => dayjs(d).format('YYYY-MM-DD HH:mm'),
    },
    { title: 'Title', dataIndex: 'title', key: 'title' },
    { title: 'Channel', dataIndex: 'channel', key: 'channel', width: 120, render: (c: string) => <Tag>{c}</Tag> },
    {
      title: 'Sent by', key: 'by',
      render: (_: unknown, r: Notification) => r.createdBy?.name || `#${r.createdbyuserid}`,
    },
    {
      title: 'Actions', key: 'actions', width: 130,
      render: (_: unknown, r: Notification) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r.notification_id)}>View</Button>
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.notification_id)} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Notifications</Title></Col>
        <Col>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => { form.resetFields(); setTargetMode('roles'); setCreateOpen(true); }}>
            Send Notification
          </Button>
        </Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Select placeholder="Channel" style={{ width: 200 }} allowClear
          value={channelFilter} onChange={(v) => { setChannelFilter(v); setPage(1); }}
          options={['app', 'email', 'sms', 'push'].map((c) => ({ value: c, label: c.toUpperCase() }))}
        />
      </Card>

      <Card>
        <Table
          dataSource={notifications} columns={columns} rowKey="notification_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} notifications` }}
          size="small"
        />
      </Card>

      {/* Create Modal */}
      <Modal
        title="Send Notification"
        open={createOpen}
        onCancel={() => { setCreateOpen(false); form.resetFields(); }}
        footer={null}
        width={500}
      >
        <Form form={form} layout="vertical" onFinish={handleCreate}>
          <Form.Item name="title" label="Title" rules={[{ required: true }]}>
            <Input placeholder="Notification title..." />
          </Form.Item>
          <Form.Item name="channel" label="Channel" rules={[{ required: true }]}>
            <Select options={['app', 'email', 'sms', 'push'].map((c) => ({ value: c, label: c.toUpperCase() }))} />
          </Form.Item>

          <Form.Item label="Target Audience">
            <Select value={targetMode} onChange={(v) => setTargetMode(v as 'roles' | 'section')} style={{ width: '100%' }}>
              <Select.Option value="roles">By Role</Select.Option>
              <Select.Option value="section">By Section</Select.Option>
            </Select>
          </Form.Item>

          {targetMode === 'roles' ? (
            <Form.Item name="roles" label="Roles" rules={[{ required: true, message: 'Select at least one role' }]}>
              <Select mode="multiple"
                options={['admin', 'teacher', 'student', 'parent'].map((r) => ({
                  value: r, label: r.charAt(0).toUpperCase() + r.slice(1),
                }))}
              />
            </Form.Item>
          ) : (
            <>
              <Form.Item name="section_id" label="Section" rules={[{ required: true }]}>
                <Select showSearch optionFilterProp="label"
                  options={sections.map((s) => ({
                    value: s.section_id, label: `${s.school_class?.name || ''} — ${s.name}`,
                  }))}
                />
              </Form.Item>
              <Form.Item name="include_parents" valuePropName="checked">
                <Checkbox>Also notify parents of students in this section</Checkbox>
              </Form.Item>
            </>
          )}

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={createLoading} block>Send</Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* Detail Modal */}
      <Modal title="Notification Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setDetail(null); }} footer={null} width={700}>
        {detailLoading ? <div>Loading...</div> : detail && (
          <>
            <Descriptions column={2} bordered size="small" style={{ marginBottom: 16 }}>
              <Descriptions.Item label="Title" span={2}>{detail.notification.title}</Descriptions.Item>
              <Descriptions.Item label="Channel"><Tag>{detail.notification.channel}</Tag></Descriptions.Item>
              <Descriptions.Item label="Sent">{dayjs(detail.notification.created_at).format('YYYY-MM-DD HH:mm')}</Descriptions.Item>
              <Descriptions.Item label="Sent By">{detail.notification.createdBy?.name || `#${detail.notification.createdbyuserid}`}</Descriptions.Item>
            </Descriptions>

            <Row gutter={12} style={{ marginBottom: 16 }}>
              <Col span={6}><Card size="small"><Statistic title="Total" value={detail.stats.total} /></Card></Col>
              <Col span={6}><Card size="small"><Statistic title="Read" value={detail.stats.read} valueStyle={{ color: 'green' }} /></Card></Col>
              <Col span={6}><Card size="small"><Statistic title="Unread" value={detail.stats.unread} valueStyle={{ color: 'orange' }} /></Card></Col>
              <Col span={6}><Card size="small"><Statistic title="Delivered" value={detail.stats.delivered} valueStyle={{ color: '#1677ff' }} /></Card></Col>
            </Row>

            <Table
              dataSource={detail.recipients} rowKey="recipient_id" pagination={{ pageSize: 10 }} size="small"
              columns={[
                { title: 'Name', dataIndex: 'name' },
                { title: 'Role', dataIndex: 'role', width: 90, render: (r: string) => <Tag>{r}</Tag> },
                {
                  title: 'Status', dataIndex: 'status', width: 100,
                  render: (s: string) => <Tag color={READ_COLOR[s]}>{s}</Tag>,
                },
                {
                  title: 'Read At', dataIndex: 'readat', width: 140,
                  render: (d: string | null) => d ? dayjs(d).format('YYYY-MM-DD HH:mm') : '—',
                },
              ]}
            />
          </>
        )}
      </Modal>
    </div>
  );
}
