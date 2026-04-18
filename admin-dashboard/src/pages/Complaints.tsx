import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, Input, Card, Typography,
  Row, Col, Space, Tag, Descriptions, message,
} from 'antd';
import { EyeOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs from 'dayjs';

const { Title } = Typography;
const { TextArea } = Input;

const STATUS_COLORS: Record<string, string> = {
  open: 'red', in_review: 'orange', resolved: 'green', dismissed: 'default',
};

interface Complaint {
  complaint_id: number;
  parent_id: number;
  student_id: number;
  subject: string;
  body: string;
  status: string;
  admin_reply: string | null;
  resolved_at: string | null;
  created_at: string;
  guardian?: { parent_id: number; user: { name: string; email: string } };
  student?: { student_id: number; user: { name: string } };
}

export default function Complaints() {
  const [complaints, setComplaints] = useState<Complaint[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [statusFilter, setStatusFilter] = useState<string | undefined>();

  // Detail + reply modal
  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<Complaint | null>(null);
  const [replyForm] = Form.useForm();
  const [replyLoading, setReplyLoading] = useState(false);

  const fetchComplaints = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (statusFilter) params.status = statusFilter;
      const res = await api.get('/admin/complaints', { params });
      const d = res.data.data || res.data;
      setComplaints(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load complaints'); }
    finally { setLoading(false); }
  }, [statusFilter, page]);

  useEffect(() => { fetchComplaints(); }, [fetchComplaints]);

  const openDetail = async (c: Complaint) => {
    try {
      const res = await api.get(`/admin/complaints/${c.complaint_id}`);
      setSelected(res.data);
    } catch { setSelected(c); }
    replyForm.setFieldsValue({ status: c.status, admin_reply: c.admin_reply || '' });
    setDetailOpen(true);
  };

  const handleReply = async (values: { status: string; admin_reply: string }) => {
    if (!selected) return;
    setReplyLoading(true);
    try {
      const res = await api.put(`/admin/complaints/${selected.complaint_id}`, values);
      message.success('Complaint updated');
      setSelected(res.data);
      // Update in list
      setComplaints((prev) => prev.map((c) => c.complaint_id === selected.complaint_id ? res.data : c));
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to update');
    } finally { setReplyLoading(false); }
  };

  const columns = [
    {
      title: 'Date', dataIndex: 'created_at', key: 'date', width: 120,
      render: (d: string) => dayjs(d).format('YYYY-MM-DD'),
    },
    { title: 'Subject', dataIndex: 'subject', key: 'subject' },
    {
      title: 'Status', dataIndex: 'status', key: 'status', width: 120,
      render: (s: string) => <Tag color={STATUS_COLORS[s]}>{s.replace('_', ' ').toUpperCase()}</Tag>,
    },
    {
      title: 'Parent', key: 'guardian',
      render: (_: unknown, r: Complaint) => r.guardian?.user?.name || `#${r.parent_id}`,
    },
    {
      title: 'Student', key: 'student',
      render: (_: unknown, r: Complaint) => r.student?.user?.name || `#${r.student_id}`,
    },
    {
      title: 'Actions', key: 'actions', width: 100,
      render: (_: unknown, r: Complaint) => (
        <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r)}>View</Button>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Complaints</Title></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Select placeholder="Status" style={{ width: 180 }} allowClear
          value={statusFilter} onChange={(v) => { setStatusFilter(v); setPage(1); }}
          options={['open', 'in_review', 'resolved', 'dismissed'].map((s) => ({
            value: s, label: s.replace('_', ' ').charAt(0).toUpperCase() + s.replace('_', ' ').slice(1),
          }))}
        />
      </Card>

      <Card>
        <Table
          dataSource={complaints} columns={columns} rowKey="complaint_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} complaints` }}
          size="small"
        />
      </Card>

      {/* Detail & Reply Modal */}
      <Modal
        title="Complaint Detail"
        open={detailOpen}
        onCancel={() => { setDetailOpen(false); setSelected(null); replyForm.resetFields(); }}
        footer={null}
        width={650}
      >
        {selected && (
          <>
            <Descriptions column={2} bordered size="small" style={{ marginBottom: 20 }}>
              <Descriptions.Item label="Date">{dayjs(selected.created_at).format('YYYY-MM-DD HH:mm')}</Descriptions.Item>
              <Descriptions.Item label="Status">
                <Tag color={STATUS_COLORS[selected.status]}>{selected.status.replace('_', ' ').toUpperCase()}</Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Parent">{selected.guardian?.user?.name || `#${selected.parent_id}`}</Descriptions.Item>
              <Descriptions.Item label="Student">{selected.student?.user?.name || `#${selected.student_id}`}</Descriptions.Item>
              <Descriptions.Item label="Subject" span={2}>{selected.subject}</Descriptions.Item>
              <Descriptions.Item label="Message" span={2}>
                <span style={{ whiteSpace: 'pre-wrap' }}>{selected.body}</span>
              </Descriptions.Item>
              {selected.admin_reply && (
                <Descriptions.Item label="Previous Reply" span={2}>
                  <span style={{ whiteSpace: 'pre-wrap', color: '#1677ff' }}>{selected.admin_reply}</span>
                </Descriptions.Item>
              )}
              {selected.resolved_at && (
                <Descriptions.Item label="Resolved At">
                  {dayjs(selected.resolved_at).format('YYYY-MM-DD HH:mm')}
                </Descriptions.Item>
              )}
            </Descriptions>

            <Form form={replyForm} layout="vertical" onFinish={handleReply}>
              <Form.Item name="status" label="Update Status" rules={[{ required: true }]}>
                <Select
                  options={['open', 'in_review', 'resolved', 'dismissed'].map((s) => ({
                    value: s, label: s.replace('_', ' ').charAt(0).toUpperCase() + s.replace('_', ' ').slice(1),
                  }))}
                />
              </Form.Item>
              <Form.Item name="admin_reply" label="Reply (optional)">
                <TextArea rows={4} placeholder="Write a reply to the parent..." />
              </Form.Item>
              <Space>
                <Button type="primary" htmlType="submit" loading={replyLoading}>Save</Button>
                <Button onClick={() => { setDetailOpen(false); setSelected(null); replyForm.resetFields(); }}>Cancel</Button>
              </Space>
            </Form>
          </>
        )}
      </Modal>
    </div>
  );
}
