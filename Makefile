.PHONY: help dev prod build pull up down restart logs clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

dev: ## Start development environment (with local builds)
	docker compose up --build

prod: ## Start production environment (from Docker Hub)
	docker compose -f docker-compose.prod.yml up -d

build: ## Build all images locally
	docker compose build

pull: ## Pull latest images from Docker Hub
	docker compose -f docker-compose.prod.yml pull

up: ## Start all services
	docker compose up -d

down: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

logs: ## Follow logs from all services
	docker compose logs -f

logs-api: ## Follow API logs
	docker compose logs -f api

logs-dolt: ## Follow Dolt logs
	docker compose logs -f dolt

clean: ## Remove all containers and volumes (WARNING: deletes data!)
	docker compose down -v

clean-client: ## Remove client build volume (forces rebuild)
	docker compose down
	docker volume rm zetteln_client-build || true
	docker compose up -d

rebuild-client: ## Rebuild client with cache busting
	@echo "Stopping services..."
	docker compose down
	@echo "Removing old build volume..."
	docker volume rm zetteln_client-build || true
	@echo "Rebuilding client (no cache)..."
	docker compose build --no-cache client
	@echo "Starting services..."
	docker compose up -d
	@echo "✅ Client rebuilt successfully!"

rebuild-client-fast: ## Rebuild client (use cached layers where possible)
	@echo "Stopping services..."
	docker compose down
	@echo "Removing old build volume..."
	docker volume rm zetteln_client-build || true
	@echo "Rebuilding client (with cache)..."
	CACHEBUST=$$(date +%s) docker compose build client
	@echo "Starting services..."
	docker compose up -d
	@echo "✅ Client rebuilt successfully!"

ps: ## Show running containers
	docker compose ps

stats: ## Show container resource usage
	docker stats

shell-api: ## Open shell in API container
	docker compose exec api sh

shell-dolt: ## Open Dolt SQL shell
	docker compose exec dolt dolt sql

dolt-log: ## View Dolt commit history
	docker compose exec dolt dolt sql -q "SELECT * FROM dolt_log"

dolt-commit: ## Commit current database state (prompts for message)
	@read -p "Commit message: " msg; \
	docker compose exec dolt dolt sql -q "CALL DOLT_COMMIT('-Am', '$$msg')"

test: ## Test API endpoint
	@echo "Testing API endpoint..."
	@curl -s http://localhost:8000/api/version | jq .

update: pull down up ## Update to latest images and restart

health: ## Check health status of all services
	@echo "Checking service health..."
	@docker compose ps --format json | jq -r '.[] | "\(.Name): \(.Health // "N/A")"'
