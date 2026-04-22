import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Input, Space, Modal, Form,
  message, Card, Typography, Row, Col, Descriptions, Tag, Select, Popconfirm, Empty, Divider,
} from 'antd';
import {
  PlusOutlined, SearchOutlined, EyeOutlined, EditOutlined, DeleteOutlined,
  UserAddOutlined, UserDeleteOutlined,
} from '@ant-design/icons';
import api from '../api/axios';

const { Title, Text } = Typography;

interface StudentLink {
  studentguardian_id: number;
  student_id: number;
  relationship: string;
  isprimary: boolean;
  student?: {
    id: number;
    user?: { name: string; email?: string };
  };
}

interface Guardian {
  parent_id: number;
  user_id: number;
  user: {
    id: number;
    name: string;
    email: string;
    phone: string | null;
    is_active: boolean;
  };
  studentLinks?: StudentLink[];
}

interface StudentOption {
  id: number;
  user?: { name: string };
}

export default function Parents() {
  const [data, setData] = useState<Guardian[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  // Create modal
  const [createOpen, setCreateOpen] = useState(false);
  const [createLoading, setCreateLoading] = useState(false);
  const [createForm] = Form.useForm();

  // Edit modal (now also manages children)
  const [editOpen, setEditOpen] = useState(false);
  const [editing, setEditing] = useState<Guardian | null>(null);
  const [editLoading, setEditLoading] = useState(false);
  const [editForm] = Form.useForm();

  // Detail modal (view-only)
  const [detailOpen, setDetailOpen] = useState(false);
  const [selected, setSelected] = useState<Guardian | null>(null);

  // Add-child sub-modal — works off `activeParentId`
  const [addChildOpen, setAddChildOpen] = useState(false);
  const [addChildForm] = Form.useForm();
  const [activeParentId, setActiveParentId] = useState<number | null>(null);
  const [students, setStudents] = useState<StudentOption[]>([]);

  const fetch = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (search) params.search = search;
      const res = await api.get('/admin/parents', { params });
      const d = res.data.data || res.data;
      setData(Array.isArray(d) ? d : []);
      setTotal(res.data.total || 0);
    } catch {
      message.error('Failed to load parents');
    } finally {
      setLoading(false);
    }
  }, [search, page]);

  const fetchStudents = async () => {
    try {
      const res = await api.get('/admin/students', { params: { per_page: 500, status: 'active' } });
      const d = res.data.data || res.data;
      setStudents(Array.isArray(d) ? d : []);
    } catch { /* ignore */ }
  };

  useEffect(() => { fetch(); }, [fetch]);
  useEffect(() => { fetchStudents(); }, []);

  const openCreate = () => { createForm.resetFields(); setCreateOpen(true); };

  const handleCreate = async (values: Record<string, unknown>) => {
    setCreateLoading(true);
    try {
      await api.post('/admin/parents', values);
      message.success('Parent account created');
      setCreateOpen(false); createForm.resetFields(); fetch();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
      const errors = axiosErr.response?.data?.errors;
      if (errors) {
        message.error(Object.values(errors).flat()[0] || 'Validation failed');
      } else {
        message.error(axiosErr.response?.data?.message || 'Failed to create parent');
      }
    } finally { setCreateLoading(false); }
  };

  // Open the edit modal — fetch full parent (with studentLinks) so we can manage children
  const openEdit = async (g: Guardian) => {
    try {
      const res = await api.get(`/admin/parents/${g.parent_id}`);
      const full: Guardian = res.data;
      setEditing(full);
      editForm.setFieldsValue({
        name: full.user.name,
        email: full.user.email,
        phone: full.user.phone || '',
        is_active: full.user.is_active,
      });
      setEditOpen(true);
    } catch {
      message.error('Failed to load parent');
    }
  };

  const refreshEditing = async () => {
    if (!editing) return;
    try {
      const res = await api.get(`/admin/parents/${editing.parent_id}`);
      setEditing(res.data);
      fetch();
    } catch {
      message.error('Failed to refresh parent');
    }
  };

  const refreshDetail = async () => {
    if (!selected) return;
    try {
      const res = await api.get(`/admin/parents/${selected.parent_id}`);
      setSelected(res.data);
      fetch();
    } catch {
      message.error('Failed to refresh parent');
    }
  };

  const handleEdit = async (values: Record<string, unknown>) => {
    if (!editing) return;
    setEditLoading(true);
    try {
      await api.put(`/admin/parents/${editing.parent_id}`, values);
      message.success('Parent updated');
      setEditOpen(false); setEditing(null); fetch();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to update');
    } finally { setEditLoading(false); }
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/admin/parents/${id}`);
      message.success('Parent deleted');
      fetch();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to delete');
    }
  };

  const openDetail = async (id: number) => {
    try {
      const res = await api.get(`/admin/parents/${id}`);
      setSelected(res.data);
      setDetailOpen(true);
    } catch { message.error('Failed to load parent'); }
  };

  // Open the "link a child" sub-modal against either the edit modal or the detail modal
  const openAddChild = (parentId: number) => {
    setActiveParentId(parentId);
    addChildForm.resetFields();
    setAddChildOpen(true);
  };

  const handleAddChild = async (values: Record<string, unknown>) => {
    if (!activeParentId) return;
    try {
      const res = await api.post(`/admin/parents/${activeParentId}/children`, values);
      const newLink: StudentLink = res.data;
      message.success('Child linked');
      setAddChildOpen(false); addChildForm.resetFields();

      // Optimistically splice the new link into whichever modal is open
      if (editing && editing.parent_id === activeParentId) {
        setEditing({
          ...editing,
          studentLinks: [...(editing.studentLinks || []), newLink],
        });
      }
      if (selected && selected.parent_id === activeParentId) {
        setSelected({
          ...selected,
          studentLinks: [...(selected.studentLinks || []), newLink],
        });
      }

      // Then re-sync from the server in the background
      if (editing && editing.parent_id === activeParentId) await refreshEditing();
      if (selected && selected.parent_id === activeParentId) await refreshDetail();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to link child');
    }
  };

  const handleRemoveChild = async (parentId: number, studentId: number) => {
    try {
      await api.delete(`/admin/parents/${parentId}/children/${studentId}`);
      message.success('Child unlinked');
      if (editing && editing.parent_id === parentId) await refreshEditing();
      if (selected && selected.parent_id === parentId) await refreshDetail();
    } catch { message.error('Failed to unlink'); }
  };

  // Reusable children table — used inside both Edit and Detail modals
  const renderChildrenTable = (parent: Guardian) => (
    <Table
      dataSource={parent.studentLinks || []}
      rowKey="studentguardian_id"
      pagination={false}
      size="small"
      locale={{ emptyText: <Empty description="No children linked yet" image={Empty.PRESENTED_IMAGE_SIMPLE} /> }}
      columns={[
        {
          title: 'Student', key: 'student',
          render: (_: unknown, l: StudentLink) =>
            l.student?.user?.name || `#${l.student_id}`,
        },
        {
          title: 'Relationship', dataIndex: 'relationship', width: 140,
          render: (r: string) => <Tag>{r}</Tag>,
        },
        {
          title: 'Primary', dataIndex: 'isprimary', width: 100,
          render: (p: boolean) => p ? <Tag color="gold">Primary</Tag> : <Text type="secondary">—</Text>,
        },
        {
          title: 'Action', key: 'act', width: 110,
          render: (_: unknown, l: StudentLink) => (
            <Popconfirm
              title="Unlink this child?"
              onConfirm={() => handleRemoveChild(parent.parent_id, l.student_id)}
            >
              <Button size="small" danger icon={<UserDeleteOutlined />}>Unlink</Button>
            </Popconfirm>
          ),
        },
      ]}
    />
  );

  const columns = [
    { title: 'ID', dataIndex: 'parent_id', key: 'id', width: 70 },
    {
      title: 'Name', key: 'name',
      render: (_: unknown, r: Guardian) => <strong>{r.user?.name}</strong>,
    },
    { title: 'Email', key: 'email', render: (_: unknown, r: Guardian) => r.user?.email },
    {
      title: 'Phone', key: 'phone',
      render: (_: unknown, r: Guardian) => r.user?.phone || <Text type="secondary">—</Text>,
    },
    {
      title: 'Children', key: 'children', width: 110,
      render: (_: unknown, r: Guardian) => (
        <Tag color={r.studentLinks?.length ? 'blue' : 'default'}>
          {r.studentLinks?.length || 0} linked
        </Tag>
      ),
    },
    {
      title: 'Status', key: 'status', width: 100,
      render: (_: unknown, r: Guardian) => (
        <Tag color={r.user?.is_active ? 'green' : 'red'}>
          {r.user?.is_active ? 'Active' : 'Inactive'}
        </Tag>
      ),
    },
    {
      title: 'Actions', key: 'actions', width: 170,
      render: (_: unknown, r: Guardian) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => openDetail(r.parent_id)} />
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
          <Popconfirm
            title="Delete this parent account?"
            description="This will also unlink their children."
            okType="danger"
            onConfirm={() => handleDelete(r.parent_id)}
          >
            <Button size="small" icon={<DeleteOutlined />} danger />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Parents</Title></Col>
        <Col>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Add Parent
          </Button>
        </Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Input
          placeholder="Search by name, email, or phone"
          prefix={<SearchOutlined />}
          allowClear
          style={{ maxWidth: 340 }}
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1); }}
        />
      </Card>

      <Card>
        <Table
          dataSource={data}
          columns={columns}
          rowKey="parent_id"
          loading={loading}
          size="middle"
          pagination={{
            current: page, total, pageSize: 20, onChange: setPage,
            showTotal: (t) => `${t} parents`,
          }}
          locale={{ emptyText: <Empty description="No parent accounts yet" /> }}
        />
      </Card>

      {/* ----- Create Parent ----- */}
      <Modal
        title="Add Parent"
        open={createOpen}
        onCancel={() => setCreateOpen(false)}
        footer={null}
        width={560}
        destroyOnHidden
      >
        <Form form={createForm} layout="vertical" onFinish={handleCreate}>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="name" label="Full Name" rules={[{ required: true }]}>
                <Input placeholder="e.g. Ali Hassan" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="phone" label="Phone">
                <Input placeholder="e.g. 0933214423" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="email" label="Email" rules={[{ required: true, type: 'email' }]}>
            <Input placeholder="parent@example.com" />
          </Form.Item>
          <Form.Item
            name="password"
            label="Password"
            rules={[{ required: true, min: 8, message: 'Minimum 8 characters' }]}
          >
            <Input.Password placeholder="At least 8 characters" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" block loading={createLoading}>
              Create Account
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* ----- Edit Parent (+ manage children) ----- */}
      <Modal
        title={`Edit Parent${editing ? ` — ${editing.user?.name}` : ''}`}
        open={editOpen}
        onCancel={() => { setEditOpen(false); setEditing(null); }}
        footer={null}
        width={720}
        destroyOnHidden
      >
        {editing && (
          <>
            <Form form={editForm} layout="vertical" onFinish={handleEdit}>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item name="name" label="Full Name" rules={[{ required: true }]}>
                    <Input />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item name="phone" label="Phone">
                    <Input />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={14}>
                  <Form.Item name="email" label="Email" rules={[{ required: true, type: 'email' }]}>
                    <Input />
                  </Form.Item>
                </Col>
                <Col span={10}>
                  <Form.Item name="is_active" label="Status" rules={[{ required: true }]}>
                    <Select options={[
                      { value: true, label: 'Active' },
                      { value: false, label: 'Inactive' },
                    ]} />
                  </Form.Item>
                </Col>
              </Row>
              <Form.Item>
                <Button type="primary" htmlType="submit" block loading={editLoading}>
                  Save Changes
                </Button>
              </Form.Item>
            </Form>

            <Divider style={{ margin: '8px 0 16px' }} />

            <Row justify="space-between" align="middle" style={{ marginBottom: 12 }}>
              <Col>
                <Title level={5} style={{ margin: 0 }}>
                  Linked Children{' '}
                  <Tag color="blue" style={{ marginLeft: 8 }}>
                    {editing.studentLinks?.length || 0}
                  </Tag>
                </Title>
              </Col>
              <Col>
                <Button
                  type="primary"
                  ghost
                  icon={<UserAddOutlined />}
                  onClick={() => openAddChild(editing.parent_id)}
                >
                  Link Child
                </Button>
              </Col>
            </Row>

            {renderChildrenTable(editing)}
          </>
        )}
      </Modal>

      {/* ----- Detail (view-only) ----- */}
      <Modal
        title={`Parent Detail${selected ? ` — ${selected.user?.name}` : ''}`}
        open={detailOpen}
        onCancel={() => { setDetailOpen(false); setSelected(null); }}
        footer={null}
        width={720}
      >
        {selected && (
          <>
            <Descriptions column={2} bordered size="small" style={{ marginBottom: 16 }}>
              <Descriptions.Item label="Parent #">{selected.parent_id}</Descriptions.Item>
              <Descriptions.Item label="Status">
                <Tag color={selected.user?.is_active ? 'green' : 'red'}>
                  {selected.user?.is_active ? 'Active' : 'Inactive'}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Name">{selected.user?.name}</Descriptions.Item>
              <Descriptions.Item label="Phone">{selected.user?.phone || '—'}</Descriptions.Item>
              <Descriptions.Item label="Email" span={2}>{selected.user?.email}</Descriptions.Item>
            </Descriptions>

            <Row justify="space-between" align="middle" style={{ marginBottom: 12 }}>
              <Col><Title level={5} style={{ margin: 0 }}>Linked Children</Title></Col>
              <Col>
                <Button
                  icon={<UserAddOutlined />}
                  onClick={() => openAddChild(selected.parent_id)}
                >
                  Link Child
                </Button>
              </Col>
            </Row>

            {renderChildrenTable(selected)}
          </>
        )}
      </Modal>

      {/* ----- Add Child ----- */}
      <Modal
        title="Link a Child"
        open={addChildOpen}
        onCancel={() => setAddChildOpen(false)}
        footer={null}
        width={460}
        destroyOnHidden
      >
        <Form form={addChildForm} layout="vertical" onFinish={handleAddChild}>
          <Form.Item name="student_id" label="Student" rules={[{ required: true }]}>
            <Select
              showSearch
              optionFilterProp="label"
              placeholder="Choose a student"
              options={students.map((s) => ({
                value: s.id,
                label: s.user?.name || `#${s.id}`,
              }))}
            />
          </Form.Item>
          <Form.Item name="relationship" label="Relationship" rules={[{ required: true }]}>
            <Select options={['father', 'mother', 'guardian', 'grandparent', 'uncle', 'aunt', 'other'].map((r) => ({
              value: r, label: r.charAt(0).toUpperCase() + r.slice(1),
            }))} />
          </Form.Item>
          <Form.Item name="isprimary" label="Primary guardian" initialValue={false}>
            <Select options={[
              { value: false, label: 'Not primary guardian' },
              { value: true, label: 'Mark as primary guardian' },
            ]} />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" block>Link</Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
