import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, Input, InputNumber, Card, Typography,
  Row, Col, Space, Descriptions, message,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined } from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

interface FeePlan {
  feeplan_id: number;
  schoolyear_id: number;
  name: string;
  totalamount: string | number;
  schoolYear?: { schoolyear_id: number; name: string };
  studentFeePlans?: { account_id: number; student?: { student_id: number; user?: { name: string } } }[];
}

interface SchoolYear { schoolyear_id: number; name: string }

export default function FeePlans() {
  const [plans, setPlans] = useState<FeePlan[]>([]);
  const [schoolYears, setSchoolYears] = useState<SchoolYear[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [yearFilter, setYearFilter] = useState<number | undefined>();

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<FeePlan | null>(null);
  const [modalLoading, setModalLoading] = useState(false);
  const [form] = Form.useForm();

  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<FeePlan | null>(null);

  const fetchPlans = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (yearFilter) params.schoolyear_id = yearFilter;
      const res = await api.get('/admin/fee-plans', { params });
      const d = res.data.data || res.data;
      setPlans(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load fee plans'); }
    finally { setLoading(false); }
  }, [yearFilter, page]);

  const fetchYears = async () => {
    try {
      const res = await api.get('/admin/school-years');
      setSchoolYears(res.data);
    } catch { /* ignore */ }
  };

  useEffect(() => { fetchYears(); }, []);
  useEffect(() => { fetchPlans(); }, [fetchPlans]);

  const openCreate = () => { setEditing(null); form.resetFields(); setModalOpen(true); };
  const openEdit = (p: FeePlan) => {
    setEditing(p);
    form.setFieldsValue({ schoolyear_id: p.schoolyear_id, name: p.name, totalamount: p.totalamount });
    setModalOpen(true);
  };

  const handleSubmit = async (values: Record<string, unknown>) => {
    setModalLoading(true);
    try {
      if (editing) {
        await api.put(`/admin/fee-plans/${editing.feeplan_id}`, values);
        message.success('Fee plan updated');
      } else {
        await api.post('/admin/fee-plans', values);
        message.success('Fee plan created');
      }
      setModalOpen(false); form.resetFields(); setEditing(null); fetchPlans();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to save');
    } finally { setModalLoading(false); }
  };

  const handleDelete = (id: number) => {
    Modal.confirm({
      title: 'Delete this fee plan?',
      content: 'Cannot be deleted if students are assigned to it.',
      okType: 'danger',
      onOk: async () => {
        try {
          await api.delete(`/admin/fee-plans/${id}`);
          message.success('Deleted'); fetchPlans();
        } catch (err: unknown) {
          const axiosErr = err as { response?: { data?: { message?: string } } };
          message.error(axiosErr.response?.data?.message || 'Failed to delete');
        }
      },
    });
  };

  const openDetail = async (id: number) => {
    try {
      const res = await api.get(`/admin/fee-plans/${id}`);
      setSelected(res.data); setDetailOpen(true);
    } catch { message.error('Failed to load detail'); }
  };

  const columns = [
    { title: 'Name', dataIndex: 'name', key: 'name' },
    {
      title: 'School Year', key: 'year',
      render: (_: unknown, r: FeePlan) => r.schoolYear?.name || `#${r.schoolyear_id}`,
    },
    {
      title: 'Total Amount', dataIndex: 'totalamount', key: 'amount', width: 160,
      render: (v: string | number) => `$${Number(v).toFixed(2)}`,
    },
    {
      title: 'Actions', key: 'actions', width: 170,
      render: (_: unknown, r: FeePlan) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r.feeplan_id)} />
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.feeplan_id)} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Fee Plans</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Create Fee Plan</Button></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Select placeholder="School Year" style={{ width: 220 }} allowClear
          value={yearFilter} onChange={(v) => { setYearFilter(v); setPage(1); }}
          options={schoolYears.map((y) => ({ value: y.schoolyear_id, label: y.name }))}
        />
      </Card>

      <Card>
        <Table
          dataSource={plans} columns={columns} rowKey="feeplan_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage, showTotal: (t) => `${t} plans` }}
          size="small"
        />
      </Card>

      <Modal title={editing ? 'Edit Fee Plan' : 'Create Fee Plan'}
        open={modalOpen} onCancel={() => { setModalOpen(false); setEditing(null); }} footer={null} width={450}>
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          <Form.Item name="name" label="Plan Name" rules={[{ required: true }]}>
            <Input placeholder="e.g. Standard Tuition 2025-2026" />
          </Form.Item>
          <Form.Item name="schoolyear_id" label="School Year" rules={[{ required: true }]}>
            <Select options={schoolYears.map((y) => ({ value: y.schoolyear_id, label: y.name }))} />
          </Form.Item>
          <Form.Item name="totalamount" label="Total Amount" rules={[{ required: true }]}>
            <InputNumber min={0} style={{ width: '100%' }} prefix="$" placeholder="e.g. 5000" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={modalLoading} block>
              {editing ? 'Save Changes' : 'Create'}
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      <Modal title="Fee Plan Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setSelected(null); }} footer={null} width={600}>
        {selected && (
          <>
            <Descriptions column={1} bordered size="small" style={{ marginBottom: 16 }}>
              <Descriptions.Item label="Name">{selected.name}</Descriptions.Item>
              <Descriptions.Item label="School Year">{selected.schoolYear?.name || `#${selected.schoolyear_id}`}</Descriptions.Item>
              <Descriptions.Item label="Total Amount">${Number(selected.totalamount).toFixed(2)}</Descriptions.Item>
              <Descriptions.Item label="Assigned Students">{selected.studentFeePlans?.length || 0}</Descriptions.Item>
            </Descriptions>
            {selected.studentFeePlans && selected.studentFeePlans.length > 0 && (
              <Table
                dataSource={selected.studentFeePlans} rowKey="account_id" size="small" pagination={{ pageSize: 10 }}
                columns={[
                  { title: 'Student', key: 'student', render: (_: unknown, r) => r.student?.user?.name || `#${r.student?.student_id}` },
                ]}
              />
            )}
          </>
        )}
      </Modal>
    </div>
  );
}
