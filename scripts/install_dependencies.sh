#!/bin/bash
echo "[$(date)] 依存関係をインストールしています..."

# エラー時は停止
set -e

# アプリケーションディレクトリに移動
cd /opt/my-python-app

# 必要なシステムパッケージの確認とインストール
echo "システム要件を確認しています..."
if ! command -v python3 &> /dev/null; then
    echo "Python3をインストールしています..."
    apt-get update -y
    apt-get install -y python3 python3-pip
fi

# Python環境の確認
echo "Python環境を確認しています..."
python3 --version
echo "Python実行可能ファイル: $(which python3)"

# ディレクトリの権限を正しく設定
echo "ディレクトリの権限を設定しています..."
chown -R ubuntu:ubuntu /opt/my-python-app
find /opt/my-python-app -type d -exec chmod 755 {} \;
find /opt/my-python-app -type f -exec chmod 644 {} \;

# 実行可能ファイルに適切な権限を付与
chmod +x /opt/my-python-app/sampl-app.py
chmod +x /opt/my-python-app/scripts/*.sh

# Python依存関係のインストール（現在は不要だが将来に備えて）
if [ -f "requirements.txt" ] && [ -s "requirements.txt" ]; then
    echo "requirements.txtからPython依存関係をインストールしています..."
    # 非コメント行があるかチェック
    if grep -v '^#' requirements.txt | grep -v '^$' | head -1 > /dev/null; then
        pip3 install --user -r requirements.txt
        echo "Python依存関係のインストールが完了しました"
    else
        echo "requirements.txtにアクティブな依存関係がありません"
    fi
else
    echo "Python依存関係のインストールをスキップします（標準ライブラリのみ使用）"
fi

# ログディレクトリの作成
echo "ログディレクトリを設定しています..."
mkdir -p /var/log/my-python-app
chown ubuntu:ubuntu /var/log/my-python-app
chmod 755 /var/log/my-python-app

# アプリケーションの構文チェック
echo "アプリケーションの構文をチェックしています..."
python3 -m py_compile sampl-app.py
echo "構文チェックが正常に完了しました"

# バージョン情報の表示（存在する場合）
if [ -f "version.json" ]; then
    echo "デプロイメントバージョン情報:"
    cat version.json | head -10  # 長すぎる場合に備えて制限
fi

# 環境情報の表示
echo "環境情報:"
echo "  - Python: $(python3 --version)"
echo "  - ユーザー: $(whoami)"
echo "  - 作業ディレクトリ: $(pwd)"
echo "  - ディスク使用量: $(df -h /opt | tail -1 | awk '{print $5}')"

echo "[$(date)] 依存関係のインストールが正常に完了しました"