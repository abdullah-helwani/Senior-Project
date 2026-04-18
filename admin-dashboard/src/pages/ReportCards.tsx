import { useEffect, useState } from 'react';
import {
  Card, Typography, Row, Col, Button, Select, Form, Input, Space, Tabs,
  DatePicker, Modal, Descriptions, Table, Tag, Statistic, message,
} from 'antd';
import { FilePdfOutlined, EyeOutlined, UserOutlined, TeamOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs, { Dayjs } from 'dayjs';

const { Title, Paragraph } = Typography;
const { RangePicker } = DatePicker;

interface Student { id: number; user?: { name: string } }
interface Section { section_id: number; name: string; school_class?: { name: string } }

interface SubjectBlock {
  subject: string;
  assessments: { title: string; type: string; score: number; max_score: number; percentage: number }[];
  average: number;
  total_assessments: number;
}

interface PreviewData {
  student_id: number;
  name: string;
  email: string;
  section: string;
  class: string;
  school_year: string;
  term: string;
  overall_average: number | null;
  subjects: SubjectBlock[];
  attendance: {
    total_days: number; present: number; absent: number; late: number; excused: number; rate: number | null;
  };
  behavior: {
    positive: number; negative: number; neutral: number;
    notes: { type: string; title: string; date: string }[];
  };
}

async function downloadFile(url: string, params: Record<string, string | number>, filename: string) {
  try {
    const res = await api.get(url, { params, responseType: 'blob' });
    const blob = new Blob([res.data]);
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(link.href);
    message.success('Download started');
  } catch (err: unknown) {
    const e = err as { response?: { data?: { message?: string } } };
    message.error(e.response?.data?.message || 'Failed to download');
  }
}

function SingleStudentTab() {
  const [students, setStudents] = useState<Student[]>([]);
  const [studentId, setStudentId] = useState<number | undefined>();
  const [term, setTerm] = useState('');
  const [range, setRange] = useState<[Dayjs, Dayjs] | null>(null);
  const [downloading, setDownloading] = useState(false);

  const [previewOpen, setPreviewOpen] = useState(false);
  const [previewLoading, setPreviewLoading] = useState(false);
  const [preview, setPreview] = useState<PreviewData | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const res = await api.get('/admin/students', { params: { per_page: 500, status: 'active' } });
        setStudents(res.data.data || res.data);
      } catch { /* ignore */ }
    })();
  }, []);

  const validate = () => {
    if (!studentId) { message.warning('Select a student'); return false; }
    if (!term) { message.warning('Enter term'); return false; }
    if (!range) { message.warning('Select date range'); return false; }
    return true;
  };

  const buildParams = () => ({
    term, from: range![0].format('YYYY-MM-DD'), to: range![1].format('YYYY-MM-DD'),
  });

  const onPreview = async () => {
    if (!validate()) return;
    setPreviewLoading(true); setPreviewOpen(true);
    try {
      const res = await api.get(`/admin/report-cards/student/${studentId}/preview`, { params: buildParams() });
      setPreview(res.data);
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e.response?.data?.message || 'Failed to load preview');
      setPreviewOpen(false);
    } finally { setPreviewLoading(false); }
  };

  const onDownload = async () => {
    if (!validate()) return;
    setDownloading(true);
    const student = students.find((s) => s.id === studentId);
    const name = (student?.user?.name || `student_${studentId}`).replace(/\s+/g, '_');
    await downloadFile(`/admin/report-cards/student/${studentId}`, buildParams(),
      `report_card_${name}_${dayjs().format('YYYY-MM-DD')}.pdf`);
    setDownloading(false);
  };

  return (
    <>
      <Paragraph type="secondary">Preview a report card as JSON or download it as PDF.</Paragraph>
      <Form layout="vertical">
        <Row gutter={16}>
          <Col span={12}>
            <Form.Item label="Student" required>
              <Select placeholder="Select student" allowClear showSearch optionFilterProp="label"
                value={studentId} onChange={setStudentId}
                options={students.map((s) => ({ value: s.id, label: s.user?.name || `#${s.id}` }))}
              />
            </Form.Item>
          </Col>
          <Col span={12}>
            <Form.Item label="Term" required tooltip="e.g. Term 1, Fall 2025, etc.">
              <Input placeholder="e.g. Term 1" value={term} onChange={(e) => setTerm(e.target.value)} />
            </Form.Item>
          </Col>
        </Row>
        <Form.Item label="Date Range" required>
          <RangePicker value={range} onChange={(v) => setRange(v as [Dayjs, Dayjs] | null)} style={{ width: '100%' }} />
        </Form.Item>
        <Space>
          <Button icon={<EyeOutlined />} onClick={onPreview}>Preview JSON</Button>
          <Button type="primary" icon={<FilePdfOutlined />} loading={downloading} onClick={onDownload}>Download PDF</Button>
        </Space>
      </Form>

      <Modal title="Report Card Preview" open={previewOpen} onCancel={() => { setPreviewOpen(false); setPreview(null); }} footer={null} width={800}>
        {previewLoading ? <div>Loading...</div> : preview && (
          <>
            <Descriptions column={2} bordered size="small" style={{ marginBottom: 16 }}>
              <Descriptions.Item label="Student">{preview.name}</Descriptions.Item>
              <Descriptions.Item label="Email">{preview.email}</Descriptions.Item>
              <Descriptions.Item label="Class">{preview.class}</Descriptions.Item>
              <Descriptions.Item label="Section">{preview.section}</Descriptions.Item>
              <Descriptions.Item label="School Year">{preview.school_year}</Descriptions.Item>
              <Descriptions.Item label="Term">{preview.term}</Descriptions.Item>
              <Descriptions.Item label="Overall Average" span={2}>
                <strong style={{ color: (preview.overall_average ?? 0) >= 70 ? 'green' : (preview.overall_average ?? 0) >= 50 ? 'orange' : 'red' }}>
                  {preview.overall_average !== null ? `${preview.overall_average.toFixed(1)}%` : '—'}
                </strong>
              </Descriptions.Item>
            </Descriptions>

            <Row gutter={12} style={{ marginBottom: 16 }}>
              <Col span={4}><Card size="small"><Statistic title="Days" value={preview.attendance.total_days} /></Card></Col>
              <Col span={4}><Card size="small"><Statistic title="Present" value={preview.attendance.present} valueStyle={{ color: 'green' }} /></Card></Col>
              <Col span={4}><Card size="small"><Statistic title="Absent" value={preview.attendance.absent} valueStyle={{ color: 'red' }} /></Card></Col>
              <Col span={4}><Card size="small"><Statistic title="Late" value={preview.attendance.late} valueStyle={{ color: 'orange' }} /></Card></Col>
              <Col span={4}><Card size="small"><Statistic title="Excused" value={preview.attendance.excused} /></Card></Col>
              <Col span={4}><Card size="small"><Statistic title="Rate" value={preview.attendance.rate ?? 0} suffix="%" precision={1} /></Card></Col>
            </Row>

            <Title level={5}>Subjects</Title>
            {preview.subjects.map((sub) => (
              <Card key={sub.subject} size="small" style={{ marginBottom: 8 }}
                title={<Space><span>{sub.subject}</span><Tag color="blue">Avg: {sub.average.toFixed(1)}%</Tag></Space>}>
                <Table size="small" pagination={false} dataSource={sub.assessments} rowKey={(r) => `${sub.subject}-${r.title}`}
                  columns={[
                    { title: 'Assessment', dataIndex: 'title' },
                    { title: 'Type', dataIndex: 'type', width: 100, render: (t: string) => <Tag>{t}</Tag> },
                    { title: 'Score', key: 's', width: 120, render: (_: unknown, r) => `${r.score} / ${r.max_score}` },
                    {
                      title: '%', dataIndex: 'percentage', width: 90,
                      render: (p: number) => <strong style={{ color: p >= 70 ? 'green' : p >= 50 ? 'orange' : 'red' }}>{p.toFixed(1)}%</strong>,
                    },
                  ]}
                />
              </Card>
            ))}

            <Title level={5}>Behavior</Title>
            <Row gutter={12} style={{ marginBottom: 16 }}>
              <Col span={8}><Card size="small"><Statistic title="Positive" value={preview.behavior.positive} valueStyle={{ color: 'green' }} /></Card></Col>
              <Col span={8}><Card size="small"><Statistic title="Negative" value={preview.behavior.negative} valueStyle={{ color: 'red' }} /></Card></Col>
              <Col span={8}><Card size="small"><Statistic title="Neutral" value={preview.behavior.neutral} /></Card></Col>
            </Row>
            {preview.behavior.notes.length > 0 && (
              <Table size="small" dataSource={preview.behavior.notes} rowKey={(n, i) => `${n.date}-${i}`} pagination={false}
                columns={[
                  { title: 'Date', dataIndex: 'date', width: 120 },
                  { title: 'Title', dataIndex: 'title' },
                  {
                    title: 'Type', dataIndex: 'type', width: 100,
                    render: (t: string) => <Tag color={t === 'positive' ? 'green' : t === 'negative' ? 'red' : 'default'}>{t}</Tag>,
                  },
                ]}
              />
            )}
          </>
        )}
      </Modal>
    </>
  );
}

