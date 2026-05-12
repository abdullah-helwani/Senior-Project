import { useEffect, useState, useCallback, useRef } from 'react';
import {
  Table, Button, Select, Input, Modal, Card, Typography, Row, Col, Space, Tag,
  Checkbox, DatePicker, Tooltip, Divider, Form, InputNumber, message,
} from 'antd';
import {
  PrinterOutlined, EyeOutlined, DollarOutlined, CheckCircleOutlined,
  WarningOutlined, FileTextOutlined,
} from '@ant-design/icons';
import api from '../api/axios';
import dayjs, { Dayjs } from 'dayjs';

const { Title, Text } = Typography;
const { Search } = Input;
const { RangePicker } = DatePicker;

const STATUS_COLOR: Record<string, string> = {
  paid: 'green', partial: 'orange', unpaid: 'red', cancelled: 'default',
};
const STATUS_LABEL: Record<string, string> = {
  paid: 'Paid', partial: 'Partial', unpaid: 'Unpaid', cancelled: 'Cancelled',
};

function planTag(name: string): { label: string; color: string } {
  const l = (name || '').toLowerCase();
  if (l.includes('tuition'))                       return { label: 'Tuition',  color: 'blue'   };
  if (l.includes('bus'))                           return { label: 'Bus',      color: 'purple' };
  if (l.includes('activity') || l.includes('lab')) return { label: 'Activity', color: 'cyan'   };
  return { label: name, color: 'default' };
}

interface InvoiceRow {
  invoice_id: number;
  account_id: number;
  issued_date: string | null;
  due_date: string | null;
  totalamount: number;
  paid: number;
  remaining: number;
  status: string;
  is_overdue: boolean;
  notes: string | null;
  student_id: number | null;
  student_name: string | null;
  parent_name: string | null;
  parent_phone: string | null;
  fee_plan_name: string | null;
}

interface InvoiceDocument {
  invoice: {
    invoice_id: number;
    issued_date: string;
    due_date: string;
    totalamount: number;
    status: string;
    notes: string | null;
  };
  student: { student_id: number; name: string; class: string | null; address: string | null };
  parent:  { parent_id: number; name: string; email: string | null; phone: string | null };
  fee_plan: { name: string; school_year: string | null };
  payments: { payment_id: number; amount: number; method: string; paidat: string; parent_name: string | null }[];
  paid_total: number;
  outstanding: number;
}

