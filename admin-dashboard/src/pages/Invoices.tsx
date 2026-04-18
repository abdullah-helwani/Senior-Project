import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, InputNumber, Card, Typography,
  Row, Col, Space, Tag, Descriptions, DatePicker, Checkbox, message,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs, { Dayjs } from 'dayjs';

const { Title } = Typography;
const { RangePicker } = DatePicker;

const STATUS_COLORS: Record<string, string> = {
  unpaid: 'red', partial: 'orange', paid: 'green', cancelled: 'default',
};

interface Invoice {
  invoice_id: number;
  account_id: number;
  due_date: string;
  totalamount: string | number;
  status: string;
  account?: {
    account_id: number;
    student?: { student_id: number; user?: { name: string } };
    feePlan?: { feeplan_id: number; name: string };
  };
}

interface InvoiceDetail {
  invoice: Invoice & {
    payments?: {
      payment_id: number; amount: string | number; method: string; paidat: string;
      guardian?: { parent_id: number; user?: { name: string } };
    }[];
  };
  paid_total: number;
  outstanding: number;
}

interface Account {
  account_id: number; balance: string | number;
  student?: { user?: { name: string } };
  feePlan?: { name: string };
}

export default function Invoices() {
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [statusFilter, setStatusFilter] = useState<string | undefined>();
  const [overdueFilter, setOverdueFilter] = useState(false);
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs] | null>(null);

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Invoice | null>(null);
  const [modalLoading, setModalLoading] = useState(false);
  const [form] = Form.useForm();

  const [detailOpen, setDetailOpen] = useState(false);
  const [detail, setDetail] = useState<InvoiceDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);

  const fetchInvoices = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number | boolean> = { page };
      if (statusFilter) params.status = statusFilter;
      if (overdueFilter) params.overdue = true;
      if (dateRange) { params.due_from = dateRange[0].format('YYYY-MM-DD'); params.due_to = dateRange[1].format('YYYY-MM-DD'); }
      const res = await api.get('/admin/invoices', { params });
      const d = res.data.data || res.data;
      setInvoices(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load invoices'); }
    finally { setLoading(false); }
  }, [statusFilter, overdueFilter, dateRange, page]);

  const fetchAccounts = async () => {
    try {
      const res = await api.get('/admin/student-fee-plans', { params: { per_page: 500 } });
      setAccounts(res.data.data || res.data);
    } catch { /* ignore */ }
  };

  useEffect(() => { fetchAccounts(); }, []);
  useEffect(() => { fetchInvoices(); }, [fetchInvoices]);

  const openCreate = () => { setEditing(null); form.resetFields(); setModalOpen(true); };
  const openEdit = (i: Invoice) => {
    setEditing(i);
    form.setFieldsValue({
      due_date: dayjs(i.due_date).format('YYYY-MM-DD'),
      totalamount: i.totalamount,
      status: i.status,
    });
    setModalOpen(true);
  };

  const handleSubmit = async (values: Record<string, unknown>) => {
    setModalLoading(true);
    try {
      if (editing) {
        await api.put(`/admin/invoices/${editing.invoice_id}`, values);
        message.success('Invoice updated');
      } else {
        await api.post('/admin/invoices', values);
        message.success('Invoice created');
      }
      setModalOpen(false); form.resetFields(); setEditing(null); fetchInvoices();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to save');
    } finally { setModalLoading(false); }
  };

  const handleDelete = (id: number) => {
    Modal.confirm({
      title: 'Delete this invoice?',
      content: 'Cannot delete if payments exist.',
      okType: 'danger',
      onOk: async () => {
        try {
          await api.delete(`/admin/invoices/${id}`);
          message.success('Deleted'); fetchInvoices();
        } catch (err: unknown) {
          const axiosErr = err as { response?: { data?: { message?: string } } };
          message.error(axiosErr.response?.data?.message || 'Failed to delete');
        }
      },
    });
  };

  const openDetail = async (id: number) => {
    setDetailLoading(true); setDetailOpen(true);
    try {
      const res = await api.get(`/admin/invoices/${id}`);
      setDetail(res.data);
    } catch { message.error('Failed to load detail'); setDetailOpen(false); }
    finally { setDetailLoading(false); }
  };

  const isOverdue = (inv: Invoice) =>
    inv.status !== 'paid' && inv.status !== 'cancelled' && dayjs(inv.due_date).isBefore(dayjs(), 'day');

  const columns = [
    { title: '#', dataIndex: 'invoice_id', key: 'id', width: 70 },
    {
      title: 'Student', key: 'student',
      render: (_: unknown, r: Invoice) => r.account?.student?.user?.name || '—',
    },
    {
      title: 'Fee Plan', key: 'plan',
      render: (_: unknown, r: Invoice) => r.account?.feePlan?.name || '—',
    },
    {
      title: 'Amount', dataIndex: 'totalamount', key: 'amt', width: 120,
      render: (v: string | number) => `$${Number(v).toFixed(2)}`,
    },
    {
      title: 'Due Date', dataIndex: 'due_date', key: 'due', width: 120,
      render: (d: string, r: Invoice) => (
        <span style={{ color: isOverdue(r) ? '#fa541c' : undefined, fontWeight: isOverdue(r) ? 500 : undefined }}>
          {dayjs(d).format('YYYY-MM-DD')}
          {isOverdue(r) && <Tag color="red" style={{ marginLeft: 6 }}>Overdue</Tag>}
        </span>
      ),
    },
    {
      title: 'Status', dataIndex: 'status', key: 'status', width: 110,
      render: (s: string) => <Tag color={STATUS_COLORS[s]}>{s.toUpperCase()}</Tag>,
    },
    {
      title: 'Actions', key: 'actions', width: 150,
      render: (_: unknown, r: Invoice) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r.invoice_id)} />
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.invoice_id)} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Invoices</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Create Invoice</Button></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Select placeholder="Status" style={{ width: 150 }} allowClear
            value={statusFilter} onChange={(v) => { setStatusFilter(v); setPage(1); }}
            options={['unpaid', 'partial', 'paid', 'cancelled'].map((s) => ({
              value: s, label: s.charAt(0).toUpperCase() + s.slice(1),
            }))}
          />
          <RangePicker placeholder={['Due from', 'Due to']}
            value={dateRange}
            onChange={(v) => { setDateRange(v as [Dayjs, Dayjs] | null); setPage(1); }}
          />
          <Checkbox checked={overdueFilter} onChange={(e) => { setOverdueFilter(e.target.checked); setPage(1); }}>
            Overdue only
          </Checkbox>
        </Space>
      </Card>

      <Card>
        <Table
          dataSource={invoices} columns={columns} rowKey="invoice_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} invoices` }}
          size="small"
        />
      </Card>

      <Modal title={editing ? 'Edit Invoice' : 'Create Invoice'}
        open={modalOpen} onCancel={() => { setModalOpen(false); setEditing(null); }} footer={null} width={500}>
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          {!editing && (
            <Form.Item name="account_id" label="Student Fee Account" rules={[{ required: true }]}>
              <Select showSearch optionFilterProp="label"
                options={accounts.map((a) => ({
                  value: a.account_id,
                  label: `${a.student?.user?.name || ''} — ${a.feePlan?.name || ''} (Bal: $${Number(a.balance).toFixed(2)})`,
                }))}
              />
            </Form.Item>
          )}
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="due_date" label="Due Date" rules={[{ required: true }]}>
                <Input type="date" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="totalamount" label="Total Amount" rules={[{ required: true }]}>
                <InputNumber min={0} style={{ width: '100%' }} prefix="$" />
              </Form.Item>
            </Col>
          </Row>
          {editing && (
            <Form.Item name="status" label="Status">
              <Select options={['unpaid', 'partial', 'paid', 'cancelled'].map((s) => ({
                value: s, label: s.charAt(0).toUpperCase() + s.slice(1),
              }))} />
            </Form.Item>
          )}
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={modalLoading} block>
              {editing ? 'Save Changes' : 'Create'}
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      <Modal title="Invoice Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setDetail(null); }} footer={null} width={650}>
        {detailLoading ? <div>Loading...</div> : detail && (
          <>
            <Descriptions column={2} bordered size="small" style={{ marginBottom: 16 }}>
              <Descriptions.Item label="Invoice #">{detail.invoice.invoice_id}</Descriptions.Item>
              <Descriptions.Item label="Status">
                <Tag color={STATUS_COLORS[detail.invoice.status]}>{detail.invoice.status.toUpperCase()}</Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Student">{detail.invoice.account?.student?.user?.name || '—'}</Descriptions.Item>
              <Descriptions.Item label="Fee Plan">{detail.invoice.account?.feePlan?.name || '—'}</Descriptions.Item>
              <Descriptions.Item label="Due Date">{dayjs(detail.invoice.due_date).format('YYYY-MM-DD')}</Descriptions.Item>
              <Descriptions.Item label="Total">${Number(detail.invoice.totalamount).toFixed(2)}</Descriptions.Item>
              <Descriptions.Item label="Paid">${Number(detail.paid_total).toFixed(2)}</Descriptions.Item>
              <Descriptions.Item label="Outstanding">
                <span style={{ color: detail.outstanding > 0 ? '#fa541c' : 'green', fontWeight: 500 }}>
                  ${Number(detail.outstanding).toFixed(2)}
                </span>
              </Descriptions.Item>
            </Descriptions>

            <Title level={5}>Payments</Title>
            <Table
              dataSource={detail.invoice.payments || []} rowKey="payment_id" pagination={false} size="small"
              columns={[
                { title: 'Date', dataIndex: 'paidat', width: 140, render: (d: string) => dayjs(d).format('YYYY-MM-DD HH:mm') },
                {
                  title: 'Parent', key: 'p',
                  render: (_: unknown, r) => r.guardian?.user?.name || `#${r.guardian?.parent_id}`,
                },
                { title: 'Method', dataIndex: 'method', width: 120, render: (m: string) => <Tag>{m}</Tag> },
                {
                  title: 'Amount', dataIndex: 'amount', width: 110,
                  render: (v: string | number) => `$${Number(v).toFixed(2)}`,
                },
              ]}
            />
          </>
        )}
      </Modal>
    </div>
  );
}
