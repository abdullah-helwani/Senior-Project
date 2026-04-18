import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, Input, InputNumber, Card, Typography,
  Row, Col, Space, Descriptions, DatePicker, message,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs, { Dayjs } from 'dayjs';

const { Title } = Typography;
const { RangePicker } = DatePicker;

interface SalaryPayment {
  salarypayment_id: number;
  teacher_id: number;
  amount: string | number;
  periodmonth: string;
  paidat: string;
  teacher?: { id: number; user?: { name: string } };
}

interface Teacher { id: number; user?: { name: string } }

export default function SalaryPayments() {
  const [payments, setPayments] = useState<SalaryPayment[]>([]);
  const [teachers, setTeachers] = useState<Teacher[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [teacherFilter, setTeacherFilter] = useState<number | undefined>();
  const [monthFilter, setMonthFilter] = useState<string | undefined>();
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs] | null>(null);

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<SalaryPayment | null>(null);
  const [modalLoading, setModalLoading] = useState(false);
  const [form] = Form.useForm();

  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<SalaryPayment | null>(null);

  const fetchPayments = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (teacherFilter) params.teacher_id = teacherFilter;
      if (monthFilter) params.period_month = monthFilter;
      if (dateRange) { params.from = dateRange[0].format('YYYY-MM-DD'); params.to = dateRange[1].format('YYYY-MM-DD'); }
      const res = await api.get('/admin/salary-payments', { params });
      const d = res.data.data || res.data;
      setPayments(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load salary payments'); }
    finally { setLoading(false); }
  }, [teacherFilter, monthFilter, dateRange, page]);

  const fetchTeachers = async () => {
    try {
      const res = await api.get('/admin/teachers', { params: { per_page: 300, status: 'active' } });
      setTeachers(res.data.data || res.data);
    } catch { /* ignore */ }
  };

  useEffect(() => { fetchTeachers(); }, []);
  useEffect(() => { fetchPayments(); }, [fetchPayments]);

  const openCreate = () => { setEditing(null); form.resetFields(); setModalOpen(true); };
  const openEdit = (p: SalaryPayment) => {
    setEditing(p);
    form.setFieldsValue({
      amount: p.amount,
      period_month: dayjs(p.periodmonth).format('YYYY-MM-DD'),
      paidat: dayjs(p.paidat).format('YYYY-MM-DDTHH:mm'),
    });
    setModalOpen(true);
  };

  const handleSubmit = async (values: Record<string, unknown>) => {
    setModalLoading(true);
    try {
      if (editing) {
        await api.put(`/admin/salary-payments/${editing.salarypayment_id}`, values);
        message.success('Updated');
      } else {
        await api.post('/admin/salary-payments', values);
        message.success('Salary payment recorded');
      }
      setModalOpen(false); form.resetFields(); setEditing(null); fetchPayments();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to save');
    } finally { setModalLoading(false); }
  };

  const handleDelete = (id: number) => {
    Modal.confirm({
      title: 'Delete this salary payment?',
      okType: 'danger',
      onOk: async () => {
        try {
          await api.delete(`/admin/salary-payments/${id}`);
          message.success('Deleted'); fetchPayments();
        } catch { message.error('Failed to delete'); }
      },
    });
  };

  const openDetail = (p: SalaryPayment) => { setSelected(p); setDetailOpen(true); };

  const columns = [
    {
      title: 'Teacher', key: 'teacher',
      render: (_: unknown, r: SalaryPayment) => r.teacher?.user?.name || `#${r.teacher_id}`,
    },
    {
      title: 'Period', dataIndex: 'periodmonth', key: 'period', width: 120,
      render: (d: string) => dayjs(d).format('MMM YYYY'),
    },
    {
      title: 'Paid Date', dataIndex: 'paidat', key: 'paid', width: 150,
      render: (d: string) => dayjs(d).format('YYYY-MM-DD HH:mm'),
    },
    {
      title: 'Amount', dataIndex: 'amount', key: 'amt', width: 120,
      render: (v: string | number) => <strong style={{ color: 'green' }}>${Number(v).toFixed(2)}</strong>,
    },
    {
      title: 'Actions', key: 'actions', width: 150,
      render: (_: unknown, r: SalaryPayment) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r)} />
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.salarypayment_id)} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Salary Payments</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Record Salary Payment</Button></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Select placeholder="Teacher" style={{ width: 220 }} allowClear showSearch optionFilterProp="label"
            value={teacherFilter} onChange={(v) => { setTeacherFilter(v); setPage(1); }}
            options={teachers.map((t) => ({ value: t.id, label: t.user?.name || `Teacher #${t.id}` }))}
          />
          <Input type="month" placeholder="Period (YYYY-MM)" style={{ width: 180 }}
            value={monthFilter} onChange={(e) => { setMonthFilter(e.target.value); setPage(1); }} />
          <RangePicker placeholder={['Paid from', 'Paid to']}
            value={dateRange}
            onChange={(v) => { setDateRange(v as [Dayjs, Dayjs] | null); setPage(1); }}
          />
        </Space>
      </Card>

      <Card>
        <Table
          dataSource={payments} columns={columns} rowKey="salarypayment_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} payments` }}
          size="small"
        />
      </Card>

      <Modal title={editing ? 'Edit Salary Payment' : 'Record Salary Payment'}
        open={modalOpen} onCancel={() => { setModalOpen(false); setEditing(null); }} footer={null} width={500}>
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          {!editing && (
            <Form.Item name="teacher_id" label="Teacher" rules={[{ required: true }]}>
              <Select showSearch optionFilterProp="label"
                options={teachers.map((t) => ({ value: t.id, label: t.user?.name || `Teacher #${t.id}` }))}
              />
            </Form.Item>
          )}
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="amount" label="Amount" rules={[{ required: true }]}>
                <InputNumber min={0} step={0.01} style={{ width: '100%' }} prefix="$" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="period_month" label="Period Month" rules={[{ required: true }]}
                tooltip="First day of the salary period month (YYYY-MM-DD)">
                <Input type="date" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="paidat" label="Paid At (optional — defaults to now)">
            <Input type="datetime-local" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={modalLoading} block>
              {editing ? 'Save Changes' : 'Record'}
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      <Modal title="Salary Payment Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setSelected(null); }} footer={null} width={500}>
        {selected && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Teacher">{selected.teacher?.user?.name || `#${selected.teacher_id}`}</Descriptions.Item>
            <Descriptions.Item label="Period">{dayjs(selected.periodmonth).format('MMMM YYYY')}</Descriptions.Item>
            <Descriptions.Item label="Paid At">{dayjs(selected.paidat).format('YYYY-MM-DD HH:mm')}</Descriptions.Item>
            <Descriptions.Item label="Amount">
              <strong style={{ color: 'green' }}>${Number(selected.amount).toFixed(2)}</strong>
            </Descriptions.Item>
          </Descriptions>
        )}
      </Modal>
    </div>
  );
}
