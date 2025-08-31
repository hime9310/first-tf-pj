#!/bin/bash
echo "[$(date)] アプリケーションを開始しています..."

# エラー時は停止
set -e

cd /opt/my-python-app

# 既存のサービスファイルをバックアップ（存在する場合）
if [ -f "/etc/systemd/system/my-python-app.service" ]; then
    echo "既存のサービスファイルをバックアップしています..."
    cp /etc/systemd/system/my-python-app.service /etc/systemd/system/my-python-app.service.backup
fi

# systemdサービスファイルの作成
echo "systemdサービスファイルを作成しています..."
cat << 'EOF' > /etc/systemd/system/my-python-app.service
[Unit]
Description=CodePipeline Demo Python Application
Documentation=https://github.com/your-repo/first-tf-pj
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/my-python-app
ExecStart=/usr/bin/python3 /opt/my-python-app/sampl-app.py
ExecReload=/bin/kill -HUP $MAINPID

# 再起動設定（本番環境では慎重に）
Restart=on-failure
RestartSec=10
StartLimitInterval=300
StartLimitBurst=3

# ログ設定
StandardOutput=append:/var/log/my-python-app/app.log
StandardError=append:/var/log/my-python-app/error.log

# 環境変数
Environment=ENV=production
Environment=PORT=8000
Environment=PYTHONPATH=/opt/my-python-app
Environment=PYTHONUNBUFFERED=1

# セキュリティ設定
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/my-python-app /var/log/my-python-app

# リソース制限
MemoryMax=512M
TasksMax=50

[Install]
WantedBy=multi-user.target
EOF

# systemd設定の再読み込み
echo "systemdデーモンを再読み込みしています..."
systemctl daemon-reload

# サービスの有効化（起動時自動開始）
echo "サービスを有効化しています..."
systemctl enable my-python-app

# サービスの開始
echo "サービスを開始しています..."
systemctl start my-python-app

# サービス開始の待機と確認（より短い間隔でチェック）
echo "サービスの開始を待機しています..."

# 段階的な確認（1秒間隔で15回）
for i in {1..15}; do
    if systemctl is-active --quiet my-python-app; then
        echo "サービスが正常に開始されました (${i}秒後に確認完了)"
        
        # 追加でポートの確認
        echo "ポートの開放を確認しています..."
        for j in {1..5}; do
            if netstat -tuln 2>/dev/null | grep -q ":8000" || ss -tuln 2>/dev/null | grep -q ":8000"; then
                echo "ポート8000が正常に開放されました (${j}秒後に確認完了)"
                break
            else
                echo "ポート開放を待機中... (${j}/5秒)"
                sleep 1
            fi
        done
        break
    else
        echo "サービス開始を待機中... (${i}/15秒)"
        sleep 1
    fi
    
    if [ $i -eq 15 ]; then
        echo "サービスの開始に失敗しました（15秒タイムアウト）"
        echo "詳細なエラー情報:"
        systemctl status my-python-app --no-pager -l
        echo "最新のログ:"
        journalctl -u my-python-app --no-pager -l -n 20
        echo "ファイル権限確認:"
        ls -la /opt/my-python-app/sampl-app.py
        exit 1
    fi
done

# サービス状態の詳細表示
echo "サービス状態の確認:"
systemctl status my-python-app --no-pager -l

# ポートの確認
echo "ポート8000の確認:"
if netstat -tuln | grep -q ":8000"; then
    echo "ポート8000が正常にリスニング中です"
else
    echo "警告: ポート8000がリスニングしていません"
fi

# 最新のログを表示
echo "最新のアプリケーションログ:"
if [ -f "/var/log/my-python-app/app.log" ]; then
    tail -n 5 /var/log/my-python-app/app.log
else
    echo "アプリケーションログファイルがまだ作成されていません"
fi

echo "[$(date)] アプリケーションが正常に開始されました!"