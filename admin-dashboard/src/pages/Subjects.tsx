import { useEffect, useState } from 'react';
import { Table, Button, Input, Modal, Form, message, Card, Typography, Row, Col, Space } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

interface Subject { id: number; name: string; code: string }

export default function Subjects() {
  const [data, setData] = useState<Subject[]>([]);
  const [filtered, setFiltered] = useState<Subject[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [modalLoading, setModalLoading] = useState(false);
  const [editing, setEditing] = useState<Subject | null>(null);
  const [form] = Form.useForm();

  const fetch = async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/subjects');
      setData(res.data);
      setFiltered(res.data);
    } catch { message.error('Failed to load subjects'); }
    finally { setLoading(false); }
  };

  useEffect(() => { fetch(); }, []);
  useEffect(() => {
    if (!search) { setFiltered(data); return; }
    const s = search.toLowerCase();
    setFiltered(data.filter((d) => d.name.toLowerCase().includes(s) || d.code.toLowerCase().includes(s)));
  }, [search, data]);

  const openCreate = () => { setEditing(null); form.resetFields(); setModalOpen(true); };
  const openEdit = (r: Subject) => { setEditing(r); form.setFieldsValue({ name: r.name, code: r.code }); setModalOpen(true); };

  const handleSubmit = async (values: { name: string; code: string }) => {
    setModalLoading(true);
    try {
      if (editing) {
        await api.put(`/admin/subjects/${editing.id}`, values);
        message.success('Subject updated');
      } else {
        await api.post('/admin/subjects', values);
        message.success('Subject created');
      }
      setModalOpen(false); form.resetFields(); setEditing(null); fetch();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to save');
    } finally { setModalLoading(false); }
  };

  const handleDelete = async (id: number) => {
    try { await api.delete(`/admin/subjects/${id}`); message.success('Deleted'); fetch(); }
    catch { message.error('Failed to delete'); }
  };

  const columns = [
    { title: 'Code', dataIndex: 'code', key: 'code', width: 120 },
    { title: 'Name', dataIndex: 'name', key: 'name' },
    {
      title: 'Actions', key: 'actions', width: 150,
      render: (_: unknown, r: Subject) => (
        <Space>
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => {
            Modal.confirm({ title: 'Delete this subject?', okType: 'danger', onOk: () => handleDelete(r.id) });
          }} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Subjects</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Add Subject</Button></Col>
      </Row>
      <Card style={{ marginBottom: 16 }}>
        <Input placeholder="Search by name or code..." prefix={<SearchOutlined />} value={search} onChange={(e) => setSearch(e.target.value)} allowClear style={{ width: 300 }} />
      </Card>
      <Card>
        <Table dataSource={filtered} columns={columns} rowKey="id" loading={loading} pagination={{ pageSize: 20, showTotal: (t) => `${t} subjects` }} />
      </Card>
      <Modal
        title={editing ? 'Edit Subject' : 'Add Subject'}
        open={modalOpen}
        onCancel={() => { setModalOpen(false); setEditing(null); }}
        footer={null} width={400}
      >
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          <Form.Item name="name" label="Subject Name" rules={[{ required: true }]}>
            <Input placeholder="e.g. Mathematics" />
          </Form.Item>
          <Form.Item name="code" label="Code" rules={[{ required: true }]}>
            <Input placeholder="e.g. MATH101" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={modalLoading} block>
              {editing ? 'Save Changes' : 'Create'}
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
