import { useState, useEffect, useRef, useCallback } from 'react';
import {
  Badge, Button, List, Typography, notification as antNotification,
} from 'antd';
import { BellOutlined, AlertOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import api from '../api/axios';

const { Text } = Typography;

interface AlertItem {
  recipient_id: number;
  notification_id: number;
  title: string;
  body: string;
  created_at: string;
  status: 'unread' | 'read';
}

const POLL_INTERVAL = 20_000;

export default function NotificationBell() {
  const [alerts, setAlerts] = useState<AlertItem[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [open, setOpen] = useState(false);
  const lastCountRef = useRef<number>(-1);
  const navigate = useNavigate();
  const [notifApi, contextHolder] = antNotification.useNotification();

  const fetchAlerts = useCallback(async () => {
    try {
      const res = await api.get('/admin/notifications/alerts');
      const { unread_count, items } = res.data as { unread_count: number; items: AlertItem[] };

      if (lastCountRef.current !== -1 && unread_count > lastCountRef.current) {
        const newItems: AlertItem[] = items.slice(0, unread_count - lastCountRef.current);
        newItems.forEach((item) => {
          notifApi.warning({
            message: item.title,
            description: item.body,
            duration: 10,
            placement: 'topRight',
            icon: <AlertOutlined style={{ color: '#ff4d4f' }} />,
            onClick: () => navigate('/surveillance-events'),
            style: { cursor: 'pointer' },
          });
        });
      }

      lastCountRef.current = unread_count;
      setUnreadCount(unread_count);
      setAlerts(items);
    } catch {
      // silent — don't disrupt the UI if polling fails
    }
  }, [navigate, notifApi]);

  useEffect(() => {
    fetchAlerts();
    const id = setInterval(fetchAlerts, POLL_INTERVAL);
    return () => clearInterval(id);
  }, [fetchAlerts]);

  const markAllRead = async () => {
    try {
      await api.put('/admin/notifications/alerts/read-all');
      setUnreadCount(0);
      setAlerts((prev) => prev.map((a) => ({ ...a, status: 'read' as const })));
      lastCountRef.current = 0;
    } catch {/* silent */}
  };

  const formatTime = (iso: string) => {
    const d = new Date(iso);
    const now = new Date();
    const diffMs = now.getTime() - d.getTime();
    const diffMin = Math.floor(diffMs / 60000);
    if (diffMin < 1) return 'just now';
    if (diffMin < 60) return `${diffMin}m ago`;
    const diffH = Math.floor(diffMin / 60);
    if (diffH < 24) return `${diffH}h ago`;
    return d.toLocaleDateString();
  };

  const dropdownContent = (
    <div
      style={{
        width: 340,
        background: '#fff',
        borderRadius: 8,
        boxShadow: '0 6px 24px rgba(0,0,0,0.12)',
        overflow: 'hidden',
      }}
    >
      {/* Header */}
      <div
        style={{
          padding: '12px 16px',
          borderBottom: '1px solid #f0f0f0',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <Text strong style={{ fontSize: 14 }}>
          Fight Alerts
          {unreadCount > 0 && (
            <Badge
              count={unreadCount}
              size="small"
              style={{ marginLeft: 8, backgroundColor: '#ff4d4f' }}
            />
          )}
        </Text>
        {unreadCount > 0 && (
          <Button type="link" size="small" onClick={markAllRead} style={{ padding: 0 }}>
            Mark all read
          </Button>
        )}
      </div>

      {/* List */}
      {alerts.length === 0 ? (
        <div style={{ padding: '28px 16px', textAlign: 'center', color: '#999' }}>
          <AlertOutlined style={{ fontSize: 24, marginBottom: 8, display: 'block', color: '#d9d9d9' }} />
          No new fight alerts
        </div>
      ) : (
        <List
          dataSource={alerts.slice(0, 5)}
          renderItem={(item) => (
            <List.Item
              key={item.recipient_id}
              style={{
                padding: '10px 16px',
                cursor: 'pointer',
                background: item.status === 'unread' ? '#fff2f0' : 'transparent',
                transition: 'background 0.15s',
              }}
              onClick={() => { navigate('/surveillance-events'); setOpen(false); }}
            >
              <List.Item.Meta
                avatar={
                  <AlertOutlined
                    style={{
                      color: item.status === 'unread' ? '#ff4d4f' : '#bbb',
                      fontSize: 16,
                      marginTop: 2,
                    }}
                  />
                }
                title={
                  <Text strong={item.status === 'unread'} style={{ fontSize: 13 }}>
                    {item.title}
                  </Text>
                }
                description={
                  <span style={{ fontSize: 12, color: '#888' }}>{item.body}</span>
                }
              />
              <span style={{ fontSize: 11, color: '#bbb', whiteSpace: 'nowrap', marginLeft: 8 }}>
                {formatTime(item.created_at)}
              </span>
            </List.Item>
          )}
        />
      )}

      {/* Footer */}
      <div
        style={{
          padding: '8px 16px',
          borderTop: '1px solid #f0f0f0',
          textAlign: 'center',
        }}
      >
        <Button
          type="link"
          size="small"
          onClick={() => { navigate('/surveillance-events'); setOpen(false); }}
        >
          View all surveillance events →
        </Button>
      </div>
    </div>
  );

  return (
    <>
      {contextHolder}
      {open && (
        <div
          style={{ position: 'fixed', inset: 0, zIndex: 999 }}
          onClick={() => setOpen(false)}
        />
      )}
      <div style={{ position: 'relative', zIndex: 1000 }}>
        <Badge count={unreadCount} size="small" offset={[-4, 4]}>
          <Button
            type="text"
            shape="circle"
            icon={<BellOutlined />}
            onClick={() => setOpen((v) => !v)}
          />
        </Badge>
        {open && (
          <div style={{ position: 'absolute', top: 40, right: 0 }}>
            {dropdownContent}
          </div>
        )}
      </div>
    </>
  );
}
