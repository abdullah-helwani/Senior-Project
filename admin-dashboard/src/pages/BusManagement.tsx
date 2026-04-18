import { useEffect, useState, useCallback } from 'react';
import {
  Tabs, Table, Button, Modal, Form, Input, Select, InputNumber, Card, Typography,
  Row, Col, Space, Tag, Descriptions, Collapse, message,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined } from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

// ────────────────────────────────────────────────────────────────────
// Types
// ────────────────────────────────────────────────────────────────────
interface Bus { bus_id: number; plate_number: string }
interface Driver {
  driver_id: number; user_id: number;
  user?: { name: string; email: string; phone?: string; is_active: boolean };
  currentBus?: Bus;
}
interface Stop { stop_id: number; route_id: number; name: string; stoporder: number }
interface BusRoute { route_id: number; name: string; stops?: Stop[] }
interface DriverAssignment {
  driverassignment_id: number; driver_id: number; bus_id: number;
  driver?: Driver; bus?: Bus;
}
interface StudentBusAssignment {
  sbassignment_id: number; student_id: number; bus_id: number; route_id: number; stop_id: number;
  student?: { student_id: number; user?: { name: string } };
  bus?: Bus; route?: BusRoute; stop?: Stop;
}
interface Student { id: number; user?: { name: string } }

// ────────────────────────────────────────────────────────────────────
// BUSES TAB
// ────────────────────────────────────────────────────────────────────
function BusesTab() {
  const [buses, setBuses] = useState<Bus[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Bus | null>(null);
  const [form] = Form.useForm();

  const fetch = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/buses', { params: { per_page: 200 } });
      setBuses(res.data.data || res.data);
    } catch { message.error('Failed to load buses'); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { fetch(); }, [fetch]);

  const openCreate = () => { setEditing(null); form.resetFields(); setModalOpen(true); };
  const openEdit = (b: Bus) => { setEditing(b); form.setFieldsValue({ plate_number: b.plate_number }); setModalOpen(true); };

  const onSubmit = async (values: Record<string, unknown>) => {
    try {
      if (editing) await api.put(`/admin/buses/${editing.bus_id}`, values);
      else await api.post('/admin/buses', values);
      message.success('Saved'); setModalOpen(false); fetch();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to save');
    }
  };

  const onDelete = (id: number) => Modal.confirm({
    title: 'Delete this bus?', okType: 'danger',
    onOk: async () => {
      try { await api.delete(`/admin/buses/${id}`); message.success('Deleted'); fetch(); }
      catch { message.error('Failed to delete'); }
    },
  });

  return (
    <>
      <Row justify="space-between" style={{ marginBottom: 12 }}>
        <Col />
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Add Bus</Button></Col>
      </Row>
      <Table size="small" loading={loading} dataSource={buses} rowKey="bus_id"
        columns={[
          { title: 'Bus ID', dataIndex: 'bus_id', width: 80 },
          { title: 'Plate Number', dataIndex: 'plate_number' },
          {
            title: 'Actions', key: 'a', width: 120,
            render: (_: unknown, r: Bus) => (
              <Space>
                <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
                <Button size="small" icon={<DeleteOutlined />} danger onClick={() => onDelete(r.bus_id)} />
              </Space>
            ),
          },
        ]}
      />
      <Modal title={editing ? 'Edit Bus' : 'Add Bus'} open={modalOpen} onCancel={() => setModalOpen(false)} footer={null} width={400}>
        <Form form={form} layout="vertical" onFinish={onSubmit}>
          <Form.Item name="plate_number" label="Plate Number" rules={[{ required: true }]}>
            <Input placeholder="e.g. ABC-1234" />
          </Form.Item>
          <Button type="primary" htmlType="submit" block>{editing ? 'Save' : 'Create'}</Button>
        </Form>
      </Modal>
    </>
  );
}

