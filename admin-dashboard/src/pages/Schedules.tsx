import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, Input, message, Card,
  Typography, Row, Col, Space, Tag, TimePicker,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs from 'dayjs';

const { Title } = Typography;

const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];

interface Slot {
  slot_id: number;
  schedule_id: number;
  subject_id: number;
  teacher_id: number;
  dayofweek: string;
  starttime: string;
  subject?: { id: number; name: string };
  teacher?: { id: number; user: { name: string } };
}

interface Schedule {
  schedule_id: number;
  section_id: number;
  termname: string;
  section?: { name: string; section_id: number; school_class?: { name: string } };
  slots?: Slot[];
}

interface Section { section_id: number; name: string; school_class?: { name: string } }
interface Subject { id: number; name: string }
interface Teacher { id: number; user: { name: string } }

export default function Schedules() {
  const [schedules, setSchedules] = useState<Schedule[]>([]);
  const [sections, setSections] = useState<Section[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [teachers, setTeachers] = useState<Teacher[]>([]);
  const [loading, setLoading] = useState(true);
  const [sectionFilter, setSectionFilter] = useState<number | undefined>();
  const [selectedSchedule, setSelectedSchedule] = useState<Schedule | null>(null);

  // Schedule modal
  const [scheduleModalOpen, setScheduleModalOpen] = useState(false);
  const [scheduleLoading, setScheduleLoading] = useState(false);
  const [scheduleForm] = Form.useForm();

  // Slot modal
  const [slotModalOpen, setSlotModalOpen] = useState(false);
  const [slotLoading, setSlotLoading] = useState(false);
  const [editingSlot, setEditingSlot] = useState<Slot | null>(null);
  const [slotForm] = Form.useForm();

  const fetchSchedules = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, number> = {};
      if (sectionFilter) params.section_id = sectionFilter;
      const res = await api.get('/admin/schedules', { params });
      setSchedules(res.data.data || res.data);
    } catch { message.error('Failed to load schedules'); }
    finally { setLoading(false); }
  }, [sectionFilter]);

  const fetchOptions = async () => {
    try {
      const [secRes, subRes, teaRes] = await Promise.all([
        api.get('/admin/sections'),
        api.get('/admin/subjects'),
        api.get('/admin/teachers', { params: { per_page: 200 } }),
      ]);
      setSections(secRes.data);
      setSubjects(subRes.data);
      setTeachers(teaRes.data.data || teaRes.data);
    } catch { /* ignore */ }
  };

  useEffect(() => { fetchOptions(); }, []);
  useEffect(() => { fetchSchedules(); }, [fetchSchedules]);

  const loadScheduleDetail = async (id: number) => {
    try {
      const res = await api.get(`/admin/schedules/${id}`);
      setSelectedSchedule(res.data);
    } catch { message.error('Failed to load schedule'); }
  };

  // Schedule CRUD
  const handleCreateSchedule = async (values: { section_id: number; termname: string }) => {
    setScheduleLoading(true);
    try {
      await api.post('/admin/schedules', values);
      message.success('Schedule created');
      setScheduleModalOpen(false); scheduleForm.resetFields(); fetchSchedules();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to create');
    } finally { setScheduleLoading(false); }
  };

  const handleDeleteSchedule = async (id: number) => {
    try {
      await api.delete(`/admin/schedules/${id}`);
      message.success('Schedule deleted');
      if (selectedSchedule?.schedule_id === id) setSelectedSchedule(null);
      fetchSchedules();
    } catch { message.error('Failed to delete'); }
  };

  // Slot CRUD
  const openAddSlot = () => { setEditingSlot(null); slotForm.resetFields(); setSlotModalOpen(true); };
  const openEditSlot = (slot: Slot) => {
    setEditingSlot(slot);
    slotForm.setFieldsValue({
      subject_id: slot.subject_id,
      teacher_id: slot.teacher_id,
      dayofweek: slot.dayofweek,
      starttime: dayjs(slot.starttime, 'HH:mm'),
    });
    setSlotModalOpen(true);
  };

  const handleSlotSubmit = async (values: { subject_id: number; teacher_id: number; dayofweek: string; starttime: dayjs.Dayjs }) => {
    if (!selectedSchedule) return;
    setSlotLoading(true);
    const payload = {
      ...values,
      starttime: values.starttime.format('HH:mm'),
    };
    try {
      if (editingSlot) {
        await api.put(`/admin/schedules/${selectedSchedule.schedule_id}/slots/${editingSlot.slot_id}`, payload);
        message.success('Slot updated');
      } else {
        await api.post(`/admin/schedules/${selectedSchedule.schedule_id}/slots`, payload);
        message.success('Slot added');
      }
      setSlotModalOpen(false); slotForm.resetFields(); setEditingSlot(null);
      loadScheduleDetail(selectedSchedule.schedule_id);
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Conflict detected — slot not saved');
    } finally { setSlotLoading(false); }
  };

  const handleDeleteSlot = async (slotId: number) => {
    if (!selectedSchedule) return;
    try {
      await api.delete(`/admin/schedules/${selectedSchedule.schedule_id}/slots/${slotId}`);
      message.success('Slot removed');
      loadScheduleDetail(selectedSchedule.schedule_id);
    } catch { message.error('Failed to remove slot'); }
  };

  // Group slots by day for timetable view
  const slotsByDay = DAYS.map((day) => ({
    day,
    slots: (selectedSchedule?.slots || [])
      .filter((s) => s.dayofweek === day)
      .sort((a, b) => a.starttime.localeCompare(b.starttime)),
  }));

  const scheduleColumns = [
    {
      title: 'Section', key: 'section',
      render: (_: unknown, r: Schedule) => `${r.section?.school_class?.name || ''} — ${r.section?.name || ''}`,
    },
    { title: 'Term', dataIndex: 'termname', key: 'termname' },
    { title: 'Slots', key: 'slots', render: (_: unknown, r: Schedule) => r.slots?.length || 0 },
    {
      title: 'Actions', key: 'actions', width: 200,
      render: (_: unknown, r: Schedule) => (
        <Space>
          <Button size="small" type="primary" onClick={() => loadScheduleDetail(r.schedule_id)}>View</Button>
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => {
            Modal.confirm({ title: 'Delete schedule?', okType: 'danger', onOk: () => handleDeleteSchedule(r.schedule_id) });
          }} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Schedules</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={() => { scheduleForm.resetFields(); setScheduleModalOpen(true); }}>Create Schedule</Button></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Select
          placeholder="Filter by section"
          style={{ width: 300 }}
          allowClear
          showSearch
          optionFilterProp="label"
          value={sectionFilter}
          onChange={(v) => setSectionFilter(v)}
          options={sections.map((s) => ({ value: s.section_id, label: `${s.school_class?.name || ''} — ${s.name}` }))}
        />
      </Card>

      <Card style={{ marginBottom: 16 }}>
        <Table dataSource={schedules} columns={scheduleColumns} rowKey="schedule_id" loading={loading} pagination={{ pageSize: 10 }} size="small" />
      </Card>

      {/* Timetable view */}
      {selectedSchedule && (
        <Card
          title={`Timetable — ${selectedSchedule.section?.school_class?.name} ${selectedSchedule.section?.name} (${selectedSchedule.termname})`}
          extra={<Button type="primary" icon={<PlusOutlined />} onClick={openAddSlot}>Add Slot</Button>}
        >
          {slotsByDay.map(({ day, slots }) => (
            <div key={day} style={{ marginBottom: 16 }}>
              <Title level={5} style={{ marginBottom: 8 }}>{day}</Title>
              {slots.length === 0 ? (
                <div style={{ color: '#8c8c8c', paddingLeft: 16 }}>No slots</div>
              ) : (
                <Table
                  dataSource={slots}
                  rowKey="slot_id"
                  pagination={false}
                  size="small"
                  columns={[
                    { title: 'Time', dataIndex: 'starttime', width: 100, render: (t: string) => t.slice(0, 5) },
                    { title: 'Subject', key: 'subject', render: (_: unknown, s: Slot) => <Tag color="blue">{s.subject?.name || '—'}</Tag> },
                    { title: 'Teacher', key: 'teacher', render: (_: unknown, s: Slot) => s.teacher?.user?.name || '—' },
                    {
                      title: 'Actions', width: 120,
                      render: (_: unknown, s: Slot) => (
                        <Space>
                          <Button size="small" icon={<EditOutlined />} onClick={() => openEditSlot(s)} />
                          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => handleDeleteSlot(s.slot_id)} />
                        </Space>
                      ),
                    },
                  ]}
                />
              )}
            </div>
          ))}
        </Card>
      )}

      {/* Create Schedule Modal */}
      <Modal title="Create Schedule" open={scheduleModalOpen} onCancel={() => setScheduleModalOpen(false)} footer={null} width={400}>
        <Form form={scheduleForm} layout="vertical" onFinish={handleCreateSchedule}>
          <Form.Item name="section_id" label="Section" rules={[{ required: true }]}>
            <Select showSearch optionFilterProp="label" options={sections.map((s) => ({ value: s.section_id, label: `${s.school_class?.name || ''} — ${s.name}` }))} />
          </Form.Item>
          <Form.Item name="termname" label="Term Name" rules={[{ required: true }]}>
            <Input placeholder="e.g. Term 1 2025-2026" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={scheduleLoading} block>Create</Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* Slot Modal */}
      <Modal title={editingSlot ? 'Edit Slot' : 'Add Slot'} open={slotModalOpen} onCancel={() => { setSlotModalOpen(false); setEditingSlot(null); }} footer={null} width={450}>
        <Form form={slotForm} layout="vertical" onFinish={handleSlotSubmit}>
          <Form.Item name="dayofweek" label="Day" rules={[{ required: true }]}>
            <Select options={DAYS.map((d) => ({ value: d, label: d }))} />
          </Form.Item>
          <Form.Item name="starttime" label="Start Time" rules={[{ required: true }]}>
            <TimePicker format="HH:mm" minuteStep={5} style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="subject_id" label="Subject" rules={[{ required: true }]}>
            <Select showSearch optionFilterProp="label" options={subjects.map((s) => ({ value: s.id, label: s.name }))} />
          </Form.Item>
          <Form.Item name="teacher_id" label="Teacher" rules={[{ required: true }]}>
            <Select showSearch optionFilterProp="label" options={teachers.map((t) => ({ value: t.id, label: t.user?.name || `Teacher #${t.id}` }))} />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={slotLoading} block>
              {editingSlot ? 'Save Changes' : 'Add Slot'}
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
