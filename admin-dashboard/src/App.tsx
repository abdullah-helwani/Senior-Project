import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ConfigProvider, theme as antdTheme } from 'antd';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import Students from './pages/Students';
import Teachers from './pages/Teachers';
import Parents from './pages/Parents';
import SchoolYears from './pages/SchoolYears';
import Classes from './pages/Classes';
import Subjects from './pages/Subjects';
import Schedules from './pages/Schedules';
import Assessments from './pages/Assessments';
import Attendance from './pages/Attendance';
import BehaviorLogs from './pages/BehaviorLogs';
import Complaints from './pages/Complaints';
import Notifications from './pages/Notifications';
import VacationRequests from './pages/VacationRequests';
import FeePlans from './pages/FeePlans';
import StudentFeePlans from './pages/StudentFeePlans';
import Invoices from './pages/Invoices';
import Payments from './pages/Payments';
import SalaryPayments from './pages/SalaryPayments';
import BusManagement from './pages/BusManagement';
import Cameras from './pages/Cameras';
import SurveillanceEvents from './pages/SurveillanceEvents';
import AnalyticsReports from './pages/AnalyticsReports';
import Exports from './pages/Exports';
import ReportCards from './pages/ReportCards';
import AuditLogs from './pages/AuditLogs';
import TeacherAvailability from './pages/TeacherAvailability';

function AppRoutes() {
  const { isAuthenticated } = useAuth();

  return (
    <Routes>
      <Route
        path="/login"
        element={isAuthenticated ? <Navigate to="/" replace /> : <Login />}
      />
      <Route
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route path="/" element={<Dashboard />} />
        <Route path="/users" element={<Users />} />
        <Route path="/students" element={<Students />} />
        <Route path="/teachers" element={<Teachers />} />
        <Route path="/parents" element={<Parents />} />
        <Route path="/school-years" element={<SchoolYears />} />
        <Route path="/classes" element={<Classes />} />
        <Route path="/subjects" element={<Subjects />} />
        <Route path="/schedules" element={<Schedules />} />
        <Route path="/assessments" element={<Assessments />} />
        <Route path="/attendance" element={<Attendance />} />
        <Route path="/behavior-logs" element={<BehaviorLogs />} />
        <Route path="/complaints" element={<Complaints />} />
        <Route path="/notifications" element={<Notifications />} />
        <Route path="/vacation-requests" element={<VacationRequests />} />
        <Route path="/fee-plans" element={<FeePlans />} />
        <Route path="/student-fee-plans" element={<StudentFeePlans />} />
        <Route path="/invoices" element={<Invoices />} />
        <Route path="/payments" element={<Payments />} />
        <Route path="/salary-payments" element={<SalaryPayments />} />
        <Route path="/bus-management" element={<BusManagement />} />
        <Route path="/cameras" element={<Cameras />} />
        <Route path="/surveillance-events" element={<SurveillanceEvents />} />
        <Route path="/analytics" element={<AnalyticsReports />} />
        <Route path="/exports" element={<Exports />} />
        <Route path="/report-cards" element={<ReportCards />} />
        <Route path="/audit-logs" element={<AuditLogs />} />
        <Route path="/teacher-availability" element={<TeacherAvailability />} />
      </Route>
    </Routes>
  );
}

export default function App() {
  return (
    <ConfigProvider
      theme={{
        algorithm: antdTheme.defaultAlgorithm,
        token: {
          /* ── Polaris brand colors ── */
          colorPrimary: '#4f46e5',
          colorInfo: '#0ea5e9',
          colorSuccess: '#16a34a',
          colorWarning: '#f59e0b',
          colorError: '#dc2626',
          /* ── Typography ── */
          fontFamily:
            "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
          fontSize: 14,
          /* ── Shape ── */
          borderRadius: 8,
          borderRadiusLG: 12,
          borderRadiusSM: 6,
          borderRadiusXS: 4,
          /* ── Surfaces ── */
          colorBgContainer: '#ffffff',
          colorBgLayout: '#f5f7fb',
          colorBgElevated: '#ffffff',
          colorBorder: '#e3e3ec',
          colorBorderSecondary: '#eef0f4',
          /* ── Text ── */
          colorText: '#0f172a',
          colorTextSecondary: '#475569',
          colorTextTertiary: '#64748b',
          colorTextQuaternary: '#94a3b8',
          /* ── Shadows ── */
          boxShadow: '0 2px 8px rgba(19,26,51,.06), 0 1px 2px rgba(19,26,51,.03)',
          boxShadowSecondary: '0 8px 24px rgba(19,26,51,.10), 0 2px 6px rgba(19,26,51,.05)',
          /* ── Motion ── */
          motionDurationFast: '120ms',
          motionDurationMid: '200ms',
          motionDurationSlow: '320ms',
          wireframe: false,
        },
        components: {
          Layout: {
            siderBg: '#0f172a',
            headerBg: '#ffffff',
            headerHeight: 64,
            bodyBg: '#f5f7fb',
          },
          Menu: {
            darkItemBg: '#0f172a',
            darkSubMenuItemBg: '#0b1324',
            darkItemSelectedBg: 'rgba(99,102,241,0.18)',
            darkItemSelectedColor: '#ffffff',
            darkItemHoverBg: 'rgba(255,255,255,0.05)',
            darkItemColor: '#cbd5e1',
            itemHeight: 42,
            itemBorderRadius: 6,
          },
          Card: {
            borderRadiusLG: 12,
            boxShadowTertiary:
              '0 2px 8px rgba(19,26,51,.06), 0 1px 2px rgba(19,26,51,.03)',
          },
          Button: {
            controlHeight: 36,
            fontWeight: 500,
            borderRadius: 8,
            primaryShadow: '0 4px 12px rgba(79,70,229,.25)',
          },
          Table: {
            headerBg: '#f7f7fb',
            headerColor: '#475569',
            headerSortHoverBg: '#eef0f4',
            rowHoverBg: '#f7f7fb',
            borderColor: '#eef0f4',
          },
          Tag: { borderRadiusSM: 4 },
          Input: { borderRadius: 8, controlHeight: 36 },
          Select: { borderRadius: 8, controlHeight: 36 },
          DatePicker: { borderRadius: 8, controlHeight: 36 },
          Modal: { borderRadiusLG: 16 },
          Breadcrumb: { fontSize: 13, separatorColor: '#94a3b8' },
          Statistic: { titleFontSize: 13 },
        },
      }}
    >
      <BrowserRouter>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </BrowserRouter>
    </ConfigProvider>
  );
}
