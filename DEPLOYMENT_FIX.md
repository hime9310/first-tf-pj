# 🚨 部署失败解决方案

## 问题诊断

你遇到的是AWS CodeDeploy健康检查约束失败的问题。这通常发生在以下情况：

1. **应用启动时间过长** - 健康检查超时
2. **端口未正确监听** - 应用没有在预期端口启动  
3. **健康检查端点异常** - `/health`端点返回错误
4. **服务配置问题** - systemd服务启动失败

## 🔧 已优化的解决方案

### 1. 优化了验证脚本 (`validate_service.sh`)
- **更短的检查间隔**: 从8秒改为1秒间隔检查
- **更多重试次数**: 增加到10-15次重试
- **更好的错误诊断**: 提供详细的调试信息
- **更快的超时设置**: 减少curl超时时间

### 2. 优化了启动脚本 (`start_server.sh`)  
- **快速启动检查**: 1秒间隔检查服务状态
- **端口验证**: 确认端口8000正确开放
- **详细错误日志**: 启动失败时提供完整诊断信息

### 3. 优化了Python应用 (`sampl-app.py`)
- **更快的启动**: 减少服务器初始化时间
- **明确的启动日志**: 显示启动完成状态
- **更好的错误处理**: 提供详细的错误信息

### 4. 改进了依赖安装 (`install_dependencies.sh`)
- **系统包检查**: 确保所有必需工具已安装
- **启动测试**: 安装后进行简单的启动测试
- **权限修复**: 确保所有文件权限正确

## 🚀 立即修复步骤

### 步骤1: 运行快速诊断
```bash
# 在EC2服务器上运行
cd /path/to/first-tf-pj
sudo bash quick-diagnosis.sh
```

### 步骤2: 手动重启服务（如果需要）
```bash
# 停止现有服务
sudo systemctl stop my-python-app

# 重新运行安装脚本
cd /opt/my-python-app
sudo bash scripts/install_dependencies.sh

# 启动服务
sudo bash scripts/start_server.sh

# 验证服务
sudo bash scripts/validate_service.sh
```

### 步骤3: 测试应用程序
```bash
# 本地测试
curl http://localhost:8000/
curl http://localhost:8000/health

# 外网测试（替换为你的EC2公网IP）
curl http://YOUR-EC2-IP:8000/
```

## 📋 预防措施

### 1. 确保AWS安全组配置
- 入站规则: 端口8000, 协议TCP, 源0.0.0.0/0

### 2. 确保EC2实例配置
- 至少1GB内存
- Python 3.9+已安装
- CodeDeploy Agent正在运行

### 3. 监控关键指标
```bash
# 检查服务状态
sudo systemctl status my-python-app

# 检查端口
netstat -tuln | grep 8000

# 检查日志
sudo journalctl -u my-python-app -f
```

## 🔍 常见问题排查

### 问题1: 端口8000被占用
```bash
# 查找占用进程
sudo lsof -i :8000

# 终止占用进程
sudo kill -9 <PID>
```

### 问题2: 权限问题
```bash
# 修复权限
sudo chown -R ubuntu:ubuntu /opt/my-python-app
sudo chmod +x /opt/my-python-app/sampl-app.py
```

### 问题3: Python环境问题
```bash
# 检查Python
python3 --version
which python3

# 测试应用
cd /opt/my-python-app
python3 sampl-app.py
```

## 📞 如果问题持续

1. **查看详细日志**:
   ```bash
   sudo tail -50 /var/log/aws/codedeploy-agent/codedeploy-agent.log
   sudo journalctl -u my-python-app -n 50
   ```

2. **重新部署**:
   - 在GitHub推送新提交
   - 或在AWS CodePipeline控制台手动重新运行

3. **联系支持**:
   - 提供诊断脚本输出
   - 提供CodeDeploy错误日志
   - 说明具体的错误症状

## ✅ 成功部署的标志

部署成功后，你应该看到：
- ✅ systemctl status显示`active (running)`
- ✅ 端口8000正在监听
- ✅ HTTP请求返回200状态码
- ✅ 健康检查返回`"status": "healthy"`
- ✅ 无错误日志

---

**记住**: 这些优化应该显著减少部署失败的可能性。如果问题仍然存在，运行诊断脚本并检查具体的错误信息。