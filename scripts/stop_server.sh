#!/bin/bash
echo "[$(date)] アプリケーションを停止しています..."

# エラー時も継続実行するよう設定
set +e

# systemdサービスの停止（グレースフル）
echo "systemdサービスを停止しています..."
if systemctl is-active --quiet my-python-app; then
    echo "サービスが実行中です。停止を開始します..."
    systemctl stop my-python-app
    
    # 停止完了を待機（最大30秒）
    timeout=30
    while [ $timeout -gt 0 ] && systemctl is-active --quiet my-python-app; do
        echo "サービス停止を待機中... (残り${timeout}秒)"
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if systemctl is-active --quiet my-python-app; then
        echo "警告: サービスが正常に停止しませんでした。強制終了を試みます..."
        systemctl kill my-python-app
        sleep 3
    fi
else
    echo "サービスは実行されていませんでした"
fi

# サービスの無効化（起動時自動開始を防ぐ）
if systemctl is-enabled --quiet my-python-app 2>/dev/null; then
    echo "サービスの自動起動を無効化しています..."
    systemctl disable my-python-app 2>/dev/null
fi

# 残存プロセスのクリーンアップ
echo "残存するプロセスをチェックしています..."
if pgrep -f "python3.*sampl-app.py" > /dev/null; then
    echo "残存するPythonプロセスを終了しています..."
    pkill -TERM -f "python3.*sampl-app.py"
    sleep 5
    
    # まだ残っている場合は強制終了
    if pgrep -f "python3.*sampl-app.py" > /dev/null; then
        echo "強制終了を実行しています..."
        pkill -KILL -f "python3.*sampl-app.py"
        sleep 2
    fi
fi

# ポート使用状況の確認とクリーンアップ
echo "ポート8000の使用状況を確認しています..."
if netstat -tuln 2>/dev/null | grep -q ":8000"; then
    echo "ポート8000がまだ使用中です。プロセスを特定して終了します..."
    lsof -ti:8000 2>/dev/null | xargs -r kill -TERM 2>/dev/null || true
    sleep 3
    
    # まだ使用中の場合は強制終了
    if netstat -tuln 2>/dev/null | grep -q ":8000"; then
        echo "強制的にポートを解放しています..."
        lsof -ti:8000 2>/dev/null | xargs -r kill -KILL 2>/dev/null || true
        sleep 2
    fi
fi

# 最終確認
if netstat -tuln 2>/dev/null | grep -q ":8000"; then
    echo "警告: ポート8000がまだ使用されています"
    netstat -tuln | grep ":8000" || true
else
    echo "ポート8000が正常に解放されました"
fi

echo "[$(date)] アプリケーションの停止が完了しました"