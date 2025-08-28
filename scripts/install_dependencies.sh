#!/bin/bash
echo "📦 [$(date)] Installing dependencies..."

# 进入应用目录
cd /opt/my-python-app

# 确保目录权限正确
echo "🔧 Setting up directory permissions..."
chown -R ubuntu:ubuntu /opt/my-python-app
find /opt/my-python-app -type d -exec chmod 755 {} \;
find /opt/my-python-app -type f -exec chmod 644 {} \;

# 给脚本文件执行权限
chmod +x /opt/my-python-app/app.py
chmod +x /opt/my-python-app/scripts/*.sh

# 安装系统依赖（如果需要）
echo "🔄 Updating package list..."
apt-get update -y

# 确保Python3和pip可用
echo "🐍 Verifying Python installation..."
python3 --version
pip3 --version

# 安装Python依赖
if [ -f "requirements.txt" ]; then
    echo "📚 Installing Python dependencies from requirements.txt..."
    pip3 install --user -r requirements.txt
    echo "✅ Python dependencies installed successfully"
else
    echo "ℹ️ No requirements.txt found, skipping Python dependency installation"
fi

# 创建日志目录
echo "📁 Setting up logging..."
mkdir -p /var/log/my-python-app
chown ubuntu:ubuntu /var/log/my-python-app
chmod 755 /var/log/my-python-app

# 显示版本信息（如果存在）
if [ -f "version.json" ]; then
    echo "📋 Deployment version info:"
    cat version.json
fi

echo "✅ [$(date)] Dependencies installation completed successfully"