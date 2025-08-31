# 🚀 クイックリファレンス

## 基本コマンド

### アプリケーションアクセス
```bash
# メインエンドポイント
curl http://your-ec2-ip:8000/

# ヘルスチェック
curl http://your-ec2-ip:8000/health
```

### サービス管理
```bash
# 状態確認
sudo systemctl status my-python-app

# 開始/停止/再起動
sudo systemctl start my-python-app
sudo systemctl stop my-python-app
sudo systemctl restart my-python-app

# ログ監視
sudo journalctl -u my-python-app -f
```

### ローカル開発
```bash
# アプリケーション実行
python3 sampl-app.py

# テスト実行
python3 test_app.py

# 構文チェック
python3 -m py_compile sampl-app.py
```

## CI/CDパイプライン

### デプロイフロー
```
GitHub Push → CodePipeline → CodeBuild → CodeDeploy → EC2
```

### 各段階の所要時間
- **ソース**: 数秒
- **ビルド**: 2-5分
- **デプロイ**: 3-8分
- **合計**: 約5-15分

## トラブルシューティング

### よくある問題
```bash
# ポート使用中
sudo lsof -i :8000
sudo pkill -f "python3.*sampl-app.py"

# 権限エラー
sudo chown ubuntu:ubuntu /opt/my-python-app/sampl-app.py
sudo chmod +x /opt/my-python-app/sampl-app.py

# サービス再起動
sudo systemctl restart my-python-app
```

### ログ確認
```bash
# システムログ
sudo journalctl -u my-python-app -n 20

# アプリケーションログ
tail -f /var/log/my-python-app/app.log

# エラーログ
tail -f /var/log/my-python-app/error.log
```

## ファイル構造
```
first-tf-pj/
├── sampl-app.py           # メインアプリケーション
├── buildspec.yml          # CodeBuildビルド設定
├── appspec.yml            # CodeDeployデプロイ設定
├── scripts/               # デプロイスクリプト
│   ├── stop_server.sh     # サーバー停止
│   ├── install_dependencies.sh # 依存関係インストール
│   ├── start_server.sh    # サーバー起動
│   └── validate_service.sh # デプロイ検証
├── README.md              # プロジェクト概要
├── USAGE.md               # 詳細使用方法
└── QUICK_REFERENCE.md     # このファイル
```

## API仕様

### GET /
**レスポンス例:**
```json
{
  "message": "Hello World from CodePipeline!",
  "timestamp": "2025-01-15T10:30:00.000Z",
  "version": "1.0.2",
  "environment": "production",
  "hostname": "ip-172-31-32-123",
  "status": "success"
}
```

### GET /health
**レスポンス例:**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:30:00.000Z",
  "uptime": 3600.5
}
```

## 設定ファイル

### systemdサービス
**場所:** `/etc/systemd/system/my-python-app.service`

**主要設定:**
- **ユーザー**: ubuntu
- **作業ディレクトリ**: /opt/my-python-app
- **ポート**: 8000
- **メモリ制限**: 512MB
- **自動再起動**: 有効

### ログファイル
- **アプリケーション**: `/var/log/my-python-app/app.log`
- **エラー**: `/var/log/my-python-app/error.log`
- **システム**: `journalctl -u my-python-app`

## 緊急時対応

### サービス完全停止
```bash
sudo systemctl stop my-python-app
sudo pkill -KILL -f "python3.*sampl-app.py"
```

### 強制ポート解放
```bash
sudo lsof -ti:8000 | xargs -r sudo kill -KILL
```

### 設定リセット
```bash
sudo systemctl disable my-python-app
sudo rm /etc/systemd/system/my-python-app.service
sudo systemctl daemon-reload
```

---

📚 **詳細情報**: [USAGE.md](./USAGE.md) | 📖 **プロジェクト概要**: [README.md](./README.md)