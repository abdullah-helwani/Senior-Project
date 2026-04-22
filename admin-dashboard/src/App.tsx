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
          colorPrimary: '#4f46e5',
          colorInfo: '#4f46e5',
          colorSuccess: '#16a34a',
          colorWarning: '#f59e0b',
          colorError: '#dc2626',
          borderRadius: 8,
          fontFamily:
            "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
          fontSize: 14,
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
            darkItemSelectedBg: '#4f46e5',
            darkItemHoverBg: 'rgba(255,255,255,0.06)',
            itemHeight: 42,
            itemBorderRadius: 6,
          },
          Card: {
            borderRadiusLG: 12,
            boxShadowTertiary:
              '0 1px 2px 0 rgba(15,23,42,0.04), 0 1px 6px -1px rgba(15,23,42,0.02)',
          },
          Button: { controlHeight: 36, fontWeight: 500 },
          Table: { headerBg: '#fafbfc', headerColor: '#475569', rowHoverBg: '#f5f7fb' },
          Tag: { borderRadiusSM: 4 },
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
