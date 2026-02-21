.PHONY: setup build test lint format clean help devcontainer devcontainer devcontainer-clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'

setup: ## Install dependencies and pre-commit hooks
	uv sync
	uv run pre-commit install

build: ## Build the package
	uv build

test: ## Run tests with coverage
	uv run pytest --cov

lint: ## Run linter and format check
	uv run ruff check .
	uv run ruff format --check .

format: ## Auto-format code
	uv run ruff format .
	uv run ruff check --fix .

clean: ## Remove build artifacts
	rm -rf dist/ build/ *.egg-info/
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete

devcontainer: ## Clean and rebuild devcontainer
	.devcontainer/clean.sh
	.devcontainer/build.sh
