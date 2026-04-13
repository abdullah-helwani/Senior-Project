import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Select, Modal, Form, Input, InputNumber, message, Card,
  Typography, Row, Col, Space, Tag, Statistic, Descriptions,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, BarChartOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs from 'dayjs';

const { Title } = Typography;

const TYPES = ['exam', 'quiz', 'assignment', 'project', 'other'];

interface Assessment {
  assessment_id: number;
  subject_id: number;
  section_id: number;
  title: string;
  createdbyteacherid: number;
  assessmenttype: string;
  date: string;
  maxscore: number;
  subject?: { id: number; name: string };
  section?: { section_id: number; name: string; school_class?: { name: string } };
  results?: Result[];
}

interface Result {
  result_id: number;
  student_id: number;
  score: number;
  grade: string;
  student?: { id: number; user: { name: string } };
}

interface ResultsData {
  assessment: Assessment;
  results: Result[];
  summary: { total_students: number; average_score: number; highest_score: number; lowest_score: number; pass_rate: number };
}

interface Section { section_id: number; name: string; school_class?: { name: string } }
interface Subject { id: number; name: string }
interface Teacher { id: number; user: { name: string } }
interface Student { id: number; user: { name: string } }

export default function Assessments() {
  const [assessments, setAssessments] = useState<Assessment[]>([]);
  const [sections, setSections] = useState<Section[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [teachers, setTeachers] = useState<Teacher[]>([]);
  const [loading, setLoading] = useState(true);
  const [sectionFilter, setSectionFilter] = useState<number | undefined>();
  const [subjectFilter, setSubjectFilter] = useState<number | undefined>();
  const [typeFilter, setTypeFilter] = useState<string | undefined>();
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);

  // Create/Edit modal
  const [modalOpen, setModalOpen] = useState(false);
  const [modalLoading, setModalLoading] = useState(false);
  const [editing, setEditing] = useState<Assessment | null>(null);
  const [form] = Form.useForm();

  // Results modal
  const [resultsOpen, setResultsOpen] = useState(false);
  const [resultsData, setResultsData] = useState<ResultsData | null>(null);
  const [resultsLoading, setResultsLoading] = useState(false);

  // Enter marks modal
  const [marksOpen, setMarksOpen] = useState(false);
  const [marksLoading, setMarksLoading] = useState(false);
  const [marksAssessment, setMarksAssessment] = useState<Assessment | null>(null);
  const [enrolledStudents, setEnrolledStudents] = useState<Student[]>([]);
  const [marksForm] = Form.useForm();

  const fetchAssessments = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, string | number> = { page };
      if (sectionFilter) params.section_id = sectionFilter;
      if (subjectFilter) params.subject_id = subjectFilter;
      if (typeFilter) params.assessmenttype = typeFilter;
      const res = await api.get('/admin/assessments', { params });
      const d = res.data.data || res.data;
      setAssessments(Array.isArray(d) ? d : []);
      setTotal(res.data.total || (Array.isArray(d) ? d.length : 0));
    } catch { message.error('Failed to load assessments'); }
    finally { setLoading(false); }
  }, [sectionFilter, subjectFilter, typeFilter, page]);

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
  useEffect(() => { fetchAssessments(); }, [fetchAssessments]);

  // Create / Edit
  const openCreate = () => { setEditing(null); form.resetFields(); setModalOpen(true); };
  const openEdit = (a: Assessment) => {
    setEditing(a);
    form.setFieldsValue({
      title: a.title,
      subject_id: a.subject_id,
      section_id: a.section_id,
      createdbyteacherid: a.createdbyteacherid,
      assessmenttype: a.assessmenttype,
      date: a.date,
      maxscore: a.maxscore,
    });
    setModalOpen(true);
  };

  const handleSubmit = async (values: Record<string, unknown>) => {
    setModalLoading(true);
    try {
      if (editing) {
        await api.put(`/admin/assessments/${editing.assessment_id}`, values);
        message.success('Assessment updated');
      } else {
        await api.post('/admin/assessments', values);
        message.success('Assessment created');
      }
      setModalOpen(false); form.resetFields(); setEditing(null); fetchAssessments();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to save');
    } finally { setModalLoading(false); }
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/admin/assessments/${id}`);
      message.success('Assessment deleted'); fetchAssessments();
    } catch { message.error('Failed to delete'); }
  };

  // View results
  const openResults = async (id: number) => {
    setResultsLoading(true); setResultsOpen(true);
    try {
      const res = await api.get(`/admin/assessments/${id}/results`);
      setResultsData(res.data);
    } catch { message.error('Failed to load results'); setResultsOpen(false); }
    finally { setResultsLoading(false); }
  };

  // Enter marks
  const openMarks = async (assessment: Assessment) => {
    setMarksAssessment(assessment);
    setMarksLoading(true); setMarksOpen(true);
    try {
      const [studRes, existingRes] = await Promise.all([
        api.get('/admin/students', { params: { section_id: assessment.section_id, per_page: 200, status: 'active' } }),
        api.get(`/admin/assessments/${assessment.assessment_id}/results`),
      ]);
      const students = studRes.data.data || studRes.data;
      setEnrolledStudents(Array.isArray(students) ? students : []);

      // Pre-fill existing marks
      const existing = existingRes.data?.results || [];
      const initial: Record<string, number> = {};
      existing.forEach((r: Result) => { initial[`score_${r.student_id}`] = r.score; });
      marksForm.setFieldsValue(initial);
    } catch { message.error('Failed to load students'); setMarksOpen(false); }
    finally { setMarksLoading(false); }
  };

  const handleMarksSubmit = async () => {
    if (!marksAssessment) return;
    const values = marksForm.getFieldsValue();
    const results: { student_id: number; score: number }[] = [];
    enrolledStudents.forEach((s) => {
      const score = values[`score_${s.id}`];
      if (score !== undefined && score !== null && score !== '') {
        results.push({ student_id: s.id, score: Number(score) });
      }
    });
    if (results.length === 0) { message.warning('No marks entered'); return; }

    setMarksLoading(true);
    try {
      await api.post(`/admin/assessments/${marksAssessment.assessment_id}/results`, { results });
      message.success(`${results.length} marks saved`);
      setMarksOpen(false); marksForm.resetFields(); setMarksAssessment(null);
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      message.error(axiosErr.response?.data?.message || 'Failed to save marks');
    } finally { setMarksLoading(false); }
  };

  const typeColor = (t: string) => {
    const map: Record<string, string> = { exam: 'red', quiz: 'orange', assignment: 'blue', project: 'green', other: 'default' };
    return map[t] || 'default';
  };

  const columns = [
    { title: 'Title', dataIndex: 'title', key: 'title' },
    {
      title: 'Type', dataIndex: 'assessmenttype', key: 'type', width: 120,
      render: (t: string) => <Tag color={typeColor(t)}>{t.toUpperCase()}</Tag>,
    },
    {
      title: 'Subject', key: 'subject',
      render: (_: unknown, r: Assessment) => r.subject?.name || '—',
    },
    {
      title: 'Section', key: 'section',
      render: (_: unknown, r: Assessment) => `${r.section?.school_class?.name || ''} — ${r.section?.name || ''}`,
    },
    {
      title: 'Date', dataIndex: 'date', key: 'date', width: 110,
      render: (d: string) => d ? dayjs(d).format('YYYY-MM-DD') : '—',
    },
    { title: 'Max', dataIndex: 'maxscore', key: 'maxscore', width: 70 },
    {
      title: 'Actions', key: 'actions', width: 250,
      render: (_: unknown, r: Assessment) => (
        <Space>
          <Button size="small" icon={<BarChartOutlined />} onClick={() => openResults(r.assessment_id)}>Results</Button>
          <Button size="small" type="primary" onClick={() => openMarks(r)}>Marks</Button>
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(r)} />
          <Button size="small" icon={<DeleteOutlined />} danger onClick={() => {
            Modal.confirm({ title: 'Delete this assessment?', okType: 'danger', onOk: () => handleDelete(r.assessment_id) });
          }} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col><Title level={4} style={{ margin: 0 }}>Assessments & Marks</Title></Col>
        <Col><Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Create Assessment</Button></Col>
      </Row>

      <Card style={{ marginBottom: 16 }}>
        <Space wrap>
          <Select placeholder="Section" style={{ width: 250 }} allowClear showSearch optionFilterProp="label"
            value={sectionFilter} onChange={(v) => { setSectionFilter(v); setPage(1); }}
            options={sections.map((s) => ({ value: s.section_id, label: `${s.school_class?.name || ''} — ${s.name}` }))}
          />
          <Select placeholder="Subject" style={{ width: 200 }} allowClear showSearch optionFilterProp="label"
            value={subjectFilter} onChange={(v) => { setSubjectFilter(v); setPage(1); }}
            options={subjects.map((s) => ({ value: s.id, label: s.name }))}
          />
          <Select placeholder="Type" style={{ width: 150 }} allowClear
            value={typeFilter} onChange={(v) => { setTypeFilter(v); setPage(1); }}
            options={TYPES.map((t) => ({ value: t, label: t.charAt(0).toUpperCase() + t.slice(1) }))}
          />
        </Space>
      </Card>

      <Card>
        <Table
          dataSource={assessments} columns={columns} rowKey="assessment_id" loading={loading}
          pagination={{ current: page, total, pageSize: 15, onChange: setPage, showTotal: (t) => `${t} assessments` }}
          size="small"
        />
      </Card>

      {/* Create/Edit Modal */}
      <Modal title={editing ? 'Edit Assessment' : 'Create Assessment'} open={modalOpen} onCancel={() => { setModalOpen(false); setEditing(null); }} footer={null} width={500}>
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          <Form.Item name="title" label="Title" rules={[{ required: true }]}>
            <Input placeholder="e.g. Midterm Exam" />
          </Form.Item>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="assessmenttype" label="Type" rules={[{ required: true }]}>
                <Select options={TYPES.map((t) => ({ value: t, label: t.charAt(0).toUpperCase() + t.slice(1) }))} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="date" label="Date" rules={[{ required: true }]}>
                <Input type="date" />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="subject_id" label="Subject" rules={[{ required: true }]}>
                <Select showSearch optionFilterProp="label" options={subjects.map((s) => ({ value: s.id, label: s.name }))} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="section_id" label="Section" rules={[{ required: true }]}>
                <Select showSearch optionFilterProp="label" options={sections.map((s) => ({ value: s.section_id, label: `${s.school_class?.name || ''} — ${s.name}` }))} />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="createdbyteacherid" label="Teacher" rules={[{ required: true }]}>
                <Select showSearch optionFilterProp="label" options={teachers.map((t) => ({ value: t.id, label: t.user?.name || `Teacher #${t.id}` }))} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="maxscore" label="Max Score" rules={[{ required: true }]}>
                <InputNumber min={1} style={{ width: '100%' }} placeholder="e.g. 100" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={modalLoading} block>
              {editing ? 'Save Changes' : 'Create'}
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      {/* Results Modal */}
      <Modal title="Assessment Results" open={resultsOpen} onCancel={() => { setResultsOpen(false); setResultsData(null); }} footer={null} width={700}>
        {resultsLoading ? <div>Loading...</div> : resultsData && (
          <>
            <Descriptions column={2} size="small" bordered style={{ marginBottom: 16 }}>
              <Descriptions.Item label="Title">{resultsData.assessment.title}</Descriptions.Item>
              <Descriptions.Item label="Type"><Tag color={typeColor(resultsData.assessment.assessmenttype)}>{resultsData.assessment.assessmenttype}</Tag></Descriptions.Item>
              <Descriptions.Item label="Max Score">{resultsData.assessment.maxscore}</Descriptions.Item>
              <Descriptions.Item label="Date">{resultsData.assessment.date ? dayjs(resultsData.assessment.date).format('YYYY-MM-DD') : '—'}</Descriptions.Item>
            </Descriptions>

            <Row gutter={16} style={{ marginBottom: 16 }}>
              <Col span={6}><Card size="small"><Statistic title="Students" value={resultsData.summary.total_students} /></Card></Col>
              <Col span={6}><Card size="small"><Statistic title="Average" value={resultsData.summary.average_score} precision={1} /></Card></Col>
              <Col span={6}><Card size="small"><Statistic title="Highest" value={resultsData.summary.highest_score} /></Card></Col>
              <Col span={6}><Card size="small"><Statistic title="Pass Rate" value={resultsData.summary.pass_rate} suffix="%" /></Card></Col>
            </Row>

            <Table
              dataSource={resultsData.results} rowKey="result_id" pagination={false} size="small"
              columns={[
                { title: 'Student', key: 'student', render: (_: unknown, r: Result) => r.student?.user?.name || '—' },
                { title: 'Score', dataIndex: 'score', width: 80 },
                { title: 'Grade', dataIndex: 'grade', width: 80, render: (g: string) => <Tag>{g}</Tag> },
                {
                  title: '%', key: 'pct', width: 80,
                  render: (_: unknown, r: Result) => resultsData.assessment.maxscore
                    ? `${((r.score / resultsData.assessment.maxscore) * 100).toFixed(1)}%`
                    : '—',
                },
              ]}
            />
          </>
        )}
      </Modal>

      {/* Enter Marks Modal */}
      <Modal
        title={`Enter Marks — ${marksAssessment?.title || ''} (Max: ${marksAssessment?.maxscore || 0})`}
        open={marksOpen}
        onCancel={() => { setMarksOpen(false); marksForm.resetFields(); setMarksAssessment(null); }}
        onOk={handleMarksSubmit}
        okText="Save Marks"
        confirmLoading={marksLoading}
        width={500}
      >
        {marksLoading && !enrolledStudents.length ? <div>Loading students...</div> : (
          <Form form={marksForm} layout="vertical">
            {enrolledStudents.length === 0 ? (
              <div style={{ color: '#8c8c8c', textAlign: 'center', padding: 20 }}>No enrolled students found for this section</div>
            ) : (
              enrolledStudents.map((s) => (
                <Form.Item
                  key={s.id}
                  name={`score_${s.id}`}
                  label={s.user?.name || `Student #${s.id}`}
                  style={{ marginBottom: 8 }}
                >
                  <InputNumber min={0} max={marksAssessment?.maxscore || 100} style={{ width: '100%' }} placeholder="Score" />
                </Form.Item>
              ))
            )}
          </Form>
        )}
      </Modal>
    </div>
  );
}
