import { useMemo, useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import {
  Layout as AntLayout,
  Menu,
  Button,
  Avatar,
  Dropdown,
  Breadcrumb,
  Typography,
  Tag,
  theme,
} from 'antd';
import type { MenuProps } from 'antd';
import {
  DashboardOutlined,
  UserOutlined,
  TeamOutlined,
  BookOutlined,
  CalendarOutlined,
  ScheduleOutlined,
  FileTextOutlined,
  CheckCircleOutlined,
  DollarOutlined,
  MessageOutlined,
  AuditOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  LogoutOutlined,
  ProfileOutlined,
  BellOutlined,
  CoffeeOutlined,
  CarOutlined,
  VideoCameraOutlined,
  AlertOutlined,
  BarChartOutlined,
  DownloadOutlined,
  IdcardOutlined,
  ClockCircleOutlined,
  ApartmentOutlined,
  FireOutlined,
  SettingOutlined,
  SafetyOutlined,
} from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';

const { Sider, Header, Content } = AntLayout;
const { Text } = Typography;

type MenuItem = Required<MenuProps>['items'][number];

const menuItems: MenuItem[] = [
  { key: '/', icon: <DashboardOutlined />, label: 'Dashboard' },

  {
    key: 'people',
    icon: <TeamOutlined />,
    label: 'People',
    children: [
      { key: '/users', icon: <UserOutlined />, label: 'Users' },
      { key: '/students', icon: <TeamOutlined />, label: 'Students' },
      { key: '/teachers', icon: <ProfileOutlined />, label: 'Teachers' },
      { key: '/parents', icon: <TeamOutlined />, label: 'Parents' },
    ],
  },

  {
    key: 'academics',
    icon: <BookOutlined />,
    label: 'Academics',
    children: [
      { key: '/school-years', icon: <CalendarOutlined />, label: 'School Years' },
      { key: '/classes', icon: <ApartmentOutlined />, label: 'Classes & Sections' },
      { key: '/subjects', icon: <FileTextOutlined />, label: 'Subjects' },
      { key: '/schedules', icon: <ScheduleOutlined />, label: 'Schedules' },
      { key: '/assessments', icon: <FileTextOutlined />, label: 'Assessments' },
    ],
  },

  {
    key: 'operations',
    icon: <CheckCircleOutlined />,
    label: 'Daily Operations',
    children: [
      { key: '/attendance', icon: <CheckCircleOutlined />, label: 'Attendance' },
      { key: '/behavior-logs', icon: <FireOutlined />, label: 'Behavior Logs' },
      { key: '/complaints', icon: <MessageOutlined />, label: 'Complaints' },
      { key: '/notifications', icon: <BellOutlined />, label: 'Notifications' },
      { key: '/vacation-requests', icon: <CoffeeOutlined />, label: 'Vacation Requests' },
    ],
  },

  {
    key: 'finance',
    icon: <DollarOutlined />,
    label: 'Finance',
    children: [
      { key: '/fee-plans', icon: <FileTextOutlined />, label: 'Fee Plans' },
      { key: '/student-fee-plans', icon: <IdcardOutlined />, label: 'Student Fee Plans' },
      { key: '/invoices', icon: <FileTextOutlined />, label: 'Invoices' },
      { key: '/payments', icon: <DollarOutlined />, label: 'Payments' },
      { key: '/salary-payments', icon: <DollarOutlined />, label: 'Salary Payments' },
    ],
  },

  {
    key: 'transport',
    icon: <CarOutlined />,
    label: 'Transport & Safety',
    children: [
      { key: '/bus-management', icon: <CarOutlined />, label: 'Bus Management' },
      { key: '/cameras', icon: <VideoCameraOutlined />, label: 'Cameras' },
      { key: '/surveillance-events', icon: <AlertOutlined />, label: 'Surveillance Events' },
    ],
  },

  {
    key: 'reports',
    icon: <BarChartOutlined />,
    label: 'Reports & Logs',
    children: [
      { key: '/analytics', icon: <BarChartOutlined />, label: 'Analytics Reports' },
      { key: '/exports', icon: <DownloadOutlined />, label: 'Exports' },
      { key: '/report-cards', icon: <FileTextOutlined />, label: 'Report Cards' },
      { key: '/audit-logs', icon: <AuditOutlined />, label: 'Audit Logs' },
      { key: '/teacher-availability', icon: <ClockCircleOutlined />, label: 'Teacher Availability' },
    ],
  },
];

// Flatten for title/breadcrumb/group lookup
interface FlatEntry {
  key: string;
  label: string;
  group?: string;
  groupKey?: string;
}
function flatten(items: MenuItem[]): FlatEntry[] {
  const out: FlatEntry[] = [];
  items.forEach((item) => {
    if (!item) return;
    const anyItem = item as { key: string; label?: string; children?: MenuItem[] };
    if (anyItem.children) {
      anyItem.children.forEach((c) => {
        if (!c) return;
        const cx = c as { key: string; label?: string };
        out.push({
          key: cx.key,
          label: String(cx.label ?? ''),
          group: String(anyItem.label ?? ''),
          groupKey: anyItem.key,
        });
      });
    } else {
      out.push({ key: anyItem.key, label: String(anyItem.label ?? '') });
    }
  });
  return out;
}
const flatMenu = flatten(menuItems);

export default function Layout() {
  const [collapsed, setCollapsed] = useState(false);
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const { token: themeToken } = theme.useToken();

  const current = useMemo(
    () =>
      flatMenu.find((m) =>
        m.key === '/' ? location.pathname === '/' : location.pathname.startsWith(m.key),
      ),
    [location.pathname],
  );
  const selectedKey = current?.key || '/';
  const openKey = current?.groupKey;

  const [openKeys, setOpenKeys] = useState<string[]>(openKey ? [String(openKey)] : []);

  const roleTag = (() => {
    const role = (user?.role_type || 'admin').toString();
    const color = role === 'admin' ? 'magenta' : role === 'teacher' ? 'blue' : 'default';
    return <Tag color={color} style={{ textTransform: 'capitalize', marginRight: 0 }}>{role}</Tag>;
  })();

  return (
    <AntLayout style={{ minHeight: '100vh' }}>
      <Sider
        trigger={null}
        collapsible
        collapsed={collapsed}
        width={248}
        style={{
          overflow: 'auto',
          height: '100vh',
          position: 'fixed',
          left: 0,
          top: 0,
          bottom: 0,
          boxShadow: '2px 0 8px rgba(15,23,42,0.06)',
        }}
      >
        {/* Brand */}
        <div
          style={{
            height: 64,
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            padding: collapsed ? '0 24px' : '0 20px',
            borderBottom: '1px solid rgba(255,255,255,0.06)',
          }}
        >
          <div
            style={{
              width: 34,
              height: 34,
              borderRadius: 8,
              background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
              boxShadow: '0 4px 12px rgba(99,102,241,0.35)',
            }}
          >
            <SafetyOutlined style={{ color: '#fff', fontSize: 18 }} />
          </div>
          {!collapsed && (
            <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.1 }}>
              <span style={{ color: '#fff', fontSize: 15, fontWeight: 600 }}>School Admin</span>
              <span style={{ color: 'rgba(255,255,255,0.45)', fontSize: 11 }}>Control Center</span>
            </div>
          )}
        </div>

        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[selectedKey]}
          openKeys={openKeys}
          onOpenChange={(keys) => setOpenKeys(keys as string[])}
          items={menuItems}
          onClick={({ key }) => navigate(String(key))}
          style={{ borderRight: 0, padding: '8px 10px' }}
        />

        {!collapsed && (
          <div
            style={{
              position: 'absolute',
              bottom: 12,
              left: 12,
              right: 12,
              padding: 12,
              borderRadius: 10,
              background: 'rgba(255,255,255,0.04)',
              border: '1px solid rgba(255,255,255,0.06)',
              color: 'rgba(255,255,255,0.75)',
              fontSize: 12,
              lineHeight: 1.5,
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
              <SettingOutlined />
              <span style={{ fontWeight: 600 }}>Admin Build</span>
            </div>
            <div style={{ color: 'rgba(255,255,255,0.45)' }}>v1.0 · School Management Suite</div>
          </div>
        )}
      </Sider>

      <AntLayout
        style={{
          marginLeft: collapsed ? 80 : 248,
          transition: 'margin-left 0.2s',
        }}
      >
        <Header
          style={{
            padding: '0 24px',
            background: themeToken.colorBgContainer,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            borderBottom: '1px solid #eef0f4',
            position: 'sticky',
            top: 0,
            zIndex: 10,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <Button
              type="text"
              icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
              onClick={() => setCollapsed(!collapsed)}
            />
            <Breadcrumb
              items={[
                { title: 'Home' },
                ...(current?.group ? [{ title: current.group }] : []),
                { title: <Text strong>{current?.label ?? 'Dashboard'}</Text> },
              ]}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <Button type="text" shape="circle" icon={<BellOutlined />} />
            <Dropdown
              menu={{
                items: [
                  { key: 'logout', icon: <LogoutOutlined />, label: 'Logout', danger: true },
                ],
                onClick: ({ key }) => {
                  if (key === 'logout') logout();
                },
              }}
            >
              <div
                style={{
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 10,
                  padding: '4px 10px 4px 4px',
                  borderRadius: 999,
                  transition: 'background 0.2s',
                }}
              >
                <Avatar
                  style={{
                    background: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
                    verticalAlign: 'middle',
                  }}
                  icon={<UserOutlined />}
                />
                <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.15 }}>
                  <span style={{ fontWeight: 600, fontSize: 13 }}>{user?.name ?? 'Admin'}</span>
                  <span style={{ fontSize: 11, color: '#64748b' }}>{user?.email}</span>
                </div>
                {roleTag}
              </div>
            </Dropdown>
          </div>
        </Header>

        <Content style={{ margin: 24, minHeight: 280 }}>
          <Outlet />
        </Content>
      </AntLayout>
    </AntLayout>
  );
}
