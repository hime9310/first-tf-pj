# Python Web アプリケーション - 使用方法ガイド

## 目次
1. [アプリケーション概要](#アプリケーション概要)
2. [CI/CDパイプラインの詳細フロー](#cicdパイプラインの詳細フロー)
3. [デプロイメント手順](#デプロイメント手順)
4. [アプリケーションの使用方法](#アプリケーションの使用方法)
5. [運用・監視](#運用監視)
6. [トラブルシューティング](#トラブルシューティング)
7. [開発者向けガイド](#開発者向けガイド)

## アプリケーション概要

### 何ができるアプリケーションか
このアプリケーションは、**AWS CodePipelineを使った自動CI/CDデプロイメント**のデモンストレーションです。

**主な機能:**
- シンプルなPython HTTPサーバー（ポート8000）
- JSON形式のAPI応答
- ヘルスチェック機能
- 自動デプロイメント対応
- systemdサービス化

### アプリケーションの構成
```
Python HTTPサーバー
├── メインエンドポイント (/)     → アプリケーション情報を返す
├── ヘルスチェック (/health)     → サービス稼働状況を返す
└── 404ハンドリング             → 存在しないパスの処理
```

### レスポンス例
**メインエンドポイント (`GET /`)**
```json
{
  "message": "Hello World from CodePipeline!",
  "timestamp": "2025-01-15T10:30:00.000Z",
  "version": "1.0.2",
  "environment": "production",
  "hostname": "ip-172-31-32-123",
  "status": "success",
  "deployment_info": {
    "deployed_at": "2025-01-15 10:29:45",
    "python_version": "3.9",
    "platform": "posix",
    "build_time": "2025-01-15T10:28:30Z",
    "commit": "abc123def456"
  }
}
```

**ヘルスチェック (`GET /health`)**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:30:00.000Z",
  "uptime": 3600.5
}
```

## CI/CDパイプラインの詳細フロー

### 全体の流れ
```
GitHub Push → CodePipeline → CodeBuild → CodeDeploy → EC2 → サービス稼働
```

### 1. ソース段階 (GitHub)
**何が起きるか:**
- 開発者がコードをGitHubリポジトリにプッシュ
- CodePipelineがWebhookで変更を検知
- パイプラインが自動的に開始される

**所要時間:** 数秒

### 2. ビルド段階 (CodeBuild)
**buildspec.ymlで定義された処理:**

#### Install フェーズ
```bash
- Python 3.9ランタイムのセットアップ
- pip、setuptools、wheelのアップグレード
- 環境情報の表示
```

#### Pre-build フェーズ
```bash
- ディレクトリ構造の確認
- Python構文チェック (py_compile)
- requirements.txtがあれば依存関係インストール
```

#### Build フェーズ
```bash
- テストファイル (test_app.py) の実行
- バージョン情報ファイル (version.json) の作成
- ビルド成果物の準備
```

#### Post-build フェーズ
```bash
- 最終的なアーティファクトの確認
- デプロイ用ファイルの準備完了
```

**所要時間:** 2-5分

### 3. デプロイ段階 (CodeDeploy → EC2)

#### 3-1. BeforeInstall (stop_server.sh)
**実行内容:**
```bash
- 既存のsystemdサービス停止
- 残存プロセスのクリーンアップ
- ポート8000の解放確認
- 強制終了処理（必要に応じて）
```

#### 3-2. AfterInstall (install_dependencies.sh)
**実行内容:**
```bash
- Python環境の確認・セットアップ
- ファイル権限の設定 (ubuntu:ubuntu)
- ログディレクトリの作成 (/var/log/my-python-app/)
- アプリケーションの構文チェック
- 環境情報の表示
```

#### 3-3. ApplicationStart (start_server.sh)
**実行内容:**
```bash
- systemdサービスファイルの作成
- サービスの有効化 (systemctl enable)
- サービスの開始 (systemctl start)
- 起動確認とログ出力
```

**作成されるサービス設定:**
```ini
[Unit]
Description=CodePipeline Demo Python Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/my-python-app
ExecStart=/usr/bin/python3 /opt/my-python-app/sampl-app.py
Restart=on-failure
Environment=ENV=production
Environment=PORT=8000
MemoryMax=512M

[Install]
WantedBy=multi-user.target
```

#### 3-4. ValidateService (validate_service.sh)
**検証項目:**
```bash
1. systemdサービス状態確認
2. ポート8000のリスニング確認
3. HTTPエンドポイントのテスト
   - メインエンドポイント (/) のテスト
   - ヘルスチェック (/health) のテスト
4. ログファイルと権限の確認
5. 基本的なパフォーマンステスト
```

**所要時間:** 3-8分

## デプロイメント手順

### 前提条件
- AWS アカウント
- GitHub アカウント
- EC2 インスタンス（Ubuntu 20.04以上）
- CodeDeploy エージェントがインストール済み

### 1. GitHubリポジトリの準備
```bash
# リポジトリをクローン
git clone <your-repository-url>
cd first-tf-pj

# ファイル構造の確認
ls -la
# sampl-app.py, buildspec.yml, appspec.yml, scripts/ が存在することを確認
```

### 2. AWS CodePipelineの設定

#### パイプライン作成
1. AWS コンソールでCodePipelineサービスを開く
2. 「パイプラインを作成」をクリック
3. 以下の設定を行う：

**ソース設定:**
- プロバイダー: GitHub (Version 2)
- リポジトリ名: your-username/first-tf-pj
- ブランチ名: main

**ビルド設定:**
- プロバイダー: AWS CodeBuild
- プロジェクト名: first-tf-pj-build
- buildspec: buildspec.yml を使用

**デプロイ設定:**
- プロバイダー: AWS CodeDeploy
- アプリケーション名: first-tf-pj-app
- デプロイグループ: production

### 3. EC2インスタンスの準備

#### CodeDeployエージェントのインストール
```bash
# EC2インスタンスにSSH接続
ssh -i your-key.pem ubuntu@your-ec2-ip

# CodeDeployエージェントのインストール
sudo apt update
sudo apt install -y ruby wget
cd /home/ubuntu
wget https://aws-codedeploy-ap-northeast-1.s3.ap-northeast-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

# エージェントの状態確認
sudo service codedeploy-agent status
```

#### 必要なディレクトリの作成
```bash
sudo mkdir -p /opt/my-python-app
sudo chown ubuntu:ubuntu /opt/my-python-app
```

### 4. パイプラインの実行
```bash
# ローカルでコードを変更
echo "# Updated" >> README.md

# GitHubにプッシュ
git add .
git commit -m "Trigger pipeline deployment"
git push origin main
```

**パイプラインが自動実行され、約5-10分でデプロイが完了します。**

## アプリケーションの使用方法

### 基本的なアクセス方法
```bash
# メインエンドポイントへのアクセス
curl http://your-ec2-ip:8000/

# ヘルスチェック
curl http://your-ec2-ip:8000/health

# ブラウザでのアクセス
# http://your-ec2-ip:8000/ をブラウザで開く
```

### API仕様詳細

#### GET /
**説明:** アプリケーションの詳細情報を取得

**レスポンス:**
- `message`: アプリケーションからのメッセージ
- `timestamp`: 現在時刻（ISO 8601形式）
- `version`: アプリケーションバージョン
- `environment`: 実行環境
- `hostname`: サーバーのホスト名
- `status`: アプリケーション状態
- `deployment_info`: デプロイメント詳細情報

#### GET /health
**説明:** サービスのヘルスチェック

**レスポンス:**
- `status`: サービス状態 ("healthy")
- `timestamp`: 現在時刻
- `uptime`: サービス稼働時間（秒）

#### その他のパス
**404 Not Found** レスポンスが返され、利用可能なエンドポイント一覧が表示されます。

### 負荷テスト例
```bash
# 簡単な負荷テスト
for i in {1..10}; do
  curl -s http://your-ec2-ip:8000/ > /dev/null && echo "Request $i: OK"
done

# Apache Benchを使用した負荷テスト
ab -n 100 -c 10 http://your-ec2-ip:8000/
```

## 運用・監視

### サービス管理コマンド
```bash
# サービス状態確認
sudo systemctl status my-python-app

# サービス開始
sudo systemctl start my-python-app

# サービス停止
sudo systemctl stop my-python-app

# サービス再起動
sudo systemctl restart my-python-app

# 自動起動の有効化/無効化
sudo systemctl enable my-python-app
sudo systemctl disable my-python-app
```

### ログ監視
```bash
# リアルタイムログ監視
sudo journalctl -u my-python-app -f

# 最新のログ表示
sudo journalctl -u my-python-app -n 50

# アプリケーションログファイル
tail -f /var/log/my-python-app/app.log

# エラーログファイル
tail -f /var/log/my-python-app/error.log
```

### ヘルスチェック監視
```bash
# 定期的なヘルスチェック（cron設定例）
# 毎分ヘルスチェックを実行し、失敗時にアラート
* * * * * curl -f http://localhost:8000/health > /dev/null || echo "Health check failed" | mail -s "App Alert" admin@example.com
```

### リソース使用量確認
```bash
# メモリ使用量
ps aux | grep sampl-app.py

# ポート使用状況
netstat -tuln | grep 8000

# システムリソース
top -p $(pgrep -f sampl-app.py)
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. サービスが起動しない
**症状:** `systemctl status my-python-app` で failed 状態

**確認手順:**
```bash
# 詳細なエラーログを確認
sudo journalctl -u my-python-app -n 20

# Python構文エラーの確認
python3 -m py_compile /opt/my-python-app/sampl-app.py

# ファイル権限の確認
ls -la /opt/my-python-app/sampl-app.py
```

**解決方法:**
```bash
# 権限修正
sudo chown ubuntu:ubuntu /opt/my-python-app/sampl-app.py
sudo chmod +x /opt/my-python-app/sampl-app.py

# サービス再起動
sudo systemctl restart my-python-app
```

#### 2. ポート8000が使用中
**症状:** "Address already in use" エラー

**確認手順:**
```bash
# ポート使用プロセスの特定
sudo lsof -i :8000
sudo netstat -tuln | grep 8000
```

**解決方法:**
```bash
# プロセス終了
sudo pkill -f "python3.*sampl-app.py"

# または特定のPIDを終了
sudo kill -TERM <PID>

# サービス再起動
sudo systemctl restart my-python-app
```

#### 3. HTTPエンドポイントが応答しない
**症状:** curl でタイムアウトまたは接続拒否

**確認手順:**
```bash
# サービス状態確認
sudo systemctl status my-python-app

# ポートリスニング確認
netstat -tuln | grep 8000

# ファイアウォール確認
sudo ufw status
```

**解決方法:**
```bash
# ファイアウォール設定
sudo ufw allow 8000

# セキュリティグループ確認（AWS EC2の場合）
# インバウンドルールでポート8000が開放されているか確認
```

#### 4. デプロイメントが失敗する
**症状:** CodeDeploy でエラーが発生

**確認手順:**
```bash
# CodeDeployエージェントログ
sudo tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log

# デプロイメントログ
sudo find /opt/codedeploy-agent/deployment-root -name "*.log" -exec tail -20 {} \;
```

**解決方法:**
```bash
# CodeDeployエージェント再起動
sudo service codedeploy-agent restart

# 権限問題の場合
sudo chown -R ubuntu:ubuntu /opt/my-python-app
```

### ログレベル別の対処法

#### ERROR レベル
- アプリケーションの致命的エラー
- 即座に対応が必要
- サービス再起動を検討

#### WARNING レベル
- 一時的な問題の可能性
- 監視を継続
- 必要に応じて調査

#### INFO レベル
- 正常な動作ログ
- 定期的な確認で十分

## 開発者向けガイド

### ローカル開発環境のセットアップ
```bash
# リポジトリクローン
git clone <repository-url>
cd first-tf-pj

# Python環境確認
python3 --version  # 3.9以上が必要

# アプリケーション実行
python3 sampl-app.py
```

### テストの実行
```bash
# 基本テスト
python3 test_app.py

# 統合テスト付き
python3 test_app.py --integration

# 構文チェックのみ
python3 -m py_compile sampl-app.py
```

### コード変更時の注意点

#### 1. 構文チェック
```bash
# 必ずプッシュ前に実行
python3 -m py_compile sampl-app.py
```

#### 2. ポート変更
```python
# sampl-app.py でポートを変更する場合
port = int(os.environ.get('PORT', 8000))  # デフォルト8000

# 対応するファイルも更新が必要:
# - scripts/validate_service.sh (ポート確認部分)
# - start_server.sh (Environment=PORT=8000)
```

#### 3. 新しいエンドポイント追加
```python
def do_GET(self):
    if self.path == '/new-endpoint':
        self._handle_new_endpoint()
    # 既存のコード...

def _handle_new_endpoint(self):
    # 新しいエンドポイントの処理
    pass
```

### デプロイメント前のチェックリスト
- [ ] 構文チェック完了
- [ ] ローカルテスト実行完了
- [ ] ログ出力の確認
- [ ] エラーハンドリングの実装
- [ ] ドキュメント更新

### カスタマイズ例

#### 環境変数の追加
```python
# sampl-app.py
app_name = os.environ.get('APP_NAME', 'CodePipeline Demo')
debug_mode = os.environ.get('DEBUG', 'false').lower() == 'true'
```

```bash
# start_server.sh のサービスファイル
Environment=APP_NAME=My Custom App
Environment=DEBUG=false
```

#### ログレベルの調整
```python
import logging

# ログ設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
```

この使用方法ガイドを参考に、アプリケーションの効果的な運用と開発を行ってください。