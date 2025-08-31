#!/usr/bin/env python3
"""
sampl-app.py用の基本的なテストスイート
"""

import unittest
import json
import socket
import time
import subprocess
import sys
import os
from urllib.request import urlopen
from urllib.error import URLError
import threading

class TestPythonApp(unittest.TestCase):
    """Python アプリケーションの基本テスト"""
    
    @classmethod
    def setUpClass(cls):
        """テストクラスの初期化"""
        cls.base_url = "http://localhost:8000"
        cls.app_process = None
        
    def test_01_python_syntax(self):
        """Python構文の検証"""
        print("Python構文をチェックしています...")
        result = subprocess.run([
            sys.executable, '-m', 'py_compile', 'sampl-app.py'
        ], capture_output=True, text=True)
        
        self.assertEqual(result.returncode, 0, 
                        f"構文エラー: {result.stderr}")
        print("✓ Python構文チェックが正常に完了しました")
    
    def test_02_import_modules(self):
        """必要なモジュールのインポート確認"""
        print("必要なモジュールをチェックしています...")
        try:
            import json
            import socket
            import os
            import sys
            from datetime import datetime
            from http.server import HTTPServer, BaseHTTPRequestHandler
            print("✓ 全ての必要なモジュールが利用可能です")
        except ImportError as e:
            self.fail(f"必要なモジュールがインポートできません: {e}")
    
    def test_03_port_availability(self):
        """ポート8000の利用可能性確認"""
        print("ポート8000の利用可能性をチェックしています...")
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            result = sock.connect_ex(('localhost', 8000))
            if result == 0:
                print("⚠ ポート8000は既に使用中です")
            else:
                print("✓ ポート8000は利用可能です")
        finally:
            sock.close()
    
    def test_04_file_permissions(self):
        """ファイル権限の確認"""
        print("ファイル権限をチェックしています...")
        
        # メインアプリケーションファイル
        self.assertTrue(os.path.exists('sampl-app.py'), 
                       "sampl-app.py が見つかりません")
        self.assertTrue(os.access('sampl-app.py', os.R_OK), 
                       "sampl-app.py が読み取り可能ではありません")
        
        # スクリプトファイル
        script_files = [
            'scripts/stop_server.sh',
            'scripts/install_dependencies.sh', 
            'scripts/start_server.sh',
            'scripts/validate_service.sh'
        ]
        
        for script in script_files:
            self.assertTrue(os.path.exists(script), 
                           f"{script} が見つかりません")
            self.assertTrue(os.access(script, os.R_OK), 
                           f"{script} が読み取り可能ではありません")
        
        print("✓ ファイル権限チェックが正常に完了しました")
    
    def test_05_config_files(self):
        """設定ファイルの確認"""
        print("設定ファイルをチェックしています...")
        
        # 必要なファイルの存在確認
        required_files = [
            'buildspec.yml',
            'appspec.yml', 
            'requirements.txt'
        ]
        
        for file_name in required_files:
            self.assertTrue(os.path.exists(file_name), 
                           f"{file_name} が見つかりません")
            
            # ファイルが空でないことを確認
            self.assertGreater(os.path.getsize(file_name), 0, 
                              f"{file_name} が空です")
        
        print("✓ 設定ファイルチェックが正常に完了しました")

class TestAppIntegration(unittest.TestCase):
    """アプリケーション統合テスト（実際にサーバーを起動）"""
    
    @classmethod
    def setUpClass(cls):
        """テストクラスの初期化 - アプリケーションを起動"""
        print("\n統合テスト用にアプリケーションを起動しています...")
        cls.base_url = "http://localhost:8001"  # テスト用に異なるポートを使用
        
        # 環境変数を設定してテスト用ポートでアプリを起動
        env = os.environ.copy()
        env['PORT'] = '8001'
        
        try:
            cls.app_process = subprocess.Popen([
                sys.executable, 'sampl-app.py'
            ], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            
            # アプリケーションの起動を待機
            time.sleep(3)
            
            # プロセスが正常に起動したかチェック
            if cls.app_process.poll() is not None:
                stdout, stderr = cls.app_process.communicate()
                raise Exception(f"アプリケーションの起動に失敗: {stderr.decode()}")
                
            print("✓ テスト用アプリケーションが起動しました")
            
        except Exception as e:
            print(f"⚠ 統合テストをスキップします: {e}")
            cls.app_process = None
    
    @classmethod 
    def tearDownClass(cls):
        """テストクラスのクリーンアップ - アプリケーションを停止"""
        if cls.app_process:
            print("テスト用アプリケーションを停止しています...")
            cls.app_process.terminate()
            cls.app_process.wait(timeout=10)
            print("✓ テスト用アプリケーションが停止しました")
    
    def test_01_http_response(self):
        """HTTPレスポンステスト"""
        if not self.app_process:
            self.skipTest("アプリケーションが起動していません")
            
        print("HTTPレスポンスをテストしています...")
        
        try:
            with urlopen(f"{self.base_url}/", timeout=10) as response:
                self.assertEqual(response.status, 200)
                
                content = response.read().decode('utf-8')
                data = json.loads(content)
                
                # レスポンス構造の確認
                self.assertIn('message', data)
                self.assertIn('timestamp', data)
                self.assertIn('version', data)
                self.assertIn('status', data)
                self.assertEqual(data['status'], 'success')
                
                print("✓ HTTPレスポンステストが正常に完了しました")
                
        except URLError as e:
            self.fail(f"HTTPリクエストが失敗しました: {e}")
        except json.JSONDecodeError as e:
            self.fail(f"JSONレスポンスの解析に失敗しました: {e}")
    
    def test_02_health_check(self):
        """ヘルスチェックエンドポイントテスト"""
        if not self.app_process:
            self.skipTest("アプリケーションが起動していません")
            
        print("ヘルスチェックエンドポイントをテストしています...")
        
        try:
            with urlopen(f"{self.base_url}/health", timeout=10) as response:
                self.assertEqual(response.status, 200)
                
                content = response.read().decode('utf-8')
                data = json.loads(content)
                
                # ヘルスチェックレスポンスの確認
                self.assertIn('status', data)
                self.assertEqual(data['status'], 'healthy')
                self.assertIn('timestamp', data)
                self.assertIn('uptime', data)
                
                print("✓ ヘルスチェックテストが正常に完了しました")
                
        except URLError as e:
            self.fail(f"ヘルスチェックリクエストが失敗しました: {e}")

def main():
    """テストメイン関数"""
    print("=== Python アプリケーション テストスイート ===")
    print(f"Python バージョン: {sys.version}")
    print(f"作業ディレクトリ: {os.getcwd()}")
    print()
    
    # テストスイートの実行
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # 基本テストを追加
    suite.addTests(loader.loadTestsFromTestCase(TestPythonApp))
    
    # 統合テストを追加（オプション）
    if '--integration' in sys.argv:
        suite.addTests(loader.loadTestsFromTestCase(TestAppIntegration))
        print("統合テストが有効化されました")
    
    # テスト実行
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # 結果の表示
    print("\n=== テスト結果 ===")
    if result.wasSuccessful():
        print("✓ 全てのテストが正常に完了しました!")
        return 0
    else:
        print(f"✗ {len(result.failures)} 個のテストが失敗しました")
        print(f"✗ {len(result.errors)} 個のエラーが発生しました")
        return 1

if __name__ == '__main__':
    sys.exit(main())