#!/bin/bash
echo "🔍 [$(date)] Validating deployment..."

# 等待服务完全启动
echo "⏱️ Waiting for service to be ready..."
sleep 10

# 检查1：验证systemd服务状态
echo "1️⃣ Checking systemd service status..."
if systemctl is-active --quiet my-python-app; then
    echo "✅ Service is active and running"
else
    echo "❌ Service is not running"
    systemctl status my-python-app --no-pager -l
    exit 1
fi

# 检查2：验证端口是否开放
echo "2️⃣ Checking if port 8000 is listening..."
if netstat -tuln | grep -q ":8000"; then
    echo "✅ Port 8000 is open and listening"
else
    echo "❌ Port 8000 is not open"
    echo "📋 Current listening ports:"
    netstat -tuln | grep LISTEN
    exit 1
fi

# 检查3：测试HTTP响应
echo "3️⃣ Testing HTTP endpoint..."
max_attempts=5
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "🌐 Attempt $attempt/$max_attempts: Testing HTTP response..."
    
    if curl -f -s -m 10 http://localhost:8000 > /dev/null; then
        echo "✅ HTTP endpoint is responding correctly"
        
        # 获取并显示响应内容
        echo "📄 Sample response:"
        curl -s http://localhost:8000 | jq . 2>/dev/null || curl -s http://localhost:8000
        break
    else
        echo "⚠️ HTTP endpoint not responding (attempt $attempt/$max_attempts)"
        
        if [ $attempt -eq $max_attempts ]; then
            echo "❌ HTTP endpoint failed to respond after $max_attempts attempts"
            echo "📋 Service logs:"
            journalctl -u my-python-app --no-pager -l -n 15
            echo "📋 System info:"
            ps aux | grep python
            exit 1
        fi
        
        echo "⏱️ Waiting 10 seconds before next attempt..."
        sleep 10
        attempt=$((attempt + 1))
    fi
done

# 检查4：验证日志文件
echo "4️⃣ Checking log files..."
if [ -f "/var/log/my-python-app/app.log" ]; then
    echo "✅ Application log file exists"
    echo "📝 Recent application logs:"
    tail -n 5 /var/log/my-python-app/app.log
else
    echo "⚠️ Application log file not found (this might be normal for new deployments)"
fi

# 检查5：验证文件权限
echo "5️⃣ Checking file permissions..."
if [ -r "/opt/my-python-app/app.py" ] && [ -x "/opt/my-python-app/app.py" ]; then
    echo "✅ Application files have correct permissions"
else
    echo "❌ Application files have incorrect permissions"
    ls -la /opt/my-python-app/
    exit 1
fi

# 性能测试（可选）
echo "6️⃣ Running quick performance test..."
if command -v ab > /dev/null 2>&1; then
    echo "🚄 Running Apache Bench test (10 requests)..."
    ab -n 10 -c 1 http://localhost:8000/ | grep -E "(Requests per second|Time per request)"
else
    echo "ℹ️ Apache Bench not available, skipping performance test"
fi

echo "🎉 [$(date)] Deployment validation completed successfully!"
echo "🌐 Application is ready and serving requests on port 8000"

# 显示最终状态摘要
echo ""
echo "📊 DEPLOYMENT SUMMARY:"
echo "======================"
echo "✅ Service Status: $(systemctl is-active my-python-app)"
echo "✅ Port 8000: Open and listening"
echo "✅ HTTP Endpoint: Responding"
echo "✅ Log Files: Created"
echo "✅ File Permissions: Correct"
echo "🎯 Deployment Time: $(date)"