export default function Invoices() {
  const [rows, setRows]                 = useState<InvoiceRow[]>([]);
  const [loading, setLoading]           = useState(true);
  const [page, setPage]                 = useState(1);
  const [total, setTotal]               = useState(0);

  const [search, setSearch]             = useState('');
  const [statusFilter, setStatusFilter] = useState<string | undefined>();
  const [feeTypeFilter, setFeeTypeFilter] = useState<string | undefined>();
  const [overdueOnly, setOverdueOnly]   = useState(false);
  const [issuedRange, setIssuedRange]   = useState<[Dayjs, Dayjs] | null>(null);
  const [dueRange, setDueRange]         = useState<[Dayjs, Dayjs] | null>(null);

  // Print preview state
  const [printOpen, setPrintOpen]       = useState(false);
  const [printDoc, setPrintDoc]         = useState<InvoiceDocument | null>(null);
  const [printLoading, setPrintLoading] = useState(false);
  const printAreaRef = useRef<HTMLDivElement>(null);

  // Record payment state
  const [payOpen, setPayOpen]           = useState(false);
  const [payTarget, setPayTarget]       = useState<InvoiceRow | null>(null);
  const [payLoading, setPayLoading]     = useState(false);
  const [payForm] = Form.useForm();

  // ── Fetch ──
  const fetchRows = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number | boolean> = { page, per_page: 20 };
      if (search.trim())   params.search   = search.trim();
      if (statusFilter)    params.status   = statusFilter;
      if (feeTypeFilter)   params.fee_type = feeTypeFilter;
      if (overdueOnly)     params.overdue  = true;
      if (issuedRange) {
        params.issued_from = issuedRange[0].format('YYYY-MM-DD');
        params.issued_to   = issuedRange[1].format('YYYY-MM-DD');
      }
      if (dueRange) {
        params.due_from = dueRange[0].format('YYYY-MM-DD');
        params.due_to   = dueRange[1].format('YYYY-MM-DD');
      }
      const res = await api.get('/admin/invoices', { params });
      const d = res.data.data || res.data;
      setRows(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load invoices'); }
    finally { setLoading(false); }
  }, [search, statusFilter, feeTypeFilter, overdueOnly, issuedRange, dueRange, page]);

  useEffect(() => { fetchRows(); }, [fetchRows]);

  // ── Open Print Preview ──
  const openPrint = async (invoiceId: number) => {
    setPrintLoading(true);
    setPrintOpen(true);
    try {
      const res = await api.get(`/admin/invoices/${invoiceId}`);
      setPrintDoc(res.data);
    } catch {
      message.error('Failed to load invoice');
      setPrintOpen(false);
    } finally { setPrintLoading(false); }
  };

  // Actual browser print — only the invoice area
  const doPrint = () => {
    const node = printAreaRef.current;
    if (!node) return;
    const win = window.open('', '_blank', 'width=900,height=1000');
    if (!win) return;
    win.document.write(`
      <html><head><title>Invoice #${printDoc?.invoice.invoice_id ?? ''}</title>
      <style>
        body { font-family: Arial, sans-serif; padding: 30px; color: #333; }
        h1 { margin: 0 0 4px 0; }
        table { width: 100%; border-collapse: collapse; margin-top: 12px; }
        th, td { padding: 8px 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f5f5f5; }
        .header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; border-bottom: 2px solid #1677ff; padding-bottom: 12px; }
        .meta { text-align: right; }
        .bill-to { margin: 16px 0; }
        .totals { float: right; margin-top: 16px; width: 320px; }
        .totals td { padding: 4px 8px; }
        .totals .grand { font-weight: bold; font-size: 16px; border-top: 2px solid #333; }
        .status-pill { display: inline-block; padding: 3px 10px; border-radius: 12px; font-size: 12px; font-weight: 500; }
        .paid { background: #d4f5d4; color: #2d7a2d; }
        .partial { background: #fff3cd; color: #b85c00; }
        .unpaid { background: #ffd6d6; color: #c92a2a; }
        .footer { margin-top: 40px; padding-top: 12px; border-top: 1px solid #ddd; font-size: 11px; color: #888; text-align: center; }
      </style></head><body>${node.innerHTML}</body></html>
    `);
    win.document.close();
    win.focus();
    setTimeout(() => { win.print(); }, 250);
  };

  // ── Mark as Paid ──
  const handleMarkPaid = (inv: InvoiceRow) => {
    Modal.confirm({
      title: 'Mark invoice as fully paid?',
      content: `This will record a $${inv.remaining.toFixed(2)} payment for ${inv.student_name}.`,
      onOk: async () => {
        try {
          await api.post(`/admin/invoices/${inv.invoice_id}/mark-paid`, { method: 'cash' });
          message.success('Invoice marked as paid');
          fetchRows();
        } catch (err: unknown) {
          const e = err as { response?: { data?: { message?: string } } };
          message.error(e.response?.data?.message || 'Failed');
        }
      },
    });
  };

  // ── Record Payment ──
  const openRecordPayment = (inv: InvoiceRow) => {
    setPayTarget(inv);
    payForm.setFieldsValue({ amount: inv.remaining, method: 'cash' });
    setPayOpen(true);
  };

  const handleRecordPayment = async (values: Record<string, unknown>) => {
    if (!payTarget) return;
    setPayLoading(true);
    try {
      const amount = Number(values.amount);
      if (amount >= payTarget.remaining) {
        await api.post(`/admin/invoices/${payTarget.invoice_id}/mark-paid`, { method: values.method });
      } else {
        await api.post('/admin/payments', {
          invoice_id: payTarget.invoice_id,
          amount,
          method: values.method,
        });
      }
      message.success('Payment recorded');
      setPayOpen(false); payForm.resetFields(); setPayTarget(null);
      fetchRows();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to record payment');
    } finally { setPayLoading(false); }
  };

  // ── Columns: each row = one billing document ──
  const columns = [
    {
      title: 'Invoice #', dataIndex: 'invoice_id', key: 'invoice_id', width: 90,
      render: (id: number) => (
        <span style={{ fontFamily: 'monospace', fontWeight: 500 }}>INV-{String(id).padStart(5, '0')}</span>
      ),
    },
    {
      title: 'Issued', dataIndex: 'issued_date', key: 'issued', width: 110,
      render: (d: string | null) => d ? dayjs(d).format('YYYY-MM-DD') : '—',
    },
    {
      title: 'Student', key: 'student', width: 180,
      render: (_: unknown, r: InvoiceRow) => r.student_name || `#${r.student_id}`,
    },
    {
      title: 'For', key: 'for', width: 110,
      render: (_: unknown, r: InvoiceRow) => {
        const t = planTag(r.fee_plan_name || '');
        return <Tag color={t.color}>{t.label}</Tag>;
      },
    },
    {
      title: 'Amount', dataIndex: 'totalamount', key: 'amt', width: 100,
      render: (v: number) => `$${Number(v).toFixed(2)}`,
    },
    {
      title: 'Paid', dataIndex: 'paid', key: 'paid', width: 100,
      render: (v: number) => <span style={{ color: 'green', fontWeight: 500 }}>${Number(v).toFixed(2)}</span>,
    },
    {
      title: 'Remaining', dataIndex: 'remaining', key: 'remaining', width: 100,
      render: (v: number) => (
        <span style={{ color: v > 0 ? '#fa541c' : 'green', fontWeight: 500 }}>
          ${Number(v).toFixed(2)}
        </span>
      ),
    },
    {
      title: 'Due', dataIndex: 'due_date', key: 'due', width: 130,
      render: (d: string | null, r: InvoiceRow) => (
        <span style={{ color: r.is_overdue ? '#fa541c' : undefined }}>
          {d ? dayjs(d).format('YYYY-MM-DD') : '—'}
          {r.is_overdue && <Tag color="red" style={{ marginLeft: 4, fontSize: 11 }}>Overdue</Tag>}
        </span>
      ),
    },
    {
      title: 'Status', dataIndex: 'status', key: 'status', width: 100,
      render: (s: string) => <Tag color={STATUS_COLOR[s]}>{STATUS_LABEL[s] || s}</Tag>,
    },
    {
      title: 'Actions', key: 'actions', width: 180,
      render: (_: unknown, r: InvoiceRow) => (
        <Space size={2}>
          <Tooltip title="Print / View document">
            <Button size="small" icon={<PrinterOutlined />} type="primary"
              onClick={() => openPrint(r.invoice_id)}>
              Print
            </Button>
          </Tooltip>
          {r.status !== 'paid' && r.status !== 'cancelled' && (
            <>
              <Tooltip title="Record payment">
                <Button size="small" icon={<DollarOutlined />}
                  onClick={() => openRecordPayment(r)} />
              </Tooltip>
              <Tooltip title="Mark fully paid">
                <Button size="small" icon={<CheckCircleOutlined />}
                  onClick={() => handleMarkPaid(r)} />
              </Tooltip>
            </>
          )}
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 12 }}>
        <Col>
          <Title level={4} style={{ margin: 0 }}>Invoices</Title>
          <Text type="secondary" style={{ fontSize: 13 }}>
            <FileTextOutlined /> Billing documents — view, print, record payments
          </Text>
        </Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Search placeholder="Search student name..." style={{ width: 220 }} allowClear
            onSearch={(v) => { setSearch(v); setPage(1); }}
            onChange={(e) => { if (!e.target.value) { setSearch(''); setPage(1); } }}
          />
          <Select placeholder="Status" style={{ width: 130 }} allowClear
            value={statusFilter} onChange={(v) => { setStatusFilter(v); setPage(1); }}
            options={[
              { value: 'paid',      label: 'Paid' },
              { value: 'partial',   label: 'Partial' },
              { value: 'unpaid',    label: 'Unpaid' },
              { value: 'cancelled', label: 'Cancelled' },
            ]}
          />
          <Select placeholder="Fee Type" style={{ width: 140 }} allowClear
            value={feeTypeFilter} onChange={(v) => { setFeeTypeFilter(v); setPage(1); }}
            options={[
              { value: 'tuition',  label: 'Tuition' },
              { value: 'bus',      label: 'Bus' },
              { value: 'activity', label: 'Activity / Lab' },
            ]}
          />
          <RangePicker placeholder={['Issued from', 'Issued to']}
            value={issuedRange}
            onChange={(v) => { setIssuedRange(v as [Dayjs, Dayjs] | null); setPage(1); }}
          />
          <RangePicker placeholder={['Due from', 'Due to']}
            value={dueRange}
            onChange={(v) => { setDueRange(v as [Dayjs, Dayjs] | null); setPage(1); }}
          />
          <Checkbox checked={overdueOnly}
            onChange={(e) => { setOverdueOnly(e.target.checked); setPage(1); }}>
            <WarningOutlined style={{ color: '#fa541c' }} /> Overdue only
          </Checkbox>
        </Space>
      </Card>

      <Card>
        <Table
          dataSource={rows} columns={columns} rowKey="invoice_id" loading={loading}
          scroll={{ x: 1200 }}
          pagination={{
            current: page, total, pageSize: 20, onChange: setPage,
            showTotal: (t) => `${t} invoices`, showSizeChanger: false,
          }}
          size="small"
        />
      </Card>

      {/* ── Printable Invoice Document Modal ── */}
      <Modal
        title={
          <Space>
            <FileTextOutlined />
            Invoice Document {printDoc ? `— INV-${String(printDoc.invoice.invoice_id).padStart(5, '0')}` : ''}
          </Space>
        }
        open={printOpen}
        onCancel={() => { setPrintOpen(false); setPrintDoc(null); }}
        width={780}
        footer={
          printDoc && (
            <Space>
              <Button onClick={() => { setPrintOpen(false); setPrintDoc(null); }}>Close</Button>
              <Button type="primary" icon={<PrinterOutlined />} onClick={doPrint}>
                Print Invoice
              </Button>
            </Space>
          )
        }
      >
        {printLoading ? (
          <div style={{ textAlign: 'center', padding: 40 }}>Loading...</div>
        ) : printDoc && (
          <div ref={printAreaRef}>
            {/* Document header */}
            <div className="header" style={{ display: 'flex', justifyContent: 'space-between',
              borderBottom: '2px solid #1677ff', paddingBottom: 12, marginBottom: 20 }}>
              <div>
                <h1 style={{ margin: 0, color: '#1677ff' }}>School Admin</h1>
                <Text type="secondary">Control Center · Finance Department</Text>
              </div>
              <div className="meta" style={{ textAlign: 'right' }}>
                <h2 style={{ margin: 0 }}>INVOICE</h2>
                <div style={{ fontSize: 14 }}>
                  <strong>#INV-{String(printDoc.invoice.invoice_id).padStart(5, '0')}</strong>
                </div>
                <span className={`status-pill ${printDoc.invoice.status}`}
                  style={{
                    display: 'inline-block', padding: '3px 10px', borderRadius: 12, fontSize: 12,
                    fontWeight: 500, marginTop: 6,
                    background: printDoc.invoice.status === 'paid' ? '#d4f5d4'
                              : printDoc.invoice.status === 'partial' ? '#fff3cd'
                              : printDoc.invoice.status === 'unpaid' ? '#ffd6d6' : '#eee',
                    color: printDoc.invoice.status === 'paid' ? '#2d7a2d'
                         : printDoc.invoice.status === 'partial' ? '#b85c00'
                         : printDoc.invoice.status === 'unpaid' ? '#c92a2a' : '#666',
                  }}>
                  {STATUS_LABEL[printDoc.invoice.status]?.toUpperCase()}
                </span>
              </div>
            </div>

            {/* Bill-To & Dates */}
            <Row gutter={20} className="bill-to">
              <Col span={12}>
                <Text type="secondary" style={{ fontSize: 12 }}>BILL TO</Text>
                <div style={{ fontWeight: 500, fontSize: 15 }}>{printDoc.parent.name || '—'}</div>
                <div style={{ fontSize: 13, color: '#666' }}>
                  {printDoc.parent.email && <div>{printDoc.parent.email}</div>}
                  {printDoc.parent.phone && <div>📞 {printDoc.parent.phone}</div>}
                </div>
                <div style={{ marginTop: 8 }}>
                  <Text type="secondary" style={{ fontSize: 12 }}>FOR STUDENT</Text>
                  <div style={{ fontWeight: 500 }}>{printDoc.student.name}</div>
                  {printDoc.student.class && (
                    <div style={{ fontSize: 13, color: '#666' }}>{printDoc.student.class}</div>
                  )}
                </div>
              </Col>
              <Col span={12} style={{ textAlign: 'right' }}>
                <div style={{ marginBottom: 8 }}>
                  <Text type="secondary" style={{ fontSize: 12 }}>ISSUE DATE</Text>
                  <div style={{ fontWeight: 500 }}>
                    {printDoc.invoice.issued_date ? dayjs(printDoc.invoice.issued_date).format('MMM D, YYYY') : '—'}
                  </div>
                </div>
                <div>
                  <Text type="secondary" style={{ fontSize: 12 }}>DUE DATE</Text>
                  <div style={{ fontWeight: 500 }}>
                    {printDoc.invoice.due_date ? dayjs(printDoc.invoice.due_date).format('MMM D, YYYY') : '—'}
                  </div>
                </div>
                {printDoc.fee_plan.school_year && (
                  <div style={{ marginTop: 8 }}>
                    <Text type="secondary" style={{ fontSize: 12 }}>SCHOOL YEAR</Text>
                    <div style={{ fontWeight: 500 }}>{printDoc.fee_plan.school_year}</div>
                  </div>
                )}
              </Col>
            </Row>

            <Divider />

            {/* Line items */}
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ background: '#f5f5f5' }}>
                  <th style={{ padding: '8px 10px', textAlign: 'left', borderBottom: '1px solid #ddd' }}>Description</th>
                  <th style={{ padding: '8px 10px', textAlign: 'right', borderBottom: '1px solid #ddd', width: 120 }}>Amount</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td style={{ padding: '10px', borderBottom: '1px solid #ddd' }}>
                    <strong>{printDoc.fee_plan.name}</strong>
                    {printDoc.invoice.notes && (
                      <div style={{ fontSize: 12, color: '#666', marginTop: 4 }}>{printDoc.invoice.notes}</div>
                    )}
                  </td>
                  <td style={{ padding: '10px', textAlign: 'right', borderBottom: '1px solid #ddd' }}>
                    ${printDoc.invoice.totalamount.toFixed(2)}
                  </td>
                </tr>
              </tbody>
            </table>

            {/* Totals */}
            <div className="totals" style={{ float: 'right', width: 320, marginTop: 16 }}>
              <table style={{ width: '100%' }}>
                <tbody>
                  <tr>
                    <td style={{ padding: '4px 8px' }}>Subtotal:</td>
                    <td style={{ padding: '4px 8px', textAlign: 'right' }}>
                      ${printDoc.invoice.totalamount.toFixed(2)}
                    </td>
                  </tr>
                  <tr>
                    <td style={{ padding: '4px 8px', color: 'green' }}>Amount Paid:</td>
                    <td style={{ padding: '4px 8px', textAlign: 'right', color: 'green' }}>
                      −${printDoc.paid_total.toFixed(2)}
                    </td>
                  </tr>
                  <tr className="grand"
                    style={{ borderTop: '2px solid #333', fontWeight: 'bold', fontSize: 16 }}>
                    <td style={{ padding: '8px 8px' }}>AMOUNT DUE:</td>
                    <td style={{ padding: '8px 8px', textAlign: 'right',
                      color: printDoc.outstanding > 0 ? '#fa541c' : 'green' }}>
                      ${printDoc.outstanding.toFixed(2)}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div style={{ clear: 'both' }} />

            {/* Payment history */}
            {printDoc.payments.length > 0 && (
              <>
                <Divider />
                <Text strong>Payment History</Text>
                <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: 8 }}>
                  <thead>
                    <tr style={{ background: '#f5f5f5' }}>
                      <th style={{ padding: '6px 10px', textAlign: 'left', borderBottom: '1px solid #ddd' }}>Date</th>
                      <th style={{ padding: '6px 10px', textAlign: 'left', borderBottom: '1px solid #ddd' }}>Method</th>
                      <th style={{ padding: '6px 10px', textAlign: 'left', borderBottom: '1px solid #ddd' }}>Paid By</th>
                      <th style={{ padding: '6px 10px', textAlign: 'right', borderBottom: '1px solid #ddd' }}>Amount</th>
                    </tr>
                  </thead>
                  <tbody>
                    {printDoc.payments.map((p) => (
                      <tr key={p.payment_id}>
                        <td style={{ padding: '6px 10px', borderBottom: '1px solid #eee' }}>
                          {dayjs(p.paidat).format('YYYY-MM-DD HH:mm')}
                        </td>
                        <td style={{ padding: '6px 10px', borderBottom: '1px solid #eee' }}>
                          {p.method.toUpperCase()}
                        </td>
                        <td style={{ padding: '6px 10px', borderBottom: '1px solid #eee' }}>
                          {p.parent_name || '—'}
                        </td>
                        <td style={{ padding: '6px 10px', textAlign: 'right', borderBottom: '1px solid #eee',
                          color: 'green', fontWeight: 500 }}>
                          ${p.amount.toFixed(2)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </>
            )}

            {/* Footer */}
            <div className="footer" style={{ marginTop: 40, paddingTop: 12, borderTop: '1px solid #ddd',
              fontSize: 11, color: '#888', textAlign: 'center' }}>
              Thank you for your continued support. For any questions about this invoice,
              please contact the school finance office.
            </div>
          </div>
        )}
      </Modal>

      {/* ── Record Payment Modal ── */}
      <Modal
        title={payTarget ? `Record Payment — INV-${String(payTarget.invoice_id).padStart(5, '0')}` : ''}
        open={payOpen}
        onCancel={() => { setPayOpen(false); payForm.resetFields(); setPayTarget(null); }}
        footer={null}
        width={440}
      >
        {payTarget && (
          <div style={{ background: '#f6f6f6', borderRadius: 6, padding: '10px 12px', marginBottom: 16 }}>
            <div style={{ marginBottom: 4 }}>
              <Text strong>{payTarget.student_name}</Text>
              <Text type="secondary"> — {payTarget.fee_plan_name}</Text>
            </div>
            <Row gutter={16}>
              <Col span={8}>
                <Text type="secondary" style={{ fontSize: 12 }}>Total</Text>
                <div>${Number(payTarget.totalamount).toFixed(2)}</div>
              </Col>
              <Col span={8}>
                <Text type="secondary" style={{ fontSize: 12 }}>Already Paid</Text>
                <div style={{ color: 'green' }}>${Number(payTarget.paid).toFixed(2)}</div>
              </Col>
              <Col span={8}>
                <Text type="secondary" style={{ fontSize: 12 }}>Remaining</Text>
                <div style={{ color: '#fa541c', fontWeight: 500 }}>
                  ${Number(payTarget.remaining).toFixed(2)}
                </div>
              </Col>
            </Row>
          </div>
        )}
        <Form form={payForm} layout="vertical" onFinish={handleRecordPayment}>
          <Form.Item name="amount" label="Payment Amount ($)" rules={[{ required: true }]}>
            <InputNumber min={0.01} max={payTarget?.remaining} style={{ width: '100%' }} prefix="$" />
          </Form.Item>
          <Form.Item name="method" label="Payment Method" rules={[{ required: true }]}>
            <Select options={[
              { value: 'cash',          label: 'Cash' },
              { value: 'card',          label: 'Card' },
              { value: 'bank_transfer', label: 'Bank Transfer' },
              { value: 'cheque',        label: 'Cheque' },
            ]} />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={payLoading} block icon={<DollarOutlined />}>
              Record Payment
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
