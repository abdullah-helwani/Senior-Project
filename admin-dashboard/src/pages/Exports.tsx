import { useEffect, useState } from 'react';
import {
  Card, Typography, Row, Col, Button, Select, Form, Space, Tabs, DatePicker, message,
} from 'antd';
import { DownloadOutlined, FilePdfOutlined, FileExcelOutlined } from '@ant-design/icons';
import api from '../api/axios';
import dayjs, { Dayjs } from 'dayjs';

const { Title, Paragraph } = Typography;
const { RangePicker } = DatePicker;

interface Section { section_id: number; name: string; school_class?: { name: string } }
interface Subject { id: number; name: string }
interface Student { id: number; user?: { name: string } }

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
  } catch {
    message.error('Failed to download');
  }
}

function MarksExportTab() {
  const [sections, setSections] = useState<Section[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [students, setStudents] = useState<Student[]>([]);
  const [sectionId, setSectionId] = useState<number | undefined>();
  const [subjectId, setSubjectId] = useState<number | undefined>();
  const [studentId, setStudentId] = useState<number | undefined>();
  const [range, setRange] = useState<[Dayjs, Dayjs] | null>(null);
  const [downloading, setDownloading] = useState<'csv' | 'pdf' | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const [sec, sub, stu] = await Promise.all([
          api.get('/admin/sections'),
          api.get('/admin/subjects'),
          api.get('/admin/students', { params: { per_page: 500, status: 'active' } }),
        ]);
        setSections(sec.data);
        setSubjects(sub.data);
        setStudents(stu.data.data || stu.data);
      } catch { /* ignore */ }
    })();
  }, []);

  const buildParams = () => {
    const params: Record<string, string | number> = {};
    if (sectionId) params.section_id = sectionId;
    if (subjectId) params.subject_id = subjectId;
    if (studentId) params.student_id = studentId;
    if (range) { params.from = range[0].format('YYYY-MM-DD'); params.to = range[1].format('YYYY-MM-DD'); }
    return params;
  };

  const onExport = async (format: 'csv' | 'pdf') => {
    setDownloading(format);
    const today = dayjs().format('YYYY-MM-DD');
    const filename = format === 'csv' ? `marks_export_${today}.csv` : `marks_report_${today}.pdf`;
    await downloadFile(`/admin/export/marks/${format}`, buildParams(), filename);
    setDownloading(null);
  };

  return (
    <>
      <Paragraph type="secondary">Export assessment results with filters. Leave filters blank to export all records.</Paragraph>
      <Form layout="vertical">
        <Row gutter={16}>
          <Col span={8}>
            <Form.Item label="Section">
              <Select placeholder="All sections" allowClear showSearch optionFilterProp="label"
                value={sectionId} onChange={setSectionId}
                options={sections.map((s) => ({ value: s.section_id, label: `${s.school_class?.name || ''} — ${s.name}` }))}
              />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item label="Subject">
              <Select placeholder="All subjects" allowClear showSearch optionFilterProp="label"
                value={subjectId} onChange={setSubjectId}
                options={subjects.map((s) => ({ value: s.id, label: s.name }))}
              />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item label="Student">
              <Select placeholder="All students" allowClear showSearch optionFilterProp="label"
                value={studentId} onChange={setStudentId}
                options={students.map((s) => ({ value: s.id, label: s.user?.name || `#${s.id}` }))}
              />
            </Form.Item>
          </Col>
        </Row>
        <Row gutter={16}>
          <Col span={12}>
            <Form.Item label="Date Range">
              <RangePicker value={range} onChange={(v) => setRange(v as [Dayjs, Dayjs] | null)} style={{ width: '100%' }} />
            </Form.Item>
          </Col>
        </Row>
        <Space>
          <Button type="primary" icon={<FileExcelOutlined />} loading={downloading === 'csv'} onClick={() => onExport('csv')}>
            Export as CSV
          </Button>
          <Button icon={<FilePdfOutlined />} loading={downloading === 'pdf'} onClick={() => onExport('pdf')}>
            Export as PDF
          </Button>
        </Space>
      </Form>
    </>
  );
}

function AttendanceExportTab() {
  const [sections, setSections] = useState<Section[]>([]);
  const [students, setStudents] = useState<Student[]>([]);
  const [sectionId, setSectionId] = useState<number | undefined>();
  const [studentId, setStudentId] = useState<number | undefined>();
  const [range, setRange] = useState<[Dayjs, Dayjs]>([dayjs().subtract(30, 'day'), dayjs()]);
  const [downloading, setDownloading] = useState<'csv' | 'pdf' | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const [sec, stu] = await Promise.all([
          api.get('/admin/sections'),
          api.get('/admin/students', { params: { per_page: 500, status: 'active' } }),
        ]);
        setSections(sec.data);
        setStudents(stu.data.data || stu.data);
      } catch { /* ignore */ }
    })();
  }, []);

  const onExport = async (format: 'csv' | 'pdf') => {
    if (!range) { message.warning('Date range is required'); return; }
    setDownloading(format);
    const params: Record<string, string | number> = {
      from: range[0].format('YYYY-MM-DD'),
      to: range[1].format('YYYY-MM-DD'),
    };
    if (sectionId) params.section_id = sectionId;
    if (studentId) params.student_id = studentId;
    const today = dayjs().format('YYYY-MM-DD');
    const filename = format === 'csv' ? `attendance_export_${today}.csv` : `attendance_report_${today}.pdf`;
    await downloadFile(`/admin/export/attendance/${format}`, params, filename);
    setDownloading(null);
  };

  return (
    <>
      <Paragraph type="secondary">Export attendance records. Date range is required.</Paragraph>
      <Form layout="vertical">
        <Row gutter={16}>
          <Col span={12}>
            <Form.Item label="Section">
              <Select placeholder="All sections" allowClear showSearch optionFilterProp="label"
                value={sectionId} onChange={setSectionId}
                options={sections.map((s) => ({ value: s.section_id, label: `${s.school_class?.name || ''} — ${s.name}` }))}
              />
            </Form.Item>
          </Col>
          <Col span={12}>
            <Form.Item label="Student">
              <Select placeholder="All students" allowClear showSearch optionFilterProp="label"
                value={studentId} onChange={setStudentId}
                options={students.map((s) => ({ value: s.id, label: s.user?.name || `#${s.id}` }))}
              />
            </Form.Item>
          </Col>
        </Row>
        <Form.Item label="Date Range" required>
          <RangePicker value={range} onChange={(v) => v && setRange(v as [Dayjs, Dayjs])} style={{ width: '100%' }} />
        </Form.Item>
        <Space>
          <Button type="primary" icon={<FileExcelOutlined />} loading={downloading === 'csv'} onClick={() => onExport('csv')}>
            Export as CSV
          </Button>
          <Button icon={<FilePdfOutlined />} loading={downloading === 'pdf'} onClick={() => onExport('pdf')}>
            Export as PDF
          </Button>
        </Space>
      </Form>
    </>
  );
}

export default function Exports() {
  return (
    <div>
      <Title level={4} style={{ marginBottom: 16 }}>
        <DownloadOutlined /> Exports
      </Title>
      <Card>
        <Tabs
          items={[
            { key: 'marks', label: 'Marks', children: <MarksExportTab /> },
            { key: 'attendance', label: 'Attendance', children: <AttendanceExportTab /> },
          ]}
        />
      </Card>
    </div>
  );
}