// ────────────────────────────────────────────────────────────────────
// DRIVERS TAB
// ────────────────────────────────────────────────────────────────────
function DriversTab() {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Driver | null>(null);
  const [form] = Form.useForm();

  const fetch = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/drivers', { params: { per_page: 200, search } });
      setDrivers(res.data.data || res.data);
    } catch { message.error('Failed to load drivers'); }
    finally { setLoading(false); }
  }, [search]);
  useEffect(() => { fetch(); }, [fetch]);

  const openCreate = () => { setEditing(null); form.resetFields(); setModalOpen(true); };
  const openEdit = (d: Driver) => {
    setEditing(d);
    form.setFieldsValue({
      name: d.user?.name, email: d.user?.email, phone: d.user?.phone,
      is_active: d.user?.is_active ?? true,
    });
    setModalOpen(true);
  };

  const onSubmit = async (values: Record<string, unknown>) => {
    try {
      if (editing) await api.put(`/admin/drivers/${editing.driver_id}`, values);
      else await api.post('/admin/drivers', values);
      message.success('Saved'); setModalOpen(false); fetch();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to save');
    }
  };

  const onDelete = (id: number) => Modal.confirm({
    title: 'Delete this driver?', okType: 'danger',
    onOk: async () => {
      try { await api.delete(`/admin/drivers/${id}`); message.success('Deleted'); fetch(); }
      catch { message.error('Failed to delete'); }
    },
  });

  return (
    <>
      <Row justify="space-between" style={{ marginBottom: 12 }} gutter={12}>
        <Col><Input.Search placeholder="Search by name/email/phone" allowClear onSearch={setSearch} style={{ width: 280 }} /></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Add Driver</Button></Col>
      </Row>
      <Table size="small" loading={loading} dataSource={drivers} rowKey="driver_id"
        columns={[
          { title: 'Name', key: 'name', render: (_: unknown, r: Driver) => r.user?.name || '—' },
          { title: 'Email', key: 'email', render: (_: unknown, r: Driver) => r.user?.email || '—' },
          { title: 'Phone', key: 'phone', render: (_: unknown, r: Driver) => r.user?.phone || '—' },
          {
            title: 'Current Bus', key: 'bus',
            render: (_: unknown, r: Driver) => r.currentBus ? <Tag color="blue">{r.currentBus.plate_number}</Tag> : <Tag>—</Tag>,
          },
          {
            title: 'Active', key: 'active', width: 90,
            render: (_: unknown, r: Driver) => <Tag color={r.user?.is_active ? 'green' : 'default'}>{r.user?.is_active ? 'Yes' : 'No'}</Tag>,
          },
          {
            title: 'Actions', key: 'a', width: 120,
            render: (_: unknown, r: Driver) => (
              <Space>
                <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
                <Button size="small" icon={<DeleteOutlined />} danger onClick={() => onDelete(r.driver_id)} />
              </Space>
            ),
          },
        ]}
      />
      <Modal title={editing ? 'Edit Driver' : 'Add Driver'} open={modalOpen} onCancel={() => setModalOpen(false)} footer={null} width={450}>
        <Form form={form} layout="vertical" onFinish={onSubmit}>
          <Form.Item name="name" label="Name" rules={[{ required: true }]}><Input /></Form.Item>
          <Form.Item name="email" label="Email" rules={[{ required: true, type: 'email' }]}><Input /></Form.Item>
          <Form.Item name="phone" label="Phone"><Input /></Form.Item>
          {!editing && (
            <Form.Item name="password" label="Password" rules={[{ required: true, min: 8 }]}>
              <Input.Password />
            </Form.Item>
          )}
          {editing && (
            <Form.Item name="is_active" label="Active">
              <Select options={[{ value: true, label: 'Active' }, { value: false, label: 'Inactive' }]} />
            </Form.Item>
          )}
          <Button type="primary" htmlType="submit" block>{editing ? 'Save' : 'Create'}</Button>
        </Form>
      </Modal>
    </>
  );
}

