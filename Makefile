# Tax Filing Microservices - Makefile
# Convenience commands for development and deployment

.PHONY: help build test clean docker-build docker-up docker-down format check deploy

# Default target
help:
	@echo "Tax Filing Microservices - Available commands:"
	@echo "  make build           - Build all services (skip tests)"
	@echo "  make test            - Run all tests (unit + integration)"
	@echo "  make clean           - Clean all build artifacts"
	@echo "  make format          - Format code with Spotless"
	@echo "  make check           - Check code formatting"
	@echo "  make docker-build    - Build all Docker images"
	@echo "  make docker-up       - Start all services with Docker Compose"
	@echo "  make docker-down     - Stop all services"
	@echo "  make docker-logs     - View logs from all containers"
	@echo "  make deploy          - Build and deploy (Docker)"

# Build all services
build:
	@echo "Building all services..."
	./mvnw clean install -DskipTests

# Run all tests
test:
	@echo "Running tests..."
	./mvnw test

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	./mvnw verify -P integration-tests

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	./mvnw clean
	rm -rf target */target

# Format code
format:
	@echo "Formatting code..."
	./mvnw spotless:apply

# Check code formatting
check:
	@echo "Checking code format..."
	./mvnw spotless:check

# Build Docker images
docker-build:
	@echo "Building Docker images..."
	docker-compose build

# Start all services
docker-up:
	@echo "Starting all services..."
	docker-compose up -d
	@echo "Services starting... Access points:"
	@echo "  - API Gateway:    http://localhost:8080"
	@echo "  - Config Server:  http://localhost:8888"
	@echo "  - Auth Service:   http://localhost:8081"
	@echo "  - Filing Service: http://localhost:8082"
	@echo "  - Payment Service: http://localhost:8083"
	@echo "  - Kafka UI:       http://localhost:8090"

# Stop all services
docker-down:
	@echo "Stopping all services..."
	docker-compose down

# View logs
docker-logs:
	docker-compose logs -f

# Deploy (build + docker up)
deploy: build docker-build docker-up
	@echo "Deployment complete!"

# Run specific service locally
run-config:
	./mvnw spring-boot:run -pl config-server

run-gateway:
	./mvnw spring-boot:run -pl api-gateway

run-auth:
	./mvnw spring-boot:run -pl auth-service

run-filing:
	./mvnw spring-boot:run -pl filing-service

run-payment:
	./mvnw spring-boot:run -pl payment-service
