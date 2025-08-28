#!/bin/bash
echo "🚀 [$(date)] Starting application..."

cd /opt/my-python-app

# 创建systemd服务文件
echo "⚙️ Creating systemd service..."
cat << 'EOF' > /etc/systemd/system/my-python-app.service
[Unit]
Description=My Python Application
Documentation=https://github.com/your-username/my-python-app
After=network.target
Wants=network.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/my-python-app
ExecStart=/usr/bin/python3 /opt/my-python-app/app.py
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10
StandardOutput=append:/var/log/my-python-app/app.log
StandardError=append:/var/log/my-python-app/error.log

# 环境变量
Environment=ENV=production
Environment=PORT=8000
Environment=PYTHONPATH=/opt/my-python-app

# 安全设置
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/my-python-app /var/log/my-python-app

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd配置
echo "🔄 Reloading systemd daemon..."
systemctl daemon-reload

# 启用服务（开机自启）
echo "✅ Enabling service..."
systemctl enable my-python-app

# 启动服务
echo "🎬 Starting service..."
systemctl start my-python-app

# 等待服务启动
echo "⏱️ Waiting for service to start..."
sleep 5

# 检查服务状态
echo "📊 Service status:"
systemctl status my-python-app --no-pager -l

# 检查服务是否真的在运行
if systemctl is-active --quiet my-python-app; then
    echo "✅ [$(date)] Application started successfully!"
    
    # 显示日志的最后几行
    echo "📝 Recent logs:"
    journalctl -u my-python-app --no-pager -l -n 10
else
    echo "❌ [$(date)] Failed to start application!"
    echo "📝 Error logs:"
    journalctl -u my-python-app --no-pager -l -n 20
    exit 1
fi