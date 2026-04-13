import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Input, Select, Tag, Space, Modal, Form,
  message, Popconfirm, Card, Typography, Row, Col, Badge,
} from 'antd';
import {
  PlusOutlined, SearchOutlined, LockOutlined,
  UserOutlined, EditOutlined,
} from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

interface User {
  id: number;
  name: string;
  email: string;
  phone: string | null;
  role_type: string;
  is_active: boolean;
  profile_picture: string | null;
  created_at: string;
}

interface PaginatedResponse {
  data: User[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

const roleColors: Record<string, string> = {
  admin: 'purple',
  teacher: 'blue',
  student: 'green',
  parent: 'orange',
};

export default function Users() {
  const [data, setData] = useState<PaginatedResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string | undefined>();
  const [activeFilter, setActiveFilter] = useState<string | undefined>();
  const [page, setPage] = useState(1);

  // Create modal
  const [createOpen, setCreateOpen] = useState(false);
  const [createLoading, setCreateLoading] = useState(false);
  const [createForm] = Form.useForm();

  // Edit modal
  const [editOpen, setEditOpen] = useState(false);
  const [editLoading, setEditLoading] = useState(false);
  const [editForm] = Form.useForm();
  const [editingUser, setEditingUser] = useState<User | null>(null);

  // Reset password modal
  const [resetOpen, setResetOpen] = useState(false);
  const [resetLoading, setResetLoading] = useState(false);
  const [resetForm] = Form.useForm();
  const [resetUser, setResetUser] = useState<User | null>(null);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page, per_page: 15 };
      if (search) params.search = search;
      if (roleFilter) params.role_type = roleFilter;
      if (activeFilter) params.is_active = activeFilter;
      const res = await api.get('/admin/users', { params });
      setData(res.data);
    } catch {
      message.error('Failed to load users');
    } finally {
      setLoading(false);
    }
  }, [page, search, roleFilter, activeFilter]);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  const handleCreate = async (values: Record<string, string>) => {
    setCreateLoading(true);
    try {
      await api.post('/admin/users', values);
      message.success('User created successfully');
      setCreateOpen(false);
      createForm.resetFields();
      fetchUsers();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to create user');
    } finally {
      setCreateLoading(false);
    }
  };

  const handleEdit = async (values: Record<string, string>) => {
    if (!editingUser) return;
    setEditLoading(true);
    try {
      await api.put(`/admin/users/${editingUser.id}`, values);
      message.success('User updated successfully');
      setEditOpen(false);
      editForm.resetFields();
      setEditingUser(null);
      fetchUsers();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to update user');
    } finally {
      setEditLoading(false);
    }
  };

  const handleToggleActive = async (user: User) => {
    try {
      await api.put(`/admin/users/${user.id}/toggle-active`);
      message.success(user.is_active ? 'User deactivated' : 'User reactivated');
      fetchUsers();
    } catch {
      message.error('Failed to toggle user status');
    }
  };

  const handleResetPassword = async (values: { new_password: string }) => {
    if (!resetUser) return;
    setResetLoading(true);
    try {
      await api.put(`/admin/users/${resetUser.id}/reset-password`, values);
      message.success('Password reset successfully');
      setResetOpen(false);
      resetForm.resetFields();
      setResetUser(null);
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to reset password');
    } finally {
      setResetLoading(false);
    }
  };

  const openEdit = (user: User) => {
    setEditingUser(user);
    editForm.setFieldsValue({ name: user.name, email: user.email, phone: user.phone });
    setEditOpen(true);
  };

  const openReset = (user: User) => {
    setResetUser(user);
    resetForm.resetFields();
    setResetOpen(true);
  };

  const columns = [
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      render: (name: string) => (
        <Space><UserOutlined />{name}</Space>
      ),
    },
    { title: 'Email', dataIndex: 'email', key: 'email' },
    { title: 'Phone', dataIndex: 'phone', key: 'phone', render: (p: string | null) => p || '—' },
    {
      title: 'Role',
      dataIndex: 'role_type',
      key: 'role_type',
      render: (role: string) => <Tag color={roleColors[role]}>{role}</Tag>,
    },
    {
      title: 'Status',
      dataIndex: 'is_active',
      key: 'is_active',
      render: (active: boolean) => (
        <Badge status={active ? 'success' : 'error'} text={active ? 'Active' : 'Inactive'} />
      ),
    },
    {
      title: 'Joined',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (d: string) => new Date(d).toLocaleDateString(),
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: unknown, record: User) => (
        <Space size="small">
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(record)}>
            Edit
          </Button>
          <Button size="small" icon={<LockOutlined />} onClick={() => openReset(record)}>
            Reset PW
          </Button>
          <Popconfirm
            title={`${record.is_active ? 'Deactivate' : 'Reactivate'} this user?`}
            onConfirm={() => handleToggleActive(record)}
            okText="Yes"
            cancelText="No"
          >
            <Button size="small" danger={record.is_active} type={record.is_active ? 'default' : 'primary'}>
              {record.is_active ? 'Deactivate' : 'Activate'}
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Users</Title></Col>
        <Col>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setCreateOpen(true)}>
            Add User
          </Button>
        </Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Row gutter={16}>
          <Col xs={24} sm={8}>
            <Input
              placeholder="Search by name or email..."
              prefix={<SearchOutlined />}
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              allowClear
            />
          </Col>
          <Col xs={12} sm={4}>
            <Select
              placeholder="Role"
              style={{ width: '100%' }}
              allowClear
              value={roleFilter}
              onChange={(v) => { setRoleFilter(v); setPage(1); }}
              options={[
                { value: 'admin', label: 'Admin' },
                { value: 'teacher', label: 'Teacher' },
                { value: 'student', label: 'Student' },
                { value: 'parent', label: 'Parent' },
              ]}
            />
          </Col>
          <Col xs={12} sm={4}>
            <Select
              placeholder="Status"
              style={{ width: '100%' }}
              allowClear
              value={activeFilter}
              onChange={(v) => { setActiveFilter(v); setPage(1); }}
              options={[
                { value: 'true', label: 'Active' },
                { value: 'false', label: 'Inactive' },
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
            showTotal: (total) => `${total} users`,
          }}
        />
      </Card>

      {/* Create User Modal */}
      <Modal
        title="Add New User"
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
          <Form.Item name="role_type" label="Role" rules={[{ required: true }]}>
            <Select
              options={[
                { value: 'admin', label: 'Admin' },
                { value: 'teacher', label: 'Teacher' },
                { value: 'student', label: 'Student' },
                { value: 'parent', label: 'Parent' },
              ]}
            />
          </Form.Item>
          <Form.Item name="gender" label="Gender">
            <Select
              allowClear
              options={[
                { value: 'male', label: 'Male' },
                { value: 'female', label: 'Female' },
              ]}
            />
          </Form.Item>
          <Form.Item name="date_of_birth" label="Date of Birth">
            <Input type="date" />
          </Form.Item>
          <Form.Item name="address" label="Address">
            <Input />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={createLoading} block>
              Create User
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* Edit User Modal */}
      <Modal
        title={`Edit User — ${editingUser?.name}`}
        open={editOpen}
        onCancel={() => { setEditOpen(false); setEditingUser(null); }}
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
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={editLoading} block>
              Save Changes
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* Reset Password Modal */}
      <Modal
        title={`Reset Password — ${resetUser?.name}`}
        open={resetOpen}
        onCancel={() => { setResetOpen(false); setResetUser(null); }}
        footer={null}
        width={400}
      >
        <Form form={resetForm} layout="vertical" onFinish={handleResetPassword}>
          <Form.Item name="new_password" label="New Password" rules={[{ required: true, min: 8 }]}>
            <Input.Password />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={resetLoading} block danger>
              Reset Password
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
