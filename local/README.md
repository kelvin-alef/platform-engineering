# Isolated Local Development Orchestration

This directory contains a complete local development orchestration environment simulating the target cloud deployment architecture.

The environment boots a functional **Go web application** that actively integrates with the local database, cache, and cloud emulation layers.

---

## Services Included

1. **Go Web Application (`app`)**: Exposes a REST API on port `8080` and dynamically interacts with other services.
2. **PostgreSQL (`postgres`)**: Relational database storage.
3. **Redis (`redis`)**: Cache layer.
4. **LocalStack (`localstack`)**: Emulates AWS services (S3 and SSM Parameter Store) locally.

---

## How it Works

1. On container startup, Docker Compose executes **`init-localstack.sh`** inside the LocalStack container once it is ready.
2. The initialization script provisions an SSM parameter (`/dev/sample-app/ecs_cluster_name`) and creates an S3 bucket (`sample-app-bucket`) containing a sample text file.
3. The Go application uses connection retries to wait for PostgreSQL/Redis/LocalStack to become healthy.
4. The Go application queries database schema tables, registers hit counts, and calls LocalStack to retrieve configuration parameters.

---

## Getting Started

### 1. Launch the Stack
Run the following command in this directory:
```bash
docker compose up -d --build
```

### 2. Verify Application Endpoints

You can verify the active connections by sending requests to the application:

#### A. Basic Status & Endpoints Map
```bash
curl http://localhost:8080/
```

#### B. Complete Health Integration Check
Checks the connectivity of Postgres and Redis:
```bash
curl http://localhost:8080/health
```

#### C. Redis Cache Validation
Increments a hit counter cached in Redis on every call:
```bash
curl http://localhost:8080/hits
```

#### D. PostgreSQL Write & Read Validation
Inserts an audit entry and queries the last 5 logs from PostgreSQL:
```bash
curl http://localhost:8080/db-test
```

#### E. AWS LocalStack S3 & SSM Integration Validation
Fetches the ECS cluster name parameter from SSM and lists files in S3:
```bash
curl http://localhost:8080/aws-check
```

---

## Tearing Down
To stop and clean up volumes:
```bash
docker compose down -v
```
