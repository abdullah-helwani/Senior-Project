import { useEffect, useState, useCallback, useMemo } from 'react';
import {
  Table, Button, Select, Input, Modal, Form, InputNumber, DatePicker,
  Card, Typography, Space, Tag, Descriptions, Statistic, Progress,
  Checkbox, Divider, message, Row, Col,
} from 'antd';
import { EditOutlined, EyeOutlined, SaveOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { TextArea } = Input;
const { Search } = Input;

const STATUS_COLOR: Record<string, string> = { paid: 'green', partial: 'orange', unpaid: 'red' };
const STATUS_LABEL: Record<string, string> = { paid: 'Paid', partial: 'Partial', unpaid: 'Unpaid' };

function planTag(name: string): { label: string; color: string } {
  const l = name.toLowerCase();
  if (l.includes('tuition'))              return { label: 'Tuition',  color: 'blue'    };
  if (l.includes('bus'))                  return { label: 'Bus',      color: 'purple'  };
  if (l.includes('activity') || l.includes('lab')) return { label: 'Activity', color: 'cyan' };
  return { label: name, color: 'default' };
}

interface PlanItem {
  account_id: number;
  feeplan_id: number;
  plan_name: string;
  school_year: string | null;
  total: number;
  paid: number;
  balance: number;
  status: string;
  due_date: string | null;
  notes: string | null;
}

interface StudentRow {
  student_id: number;
  student_name: string;
  plans: PlanItem[];
  total_fee: number;
  total_paid: number;
  total_balance: number;
  overall_status: string;
}

interface FeePlanOpt { feeplan_id: number; name: string; totalamount: string | number }
interface SchoolYear  { schoolyearid: number; name: string }

export default function StudentFeePlans() {
  const [rows, setRows]         = useState<StudentRow[]>([]);
  const [allPlans, setAllPlans] = useState<FeePlanOpt[]>([]);
  const [years, setYears]       = useState<SchoolYear[]>([]);
  const [loading, setLoading]   = useState(true);
  const [page, setPage]         = useState(1);
  const [total, setTotal]       = useState(0);
  const [yearFilter, setYearFilter]     = useState<number | undefined>();
  const [statusFilter, setStatusFilter] = useState<string | undefined>();
  const [search, setSearch]             = useState('');

  // ── Detail + enrollment modal ──
  const [detailOpen, setDetailOpen]   = useState(false);
  const [selected, setSelected]       = useState<StudentRow | null>(null);
  const [checkedIds, setCheckedIds]   = useState<Set<number>>(new Set()); // feeplan_ids checked
  const [enrollSaving, setEnrollSaving] = useState(false);

  // ── Edit payment modal ──
  const [editOpen, setEditOpen]       = useState(false);
  const [editLoading, setEditLoading] = useState(false);
  const [editTarget, setEditTarget]   = useState<PlanItem | null>(null);
  const [editForm] = Form.useForm();

  // ── Fetch ──────────────────────────────────────────────────────────
  const fetchRows = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page, per_page: 20 };
      if (yearFilter)    params.schoolyear_id = yearFilter;
      if (statusFilter)  params.status = statusFilter;
      if (search.trim()) params.search = search.trim();
      const res = await api.get('/admin/student-fee-plans/by-student', { params });
      setRows(res.data.data || []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load student fee plans'); }
    finally { setLoading(false); }
  }, [yearFilter, statusFilter, search, page]);

  const fetchOptions = async () => {
    try {
      const pRes = await api.get('/admin/fee-plans', { params: { per_page: 200 } });
      setAllPlans(pRes.data.data || pRes.data);
    } catch { /* ignore */ }
    try {
      const yRes = await api.get('/admin/school-years');
      const yData = yRes.data;
      setYears(Array.isArray(yData) ? yData : (yData?.data ?? []));
    } catch { /* ignore */ }
  };

  useEffect(() => { fetchOptions(); }, []);
  useEffect(() => { fetchRows(); }, [fetchRows]);

  // ── Re-fetch a single student's detail and refresh selected ──────
  const refreshSelected = async (studentId: number) => {
    try {
      const res = await api.get('/admin/student-fee-plans/by-student', {
        params: { per_page: 200 },
      });
      const updated = (res.data.data as StudentRow[]).find((r) => r.student_id === studentId);
      if (updated) {
        setSelected(updated);
        setCheckedIds(new Set(updated.plans.map((p) => p.feeplan_id)));
      }
    } catch { /* ignore */ }
  };

  // ── Open detail ──────────────────────────────────────────────────
  const openDetail = (row: StudentRow) => {
    setSelected(row);
    setCheckedIds(new Set(row.plans.map((p) => p.feeplan_id)));
    setDetailOpen(true);
  };

  // ── Checkbox toggle ──────────────────────────────────────────────
  const togglePlan = (feePlanId: number) => {
    setCheckedIds((prev) => {
      const next = new Set(prev);
      if (next.has(feePlanId)) next.delete(feePlanId);
      else next.add(feePlanId);
      return next;
    });
  };

  // Preview totals based on current checkbox state
  const previewTotals = useMemo(() => {
    if (!selected) return { fee: 0, paid: 0, balance: 0 };
    const fee  = allPlans.filter((p) => checkedIds.has(p.feeplan_id))
                         .reduce((s, p) => s + Number(p.totalamount), 0);
    const paid = selected.plans.filter((p) => checkedIds.has(p.feeplan_id))
                               .reduce((s, p) => s + p.paid, 0);
    return { fee, paid, balance: Math.max(0, fee - paid) };
  }, [checkedIds, allPlans, selected]);

  const enrollmentChanged = useMemo(() => {
    if (!selected) return false;
    const original = new Set(selected.plans.map((p) => p.feeplan_id));
    if (original.size !== checkedIds.size) return true;
    for (const id of original) if (!checkedIds.has(id)) return true;
    return false;
  }, [checkedIds, selected]);

  // ── Save enrollment changes ──────────────────────────────────────
  const saveEnrollment = async () => {
    if (!selected) return;
    setEnrollSaving(true);
    try {
      const originalIds = new Set(selected.plans.map((p) => p.feeplan_id));

      // Plans to ADD (newly checked)
      const toAdd = [...checkedIds].filter((id) => !originalIds.has(id));
      // Plans to REMOVE (unchecked)
      const toRemove = selected.plans.filter((p) => !checkedIds.has(p.feeplan_id));

      // Remove unchecked
      for (const plan of toRemove) {
        await api.delete(`/admin/student-fee-plans/${plan.account_id}`);
      }

      // Add newly checked — get default due dates per plan type
      for (const feePlanId of toAdd) {
        const planInfo = allPlans.find((p) => p.feeplan_id === feePlanId);
        const planName = planInfo?.name?.toLowerCase() ?? '';
        let dueDate = null;
        if (planName.includes('tuition'))              dueDate = '2025-10-01';
        else if (planName.includes('bus'))             dueDate = '2025-09-15';
        else if (planName.includes('activity') || planName.includes('lab')) dueDate = '2025-11-01';

        await api.post('/admin/student-fee-plans', {
          student_id: selected.student_id,
          feeplan_id: feePlanId,
          paid_amount: 0,
          due_date: dueDate,
        });
      }

      message.success('Enrollment updated successfully');
      await fetchRows();
      await refreshSelected(selected.student_id);
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to update enrollment');
    } finally { setEnrollSaving(false); }
  };

  // ── Edit payment ─────────────────────────────────────────────────
  const openEditPlan = (plan: PlanItem) => {
    setEditTarget(plan);
    editForm.setFieldsValue({
      paid_amount: plan.paid,
      due_date: plan.due_date ? dayjs(plan.due_date) : null,
      notes: plan.notes || '',
    });
    setEditOpen(true);
  };

  const handleEditPlan = async (values: Record<string, unknown>) => {
    if (!editTarget || !selected) return;
    setEditLoading(true);
    try {
      await api.put(`/admin/student-fee-plans/${editTarget.account_id}`, {
        ...values,
        due_date: values.due_date ? dayjs(values.due_date as string).format('YYYY-MM-DD') : null,
      });
      message.success('Payment updated');
      setEditOpen(false); editForm.resetFields(); setEditTarget(null);
      await fetchRows();
      await refreshSelected(selected.student_id);
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to update');
    } finally { setEditLoading(false); }
  };

  const pct = (paid: number, t: number) => t > 0 ? Math.min(100, Math.round((paid / t) * 100)) : 0;

  // ── Main table ───────────────────────────────────────────────────
  const columns = [
    { title: 'Student', dataIndex: 'student_name', key: 'student', width: 200 },
    {
      title: 'Enrolled Fee Plans', key: 'plans',
      render: (_: unknown, r: StudentRow) => (
        <Space wrap size={4}>
          {r.plans.map((p) => {
            const t = planTag(p.plan_name || '');
            return <Tag key={p.account_id} color={t.color}>{t.label}</Tag>;
          })}
        </Space>
      ),
    },
    {
      title: 'Total Fee', key: 'total_fee', width: 110,
      render: (_: unknown, r: StudentRow) => `$${r.total_fee.toFixed(2)}`,
    },
    {
      title: 'Paid', key: 'paid', width: 110,
      render: (_: unknown, r: StudentRow) => (
        <span style={{ color: 'green', fontWeight: 500 }}>${r.total_paid.toFixed(2)}</span>
      ),
    },
    {
      title: 'Balance', key: 'balance', width: 110,
      render: (_: unknown, r: StudentRow) => (
        <span style={{ color: r.total_balance > 0 ? '#fa541c' : 'green', fontWeight: 500 }}>
          ${r.total_balance.toFixed(2)}
        </span>
      ),
    },
    {
      title: 'Status', key: 'status', width: 100,
      render: (_: unknown, r: StudentRow) => (
        <Tag color={STATUS_COLOR[r.overall_status]}>{STATUS_LABEL[r.overall_status]}</Tag>
      ),
    },
    {
      title: 'Actions', key: 'actions', width: 80,
      render: (_: unknown, r: StudentRow) => (
        <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r)}>View</Button>
      ),
    },
  ];

  const overallStatus = (paid: number, fee: number) =>
    fee <= 0 ? 'unpaid' : paid >= fee ? 'paid' : paid > 0 ? 'partial' : 'unpaid';

  return (
    <div>
      <Title level={4} style={{ marginBottom: 16 }}>Student Fee Plans</Title>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Search placeholder="Search student name..." style={{ width: 220 }} allowClear
            onSearch={(v) => { setSearch(v); setPage(1); }}
            onChange={(e) => { if (!e.target.value) { setSearch(''); setPage(1); } }}
          />
          <Select placeholder="School Year" style={{ width: 160 }} allowClear
            value={yearFilter} onChange={(v) => { setYearFilter(v); setPage(1); }}
            options={years.map((y) => ({ value: y.schoolyearid, label: y.name }))}
          />
          <Select placeholder="Payment Status" style={{ width: 160 }} allowClear
            value={statusFilter} onChange={(v) => { setStatusFilter(v); setPage(1); }}
            options={[
              { value: 'paid',    label: 'Fully Paid' },
              { value: 'partial', label: 'Partial Payment' },
              { value: 'unpaid',  label: 'Unpaid' },
            ]}
          />
        </Space>
      </Card>

      <Card>
        <Table
          dataSource={rows} columns={columns} rowKey="student_id" loading={loading}
          pagination={{ current: page, total, pageSize: 20, onChange: setPage,
            showTotal: (t) => `${t} students`, showSizeChanger: false }}
          size="small"
        />
      </Card>

      {/* ── Student Detail + Enrollment Modal ── */}
      <Modal
        title={selected ? `Financial Profile — ${selected.student_name}` : ''}
        open={detailOpen}
        onCancel={() => { setDetailOpen(false); setSelected(null); }}
        footer={null}
        width={660}
      >
        {selected && (() => {
          const status = overallStatus(previewTotals.paid, previewTotals.fee);
          const prog   = pct(previewTotals.paid, previewTotals.fee);

          return (
            <>
              {/* Live summary — updates as checkboxes change */}
              <Row gutter={12} style={{ marginBottom: 12 }}>
                <Col span={6}>
                  <Card size="small">
                    <Statistic title="Total Fee" value={previewTotals.fee} prefix="$" precision={2} />
                  </Card>
                </Col>
                <Col span={6}>
                  <Card size="small">
                    <Statistic title="Paid" value={previewTotals.paid} prefix="$" precision={2}
                      valueStyle={{ color: 'green' }} />
                  </Card>
                </Col>
                <Col span={6}>
                  <Card size="small">
                    <Statistic title="Balance" value={previewTotals.balance} prefix="$" precision={2}
                      valueStyle={{ color: previewTotals.balance > 0 ? '#fa541c' : 'green' }} />
                  </Card>
                </Col>
                <Col span={6}>
                  <Card size="small" style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: 12, color: '#888', marginBottom: 4 }}>Status</div>
                    <Tag color={STATUS_COLOR[status]} style={{ margin: 0, fontSize: 13 }}>
                      {STATUS_LABEL[status]}
                    </Tag>
                  </Card>
                </Col>
              </Row>

              <Progress percent={prog} size="small"
                strokeColor={prog === 100 ? 'green' : prog > 0 ? 'orange' : '#fa541c'}
                format={(p) => `${p}% paid`}
                style={{ marginBottom: 20 }}
              />

              <Divider style={{ margin: '12px 0' }}>
                <Text strong>Enrolled Fee Plans</Text>
                <Text type="secondary" style={{ fontSize: 12, marginLeft: 8 }}>
                  Check to enroll · Uncheck to remove
                </Text>
              </Divider>

              {/* Checkbox list — ALL available plans */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 16 }}>
                {allPlans.map((plan) => {
                  const isChecked    = checkedIds.has(plan.feeplan_id);
                  const enrolledItem = selected.plans.find((p) => p.feeplan_id === plan.feeplan_id);
                  const tag          = planTag(plan.name);

                  return (
                    <Card
                      key={plan.feeplan_id}
                      size="small"
                      style={{
                        borderColor: isChecked ? '#1677ff' : '#d9d9d9',
                        background: isChecked ? '#f0f7ff' : '#fafafa',
                        transition: 'all 0.2s',
                      }}
                    >
                      <Row align="middle" gutter={8}>
                        <Col>
                          <Checkbox
                            checked={isChecked}
                            onChange={() => togglePlan(plan.feeplan_id)}
                          />
                        </Col>
                        <Col flex={1}>
                          <Space>
                            <Tag color={tag.color}>{tag.label}</Tag>
                            <Text strong>{plan.name}</Text>
                            <Text type="secondary">${Number(plan.totalamount).toFixed(2)}</Text>
                          </Space>
                        </Col>
                        {isChecked && enrolledItem && (
                          <Col>
                            <Space size={4}>
                              <Tag color={STATUS_COLOR[enrolledItem.status]} style={{ margin: 0 }}>
                                {STATUS_LABEL[enrolledItem.status]}
                              </Tag>
                              <Text style={{ fontSize: 12 }}>
                                Paid: <span style={{ color: 'green' }}>${enrolledItem.paid.toFixed(2)}</span>
                                {' · '}
                                Due: {enrolledItem.balance.toFixed(2) === '0.00'
                                  ? <span style={{ color: 'green' }}>$0</span>
                                  : <span style={{ color: '#fa541c' }}>${enrolledItem.balance.toFixed(2)}</span>}
                              </Text>
                              <Button size="small" icon={<EditOutlined />}
                                onClick={() => openEditPlan(enrolledItem)}>
                                Edit
                              </Button>
                            </Space>
                          </Col>
                        )}
                        {isChecked && !enrolledItem && (
                          <Col>
                            <Tag color="blue">Will be added</Tag>
                          </Col>
                        )}
                        {!isChecked && enrolledItem && (
                          <Col>
                            <Tag color="red">Will be removed</Tag>
                          </Col>
                        )}
                      </Row>
                    </Card>
                  );
                })}
              </div>

              {enrollmentChanged && (
                <Button
                  type="primary"
                  icon={<SaveOutlined />}
                  block
                  loading={enrollSaving}
                  onClick={saveEnrollment}
                >
                  Save Enrollment Changes
                </Button>
              )}
            </>
          );
        })()}
      </Modal>

      {/* ── Edit Payment Modal ── */}
      <Modal
        title={editTarget ? `Edit Payment — ${editTarget.plan_name}` : 'Edit Payment'}
        open={editOpen}
        onCancel={() => { setEditOpen(false); editForm.resetFields(); setEditTarget(null); }}
        footer={null}
        width={440}
      >
        {editTarget && (
          <div style={{ background: '#f6f6f6', borderRadius: 6, padding: '8px 12px', marginBottom: 16 }}>
            <Text type="secondary">Total for this plan: </Text>
            <Text strong>${editTarget.total.toFixed(2)}</Text>
          </div>
        )}
        <Form form={editForm} layout="vertical" onFinish={handleEditPlan}>
          <Form.Item name="paid_amount" label="Amount Paid ($)" rules={[{ required: true }]}>
            <InputNumber min={0} max={editTarget?.total} style={{ width: '100%' }} prefix="$" />
          </Form.Item>
          <Form.Item name="due_date" label="Payment Due Date">
            <DatePicker style={{ width: '100%' }} format="YYYY-MM-DD" />
          </Form.Item>
          <Form.Item name="notes" label="Notes (optional)">
            <TextArea rows={2} placeholder="e.g. Partial payment received, awaiting remainder..." />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={editLoading} block>Save Changes</Button>
          </Form.Item>
        </Form>
      </Modal>

    </div>
  );
}
