import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Input, Card, Typography, Row, Col, Space, Tag,
  Descriptions, DatePicker, message,
} from 'antd';
import { EyeOutlined, AuditOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs, { Dayjs } from 'dayjs';

const { Title } = Typography;
const { RangePicker } = DatePicker;

const ACTION_COLORS: Record<string, string> = {
  POST: 'green', PUT: 'blue', DELETE: 'red', PATCH: 'orange',
};

const ROLE_COLORS: Record<string, string> = {
  admin: 'magenta', teacher: 'blue', student: 'cyan', parent: 'purple', driver: 'gold',
};

interface AuditLog {
  id: number;
  user_id: number;
  user_name: string;
  role: string;
  action: string;
  endpoint: string;
  resource: string;
  resource_id: string | null;
  old_values: Record<string, unknown> | null;
  new_values: Record<string, unknown> | null;
  ip_address: string;
  performed_at: string;
}

export default function AuditLogs() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);

  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string | undefined>();
  const [actionFilter, setActionFilter] = useState<string | undefined>();
  const [resourceFilter, setResourceFilter] = useState('');
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs] | null>(null);

  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<AuditLog | null>(null);

  const fetch = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (search) params.search = search;
      if (roleFilter) params.role = roleFilter;
      if (actionFilter) params.action = actionFilter;
      if (resourceFilter) params.resource = resourceFilter;
      if (dateRange) {
        params.from = dateRange[0].format('YYYY-MM-DD HH:mm:ss');
        params.to = dateRange[1].format('YYYY-MM-DD HH:mm:ss');
      }
      const res = await api.get('/admin/audit-logs', { params });
      const d = res.data.data || res.data;
      setLogs(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load audit logs'); }
    finally { setLoading(false); }
  }, [search, roleFilter, actionFilter, resourceFilter, dateRange, page]);

  useEffect(() => { fetch(); }, [fetch]);

  const openDetail = async (id: number) => {
    try {
      const res = await api.get(`/admin/audit-logs/${id}`);
      setSelected(res.data); setDetailOpen(true);
    } catch { message.error('Failed to load'); }
  };

  const renderValues = (v: Record<string, unknown> | null) => {
    if (!v || Object.keys(v).length === 0) return <span style={{ color: '#8c8c8c' }}>—</span>;
    return (
      <pre style={{ background: '#fafafa', padding: 8, margin: 0, fontSize: 12, maxHeight: 200, overflow: 'auto' }}>
        {JSON.stringify(v, null, 2)}
      </pre>
    );
  };

  const columns = [
    {
      title: 'Time', dataIndex: 'performed_at', key: 't', width: 160,
      render: (d: string) => dayjs(d).format('YYYY-MM-DD HH:mm:ss'),
    },
    {
      title: 'User', key: 'user',
      render: (_: unknown, r: AuditLog) => (
        <Space direction="vertical" size={0}>
          <span>{r.user_name}</span>
          <Tag color={ROLE_COLORS[r.role]} style={{ fontSize: 11 }}>{r.role}</Tag>
        </Space>
      ),
    },
    {
      title: 'Action', dataIndex: 'action', key: 'a', width: 100,
      render: (a: string) => <Tag color={ACTION_COLORS[a]}>{a}</Tag>,
    },
    { title: 'Resource', dataIndex: 'resource', key: 'r', width: 150 },
    { title: 'Resource ID', dataIndex: 'resource_id', key: 'rid', width: 120, render: (v: string) => v || '—' },
    { title: 'IP', dataIndex: 'ip_address', key: 'ip', width: 130 },
    {
      title: '', key: 'actions', width: 50,
      render: (_: unknown, r: AuditLog) => (
        <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r.id)} />
      ),
    },
  ];

  return (
    <div>
      <Title level={4} style={{ marginBottom: 16 }}>
        <AuditOutlined /> Audit Logs
      </Title>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Input.Search placeholder="Search user name" allowClear style={{ width: 220 }}
            onSearch={(v) => { setSearch(v); setPage(1); }}
          />
          <Select placeholder="Role" style={{ width: 130 }} allowClear
            value={roleFilter} onChange={(v) => { setRoleFilter(v); setPage(1); }}
            options={['admin', 'teacher', 'student', 'parent', 'driver'].map((r) => ({
              value: r, label: r.charAt(0).toUpperCase() + r.slice(1),
            }))}
          />
          <Select placeholder="Action" style={{ width: 130 }} allowClear
            value={actionFilter} onChange={(v) => { setActionFilter(v); setPage(1); }}
            options={['POST', 'PUT', 'DELETE', 'PATCH'].map((a) => ({ value: a, label: a }))}
          />
          <Input placeholder="Resource (e.g. students)" style={{ width: 200 }} allowClear
            value={resourceFilter} onChange={(e) => { setResourceFilter(e.target.value); setPage(1); }}
          />
          <RangePicker showTime value={dateRange}
            onChange={(v) => { setDateRange(v as [Dayjs, Dayjs] | null); setPage(1); }}
          />
        </Space>
      </Card>

      <Card>
        <Table size="small" loading={loading} dataSource={logs} rowKey="id" columns={columns}
          pagination={{ current: page, total, pageSize: 30, onChange: setPage, showTotal: (t) => `${t} logs` }}
        />
      </Card>

      <Modal title="Audit Log Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setSelected(null); }} footer={null} width={700}>
        {selected && (
          <>
            <Descriptions column={2} bordered size="small" style={{ marginBottom: 16 }}>
              <Descriptions.Item label="Time" span={2}>{dayjs(selected.performed_at).format('YYYY-MM-DD HH:mm:ss')}</Descriptions.Item>
              <Descriptions.Item label="User">{selected.user_name}</Descriptions.Item>
              <Descriptions.Item label="Role"><Tag color={ROLE_COLORS[selected.role]}>{selected.role}</Tag></Descriptions.Item>
              <Descriptions.Item label="Action"><Tag color={ACTION_COLORS[selected.action]}>{selected.action}</Tag></Descriptions.Item>
              <Descriptions.Item label="IP Address">{selected.ip_address}</Descriptions.Item>
              <Descriptions.Item label="Resource">{selected.resource}</Descriptions.Item>
              <Descriptions.Item label="Resource ID">{selected.resource_id || '—'}</Descriptions.Item>
              <Descriptions.Item label="Endpoint" span={2}>
                <code style={{ fontSize: 12 }}>{selected.endpoint}</code>
              </Descriptions.Item>
            </Descriptions>

            <Row gutter={16}>
              <Col span={12}>
                <Title level={5}>Old Values</Title>
                {renderValues(selected.old_values)}
              </Col>
              <Col span={12}>
                <Title level={5}>New Values</Title>
                {renderValues(selected.new_values)}
              </Col>
            </Row>
          </>
        )}
      </Modal>
    </div>
  );
}
