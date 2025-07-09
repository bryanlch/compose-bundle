# NestJS Microservices with RabbitMQ and Docker

This repository defines a development and production environment for running multiple NestJS microservices using Docker, RabbitMQ as a broker (and message queue), and PostgreSQL or MySQL via TypeORM. It also supports Swagger documentation per service.

---

## 📁 Structure

```
.
├── docker-compose.yml
├── docker-compose.override.yml   # Used automatically in development
├── microservice-1/
│   └── Dockerfile
│   └── src/...
├── microservice-2/
│   └── Dockerfile
│   └── src/...
└── README.md
```

---

## 🚀 Getting Started

### 🧪 Development Mode

Uses volume mounting and `start:dev` for live reload via `docker-compose.override.yml`.

```bash
docker-compose up --build
```

This will:

- Start RabbitMQ
- Start each microservice with `npm run start:dev`
- Mount source code from local folder
- Reload services on code change

### 🔒 Production Mode

Runs each microservice using `npm run start` without mounting the code.

```bash
docker-compose -f docker-compose.yml up --build
```

This ignores `override.yml` and uses the `start` command for performance and isolation.

---

## 🧠 Switching Between `start` and `start:dev` via ENV

Instead of defining the command in `docker-compose.override.yml`, you can set the command dynamically in your `Dockerfile`:

```Dockerfile
CMD ["npm", "run", "${NEST_MODE}"]
```

Then set the environment variable in `docker-compose`:

```yaml
environment:
  - NEST_MODE=start:dev  # or "start" in production
```

This approach allows a single `Dockerfile` to be used for all environments.

---

## 🔁 RabbitMQ UI Access

Once running, visit:  
📍 `http://localhost:15672`  
Login with:

- **Username:** `admin`  
- **Password:** `admin123`

---

## ➕ Adding a New Microservice

1. Create a new folder like `microservice-3`
2. Add a `Dockerfile` inside it
3. Register it in `docker-compose.yml`:

```yaml
  microservice-3:
    build:
      context: ./microservice-3
    environment:
      RABBITMQ_URI: amqp://admin:admin123@rabbitmq:5672
    depends_on:
      - rabbitmq
```

4. (Optional) Add override for development in `docker-compose.override.yml`:

```yaml
  microservice-3:
    volumes:
      - ./microservice-3:/app
      - /app/node_modules
    command: npm run start:dev
    ports:
      - "3003:3000"
```

---

## ✅ Important Notes

- You must define the proper `start` and `start:dev` scripts in each service:

```json
"scripts": {
  "start": "node dist/main",
  "start:dev": "nest start --watch"
}
```

- Don't forget to expose Swagger if needed (e.g., `@nestjs/swagger` with `@Controller('docs')`)
- Use `.env` files to manage service-specific configs like database credentials and load them with `@nestjs/config`

---

## 📦 Useful Commands

| Command | Description |
|--------|-------------|
| `docker-compose up` | Start all services in development |
| `docker-compose down` | Stop and clean up containers |
| `docker-compose -f docker-compose.yml up` | Start services in production |
| `docker-compose build` | Rebuild the services |
| `docker-compose logs -f` | Watch real-time logs |
| `docker exec -it <container> bash` | Access a container’s shell |

---

## 📁 Suggested `.gitignore` for root folder

This ignores everything except the microservices and Docker files:

```
# Ignore everything
*

# Except these:
!docker-compose.yml
!docker-compose.override.yml
!README.md
!microservice-1/**
!microservice-2/**
```

You can place a `.gitignore` inside each microservice as well to ignore `node_modules`, `dist`, etc.

---

Happy coding! 🎯