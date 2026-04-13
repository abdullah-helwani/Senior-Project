import { useEffect, useState } from 'react';
import { Table, Button, Input, Modal, Form, message, Card, Typography, Row, Col, Space } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

interface SchoolYear { schoolyearid: number; name: string }

export default function SchoolYears() {
  const [data, setData] = useState<SchoolYear[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [modalLoading, setModalLoading] = useState(false);
  const [editing, setEditing] = useState<SchoolYear | null>(null);
  const [form] = Form.useForm();

  const fetch = async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/school-years');
      setData(res.data);
    } catch { message.error('Failed to load school years'); }
    finally { setLoading(false); }
  };

  useEffect(() => { fetch(); }, []);

  const openCreate = () => { setEditing(null); form.resetFields(); setModalOpen(true); };
  const openEdit = (r: SchoolYear) => { setEditing(r); form.setFieldsValue({ name: r.name }); setModalOpen(true); };

  const handleSubmit = async (values: { name: string }) => {
    setModalLoading(true);
    try {
      if (editing) {
        await api.put(`/admin/school-years/${editing.schoolyearid}`, values);
        message.success('School year updated');
      } else {
        await api.post('/admin/school-years', values);
        message.success('School year created');
      }
      setModalOpen(false);
      form.resetFields();
      setEditing(null);
      fetch();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to save');
    } finally { setModalLoading(false); }
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/admin/school-years/${id}`);
      message.success('Deleted');
      fetch();
    } catch { message.error('Failed to delete'); }
  };

  const columns = [
    { title: 'ID', dataIndex: 'schoolyearid', key: 'id', width: 80 },
    { title: 'Name', dataIndex: 'name', key: 'name' },
    {
      title: 'Actions', key: 'actions', width: 150,
      render: (_: unknown, r: SchoolYear) => (
        <Space>
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => {
            Modal.confirm({ title: 'Delete this school year?', okType: 'danger', onOk: () => handleDelete(r.schoolyearid) });
          }} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>School Years</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Add School Year</Button></Col>
      </Row>
      <Card>
        <Table dataSource={data} columns={columns} rowKey="schoolyearid" loading={loading} pagination={false} />
      </Card>
      <Modal
        title={editing ? 'Edit School Year' : 'Add School Year'}
        open={modalOpen}
        onCancel={() => { setModalOpen(false); setEditing(null); }}
        footer={null} width={400}
      >
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          <Form.Item name="name" label="Name" rules={[{ required: true }]}>
            <Input placeholder="e.g. 2025-2026" />
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
