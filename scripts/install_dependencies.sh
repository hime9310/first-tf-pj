#!/bin/bash
echo "[$(date)] 依存関係をインストールしています..."

# エラー時は停止
set -e

# アプリケーションディレクトリに移動
cd /opt/my-python-app

# システムの更新（必要に応じて）
echo "システムパッケージを確認しています..."
apt-get update -qq

# 必要なシステムパッケージの確認とインストール
echo "必要なシステムツールを確認しています..."
required_packages="python3 python3-pip curl net-tools"
for package in $required_packages; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        echo "  $package をインストールしています..."
        apt-get install -y $package
    else
        echo "  ✓ $package は利用可能です"
    fi
done

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

# Python依存関係のインストール
if [ -f "requirements.txt" ] && [ -s "requirements.txt" ]; then
    echo "requirements.txtからPython依存関係をインストールしています..."
    # 非コメント行があるかチェック
    if grep -v '^#' requirements.txt | grep -v '^$' | head -1 > /dev/null; then
        pip3 install --upgrade pip
        pip3 install -r requirements.txt
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

# 簡単な起動テスト（3秒間）
echo "簡単な起動テストを実行しています..."
timeout 3s python3 sampl-app.py > /tmp/app_test.log 2>&1 &
test_pid=$!
sleep 1

if kill -0 $test_pid 2>/dev/null; then
    echo "✓ アプリケーションが正常に起動可能です"
    kill $test_pid 2>/dev/null || true
else
    echo "⚠ アプリケーションの起動テストで問題が発生しました"
    if [ -f "/tmp/app_test.log" ]; then
        echo "テストログ:"
        cat /tmp/app_test.log | head -10
    fi
fi

# 既存のサービスを停止（存在する場合）
if systemctl list-units --type=service | grep -q my-python-app; then
    echo "既存のサービスを停止しています..."
    systemctl stop my-python-app || true
fi

# バージョン情報の表示（存在する場合）
if [ -f "version.json" ]; then
    echo "デプロイメントバージョン情報:"
    cat version.json | head -5
fi

# 環境情報の表示
echo "環境情報:"
echo "  - Python: $(python3 --version)"
echo "  - ユーザー: $(whoami)"
echo "  - 作業ディレクトリ: $(pwd)"
echo "  - ディスク使用量: $(df -h /opt | tail -1 | awk '{print $5}')"
echo "  - メモリ使用量: $(free -h | grep Mem | awk '{print $3"/"$2}')"

echo "[$(date)] 依存関係のインストールが正常に完了しました"