#!/bin/bash
# 快速诊断脚本 - 部署失败时使用

echo "🔍 CodeDeploy 部署失败快速诊断"
echo "=================================="
echo "执行时间: $(date)"
echo ""

# 1. 检查CodeDeploy Agent状态
echo "1️⃣ CodeDeploy Agent 状态检查:"
if systemctl is-active --quiet codedeploy-agent; then
    echo "   ✅ CodeDeploy Agent 正在运行"
else
    echo "   ❌ CodeDeploy Agent 未运行"
    echo "   尝试启动 CodeDeploy Agent..."
    sudo systemctl start codedeploy-agent
    sudo systemctl enable codedeploy-agent
fi

# 2. 检查应用程序服务状态
echo ""
echo "2️⃣ 应用程序服务状态:"
if systemctl list-units --type=service | grep -q my-python-app; then
    echo "   服务存在，状态:"
    systemctl status my-python-app --no-pager -l | head -10
else
    echo "   ❌ my-python-app 服务不存在"
fi

# 3. 检查部署目录
echo ""
echo "3️⃣ 部署目录检查:"
if [ -d "/opt/my-python-app" ]; then
    echo "   ✅ 部署目录存在: /opt/my-python-app"
    echo "   目录内容:"
    ls -la /opt/my-python-app/ | head -10
    
    if [ -f "/opt/my-python-app/sampl-app.py" ]; then
        echo "   ✅ 主应用文件存在"
        echo "   文件权限:"
        ls -la /opt/my-python-app/sampl-app.py
    else
        echo "   ❌ 主应用文件不存在"
    fi
else
    echo "   ❌ 部署目录不存在: /opt/my-python-app"
fi

# 4. 检查端口占用
echo ""
echo "4️⃣ 端口8000状态检查:"
if netstat -tuln 2>/dev/null | grep -q ":8000" || ss -tuln 2>/dev/null | grep -q ":8000"; then
    echo "   ✅ 端口8000正在被使用"
    netstat -tuln 2>/dev/null | grep ":8000" || ss -tuln 2>/dev/null | grep ":8000"
else
    echo "   ❌ 端口8000未被使用"
fi

# 5. 检查Python进程
echo ""
echo "5️⃣ Python应用进程检查:"
python_processes=$(ps aux | grep sampl-app.py | grep -v grep)
if [ -n "$python_processes" ]; then
    echo "   ✅ 发现Python应用进程:"
    echo "$python_processes"
else
    echo "   ❌ 未发现Python应用进程"
fi

# 6. 检查最近的系统日志
echo ""
echo "6️⃣ 最近的系统日志 (CodeDeploy相关):"
echo "   CodeDeploy Agent 日志:"
if [ -f "/var/log/aws/codedeploy-agent/codedeploy-agent.log" ]; then
    tail -5 /var/log/aws/codedeploy-agent/codedeploy-agent.log
else
    echo "   CodeDeploy Agent 日志文件不存在"
fi

echo ""
echo "   应用程序日志:"
if systemctl list-units --type=service | grep -q my-python-app; then
    journalctl -u my-python-app --no-pager -l -n 5
else
    echo "   应用程序服务不存在，无法获取日志"
fi

# 7. 手动测试应用程序
echo ""
echo "7️⃣ 手动应用程序测试:"
if [ -f "/opt/my-python-app/sampl-app.py" ]; then
    echo "   尝试手动启动应用程序 (5秒测试):"
    cd /opt/my-python-app
    timeout 5s python3 sampl-app.py &
    test_pid=$!
    sleep 2
    
    if kill -0 $test_pid 2>/dev/null; then
        echo "   ✅ 应用程序可以手动启动"
        kill $test_pid 2>/dev/null
    else
        echo "   ❌ 应用程序无法手动启动"
    fi
else
    echo "   ❌ 应用程序文件不存在，无法测试"
fi

# 8. 网络连接测试
echo ""
echo "8️⃣ 网络连接测试:"
if curl -s --connect-timeout 3 http://localhost:8000/ > /dev/null 2>&1; then
    echo "   ✅ 本地HTTP连接正常"
else
    echo "   ❌ 本地HTTP连接失败"
fi

# 9. 磁盘空间检查
echo ""
echo "9️⃣ 系统资源检查:"
echo "   磁盘使用情况:"
df -h / | tail -1
echo "   内存使用情况:"
free -h | head -2

# 10. 建议的修复步骤
echo ""
echo "🔧 建议的修复步骤:"
echo "=================================="

if ! systemctl is-active --quiet my-python-app; then
    echo "1. 重新启动应用程序服务:"
    echo "   sudo systemctl stop my-python-app"
    echo "   sudo systemctl start my-python-app"
    echo "   sudo systemctl status my-python-app"
    echo ""
fi

if [ ! -f "/opt/my-python-app/sampl-app.py" ]; then
    echo "2. 检查部署文件是否正确复制:"
    echo "   ls -la /opt/my-python-app/"
    echo "   # 如果文件缺失，可能需要重新部署"
    echo ""
fi

echo "3. 查看详细的部署日志:"
echo "   sudo tail -50 /var/log/aws/codedeploy-agent/codedeploy-agent.log"
echo ""

echo "4. 手动运行验证脚本:"
echo "   cd /opt/my-python-app"
echo "   sudo bash scripts/validate_service.sh"
echo ""

echo "5. 如果问题持续，重新触发部署:"
echo "   - 在GitHub推送新的提交"
echo "   - 或在AWS CodePipeline控制台手动重新运行"

echo ""
echo "=================================="
echo "诊断完成。请根据上述信息进行故障排除。"