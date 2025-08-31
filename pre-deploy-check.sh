#!/bin/bash
# Pre-deployment check script
# CodePipelineデプロイ前の事前チェックスクリプト

echo "=== CodePipeline デプロイ前チェック ==="
echo "実行時刻: $(date)"
echo ""

# エラー時は停止
set -e

# 1. Python環境の確認
echo "1. Python環境をチェックしています..."
python3 --version
echo "   ✓ Python3が利用可能です"

# 2. 必要なファイルの存在確認
echo ""
echo "2. 必要なファイルをチェックしています..."
required_files=(
    "sampl-app.py"
    "buildspec.yml" 
    "appspec.yml"
    "requirements.txt"
    "scripts/stop_server.sh"
    "scripts/install_dependencies.sh"
    "scripts/start_server.sh"
    "scripts/validate_service.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✓ $file"
    else
        echo "   ✗ $file が見つかりません"
        exit 1
    fi
done

# 3. スクリプトファイルの実行権限確認
echo ""
echo "3. スクリプトファイルの権限をチェックしています..."
script_files=(
    "scripts/stop_server.sh"
    "scripts/install_dependencies.sh"
    "scripts/start_server.sh"
    "scripts/validate_service.sh"
)

for script in "${script_files[@]}"; do
    if [ -x "$script" ]; then
        echo "   ✓ $script (実行可能)"
    else
        echo "   ⚠ $script に実行権限を付与しています..."
        chmod +x "$script"
        echo "   ✓ $script (権限付与完了)"
    fi
done

# 4. Python構文チェック
echo ""
echo "4. Python構文をチェックしています..."
python3 -m py_compile sampl-app.py
echo "   ✓ sampl-app.py の構文チェック完了"

if [ -f "test_app.py" ]; then
    python3 -m py_compile test_app.py
    echo "   ✓ test_app.py の構文チェック完了"
fi

# 5. YAML設定ファイルの基本チェック
echo ""
echo "5. YAML設定ファイルをチェックしています..."

# buildspec.yml の基本チェック
if grep -q "version:" buildspec.yml && grep -q "phases:" buildspec.yml; then
    echo "   ✓ buildspec.yml の基本構造が正常です"
else
    echo "   ✗ buildspec.yml の構造に問題があります"
    exit 1
fi

# appspec.yml の基本チェック
if grep -q "version:" appspec.yml && grep -q "files:" appspec.yml && grep -q "hooks:" appspec.yml; then
    echo "   ✓ appspec.yml の基本構造が正常です"
else
    echo "   ✗ appspec.yml の構造に問題があります"
    exit 1
fi

# 6. 基本テストの実行
echo ""
echo "6. 基本テストを実行しています..."
if [ -f "test_app.py" ]; then
    python3 test_app.py
    echo "   ✓ 基本テストが正常に完了しました"
else
    echo "   ⚠ test_app.py が見つかりません。テストをスキップします"
fi

# 7. プロジェクト情報の表示
echo ""
echo "7. プロジェクト情報:"
echo "   - 作業ディレクトリ: $(pwd)"
echo "   - ファイル数: $(find . -type f | wc -l)"
echo "   - Pythonファイル数: $(find . -name "*.py" | wc -l)"
echo "   - シェルスクリプト数: $(find . -name "*.sh" | wc -l)"

# 8. Git情報（利用可能な場合）
echo ""
echo "8. Git情報:"
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "   - ブランチ: $(git branch --show-current 2>/dev/null || echo 'N/A')"
    echo "   - 最新コミット: $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
    echo "   - 変更されたファイル: $(git status --porcelain 2>/dev/null | wc -l || echo 'N/A')"
else
    echo "   - Gitリポジトリではありません"
fi

echo ""
echo "=== デプロイ前チェックが正常に完了しました! ==="
echo "このプロジェクトはCodePipelineでのデプロイ準備が整っています。"
echo ""