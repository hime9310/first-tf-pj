# first-tf-pj
# My Python App - CodePipeline Demo

一个简单的Python Web应用，演示使用AWS CodePipeline进行自动化CI/CD部署。

## 🎯 项目概述

这是一个使用Python的HTTP服务器创建的简单Web应用，通过AWS CodePipeline实现从GitHub到EC2的自动化部署。

## 🏗️ 技术栈

- **后端**: Python 3.9+ 
- **部署**: AWS CodePipeline + CodeBuild + CodeDeploy
- **基础设施**: AWS EC2 (Ubuntu)
- **版本控制**: GitHub

## 📁 项目结构
my-python-app/
├── app.py                    # Python应用主文件
├── requirements.txt          # Python依赖（可选）
├── buildspec.yml            # CodeBuild构建配置
├── appspec.yml              # CodeDeploy部署配置
├── scripts/                 # 部署脚本
│   ├── stop_server.sh       # 停止服务
│   ├── install_dependencies.sh # 安装依赖
│   ├── start_server.sh      # 启动服务
│   └── validate_service.sh  # 验证部署
└── README.md                # 项目文档

## 🚀 功能特性

- ✅ RESTful API端点 (GET /)
- ✅ JSON响应格式
- ✅ 健康检查支持
- ✅ 详细日志记录
- ✅ 优雅的服务启停
- ✅ 自动化部署验证

## 📊 API文档

### GET /

返回应用状态信息

**响应示例:**
```json
{
  "message": "🎉 Hello World from CodePipeline!",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "1.0.1",
  "environment": "production",
  "hostname": "ip-172-31-32-123",
  "status": "success",
  "deployment_info": {
    "deployed_at": "2024-01-15 10:29:45",
    "python_version": "3.9",
    "platform": "posix"
  }
}
