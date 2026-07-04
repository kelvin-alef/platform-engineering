# Local Development Environment

This Docker Compose environment provides a lightweight local development setup for platform users.

Included services:

- PostgreSQL
- Redis
- LocalStack (AWS service emulator)
- Sample application container

Start the environment:

```bash
docker compose up -d
```

Stop the environment:

```bash
docker compose down
```

This setup allows developers to work locally without depending on shared AWS development environments, improving onboarding, reducing costs, and enabling isolated testing.
