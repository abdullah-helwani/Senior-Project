import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, Input, Card, Typography,
  Row, Col, Space, Tag, message,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, ClockCircleOutlined } from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

const DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const TYPES = ['available', 'unavailable', 'preferred'];

const TYPE_COLORS: Record<string, string> = {
  available: 'green', unavailable: 'red', preferred: 'blue',
};

interface Availability {
  availability_id: number;
  teacher_id: number;
  dayofweek: string;
  start_time: string;
  end_time: string;
  availabilitytype: string;
  teacher?: { id: number; user?: { name: string } };
}

interface Teacher { id: number; user?: { name: string } }

export default function TeacherAvailability() {
  const [slots, setSlots] = useState<Availability[]>([]);
  const [teachers, setTeachers] = useState<Teacher[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);

  const [teacherFilter, setTeacherFilter] = useState<number | undefined>();
  const [dayFilter, setDayFilter] = useState<string | undefined>();
  const [typeFilter, setTypeFilter] = useState<string | undefined>();

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Availability | null>(null);
  const [modalLoading, setModalLoading] = useState(false);
  const [form] = Form.useForm();

  const fetchSlots = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (teacherFilter) params.teacher_id = teacherFilter;
      if (dayFilter) params.dayofweek = dayFilter;
      if (typeFilter) params.availabilitytype = typeFilter;
      const res = await api.get('/admin/teacher-availability', { params });
      const d = res.data.data || res.data;
      setSlots(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch { message.error('Failed to load availability'); }
    finally { setLoading(false); }
  }, [teacherFilter, dayFilter, typeFilter, page]);

  const fetchTeachers = async () => {
    try {
      const res = await api.get('/admin/teachers', { params: { per_page: 300, status: 'active' } });
      setTeachers(res.data.data || res.data);
    } catch { /* ignore */ }
  };

  useEffect(() => { fetchTeachers(); }, []);
  useEffect(() => { fetchSlots(); }, [fetchSlots]);

  const openCreate = () => { setEditing(null); form.resetFields(); setModalOpen(true); };
  const openEdit = (a: Availability) => {
    setEditing(a);
    form.setFieldsValue({
      teacher_id: a.teacher_id,
      dayofweek: a.dayofweek,
      start_time: a.start_time.substring(0, 5),
      end_time: a.end_time.substring(0, 5),
      availabilitytype: a.availabilitytype,
    });
    setModalOpen(true);
  };

  const handleSubmit = async (values: Record<string, unknown>) => {
    setModalLoading(true);
    try {
      if (editing) {
        await api.put(`/admin/teacher-availability/${editing.availability_id}`, values);
        message.success('Updated');
      } else {
        await api.post('/admin/teacher-availability', values);
        message.success('Created');
      }
      setModalOpen(false); form.resetFields(); setEditing(null); fetchSlots();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to save');
    } finally { setModalLoading(false); }
  };

  const handleDelete = (id: number) => Modal.confirm({
    title: 'Delete this availability slot?', okType: 'danger',
    onOk: async () => {
      try { await api.delete(`/admin/teacher-availability/${id}`); message.success('Deleted'); fetchSlots(); }
      catch { message.error('Failed to delete'); }
    },
  });

  const columns = [
    {
      title: 'Teacher', key: 'teacher',
      render: (_: unknown, r: Availability) => r.teacher?.user?.name || `Teacher #${r.teacher_id}`,
    },
    { title: 'Day', dataIndex: 'dayofweek', key: 'day', width: 120 },
    {
      title: 'Time', key: 'time', width: 160,
      render: (_: unknown, r: Availability) => (
        <Space><ClockCircleOutlined />{r.start_time.substring(0, 5)} – {r.end_time.substring(0, 5)}</Space>
      ),
    },
    {
      title: 'Type', dataIndex: 'availabilitytype', key: 'type', width: 130,
      render: (t: string) => <Tag color={TYPE_COLORS[t]}>{t.toUpperCase()}</Tag>,
    },
    {
      title: 'Actions', key: 'a', width: 110,
      render: (_: unknown, r: Availability) => (
        <Space>
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDelete(r.availability_id)} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Teacher Availability</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Add Slot</Button></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Select placeholder="Teacher" style={{ width: 240 }} allowClear showSearch optionFilterProp="label"
            value={teacherFilter} onChange={(v) => { setTeacherFilter(v); setPage(1); }}
            options={teachers.map((t) => ({ value: t.id, label: t.user?.name || `Teacher #${t.id}` }))}
          />
          <Select placeholder="Day" style={{ width: 150 }} allowClear
            value={dayFilter} onChange={(v) => { setDayFilter(v); setPage(1); }}
            options={DAYS.map((d) => ({ value: d, label: d }))}
          />
          <Select placeholder="Type" style={{ width: 150 }} allowClear
            value={typeFilter} onChange={(v) => { setTypeFilter(v); setPage(1); }}
            options={TYPES.map((t) => ({ value: t, label: t.charAt(0).toUpperCase() + t.slice(1) }))}
          />
        </Space>
      </Card>

      <Card>
        <Table size="small" loading={loading} dataSource={slots} rowKey="availability_id" columns={columns}
          pagination={{ current: page, total, pageSize: 50, onChange: setPage, showTotal: (t) => `${t} slots` }}
        />
      </Card>

      <Modal title={editing ? 'Edit Availability' : 'Add Availability'} open={modalOpen}
        onCancel={() => { setModalOpen(false); setEditing(null); }} footer={null} width={500}>
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          {!editing && (
            <Form.Item name="teacher_id" label="Teacher" rules={[{ required: true }]}>
              <Select showSearch optionFilterProp="label"
                options={teachers.map((t) => ({ value: t.id, label: t.user?.name || `Teacher #${t.id}` }))}
              />
            </Form.Item>
          )}
          <Form.Item name="dayofweek" label="Day of Week" rules={[{ required: true }]}>
            <Select options={DAYS.map((d) => ({ value: d, label: d }))} />
          </Form.Item>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="start_time" label="Start Time (HH:MM)" rules={[{ required: true }]}>
                <Input type="time" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="end_time" label="End Time (HH:MM)" rules={[{ required: true }]}>
                <Input type="time" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="availabilitytype" label="Type" rules={[{ required: true }]}>
            <Select options={TYPES.map((t) => ({ value: t, label: t.charAt(0).toUpperCase() + t.slice(1) }))} />
          </Form.Item>
          <Button type="primary" htmlType="submit" loading={modalLoading} block>
            {editing ? 'Save Changes' : 'Create'}
          </Button>
        </Form>
      </Modal>
    </div>
  );
}
