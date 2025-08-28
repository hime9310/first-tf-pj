#!/bin/bash
echo "🛑 [$(date)] Stopping application..."

# 设置错误时继续执行
set +e

# 停止systemd服务
echo "📝 Stopping systemd service..."
systemctl stop my-python-app 2>/dev/null || echo "ℹ️ Service was not running"

# 禁用服务（避免开机自启）
systemctl disable my-python-app 2>/dev/null || echo "ℹ️ Service was not enabled"

# 强制杀死可能残留的Python进程
echo "🔍 Killing any remaining Python processes..."
pkill -f "python3.*app.py" 2>/dev/null || echo "ℹ️ No Python app processes found"

# 等待进程完全停止
echo "⏱️ Waiting for processes to terminate..."
sleep 3

# 检查端口是否仍被占用
if netstat -tuln | grep -q ":8000"; then
    echo "⚠️ Port 8000 still in use, attempting to free it..."
    fuser -k 8000/tcp 2>/dev/null || true
    sleep 2
fi

# 清理旧的日志文件（可选）
if [ -f "/var/log/my-python-app.log" ]; then
    echo "🧹 Rotating log file..."
    mv /var/log/my-python-app.log /var/log/my-python-app.log.old 2>/dev/null || true
fi

echo "✅ [$(date)] Application stop completed"