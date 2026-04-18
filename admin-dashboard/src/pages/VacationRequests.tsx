import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Card, Typography,
  Row, Col, Space, Tag, Descriptions, message,
} from 'antd';
import { CheckOutlined, CloseOutlined, EyeOutlined, DeleteOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs from 'dayjs';

const { Title } = Typography;

const STATUS_COLORS: Record<string, string> = {
  pending: 'orange', approved: 'green', rejected: 'red',
};

interface VacationRequest {
  vacation_id: number;
  teacher_id: number;
  start_date: string;
  end_date: string;
  status: string;
  approvedbyadmin_id: number | null;
  teacher?: { id: number; user: { name: string } };
  approvedByAdmin?: { admin_id: number; user: { name: string } } | null;
}

export default function VacationRequests() {
  const [requests, setRequests] = useState<VacationRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [statusFilter, setStatusFilter] = useState<string | undefined>('pending');

  // Detail modal
  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<VacationRequest | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  const fetchRequests = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (statusFilter) params.status = statusFilter;
      const res = await api.get('/admin/vacation-requests', { params });
      const d = res.data.data || res.data;
      setRequests(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load vacation requests'); }
    finally { setLoading(false); }
  }, [statusFilter, page]);

  useEffect(() => { fetchRequests(); }, [fetchRequests]);

  const handleAction = async (id: number, status: 'approved' | 'rejected') => {
    setActionLoading(true);
    try {
      const res = await api.put(`/admin/vacation-requests/${id}`, { status });
      message.success(`Request ${status}`);
      // Update in list
      setRequests((prev) => prev.map((r) => r.vacation_id === id ? res.data : r));
      // Update detail if open
      if (selected?.vacation_id === id) setSelected(res.data);
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || `Failed to ${status}`);
    } finally { setActionLoading(false); }
  };

  const handleDelete = (id: number) => {
    Modal.confirm({
      title: 'Delete this vacation request?',
      okType: 'danger',
      onOk: async () => {
        try {
          await api.delete(`/admin/vacation-requests/${id}`);
          message.success('Request deleted');
          setDetailOpen(false);
          fetchRequests();
        } catch { message.error('Failed to delete'); }
      },
    });
  };

  const openDetail = async (req: VacationRequest) => {
    try {
      const res = await api.get(`/admin/vacation-requests/${req.vacation_id}`);
      setSelected(res.data);
    } catch { setSelected(req); }
    setDetailOpen(true);
  };

  const durationDays = (start: string, end: string) => dayjs(end).diff(dayjs(start), 'day') + 1;

  const columns = [
    {
      title: 'Teacher', key: 'teacher',
      render: (_: unknown, r: VacationRequest) => r.teacher?.user?.name || `#${r.teacher_id}`,
    },
    {
      title: 'Start', dataIndex: 'start_date', key: 'start', width: 110,
      render: (d: string) => dayjs(d).format('YYYY-MM-DD'),
    },
    {
      title: 'End', dataIndex: 'end_date', key: 'end', width: 110,
      render: (d: string) => dayjs(d).format('YYYY-MM-DD'),
    },
    {
      title: 'Days', key: 'days', width: 70,
      render: (_: unknown, r: VacationRequest) => durationDays(r.start_date, r.end_date),
    },
    {
      title: 'Status', dataIndex: 'status', key: 'status', width: 110,
      render: (s: string) => <Tag color={STATUS_COLORS[s]}>{s.toUpperCase()}</Tag>,
    },
    {
      title: 'Actions', key: 'actions', width: 230,
      render: (_: unknown, r: VacationRequest) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r)}>View</Button>
          {r.status === 'pending' && (
            <>
              <Button size="small" type="primary" icon={<CheckOutlined />}
                onClick={() => handleAction(r.vacation_id, 'approved')} loading={actionLoading}>
                Approve
              </Button>
              <Button size="small" danger icon={<CloseOutlined />}
                onClick={() => handleAction(r.vacation_id, 'rejected')} loading={actionLoading}>
                Reject
              </Button>
            </>
          )}
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.vacation_id)} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Vacation Requests</Title></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Select placeholder="Status" style={{ width: 180 }}
          value={statusFilter} onChange={(v) => { setStatusFilter(v); setPage(1); }}
          allowClear
          options={['pending', 'approved', 'rejected'].map((s) => ({
            value: s, label: s.charAt(0).toUpperCase() + s.slice(1),
          }))}
        />
      </Card>

      <Card>
        <Table
          dataSource={requests} columns={columns} rowKey="vacation_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} requests` }}
          size="small"
        />
      </Card>

      {/* Detail Modal */}
      <Modal
        title="Vacation Request Detail"
        open={detailOpen}
        onCancel={() => { setDetailOpen(false); setSelected(null); }}
        footer={
          selected?.status === 'pending' ? (
            <Space>
              <Button icon={<CloseOutlined />} danger loading={actionLoading}
                onClick={() => handleAction(selected.vacation_id, 'rejected')}>Reject</Button>
              <Button type="primary" icon={<CheckOutlined />} loading={actionLoading}
                onClick={() => handleAction(selected.vacation_id, 'approved')}>Approve</Button>
            </Space>
          ) : null
        }
        width={500}
      >
        {selected && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Teacher">{selected.teacher?.user?.name || `#${selected.teacher_id}`}</Descriptions.Item>
            <Descriptions.Item label="Start Date">{dayjs(selected.start_date).format('YYYY-MM-DD')}</Descriptions.Item>
            <Descriptions.Item label="End Date">{dayjs(selected.end_date).format('YYYY-MM-DD')}</Descriptions.Item>
            <Descriptions.Item label="Duration">{durationDays(selected.start_date, selected.end_date)} days</Descriptions.Item>
            <Descriptions.Item label="Status">
              <Tag color={STATUS_COLORS[selected.status]}>{selected.status.toUpperCase()}</Tag>
            </Descriptions.Item>
            {selected.approvedByAdmin && (
              <Descriptions.Item label="Actioned By">
                {selected.approvedByAdmin.user?.name || `Admin #${selected.approvedbyadmin_id}`}
              </Descriptions.Item>
            )}
          </Descriptions>
        )}
      </Modal>
    </div>
  );
}
