# Python Web アプリケーション - AWS CodePipeline デモ

AWS CodePipelineを使用した自動CI/CDデプロイメントのデモンストレーション用Pythonアプリケーションです。

## 🎯 このプロジェクトについて

**GitHubからEC2への自動デプロイメント**を実現するCI/CDパイプラインの学習・検証用プロジェクトです。

### 何ができるか
- GitHub にコードをプッシュすると自動的にEC2にデプロイされる
- シンプルなJSON APIサーバーが稼働する（ポート8000）
- ヘルスチェック機能でサービス監視ができる
- 本番環境レベルの安定稼働（systemdサービス化）

### CI/CDフロー
```
GitHub Push → CodePipeline → CodeBuild → CodeDeploy → EC2 → 本番稼働
```

### 設計思想
- **学習重視**: CI/CDパイプラインの理解を深める
- **軽量**: 外部依存なし、すぐに動作する
- **実用的**: 本番環境でも使える品質

## 🛠 技術スタック

| 項目 | 技術 |
|------|------|
| **アプリケーション** | Python 3.9+ (標準ライブラリのみ) |
| **CI/CD** | AWS CodePipeline + CodeBuild + CodeDeploy |
| **インフラ** | AWS EC2 (Ubuntu) |
| **ソース管理** | GitHub |

## 📁 プロジェクト構造

```
first-tf-pj/
├── sampl-app.py           # メインアプリケーション
├── buildspec.yml          # ビルド設定
├── appspec.yml            # デプロイ設定
├── scripts/               # デプロイスクリプト
└── docs/                  # ドキュメント
```

## ✨ 主な機能

- **JSON API**: `/` (メイン情報) と `/health` (ヘルスチェック)
- **自動デプロイ**: GitHubプッシュで自動実行
- **サービス管理**: systemdによる安定稼働
- **ログ管理**: 詳細なログ出力とエラーハンドリング

## 🚀 クイックスタート

### 1. ローカルで試す
```bash
git clone <repository-url>
cd first-tf-pj
python3 sampl-app.py
```
→ http://localhost:8000/ でアクセス

### 2. AWS環境にデプロイ
1. GitHubリポジトリを作成
2. AWS CodePipelineを設定
3. EC2インスタンスを準備
4. コードをプッシュ → 自動デプロイ

### 3. 動作確認
```bash
curl http://your-ec2-ip:8000/        # メイン情報
curl http://your-ec2-ip:8000/health  # ヘルスチェック
```

**期待されるレスポンス例:**
```json
{
  "message": "Hello World from CodePipeline!",
  "status": "success",
  "deployment_info": { ... }
}
```

## 📚 詳細ドキュメント

このREADMEでは概要を説明しています。詳細な情報は以下のドキュメントを参照してください：

### 📖 [USAGE.md - 詳細な使用方法ガイド](./USAGE.md)
- CI/CDパイプラインの詳細フロー
- ステップバイステップのデプロイメント手順
- 運用・監視方法
- トラブルシューティング
- 開発者向けガイド

### ⚡ [QUICK_REFERENCE.md - クイックリファレンス](./QUICK_REFERENCE.md)
- 基本コマンド一覧
- よくある問題の解決方法
- 緊急時対応手順

## 📋 前提条件

- AWS アカウント
- GitHub アカウント
- EC2 インスタンス（Ubuntu 20.04以上）
- Python 3.9以上（ローカル開発時）

## 🤝 貢献

プロジェクトへの貢献を歓迎します！

### プルリクエスト前のチェックリスト
- [ ] `python3 test_app.py` でテストが通ること
- [ ] `python3 -m py_compile sampl-app.py` で構文チェック完了
- [ ] ローカルでアプリケーションが正常に動作すること
- [ ] 変更内容に応じてドキュメントを更新すること

### 開発者向け情報
詳細な開発ガイドラインは [USAGE.md](./USAGE.md) の「開発者向けガイド」セクションを参照してください。