function SectionBulkTab() {
  const [sections, setSections] = useState<Section[]>([]);
  const [sectionId, setSectionId] = useState<number | undefined>();
  const [term, setTerm] = useState('');
  const [range, setRange] = useState<[Dayjs, Dayjs] | null>(null);
  const [downloading, setDownloading] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const res = await api.get('/admin/sections');
        setSections(res.data);
      } catch { /* ignore */ }
    })();
  }, []);

  const onDownload = async () => {
    if (!sectionId) { message.warning('Select a section'); return; }
    if (!term) { message.warning('Enter term'); return; }
    if (!range) { message.warning('Select date range'); return; }
    setDownloading(true);
    const section = sections.find((s) => s.section_id === sectionId);
    const name = (section?.name || `section_${sectionId}`).replace(/\s+/g, '_');
    await downloadFile(`/admin/report-cards/section/${sectionId}`,
      { term, from: range[0].format('YYYY-MM-DD'), to: range[1].format('YYYY-MM-DD') },
      `report_cards_${name}_${dayjs().format('YYYY-MM-DD')}.pdf`);
    setDownloading(false);
  };

  return (
    <>
      <Paragraph type="secondary">Generate a single PDF with one page per student in the section.</Paragraph>
      <Form layout="vertical">
        <Row gutter={16}>
          <Col span={12}>
            <Form.Item label="Section" required>
              <Select placeholder="Select section" allowClear showSearch optionFilterProp="label"
                value={sectionId} onChange={setSectionId}
                options={sections.map((s) => ({ value: s.section_id, label: `${s.school_class?.name || ''} — ${s.name}` }))}
              />
            </Form.Item>
          </Col>
          <Col span={12}>
            <Form.Item label="Term" required>
              <Input placeholder="e.g. Term 1" value={term} onChange={(e) => setTerm(e.target.value)} />
            </Form.Item>
          </Col>
        </Row>
        <Form.Item label="Date Range" required>
          <RangePicker value={range} onChange={(v) => setRange(v as [Dayjs, Dayjs] | null)} style={{ width: '100%' }} />
        </Form.Item>
        <Button type="primary" icon={<FilePdfOutlined />} loading={downloading} onClick={onDownload}>
          Generate Section Report Cards PDF
        </Button>
      </Form>
    </>
  );
}

export default function ReportCards() {
  return (
    <div>
      <Title level={4} style={{ marginBottom: 16 }}>Report Cards</Title>
      <Card>
        <Tabs
          items={[
            { key: 'single', label: <span><UserOutlined /> Single Student</span>, children: <SingleStudentTab /> },
            { key: 'section', label: <span><TeamOutlined /> Whole Section</span>, children: <SectionBulkTab /> },
          ]}
        />
      </Card>
    </div>
  );
}
