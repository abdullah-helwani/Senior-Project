import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Input, Modal, Form, Select, message, Card,
  Typography, Row, Col, Space, Tag, Collapse,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import api from '../api/axios';

const { Title } = Typography;

interface SchoolYear { schoolyearid: number; name: string }
interface Section { section_id: number; name: string; class_id: number }
interface SchoolClass {
  class_id: number;
  name: string;
  schoolyearid: number;
  school_year?: SchoolYear;
  sections?: Section[];
}

export default function Classes() {
  const [classes, setClasses] = useState<SchoolClass[]>([]);
  const [schoolYears, setSchoolYears] = useState<SchoolYear[]>([]);
  const [loading, setLoading] = useState(true);
  const [yearFilter, setYearFilter] = useState<number | undefined>();

  // Class modals
  const [classModalOpen, setClassModalOpen] = useState(false);
  const [classLoading, setClassLoading] = useState(false);
  const [editingClass, setEditingClass] = useState<SchoolClass | null>(null);
  const [classForm] = Form.useForm();

  // Section modals
  const [sectionModalOpen, setSectionModalOpen] = useState(false);
  const [sectionLoading, setSectionLoading] = useState(false);
  const [editingSection, setEditingSection] = useState<Section | null>(null);
  const [sectionClassId, setSectionClassId] = useState<number | null>(null);
  const [sectionForm] = Form.useForm();

  const fetchClasses = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, number> = {};
      if (yearFilter) params.schoolyearid = yearFilter;
      const res = await api.get('/admin/classes', { params });
      // Load sections for each class
      const classesWithSections = await Promise.all(
        res.data.map(async (c: SchoolClass) => {
          const detail = await api.get(`/admin/classes/${c.class_id}`);
          return detail.data;
        })
      );
      setClasses(classesWithSections);
    } catch { message.error('Failed to load classes'); }
    finally { setLoading(false); }
  }, [yearFilter]);

  const fetchSchoolYears = async () => {
    try {
      const res = await api.get('/admin/school-years');
      setSchoolYears(res.data);
    } catch { /* ignore */ }
  };

  useEffect(() => { fetchSchoolYears(); }, []);
  useEffect(() => { fetchClasses(); }, [fetchClasses]);

  // Class CRUD
  const openCreateClass = () => { setEditingClass(null); classForm.resetFields(); setClassModalOpen(true); };
  const openEditClass = (c: SchoolClass) => {
    setEditingClass(c);
    classForm.setFieldsValue({ name: c.name, schoolyearid: c.schoolyearid });
    setClassModalOpen(true);
  };

  const handleClassSubmit = async (values: { name: string; schoolyearid: number }) => {
    setClassLoading(true);
    try {
      if (editingClass) {
        await api.put(`/admin/classes/${editingClass.class_id}`, values);
        message.success('Class updated');
      } else {
        await api.post('/admin/classes', values);
        message.success('Class created');
      }
      setClassModalOpen(false); classForm.resetFields(); setEditingClass(null);
      fetchClasses();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to save class');
    } finally { setClassLoading(false); }
  };

  const handleDeleteClass = async (id: number) => {
    try { await api.delete(`/admin/classes/${id}`); message.success('Class deleted'); fetchClasses(); }
    catch { message.error('Failed to delete class'); }
  };

  // Section CRUD
  const openCreateSection = (classId: number) => {
    setEditingSection(null); setSectionClassId(classId);
    sectionForm.resetFields(); setSectionModalOpen(true);
  };
  const openEditSection = (section: Section) => {
    setEditingSection(section); setSectionClassId(section.class_id);
    sectionForm.setFieldsValue({ name: section.name });
    setSectionModalOpen(true);
  };

  const handleSectionSubmit = async (values: { name: string }) => {
    setSectionLoading(true);
    try {
      if (editingSection) {
        await api.put(`/admin/sections/${editingSection.section_id}`, values);
        message.success('Section updated');
      } else {
        await api.post('/admin/sections', { ...values, class_id: sectionClassId });
        message.success('Section created');
      }
      setSectionModalOpen(false); sectionForm.resetFields();
      setEditingSection(null); setSectionClassId(null);
      fetchClasses();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to save section');
    } finally { setSectionLoading(false); }
  };

  const handleDeleteSection = async (id: number) => {
    try { await api.delete(`/admin/sections/${id}`); message.success('Section deleted'); fetchClasses(); }
    catch { message.error('Failed to delete section'); }
  };

  const collapseItems = classes.map((c) => ({
    key: String(c.class_id),
    label: (
      <Row justify="space-between" align="middle" style={{ width: '100%' }}>
        <Col>
          <Space>
            <strong>{c.name}</strong>
            <Tag>{c.school_year?.name || '—'}</Tag>
            <Tag color="blue">{c.sections?.length || 0} sections</Tag>
          </Space>
        </Col>
        <Col>
          <Space onClick={(e) => e.stopPropagation()}>
            <Button size="small" icon={<EditOutlined />} onClick={() => openEditClass(c)} />
            <Button size="small" icon={<DeleteOutlined />} danger onClick={() => {
              Modal.confirm({ title: 'Delete this class?', okType: 'danger', onOk: () => handleDeleteClass(c.class_id) });
            }} />
            <Button size="small" type="primary" icon={<PlusOutlined />} onClick={() => openCreateSection(c.class_id)}>
              Add Section
            </Button>
          </Space>
        </Col>
      </Row>
    ),
    children: (
      <Table
        dataSource={c.sections || []}
        rowKey="section_id"
        pagination={false}
        size="small"
        columns={[
          { title: 'Section ID', dataIndex: 'section_id', width: 100 },
          { title: 'Name', dataIndex: 'name' },
          {
            title: 'Actions', width: 120,
            render: (_: unknown, s: Section) => (
              <Space>
                <Button size="small" icon={<EditOutlined />} onClick={() => openEditSection(s)} />
                <Button size="small" icon={<DeleteOutlined />} danger onClick={() => {
                  Modal.confirm({ title: 'Delete this section?', okType: 'danger', onOk: () => handleDeleteSection(s.section_id) });
                }} />
              </Space>
            ),
          },
        ]}
      />
    ),
  }));

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Classes & Sections</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreateClass}>Add Class</Button></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Select
          placeholder="Filter by school year"
          style={{ width: 250 }}
          allowClear
          value={yearFilter}
          onChange={(v) => setYearFilter(v)}
          options={schoolYears.map((y) => ({ value: y.schoolyearid, label: y.name }))}
        />
      </Card>

      <Card loading={loading}>
        {classes.length > 0 ? (
          <Collapse items={collapseItems} />
        ) : (
          <div style={{ textAlign: 'center', padding: 40, color: '#8c8c8c' }}>No classes found</div>
        )}
      </Card>

      {/* Class Modal */}
      <Modal
        title={editingClass ? 'Edit Class' : 'Add Class'}
        open={classModalOpen}
        onCancel={() => { setClassModalOpen(false); setEditingClass(null); }}
        footer={null} width={400}
      >
        <Form form={classForm} layout="vertical" onFinish={handleClassSubmit}>
          <Form.Item name="name" label="Class Name" rules={[{ required: true }]}>
            <Input placeholder="e.g. Grade 10" />
          </Form.Item>
          <Form.Item name="schoolyearid" label="School Year" rules={[{ required: true }]}>
            <Select options={schoolYears.map((y) => ({ value: y.schoolyearid, label: y.name }))} />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={classLoading} block>
              {editingClass ? 'Save Changes' : 'Create'}
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* Section Modal */}
      <Modal
        title={editingSection ? 'Edit Section' : 'Add Section'}
        open={sectionModalOpen}
        onCancel={() => { setSectionModalOpen(false); setEditingSection(null); }}
        footer={null} width={400}
      >
        <Form form={sectionForm} layout="vertical" onFinish={handleSectionSubmit}>
          <Form.Item name="name" label="Section Name" rules={[{ required: true }]}>
            <Input placeholder="e.g. Section A" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={sectionLoading} block>
              {editingSection ? 'Save Changes' : 'Create'}
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
