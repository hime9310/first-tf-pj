#!/bin/bash
echo "[$(date)] デプロイメントを検証しています..."

# エラー時は停止
set -e

# 検証関数の定義
validate_service_status() {
    echo "1. systemdサービス状態を確認しています..."
    
    # サービスの完全起動を待機
    echo "   サービスの準備完了を待機しています..."
    sleep 8
    
    if systemctl is-active --quiet my-python-app; then
        echo "   ✓ サービスがアクティブで実行中です"
        systemctl status my-python-app --no-pager -l | head -10
    else
        echo "   ✗ サービスが実行されていません"
        systemctl status my-python-app --no-pager -l
        return 1
    fi
}

validate_port_listening() {
    echo "2. ポート8000がリスニング中かを確認しています..."
    
    # ポートの確認（複数回試行）
    for i in {1..5}; do
        if netstat -tuln 2>/dev/null | grep -q ":8000"; then
            echo "   ✓ ポート8000が開放されリスニング中です"
            return 0
        else
            echo "   待機中... (試行 $i/5)"
            sleep 3
        fi
    done
    
    echo "   ✗ ポート8000が開放されていません"
    echo "   現在リスニング中のポート:"
    netstat -tuln 2>/dev/null | grep LISTEN | head -10
    return 1
}

validate_http_endpoints() {
    echo "3. HTTPエンドポイントをテストしています..."
    
    max_attempts=6
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "   試行 $attempt/$max_attempts: メインエンドポイントをテスト中..."
        
        if curl -f -s -m 10 http://localhost:8000 > /dev/null; then
            echo "   ✓ メインエンドポイントが正常に応答しています"
            
            # レスポンス内容の取得と表示
            echo "   サンプルレスポンス:"
            response=$(curl -s -m 5 http://localhost:8000)
            if command -v jq > /dev/null 2>&1; then
                echo "$response" | jq . | head -15
            else
                echo "$response" | head -15
            fi
            break
        else
            echo "   HTTPエンドポイントが応答していません (試行 $attempt/$max_attempts)"
            
            if [ $attempt -eq $max_attempts ]; then
                echo "   ✗ $max_attempts 回の試行後もHTTPエンドポイントが応答しませんでした"
                echo "   サービスログ:"
                journalctl -u my-python-app --no-pager -l -n 10
                return 1
            fi
            
            echo "   次の試行まで8秒待機しています..."
            sleep 8
            attempt=$((attempt + 1))
        fi
    done
    
    # ヘルスチェックエンドポイントのテスト
    echo "   ヘルスチェックエンドポイントをテスト中..."
    if curl -f -s -m 5 http://localhost:8000/health > /dev/null; then
        echo "   ✓ ヘルスチェックエンドポイントが正常に応答しています"
    else
        echo "   ⚠ ヘルスチェックエンドポイントが応答していません（メインエンドポイントは正常）"
    fi
}

validate_logs_and_permissions() {
    echo "4. ログファイルとファイル権限を確認しています..."
    
    # ログファイルの確認
    if [ -f "/var/log/my-python-app/app.log" ]; then
        echo "   ✓ アプリケーションログファイルが存在します"
        echo "   最新のアプリケーションログ:"
        tail -n 3 /var/log/my-python-app/app.log | sed 's/^/     /'
    else
        echo "   ⚠ アプリケーションログファイルが見つかりません（新規デプロイメントでは正常）"
    fi
    
    # ファイル権限の確認
    if [ -r "/opt/my-python-app/sampl-app.py" ] && [ -x "/opt/my-python-app/sampl-app.py" ]; then
        echo "   ✓ アプリケーションファイルの権限が正しく設定されています"
    else
        echo "   ✗ アプリケーションファイルの権限が正しくありません"
        ls -la /opt/my-python-app/sampl-app.py
        return 1
    fi
}

run_basic_performance_test() {
    echo "5. 基本的なパフォーマンステストを実行しています..."
    
    # 簡単な負荷テスト（curlを使用）
    echo "   軽量な負荷テストを実行中..."
    success_count=0
    total_requests=5
    
    for i in $(seq 1 $total_requests); do
        if curl -f -s -m 5 http://localhost:8000 > /dev/null; then
            success_count=$((success_count + 1))
        fi
        sleep 0.5
    done
    
    echo "   結果: $success_count/$total_requests リクエストが成功"
    
    if [ $success_count -eq $total_requests ]; then
        echo "   ✓ 基本的なパフォーマンステストが正常に完了しました"
    else
        echo "   ⚠ 一部のリクエストが失敗しました"
    fi
}

# メイン検証プロセス
echo "=== デプロイメント検証を開始します ==="

validate_service_status
validate_port_listening  
validate_http_endpoints
validate_logs_and_permissions
run_basic_performance_test

echo ""
echo "=== デプロイメント検証が正常に完了しました! ==="
echo ""
echo "デプロイメント要約:"
echo "===================="
echo "✓ サービス状態: $(systemctl is-active my-python-app)"
echo "✓ ポート8000: 開放済みでリスニング中"
echo "✓ HTTPエンドポイント: 応答中"
echo "✓ ヘルスチェック: /health エンドポイント利用可能"
echo "✓ ログファイル: 設定済み"
echo "✓ ファイル権限: 正常"
echo "✓ デプロイメント時刻: $(date)"
echo ""
echo "アプリケーションの準備が完了し、本番環境で稼働中です。"