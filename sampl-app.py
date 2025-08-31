#!/usr/bin/env python3
"""
CodePipeline用の最適化されたPython Webアプリケーション
軽量で安定性を重視した設計
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
import sys
import signal
from datetime import datetime
import socket
import threading
import time

class HealthHandler(BaseHTTPRequestHandler):
    """軽量で安定したHTTPハンドラー"""
    
    def do_GET(self):
        """GETリクエストの処理"""
        try:
            if self.path == '/health':
                self._handle_health_check()
            elif self.path == '/':
                self._handle_main_endpoint()
            else:
                self._handle_not_found()
        except Exception as e:
            self._handle_error(e)
    
    def do_HEAD(self):
        """HEADリクエストの処理（ヘルスチェック用）"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
    
    def _handle_health_check(self):
        """ヘルスチェックエンドポイント"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Cache-Control', 'no-cache')
        self.end_headers()
        
        health_response = {
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'uptime': time.time() - start_time
        }
        
        self.wfile.write(json.dumps(health_response).encode('utf-8'))
    
    def _handle_main_endpoint(self):
        """メインエンドポイント"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        # デプロイメント情報を読み込み
        deployment_info = self._get_deployment_info()
        
        response = {
            'message': 'Hello World from CodePipeline!',
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.4-fixed-permissions',
            'environment': os.environ.get('ENV', 'production'),
            'hostname': socket.gethostname(),
            'status': 'success',
            'deployment_info': deployment_info
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode('utf-8'))
    
    def _handle_not_found(self):
        """404エラーの処理"""
        self.send_response(404)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        error_response = {
            'error': 'Not Found',
            'message': f'Path {self.path} not found',
            'available_endpoints': ['/', '/health']
        }
        
        self.wfile.write(json.dumps(error_response).encode('utf-8'))
    
    def _handle_error(self, error):
        """エラーハンドリング"""
        self.send_response(500)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        error_response = {
            'error': 'Internal Server Error',
            'message': str(error),
            'timestamp': datetime.now().isoformat()
        }
        
        self.wfile.write(json.dumps(error_response).encode('utf-8'))
        print(f"[ERROR] {datetime.now().isoformat()} - {error}")
    
    def _get_deployment_info(self):
        """デプロイメント情報の取得"""
        deployment_info = {
            'deployed_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'python_version': f"{sys.version_info.major}.{sys.version_info.minor}",
            'platform': os.name
        }
        
        # バージョン情報ファイルがあれば読み込み
        try:
            if os.path.exists('version.json'):
                with open('version.json', 'r') as f:
                    version_data = json.load(f)
                    deployment_info.update(version_data)
        except Exception:
            pass  # ファイルが読めなくても継続
        
        return deployment_info
    
    def log_message(self, format, *args):
        """カスタムログ形式"""
        print(f"[{datetime.now().isoformat()}] {format % args}")

# グローバル変数
start_time = time.time()
server = None

def signal_handler(signum, frame):
    """シグナルハンドラー（グレースフルシャットダウン）"""
    print(f"\n[{datetime.now().isoformat()}] シャットダウンシグナルを受信しました")
    if server:
        print("サーバーを停止しています...")
        server.shutdown()
        server.server_close()
    print("アプリケーションが正常に終了しました")
    sys.exit(0)

def main():
    """メイン関数"""
    global server
    
    # シグナルハンドラーの設定
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    port = int(os.environ.get('PORT', 8000))
    host = '0.0.0.0'
    
    try:
        # サーバーの作成（より高速な起動のため）
        server = HTTPServer((host, port), HealthHandler)
        server.timeout = 1  # タイムアウトを短く設定
        
        print(f"[{datetime.now().isoformat()}] サーバーを開始しています")
        print(f"  - アドレス: {host}:{port}")
        print(f"  - エンドポイント: http://localhost:{port}/")
        print(f"  - ヘルスチェック: http://localhost:{port}/health")
        print(f"  - 環境: {os.environ.get('ENV', 'production')}")
        print(f"  - PID: {os.getpid()}")
        
        # 起動完了の明確な表示
        print(f"[{datetime.now().isoformat()}] ✓ サーバーが正常に起動しました")
        
        # サーバーの開始
        server.serve_forever()
        
    except OSError as e:
        if e.errno == 98:  # Address already in use
            print(f"[ERROR] ポート{port}は既に使用されています")
            # 既存のプロセスを確認
            try:
                import subprocess
                result = subprocess.run(['netstat', '-tuln'], capture_output=True, text=True)
                print(f"[DEBUG] 現在のポート使用状況:\n{result.stdout}")
            except:
                pass
            sys.exit(1)
        else:
            print(f"[ERROR] サーバー開始エラー: {e}")
            sys.exit(1)
    except Exception as e:
        print(f"[ERROR] 予期しないエラー: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()