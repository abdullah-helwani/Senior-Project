import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, Input, InputNumber, Card, Typography,
  Row, Col, Space, Tag, Descriptions, DatePicker, message,
} from 'antd';
import { PlusOutlined, EyeOutlined, DeleteOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs, { Dayjs } from 'dayjs';

const { Title } = Typography;
const { RangePicker } = DatePicker;

const METHODS = ['cash', 'card', 'bank_transfer', 'cheque', 'stripe'];
const METHOD_COLORS: Record<string, string> = {
  cash: 'green', card: 'blue', bank_transfer: 'cyan', cheque: 'purple', stripe: 'geekblue',
};

interface Payment {
  payment_id: number;
  invoice_id: number;
  parent_id: number;
  amount: string | number;
  method: string;
  paidat: string;
  status?: string | null;
  invoice?: {
    invoice_id: number; totalamount: string | number;
    account?: { student?: { user?: { name: string } }; };
  };
  guardian?: { parent_id: number; user?: { name: string } };
}

interface Invoice {
  invoice_id: number; totalamount: string | number; status: string;
  account?: { student_id: number; student?: { user?: { name: string } }; feePlan?: { name: string } };
}

interface Guardian { parent_id: number; user?: { name: string } }

export default function Payments() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [guardians, setGuardians] = useState<Guardian[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [methodFilter, setMethodFilter] = useState<string | undefined>();
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs] | null>(null);

  const [modalOpen, setModalOpen] = useState(false);
  const [modalLoading, setModalLoading] = useState(false);
  const [form] = Form.useForm();

  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<Payment | null>(null);

  const fetchPayments = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (methodFilter) params.method = methodFilter;
      if (dateRange) { params.paid_from = dateRange[0].format('YYYY-MM-DD'); params.paid_to = dateRange[1].format('YYYY-MM-DD'); }
      const res = await api.get('/admin/payments', { params });
      const d = res.data.data || res.data;
      setPayments(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load payments'); }
    finally { setLoading(false); }
  }, [methodFilter, dateRange, page]);

  const fetchOptions = async () => {
    try {
      const [iRes, pRes] = await Promise.all([
        api.get('/admin/invoices', { params: { per_page: 300, status: 'unpaid' } }),
        api.get('/admin/users', { params: { per_page: 500, role: 'parent' } }),
      ]);
      // Include partial also
      const unpaid = iRes.data.data || iRes.data;
      const partialRes = await api.get('/admin/invoices', { params: { per_page: 300, status: 'partial' } });
      const partial = partialRes.data.data || partialRes.data;
      setInvoices([...(Array.isArray(unpaid) ? unpaid : []), ...(Array.isArray(partial) ? partial : [])]);

      // Map guardians from users list (assumes users endpoint returns users with role=parent)
      const users = pRes.data.data || pRes.data;
      setGuardians((Array.isArray(users) ? users : []).map((u: { id: number; name: string; parent?: { parent_id: number } }) => ({
        parent_id: u.parent?.parent_id || u.id,
        user: { name: u.name },
      })));
    } catch { /* ignore */ }
  };

  useEffect(() => { fetchOptions(); }, []);
  useEffect(() => { fetchPayments(); }, [fetchPayments]);

  const openRecord = () => { form.resetFields(); setModalOpen(true); };

  const handleSubmit = async (values: Record<string, unknown>) => {
    setModalLoading(true);
    try {
      const payload = { ...values };
      if (values.paidat) payload.paidat = values.paidat;
      await api.post('/admin/payments', payload);
      message.success('Payment recorded');
      setModalOpen(false); form.resetFields(); fetchPayments();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to record payment');
    } finally { setModalLoading(false); }
  };

  const handleVoid = (id: number) => {
    Modal.confirm({
      title: 'Void this payment?',
      content: 'This will reverse the invoice status and student account balance.',
      okType: 'danger', okText: 'Void',
      onOk: async () => {
        try {
          await api.delete(`/admin/payments/${id}`);
          message.success('Payment voided'); fetchPayments();
        } catch { message.error('Failed to void'); }
      },
    });
  };

  const openDetail = async (id: number) => {
    try {
      const res = await api.get(`/admin/payments/${id}`);
      setSelected(res.data); setDetailOpen(true);
    } catch { message.error('Failed to load'); }
  };

  const columns = [
    {
      title: 'Date', dataIndex: 'paidat', key: 'date', width: 150,
      render: (d: string) => dayjs(d).format('YYYY-MM-DD HH:mm'),
    },
    { title: 'Invoice #', dataIndex: 'invoice_id', key: 'inv', width: 90 },
    {
      title: 'Student', key: 'student',
      render: (_: unknown, r: Payment) => r.invoice?.account?.student?.user?.name || '—',
    },
    {
      title: 'Parent', key: 'parent',
      render: (_: unknown, r: Payment) => r.guardian?.user?.name || `#${r.parent_id}`,
    },
    {
      title: 'Method', dataIndex: 'method', key: 'method', width: 130,
      render: (m: string) => <Tag color={METHOD_COLORS[m]}>{m.replace('_', ' ')}</Tag>,
    },
    {
      title: 'Amount', dataIndex: 'amount', key: 'amt', width: 120,
      render: (v: string | number) => <strong style={{ color: 'green' }}>${Number(v).toFixed(2)}</strong>,
    },
    {
      title: 'Actions', key: 'actions', width: 140,
      render: (_: unknown, r: Payment) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r.payment_id)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleVoid(r.payment_id)}>Void</Button>
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Payments</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openRecord}>Record Payment</Button></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Select placeholder="Method" style={{ width: 180 }} allowClear
            value={methodFilter} onChange={(v) => { setMethodFilter(v); setPage(1); }}
            options={METHODS.map((m) => ({ value: m, label: m.replace('_', ' ').toUpperCase() }))}
          />
          <RangePicker placeholder={['Paid from', 'Paid to']}
            value={dateRange}
            onChange={(v) => { setDateRange(v as [Dayjs, Dayjs] | null); setPage(1); }}
          />
        </Space>
      </Card>

      <Card>
        <Table
          dataSource={payments} columns={columns} rowKey="payment_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} payments` }}
          size="small"
        />
      </Card>

      {/* Record Payment Modal */}
      <Modal title="Record Payment" open={modalOpen} onCancel={() => setModalOpen(false)} footer={null} width={500}>
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          <Form.Item name="invoice_id" label="Invoice" rules={[{ required: true }]}>
            <Select showSearch optionFilterProp="label"
              options={invoices.map((i) => ({
                value: i.invoice_id,
                label: `#${i.invoice_id} — ${i.account?.student?.user?.name || ''} — $${Number(i.totalamount).toFixed(2)} (${i.status})`,
              }))}
            />
          </Form.Item>
          <Form.Item name="parent_id" label="Paying Parent" rules={[{ required: true }]}>
            <Select showSearch optionFilterProp="label"
              options={guardians.map((g) => ({ value: g.parent_id, label: g.user?.name || `#${g.parent_id}` }))}
            />
          </Form.Item>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="amount" label="Amount" rules={[{ required: true }]}>
                <InputNumber min={0.01} step={0.01} style={{ width: '100%' }} prefix="$" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="method" label="Method" rules={[{ required: true }]}>
                <Select options={METHODS.map((m) => ({ value: m, label: m.replace('_', ' ').toUpperCase() }))} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="paidat" label="Paid At (optional — defaults to now)">
            <Input type="datetime-local" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={modalLoading} block>Record Payment</Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* Detail Modal */}
      <Modal title="Payment Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setSelected(null); }} footer={null} width={500}>
        {selected && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Payment #">{selected.payment_id}</Descriptions.Item>
            <Descriptions.Item label="Date">{dayjs(selected.paidat).format('YYYY-MM-DD HH:mm')}</Descriptions.Item>
            <Descriptions.Item label="Invoice #">{selected.invoice_id}</Descriptions.Item>
            <Descriptions.Item label="Student">{selected.invoice?.account?.student?.user?.name || '—'}</Descriptions.Item>
            <Descriptions.Item label="Parent">{selected.guardian?.user?.name || `#${selected.parent_id}`}</Descriptions.Item>
            <Descriptions.Item label="Method">
              <Tag color={METHOD_COLORS[selected.method]}>{selected.method.replace('_', ' ')}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="Amount">
              <strong style={{ color: 'green' }}>${Number(selected.amount).toFixed(2)}</strong>
            </Descriptions.Item>
            {selected.status && <Descriptions.Item label="Status">{selected.status}</Descriptions.Item>}
          </Descriptions>
        )}
      </Modal>
    </div>
  );
}
