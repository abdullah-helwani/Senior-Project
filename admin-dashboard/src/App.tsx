import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import Students from './pages/Students';
import Teachers from './pages/Teachers';
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
      </Route>
    </Routes>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <AppRoutes />
      </AuthProvider>
    </BrowserRouter>
  );
}