// ────────────────────────────────────────────────────────────────────
// ROUTES TAB (with nested stops)
// ────────────────────────────────────────────────────────────────────
function RoutesTab() {
  const [routes, setRoutes] = useState<BusRoute[]>([]);
  const [loading, setLoading] = useState(true);
  const [routeModalOpen, setRouteModalOpen] = useState(false);
  const [editingRoute, setEditingRoute] = useState<BusRoute | null>(null);
  const [routeForm] = Form.useForm();

  const [stopModalOpen, setStopModalOpen] = useState(false);
  const [stopRouteId, setStopRouteId] = useState<number | null>(null);
  const [editingStop, setEditingStop] = useState<Stop | null>(null);
  const [stopForm] = Form.useForm();

  const fetch = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/bus-routes', { params: { per_page: 100 } });
      setRoutes(res.data.data || res.data);
    } catch { message.error('Failed to load routes'); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { fetch(); }, [fetch]);

  const openCreateRoute = () => { setEditingRoute(null); routeForm.resetFields(); setRouteModalOpen(true); };
  const openEditRoute = (r: BusRoute) => { setEditingRoute(r); routeForm.setFieldsValue({ name: r.name }); setRouteModalOpen(true); };

  const onSubmitRoute = async (values: Record<string, unknown>) => {
    try {
      if (editingRoute) await api.put(`/admin/bus-routes/${editingRoute.route_id}`, values);
      else await api.post('/admin/bus-routes', values);
      message.success('Saved'); setRouteModalOpen(false); fetch();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to save');
    }
  };

  const deleteRoute = (id: number) => Modal.confirm({
    title: 'Delete this route and its stops?', okType: 'danger',
    onOk: async () => {
      try { await api.delete(`/admin/bus-routes/${id}`); message.success('Deleted'); fetch(); }
      catch { message.error('Failed to delete'); }
    },
  });

  const openCreateStop = (routeId: number) => {
    setStopRouteId(routeId); setEditingStop(null); stopForm.resetFields(); setStopModalOpen(true);
  };
  const openEditStop = (s: Stop) => {
    setStopRouteId(s.route_id); setEditingStop(s);
    stopForm.setFieldsValue({ name: s.name, stoporder: s.stoporder });
    setStopModalOpen(true);
  };

  const onSubmitStop = async (values: Record<string, unknown>) => {
    try {
      if (editingStop) {
        await api.put(`/admin/route-stops/${editingStop.stop_id}`, values);
      } else {
        await api.post('/admin/route-stops', { ...values, route_id: stopRouteId });
      }
      message.success('Saved'); setStopModalOpen(false); fetch();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to save');
    }
  };

  const deleteStop = (id: number) => Modal.confirm({
    title: 'Delete this stop?', okType: 'danger',
    onOk: async () => {
      try { await api.delete(`/admin/route-stops/${id}`); message.success('Deleted'); fetch(); }
      catch { message.error('Failed to delete'); }
    },
  });

  return (
    <>
      <Row justify="end" style={{ marginBottom: 12 }}>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreateRoute}>Add Route</Button>
      </Row>
      {loading ? 'Loading...' : (
        <Collapse accordion items={routes.map((r) => ({
          key: String(r.route_id),
          label: (
            <Space>
              <strong>{r.name}</strong>
              <Tag>{r.stops?.length || 0} stops</Tag>
            </Space>
          ),
          extra: (
            <Space onClick={(e) => e.stopPropagation()}>
              <Button size="small" icon={<EditOutlined />} onClick={() => openEditRoute(r)} />
              <Button size="small" icon={<DeleteOutlined />} danger onClick={() => deleteRoute(r.route_id)} />
            </Space>
          ),
          children: (
            <>
              <Row justify="end" style={{ marginBottom: 8 }}>
                <Button size="small" icon={<PlusOutlined />} onClick={() => openCreateStop(r.route_id)}>Add Stop</Button>
              </Row>
              <Table size="small" dataSource={r.stops || []} rowKey="stop_id" pagination={false}
                columns={[
                  { title: '#', dataIndex: 'stoporder', width: 60 },
                  { title: 'Stop Name', dataIndex: 'name' },
                  {
                    title: 'Actions', key: 'a', width: 110,
                    render: (_: unknown, s: Stop) => (
                      <Space>
                        <Button size="small" icon={<EditOutlined />} onClick={() => openEditStop(s)} />
                        <Button size="small" icon={<DeleteOutlined />} danger onClick={() => deleteStop(s.stop_id)} />
                      </Space>
                    ),
                  },
                ]}
              />
            </>
          ),
        }))} />
      )}

      <Modal title={editingRoute ? 'Edit Route' : 'Add Route'} open={routeModalOpen}
        onCancel={() => setRouteModalOpen(false)} footer={null} width={400}>
        <Form form={routeForm} layout="vertical" onFinish={onSubmitRoute}>
          <Form.Item name="name" label="Route Name" rules={[{ required: true }]}>
            <Input placeholder="e.g. North Route" />
          </Form.Item>
          <Button type="primary" htmlType="submit" block>{editingRoute ? 'Save' : 'Create'}</Button>
        </Form>
      </Modal>

      <Modal title={editingStop ? 'Edit Stop' : 'Add Stop'} open={stopModalOpen}
        onCancel={() => setStopModalOpen(false)} footer={null} width={400}>
        <Form form={stopForm} layout="vertical" onFinish={onSubmitStop}>
          <Form.Item name="name" label="Stop Name" rules={[{ required: true }]}>
            <Input placeholder="e.g. Main Street" />
          </Form.Item>
          <Form.Item name="stoporder" label="Stop Order" rules={[{ required: true }]}>
            <InputNumber min={1} style={{ width: '100%' }} />
          </Form.Item>
          <Button type="primary" htmlType="submit" block>{editingStop ? 'Save' : 'Create'}</Button>
        </Form>
      </Modal>
    </>
  );
}

