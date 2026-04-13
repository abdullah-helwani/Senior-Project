import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Input, Select, Tag, Space, Modal, Form,
  message, Card, Typography, Row, Col, Descriptions, Badge,
} from 'antd';
import {
  PlusOutlined, SearchOutlined, EyeOutlined, EditOutlined, DeleteOutlined,
} from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

interface TeacherRecord {
  id: number;
  user_id: number;
  date_of_birth: string | null;
  gender: string | null;
  address: string | null;
  hire_date: string | null;
  status: string;
  user: {
    id: number;
    name: string;
    email: string;
    phone: string | null;
    is_active: boolean;
  };
  subjects: Array<{ id: number; name: string }>;
  assignments?: Array<{
    subject: { name: string };
    section: { name: string; school_class: { name: string; school_year?: { name: string } } };
  }>;
}

const statusColors: Record<string, string> = {
  active: 'green',
  inactive: 'orange',
  resigned: 'red',
};

export default function Teachers() {
  const [data, setData] = useState<{ data: TeacherRecord[]; total: number; current_page: number; per_page: number } | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string | undefined>();
  const [page, setPage] = useState(1);

  const [createOpen, setCreateOpen] = useState(false);
  const [createLoading, setCreateLoading] = useState(false);
  const [createForm] = Form.useForm();

  const [editOpen, setEditOpen] = useState(false);
  const [editLoading, setEditLoading] = useState(false);
  const [editForm] = Form.useForm();
  const [editingTeacher, setEditingTeacher] = useState<TeacherRecord | null>(null);

  const [viewOpen, setViewOpen] = useState(false);
  const [viewTeacher, setViewTeacher] = useState<TeacherRecord | null>(null);

  const fetchTeachers = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page, per_page: 15 };
      if (search) params.search = search;
      if (statusFilter) params.status = statusFilter;
      const res = await api.get('/admin/teachers', { params });
      setData(res.data);
    } catch {
      message.error('Failed to load teachers');
    } finally {
      setLoading(false);
    }
  }, [page, search, statusFilter]);

  useEffect(() => { fetchTeachers(); }, [fetchTeachers]);

  const handleCreate = async (values: Record<string, string>) => {
    setCreateLoading(true);
    try {
      await api.post('/admin/teachers', values);
      message.success('Teacher created successfully');
      setCreateOpen(false);
      createForm.resetFields();
      fetchTeachers();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to create teacher');
    } finally {
      setCreateLoading(false);
    }
  };

  const handleEdit = async (values: Record<string, string>) => {
    if (!editingTeacher) return;
    setEditLoading(true);
    try {
      await api.put(`/admin/teachers/${editingTeacher.id}`, values);
      message.success('Teacher updated successfully');
      setEditOpen(false);
      editForm.resetFields();
      setEditingTeacher(null);
      fetchTeachers();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to update teacher');
    } finally {
      setEditLoading(false);
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/admin/teachers/${id}`);
      message.success('Teacher deleted');
      fetchTeachers();
    } catch {
      message.error('Failed to delete teacher');
    }
  };

  const openEdit = (teacher: TeacherRecord) => {
    setEditingTeacher(teacher);
    editForm.setFieldsValue({
      name: teacher.user.name,
      email: teacher.user.email,
      phone: teacher.user.phone,
      date_of_birth: teacher.date_of_birth,
      gender: teacher.gender,
      address: teacher.address,
      hire_date: teacher.hire_date,
      status: teacher.status,
    });
    setEditOpen(true);
  };

  const openView = async (id: number) => {
    try {
      const res = await api.get(`/admin/teachers/${id}`);
      setViewTeacher(res.data);
      setViewOpen(true);
    } catch {
      message.error('Failed to load teacher');
    }
  };

  const columns = [
    {
      title: 'Name',
      key: 'name',
      render: (_: unknown, r: TeacherRecord) => r.user.name,
    },
    {
      title: 'Email',
      key: 'email',
      render: (_: unknown, r: TeacherRecord) => r.user.email,
    },
    {
      title: 'Subjects',
      key: 'subjects',
      render: (_: unknown, r: TeacherRecord) =>
        r.subjects?.length
          ? r.subjects.map((s) => <Tag key={s.id}>{s.name}</Tag>)
          : <Tag>None</Tag>,
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (s: string) => <Tag color={statusColors[s]}>{s}</Tag>,
    },
    {
      title: 'Hire Date',
      dataIndex: 'hire_date',
      key: 'hire_date',
      render: (d: string | null) => d ? new Date(d).toLocaleDateString() : '—',
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: unknown, record: TeacherRecord) => (
        <Space size="small">
          <Button size="small" icon={<EyeOutlined />} onClick={() => openView(record.id)} />
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(record)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => {
            Modal.confirm({
              title: 'Delete this teacher?',
              content: 'This will permanently delete the teacher and their user account.',
              okText: 'Delete',
              okType: 'danger',
              onOk: () => handleDelete(record.id),
            });
          }} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Teachers</Title></Col>
        <Col>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setCreateOpen(true)}>
            Add Teacher
          </Button>
        </Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Row gutter={16}>
          <Col xs={24} sm={10}>
            <Input
              placeholder="Search by name, email, or phone..."
              prefix={<SearchOutlined />}
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              allowClear
            />
          </Col>
          <Col xs={12} sm={4}>
            <Select
              placeholder="Status"
              style={{ width: '100%' }}
              allowClear
              value={statusFilter}
              onChange={(v) => { setStatusFilter(v); setPage(1); }}
              options={[
                { value: 'active', label: 'Active' },
                { value: 'inactive', label: 'Inactive' },
                { value: 'resigned', label: 'Resigned' },
              ]}
            />
          </Col>
        </Row>
      </Card>

      <Card>
        <Table
          dataSource={data?.data || []}
          columns={columns}
          rowKey="id"
          loading={loading}
          pagination={{
            current: data?.current_page || 1,
            total: data?.total || 0,
            pageSize: data?.per_page || 15,
            onChange: (p) => setPage(p),
            showSizeChanger: false,
            showTotal: (total) => `${total} teachers`,
          }}
        />
      </Card>

      {/* Create Teacher Modal */}
      <Modal
        title="Add New Teacher"
        open={createOpen}
        onCancel={() => { setCreateOpen(false); createForm.resetFields(); }}
        footer={null}
        width={500}
      >
        <Form form={createForm} layout="vertical" onFinish={handleCreate}>
          <Form.Item name="name" label="Full Name" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="email" label="Email" rules={[{ required: true, type: 'email' }]}>
            <Input />
          </Form.Item>
          <Form.Item name="phone" label="Phone">
            <Input />
          </Form.Item>
          <Form.Item name="password" label="Password" rules={[{ required: true, min: 8 }]}>
            <Input.Password />
          </Form.Item>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="gender" label="Gender">
                <Select allowClear options={[
                  { value: 'male', label: 'Male' },
                  { value: 'female', label: 'Female' },
                ]} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="date_of_birth" label="Date of Birth">
                <Input type="date" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="address" label="Address">
            <Input />
          </Form.Item>
          <Form.Item name="hire_date" label="Hire Date">
            <Input type="date" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={createLoading} block>
              Create Teacher
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* Edit Teacher Modal */}
      <Modal
        title={`Edit Teacher — ${editingTeacher?.user.name}`}
        open={editOpen}
        onCancel={() => { setEditOpen(false); setEditingTeacher(null); }}
        footer={null}
        width={500}
      >
        <Form form={editForm} layout="vertical" onFinish={handleEdit}>
          <Form.Item name="name" label="Full Name" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="email" label="Email" rules={[{ required: true, type: 'email' }]}>
            <Input />
          </Form.Item>
          <Form.Item name="phone" label="Phone">
            <Input />
          </Form.Item>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="gender" label="Gender">
                <Select allowClear options={[
                  { value: 'male', label: 'Male' },
                  { value: 'female', label: 'Female' },
                ]} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="date_of_birth" label="Date of Birth">
                <Input type="date" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="address" label="Address">
            <Input />
          </Form.Item>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="hire_date" label="Hire Date">
                <Input type="date" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="status" label="Status">
                <Select options={[
                  { value: 'active', label: 'Active' },
                  { value: 'inactive', label: 'Inactive' },
                  { value: 'resigned', label: 'Resigned' },
                ]} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={editLoading} block>
              Save Changes
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* View Teacher Modal */}
      <Modal
        title={`Teacher Profile — ${viewTeacher?.user.name}`}
        open={viewOpen}
        onCancel={() => { setViewOpen(false); setViewTeacher(null); }}
        footer={null}
        width={600}
      >
        {viewTeacher && (
          <Descriptions column={2} bordered size="small">
            <Descriptions.Item label="Name">{viewTeacher.user.name}</Descriptions.Item>
            <Descriptions.Item label="Email">{viewTeacher.user.email}</Descriptions.Item>
            <Descriptions.Item label="Phone">{viewTeacher.user.phone || '—'}</Descriptions.Item>
            <Descriptions.Item label="Gender">{viewTeacher.gender || '—'}</Descriptions.Item>
            <Descriptions.Item label="Date of Birth">{viewTeacher.date_of_birth || '—'}</Descriptions.Item>
            <Descriptions.Item label="Address">{viewTeacher.address || '—'}</Descriptions.Item>
            <Descriptions.Item label="Hire Date">{viewTeacher.hire_date || '—'}</Descriptions.Item>
            <Descriptions.Item label="Status">
              <Tag color={statusColors[viewTeacher.status]}>{viewTeacher.status}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="Account">
              <Badge status={viewTeacher.user.is_active ? 'success' : 'error'} text={viewTeacher.user.is_active ? 'Active' : 'Inactive'} />
            </Descriptions.Item>
            {viewTeacher.assignments && viewTeacher.assignments.length > 0 && (
              <Descriptions.Item label="Assignments" span={2}>
                {viewTeacher.assignments.map((a, i) => (
                  <Tag key={i}>
                    {a.subject.name} — {a.section.school_class.name} {a.section.name}
                  </Tag>
                ))}
              </Descriptions.Item>
            )}
          </Descriptions>
        )}
      </Modal>
    </div>
  );
}
