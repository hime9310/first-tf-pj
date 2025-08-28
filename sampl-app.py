#!/usr/bin/env python3
"""
Simple Python web application for CodePipeline demo
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
from datetime import datetime
import socket

class HelloHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """处理GET请求"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        # 获取系统信息
        hostname = socket.gethostname()
        
        response = {
            'message': '🎉 Hello World from CodePipeline!',
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.1',
            'environment': os.environ.get('ENV', 'development'),
            'hostname': hostname,
            'status': 'success',
            'deployment_info': {
                'deployed_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'python_version': f"{os.sys.version_info.major}.{os.sys.version_info.minor}",
                'platform': os.name
            }
        }
        
        self.wfile.write(json.dumps(response, indent=2, ensure_ascii=False).encode('utf-8'))
    
    def do_HEAD(self):
        """处理HEAD请求（健康检查）"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
    
    def log_message(self, format, *args):
        """自定义日志格式"""
        print(f"[{datetime.now().isoformat()}] {format % args}")

def main():
    """主函数"""
    port = int(os.environ.get('PORT', 8000))
    host = '0.0.0.0'
    
    try:
        server = HTTPServer((host, port), HelloHandler)
        print(f'🚀 Starting server on {host}:{port}')
        print(f'📱 Local access: http://localhost:{port}')
        print(f'🌐 Network access: http://{socket.gethostname()}:{port}')
        print(f'⏰ Started at: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
        print('Press Ctrl+C to stop the server')
        
        server.serve_forever()
        
    except KeyboardInterrupt:
        print('\n⛔ Shutting down server...')
        server.server_close()
        print('✅ Server stopped gracefully')
    except Exception as e:
        print(f'❌ Error starting server: {e}')
        exit(1)

if __name__ == '__main__':
    main()