// ────────────────────────────────────────────────────────────────────
// DRIVER ASSIGNMENTS TAB
// ────────────────────────────────────────────────────────────────────
function DriverAssignmentsTab() {
  const [assignments, setAssignments] = useState<DriverAssignment[]>([]);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [buses, setBuses] = useState<Bus[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [form] = Form.useForm();

  const fetch = useCallback(async () => {
    setLoading(true);
    try {
      const [aRes, dRes, bRes] = await Promise.all([
        api.get('/admin/driver-assignments', { params: { per_page: 200 } }),
        api.get('/admin/drivers', { params: { per_page: 200 } }),
        api.get('/admin/buses', { params: { per_page: 200 } }),
      ]);
      setAssignments(aRes.data.data || aRes.data);
      setDrivers(dRes.data.data || dRes.data);
      setBuses(bRes.data.data || bRes.data);
    } catch { message.error('Failed to load'); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { fetch(); }, [fetch]);

  const openCreate = () => { form.resetFields(); setModalOpen(true); };

  const onSubmit = async (values: Record<string, unknown>) => {
    try {
      await api.post('/admin/driver-assignments', values);
      message.success('Assignment created'); setModalOpen(false); fetch();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to create');
    }
  };

  const onDelete = (id: number) => Modal.confirm({
    title: 'Remove this driver-bus assignment?', okType: 'danger',
    onOk: async () => {
      try { await api.delete(`/admin/driver-assignments/${id}`); message.success('Removed'); fetch(); }
      catch { message.error('Failed to remove'); }
    },
  });

  return (
    <>
      <Row justify="end" style={{ marginBottom: 12 }}>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Assign Driver to Bus</Button>
      </Row>
      <Table size="small" loading={loading} dataSource={assignments} rowKey="driverassignment_id"
        columns={[
          { title: 'Driver', key: 'd', render: (_: unknown, r: DriverAssignment) => r.driver?.user?.name || `#${r.driver_id}` },
          { title: 'Bus Plate', key: 'b', render: (_: unknown, r: DriverAssignment) => r.bus?.plate_number || `#${r.bus_id}` },
          {
            title: 'Actions', key: 'a', width: 100,
            render: (_: unknown, r: DriverAssignment) => (
              <Button size="small" icon={<DeleteOutlined />} danger onClick={() => onDelete(r.driverassignment_id)} />
            ),
          },
        ]}
      />
      <Modal title="Assign Driver to Bus" open={modalOpen} onCancel={() => setModalOpen(false)} footer={null} width={400}>
        <Form form={form} layout="vertical" onFinish={onSubmit}>
          <Form.Item name="driver_id" label="Driver" rules={[{ required: true }]}>
            <Select showSearch optionFilterProp="label"
              options={drivers.map((d) => ({ value: d.driver_id, label: d.user?.name || `Driver #${d.driver_id}` }))}
            />
          </Form.Item>
          <Form.Item name="bus_id" label="Bus" rules={[{ required: true }]}>
            <Select showSearch optionFilterProp="label"
              options={buses.map((b) => ({ value: b.bus_id, label: b.plate_number }))}
            />
          </Form.Item>
          <Button type="primary" htmlType="submit" block>Create</Button>
        </Form>
      </Modal>
    </>
  );
}

// ────────────────────────────────────────────────────────────────────
// STUDENT BUS ASSIGNMENTS TAB
// ────────────────────────────────────────────────────────────────────
function StudentAssignmentsTab() {
  const [assignments, setAssignments] = useState<StudentBusAssignment[]>([]);
  const [students, setStudents] = useState<Student[]>([]);
  const [buses, setBuses] = useState<Bus[]>([]);
  const [routes, setRoutes] = useState<BusRoute[]>([]);
  const [loading, setLoading] = useState(true);

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<StudentBusAssignment | null>(null);
  const [selectedRouteId, setSelectedRouteId] = useState<number | null>(null);
  const [form] = Form.useForm();

  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<StudentBusAssignment | null>(null);

  const fetch = useCallback(async () => {
    setLoading(true);
    try {
      const [aRes, sRes, bRes, rRes] = await Promise.all([
        api.get('/admin/student-bus-assignments', { params: { per_page: 300 } }),
        api.get('/admin/students', { params: { per_page: 500, status: 'active' } }),
        api.get('/admin/buses', { params: { per_page: 200 } }),
        api.get('/admin/bus-routes', { params: { per_page: 100 } }),
      ]);
      setAssignments(aRes.data.data || aRes.data);
      setStudents(sRes.data.data || sRes.data);
      setBuses(bRes.data.data || bRes.data);
      setRoutes(rRes.data.data || rRes.data);
    } catch { message.error('Failed to load'); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { fetch(); }, [fetch]);

  const openCreate = () => {
    setEditing(null); setSelectedRouteId(null); form.resetFields(); setModalOpen(true);
  };
  const openEdit = (a: StudentBusAssignment) => {
    setEditing(a); setSelectedRouteId(a.route_id);
    form.setFieldsValue({
      student_id: a.student_id, bus_id: a.bus_id, route_id: a.route_id, stop_id: a.stop_id,
    });
    setModalOpen(true);
  };

  const onSubmit = async (values: Record<string, unknown>) => {
    try {
      if (editing) await api.put(`/admin/student-bus-assignments/${editing.sbassignment_id}`, values);
      else await api.post('/admin/student-bus-assignments', values);
      message.success('Saved'); setModalOpen(false); fetch();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to save');
    }
  };

  const onDelete = (id: number) => Modal.confirm({
    title: 'Remove this student assignment?', okType: 'danger',
    onOk: async () => {
      try { await api.delete(`/admin/student-bus-assignments/${id}`); message.success('Removed'); fetch(); }
      catch { message.error('Failed to remove'); }
    },
  });

  const currentRouteStops = routes.find((r) => r.route_id === selectedRouteId)?.stops || [];

  return (
    <>
      <Row justify="end" style={{ marginBottom: 12 }}>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Assign Student to Bus</Button>
      </Row>
      <Table size="small" loading={loading} dataSource={assignments} rowKey="sbassignment_id"
        columns={[
          { title: 'Student', key: 's', render: (_: unknown, r: StudentBusAssignment) => r.student?.user?.name || `#${r.student_id}` },
          { title: 'Bus', key: 'b', render: (_: unknown, r: StudentBusAssignment) => r.bus?.plate_number || `#${r.bus_id}` },
          { title: 'Route', key: 'r', render: (_: unknown, r: StudentBusAssignment) => r.route?.name || `#${r.route_id}` },
          { title: 'Stop', key: 'st', render: (_: unknown, r: StudentBusAssignment) => r.stop?.name || `#${r.stop_id}` },
          {
            title: 'Actions', key: 'a', width: 150,
            render: (_: unknown, r: StudentBusAssignment) => (
              <Space>
                <Button size="small" icon={<EyeOutlined />} onClick={() => { setSelected(r); setDetailOpen(true); }} />
                <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
                <Button size="small" icon={<DeleteOutlined />} danger onClick={() => onDelete(r.sbassignment_id)} />
              </Space>
            ),
          },
        ]}
      />
      <Modal title={editing ? 'Edit Assignment' : 'Assign Student to Bus'} open={modalOpen}
        onCancel={() => setModalOpen(false)} footer={null} width={500}>
        <Form form={form} layout="vertical" onFinish={onSubmit}>
          {!editing && (
            <Form.Item name="student_id" label="Student" rules={[{ required: true }]}>
              <Select showSearch optionFilterProp="label"
                options={students.map((s) => ({ value: s.id, label: s.user?.name || `Student #${s.id}` }))}
              />
            </Form.Item>
          )}
          <Form.Item name="bus_id" label="Bus" rules={[{ required: true }]}>
            <Select showSearch optionFilterProp="label"
              options={buses.map((b) => ({ value: b.bus_id, label: b.plate_number }))}
            />
          </Form.Item>
          <Form.Item name="route_id" label="Route" rules={[{ required: true }]}>
            <Select showSearch optionFilterProp="label"
              onChange={(v) => { setSelectedRouteId(v); form.setFieldValue('stop_id', undefined); }}
              options={routes.map((r) => ({ value: r.route_id, label: r.name }))}
            />
          </Form.Item>
          <Form.Item name="stop_id" label="Stop" rules={[{ required: true }]}>
            <Select showSearch optionFilterProp="label" disabled={!selectedRouteId}
              options={currentRouteStops.map((s) => ({ value: s.stop_id, label: `${s.stoporder}. ${s.name}` }))}
            />
          </Form.Item>
          <Button type="primary" htmlType="submit" block>{editing ? 'Save' : 'Create'}</Button>
        </Form>
      </Modal>

      <Modal title="Assignment Detail" open={detailOpen} onCancel={() => { setDetailOpen(false); setSelected(null); }} footer={null} width={450}>
        {selected && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Student">{selected.student?.user?.name || `#${selected.student_id}`}</Descriptions.Item>
            <Descriptions.Item label="Bus"><Tag color="blue">{selected.bus?.plate_number || `#${selected.bus_id}`}</Tag></Descriptions.Item>
            <Descriptions.Item label="Route">{selected.route?.name || `#${selected.route_id}`}</Descriptions.Item>
            <Descriptions.Item label="Stop">{selected.stop?.name || `#${selected.stop_id}`}</Descriptions.Item>
          </Descriptions>
        )}
      </Modal>
    </>
  );
}

// ────────────────────────────────────────────────────────────────────
// MAIN PAGE
// ────────────────────────────────────────────────────────────────────
export default function BusManagement() {
  return (
    <div>
      <Title level={4} style={{ marginBottom: 16 }}>Bus Management</Title>
      <Card>
        <Tabs
          items={[
            { key: 'buses', label: 'Buses', children: <BusesTab /> },
            { key: 'drivers', label: 'Drivers', children: <DriversTab /> },
            { key: 'routes', label: 'Routes & Stops', children: <RoutesTab /> },
            { key: 'driver-assign', label: 'Driver Assignments', children: <DriverAssignmentsTab /> },
            { key: 'student-assign', label: 'Student Assignments', children: <StudentAssignmentsTab /> },
          ]}
        />
      </Card>
    </div>
  );
}
