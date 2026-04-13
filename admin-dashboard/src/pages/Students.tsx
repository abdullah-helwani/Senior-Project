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

interface StudentRecord {
  id: number;
  user_id: number;
  date_of_birth: string | null;
  gender: string | null;
  address: string | null;
  enrollment_date: string | null;
  graduation_year: number | null;
  status: string;
  user: {
    id: number;
    name: string;
    email: string;
    phone: string | null;
    is_active: boolean;
  };
  active_enrollment: {
    section: {
      name: string;
      section_id: number;
      school_class: {
        name: string;
        school_year?: { name: string };
      };
    };
  } | null;
}

const statusColors: Record<string, string> = {
  active: 'green',
  graduated: 'blue',
  transferred: 'orange',
  withdrawn: 'red',
};

export default function Students() {
  const [data, setData] = useState<{ data: StudentRecord[]; total: number; current_page: number; per_page: number } | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string | undefined>();
  const [page, setPage] = useState(1);

  // Create modal
  const [createOpen, setCreateOpen] = useState(false);
  const [createLoading, setCreateLoading] = useState(false);
  const [createForm] = Form.useForm();

  // Edit modal
  const [editOpen, setEditOpen] = useState(false);
  const [editLoading, setEditLoading] = useState(false);
  const [editForm] = Form.useForm();
  const [editingStudent, setEditingStudent] = useState<StudentRecord | null>(null);

  // View modal
  const [viewOpen, setViewOpen] = useState(false);
  const [viewStudent, setViewStudent] = useState<StudentRecord | null>(null);

  const fetchStudents = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page, per_page: 15 };
      if (search) params.search = search;
      if (statusFilter) params.status = statusFilter;
      const res = await api.get('/admin/students', { params });
      setData(res.data);
    } catch {
      message.error('Failed to load students');
    } finally {
      setLoading(false);
    }
  }, [page, search, statusFilter]);

  useEffect(() => { fetchStudents(); }, [fetchStudents]);

  const handleCreate = async (values: Record<string, string>) => {
    setCreateLoading(true);
    try {
      await api.post('/admin/students', values);
      message.success('Student created successfully');
      setCreateOpen(false);
      createForm.resetFields();
      fetchStudents();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to create student');
    } finally {
      setCreateLoading(false);
    }
  };

  const handleEdit = async (values: Record<string, string>) => {
    if (!editingStudent) return;
    setEditLoading(true);
    try {
      await api.put(`/admin/students/${editingStudent.id}`, values);
      message.success('Student updated successfully');
      setEditOpen(false);
      editForm.resetFields();
      setEditingStudent(null);
      fetchStudents();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to update student');
    } finally {
      setEditLoading(false);
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/admin/students/${id}`);
      message.success('Student deleted');
      fetchStudents();
    } catch {
      message.error('Failed to delete student');
    }
  };

  const openEdit = (student: StudentRecord) => {
    setEditingStudent(student);
    editForm.setFieldsValue({
      name: student.user.name,
      email: student.user.email,
      phone: student.user.phone,
      date_of_birth: student.date_of_birth,
      gender: student.gender,
      address: student.address,
      graduation_year: student.graduation_year,
      status: student.status,
    });
    setEditOpen(true);
  };

  const openView = async (id: number) => {
    try {
      const res = await api.get(`/admin/students/${id}`);
      setViewStudent(res.data);
      setViewOpen(true);
    } catch {
      message.error('Failed to load student');
    }
  };

  const columns = [
    {
      title: 'Name',
      key: 'name',
      render: (_: unknown, r: StudentRecord) => r.user.name,
    },
    {
      title: 'Email',
      key: 'email',
      render: (_: unknown, r: StudentRecord) => r.user.email,
    },
    {
      title: 'Class / Section',
      key: 'enrollment',
      render: (_: unknown, r: StudentRecord) => {
        if (!r.active_enrollment) return <Tag>Not enrolled</Tag>;
        const e = r.active_enrollment;
        return `${e.section.school_class.name} — ${e.section.name}`;
      },
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (s: string) => <Tag color={statusColors[s]}>{s}</Tag>,
    },
    {
      title: 'Account',
      key: 'is_active',
      render: (_: unknown, r: StudentRecord) => (
        <Badge status={r.user.is_active ? 'success' : 'error'} text={r.user.is_active ? 'Active' : 'Inactive'} />
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: unknown, record: StudentRecord) => (
        <Space size="small">
          <Button size="small" icon={<EyeOutlined />} onClick={() => openView(record.id)} />
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(record)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => {
            Modal.confirm({
              title: 'Delete this student?',
              content: 'This will permanently delete the student and their user account.',
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
        <Col><Title level={4} style={{ margin: 0 }}>Students</Title></Col>
        <Col>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setCreateOpen(true)}>
            Add Student
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
                { value: 'graduated', label: 'Graduated' },
                { value: 'transferred', label: 'Transferred' },
                { value: 'withdrawn', label: 'Withdrawn' },
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
            showTotal: (total) => `${total} students`,
          }}
        />
      </Card>

      {/* Create Student Modal */}
      <Modal
        title="Add New Student"
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
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="graduation_year" label="Graduation Year">
                <Input type="number" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="enrollment_date" label="Enrollment Date">
                <Input type="date" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={createLoading} block>
              Create Student
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* Edit Student Modal */}
      <Modal
        title={`Edit Student — ${editingStudent?.user.name}`}
        open={editOpen}
        onCancel={() => { setEditOpen(false); setEditingStudent(null); }}
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
              <Form.Item name="graduation_year" label="Graduation Year">
                <Input type="number" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="status" label="Status">
                <Select options={[
                  { value: 'active', label: 'Active' },
                  { value: 'graduated', label: 'Graduated' },
                  { value: 'transferred', label: 'Transferred' },
                  { value: 'withdrawn', label: 'Withdrawn' },
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

      {/* View Student Modal */}
      <Modal
        title={`Student Profile — ${viewStudent?.user.name}`}
        open={viewOpen}
        onCancel={() => { setViewOpen(false); setViewStudent(null); }}
        footer={null}
        width={600}
      >
        {viewStudent && (
          <Descriptions column={2} bordered size="small">
            <Descriptions.Item label="Name">{viewStudent.user.name}</Descriptions.Item>
            <Descriptions.Item label="Email">{viewStudent.user.email}</Descriptions.Item>
            <Descriptions.Item label="Phone">{viewStudent.user.phone || '—'}</Descriptions.Item>
            <Descriptions.Item label="Gender">{viewStudent.gender || '—'}</Descriptions.Item>
            <Descriptions.Item label="Date of Birth">{viewStudent.date_of_birth || '—'}</Descriptions.Item>
            <Descriptions.Item label="Address">{viewStudent.address || '—'}</Descriptions.Item>
            <Descriptions.Item label="Enrollment Date">{viewStudent.enrollment_date || '—'}</Descriptions.Item>
            <Descriptions.Item label="Graduation Year">{viewStudent.graduation_year || '—'}</Descriptions.Item>
            <Descriptions.Item label="Status">
              <Tag color={statusColors[viewStudent.status]}>{viewStudent.status}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="Account">
              <Badge status={viewStudent.user.is_active ? 'success' : 'error'} text={viewStudent.user.is_active ? 'Active' : 'Inactive'} />
            </Descriptions.Item>
            {viewStudent.enrollments && (
              <Descriptions.Item label="Enrollments" span={2}>
                {(viewStudent as unknown as { enrollments: Array<{ section: { name: string; school_class: { name: string; school_year?: { name: string } } } }> }).enrollments.map((e, i) => (
                  <Tag key={i}>{e.section.school_class.name} — {e.section.name} {e.section.school_class.school_year ? `(${e.section.school_class.school_year.name})` : ''}</Tag>
                ))}
              </Descriptions.Item>
            )}
          </Descriptions>
        )}
      </Modal>
    </div>
  );
}
