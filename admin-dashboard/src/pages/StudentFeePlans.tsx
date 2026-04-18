import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, InputNumber, Card, Typography,
  Row, Col, Space, message,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

interface StudentFeePlan {
  account_id: number;
  student_id: number;
  feeplan_id: number;
  balance: string | number;
  student?: { student_id: number; user?: { name: string } };
  feePlan?: {
    feeplan_id: number; name: string; totalamount: string | number;
    schoolYear?: { schoolyear_id: number; name: string };
  };
}

interface Student { id: number; user?: { name: string } }
interface FeePlan {
  feeplan_id: number; name: string; totalamount: string | number;
  schoolYear?: { name: string };
}
interface SchoolYear { schoolyear_id: number; name: string }

export default function StudentFeePlans() {
  const [accounts, setAccounts] = useState<StudentFeePlan[]>([]);
  const [students, setStudents] = useState<Student[]>([]);
  const [plans, setPlans] = useState<FeePlan[]>([]);
  const [years, setYears] = useState<SchoolYear[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [yearFilter, setYearFilter] = useState<number | undefined>();
  const [planFilter, setPlanFilter] = useState<number | undefined>();

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<StudentFeePlan | null>(null);
  const [modalLoading, setModalLoading] = useState(false);
  const [form] = Form.useForm();

  const fetchAccounts = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (yearFilter) params.schoolyear_id = yearFilter;
      if (planFilter) params.feeplan_id = planFilter;
      const res = await api.get('/admin/student-fee-plans', { params });
      const d = res.data.data || res.data;
      setAccounts(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load accounts'); }
    finally { setLoading(false); }
  }, [yearFilter, planFilter, page]);

  const fetchOptions = async () => {
    try {
      const [sRes, pRes, yRes] = await Promise.all([
        api.get('/admin/students', { params: { per_page: 500, status: 'active' } }),
        api.get('/admin/fee-plans', { params: { per_page: 200 } }),
        api.get('/admin/school-years'),
      ]);
      setStudents(sRes.data.data || sRes.data);
      setPlans(pRes.data.data || pRes.data);
      setYears(yRes.data);
    } catch { /* ignore */ }
  };

  useEffect(() => { fetchOptions(); }, []);
  useEffect(() => { fetchAccounts(); }, [fetchAccounts]);

  const openCreate = () => { setEditing(null); form.resetFields(); setModalOpen(true); };
  const openEdit = (a: StudentFeePlan) => {
    setEditing(a);
    form.setFieldsValue({ feeplan_id: a.feeplan_id, balance: a.balance });
    setModalOpen(true);
  };

  const handleSubmit = async (values: Record<string, unknown>) => {
    setModalLoading(true);
    try {
      if (editing) {
        await api.put(`/admin/student-fee-plans/${editing.account_id}`, values);
        message.success('Account updated');
      } else {
        await api.post('/admin/student-fee-plans', values);
        message.success('Plan assigned to student');
      }
      setModalOpen(false); form.resetFields(); setEditing(null); fetchAccounts();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to save');
    } finally { setModalLoading(false); }
  };

  const handleDelete = (id: number) => {
    Modal.confirm({
      title: 'Remove this fee plan from student?',
      content: 'Cannot be deleted if invoices exist.',
      okType: 'danger',
      onOk: async () => {
        try {
          await api.delete(`/admin/student-fee-plans/${id}`);
          message.success('Removed'); fetchAccounts();
        } catch (err: unknown) {
          const axiosErr = err as { response?: { data?: { message?: string } } };
          message.error(axiosErr.response?.data?.message || 'Failed to remove');
        }
      },
    });
  };

  const columns = [
    {
      title: 'Student', key: 'student',
      render: (_: unknown, r: StudentFeePlan) => r.student?.user?.name || `#${r.student_id}`,
    },
    {
      title: 'Fee Plan', key: 'plan',
      render: (_: unknown, r: StudentFeePlan) => r.feePlan?.name || `#${r.feeplan_id}`,
    },
    {
      title: 'School Year', key: 'year',
      render: (_: unknown, r: StudentFeePlan) => r.feePlan?.schoolYear?.name || '—',
    },
    {
      title: 'Total', key: 'total', width: 120,
      render: (_: unknown, r: StudentFeePlan) => r.feePlan ? `$${Number(r.feePlan.totalamount).toFixed(2)}` : '—',
    },
    {
      title: 'Balance', dataIndex: 'balance', key: 'balance', width: 130,
      render: (v: string | number) => {
        const n = Number(v);
        return <span style={{ color: n > 0 ? '#fa541c' : 'green', fontWeight: 500 }}>${n.toFixed(2)}</span>;
      },
    },
    {
      title: 'Actions', key: 'actions', width: 110,
      render: (_: unknown, r: StudentFeePlan) => (
        <Space>
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.account_id)} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Student Fee Plans</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Assign Plan</Button></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Select placeholder="School Year" style={{ width: 200 }} allowClear
            value={yearFilter} onChange={(v) => { setYearFilter(v); setPage(1); }}
            options={years.map((y) => ({ value: y.schoolyear_id, label: y.name }))}
          />
          <Select placeholder="Fee Plan" style={{ width: 250 }} allowClear showSearch optionFilterProp="label"
            value={planFilter} onChange={(v) => { setPlanFilter(v); setPage(1); }}
            options={plans.map((p) => ({ value: p.feeplan_id, label: p.name }))}
          />
        </Space>
      </Card>

      <Card>
        <Table
          dataSource={accounts} columns={columns} rowKey="account_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} accounts` }}
          size="small"
        />
      </Card>

      <Modal title={editing ? 'Edit Account' : 'Assign Fee Plan'}
        open={modalOpen} onCancel={() => { setModalOpen(false); setEditing(null); }} footer={null} width={450}>
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          {!editing && (
            <Form.Item name="student_id" label="Student" rules={[{ required: true }]}>
              <Select showSearch optionFilterProp="label"
                options={students.map((s) => ({ value: s.id, label: s.user?.name || `Student #${s.id}` }))}
              />
            </Form.Item>
          )}
          <Form.Item name="feeplan_id" label="Fee Plan" rules={[{ required: true }]}>
            <Select showSearch optionFilterProp="label"
              options={plans.map((p) => ({
                value: p.feeplan_id,
                label: `${p.name} (${p.schoolYear?.name || ''}) — $${Number(p.totalamount).toFixed(2)}`,
              }))}
            />
          </Form.Item>
          <Form.Item name="balance" label="Balance (optional — defaults to plan total)">
            <InputNumber min={0} style={{ width: '100%' }} prefix="$" placeholder="e.g. 5000" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={modalLoading} block>
              {editing ? 'Save Changes' : 'Assign'}
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
