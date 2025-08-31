# Makefile for Python CodePipeline Demo App

.PHONY: help test run clean check install-deps pre-deploy

# デフォルトターゲット
help:
	@echo "利用可能なコマンド:"
	@echo "  make run          - アプリケーションを起動"
	@echo "  make test         - 基本テストを実行"
	@echo "  make test-full    - 統合テスト付きで実行"
	@echo "  make check        - 構文チェックのみ実行"
	@echo "  make pre-deploy   - デプロイ前の総合チェック"
	@echo "  make clean        - 一時ファイルをクリーンアップ"
	@echo "  make install-deps - 依存関係をインストール（現在は不要）"

# アプリケーションの起動
run:
	@echo "アプリケーションを起動しています..."
	python3 sampl-app.py

# 基本テストの実行
test:
	@echo "基本テストを実行しています..."
	python3 test_app.py

# 統合テスト付きで実行
test-full:
	@echo "統合テスト付きでテストを実行しています..."
	python3 test_app.py --integration

# 構文チェック
check:
	@echo "Python構文をチェックしています..."
	python3 -m py_compile sampl-app.py
	python3 -m py_compile test_app.py
	@echo "構文チェックが完了しました"

# 依存関係のインストール（現在は標準ライブラリのみなので実質的に何もしない）
install-deps:
	@echo "依存関係を確認しています..."
	@if [ -f requirements.txt ] && grep -v '^#' requirements.txt | grep -v '^$$' | head -1 > /dev/null; then \
		echo "requirements.txtから依存関係をインストールしています..."; \
		pip3 install --user -r requirements.txt; \
	else \
		echo "インストールする依存関係はありません（標準ライブラリのみ使用）"; \
	fi

# クリーンアップ
clean:
	@echo "一時ファイルをクリーンアップしています..."
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.pyo" -delete
	@echo "クリーンアップが完了しました"

# 開発環境のセットアップ
dev-setup: install-deps check
	@echo "開発環境のセットアップが完了しました"

# デプロイ前の総合チェック
pre-deploy:
	@echo "デプロイ前の総合チェックを実行しています..."
	./pre-deploy-check.sh

# CI/CD用のテスト（buildspec.ymlで使用される形式）
ci-test: check test
	@echo "CI/CDテストが完了しました"