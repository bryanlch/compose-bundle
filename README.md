# NestJS Microservices with RabbitMQ and Docker

This repository defines a development and production environment for running multiple NestJS microservices using Docker, RabbitMQ as a broker (and message queue), and PostgreSQL or MySQL via TypeORM. It also supports Swagger documentation per service.

---

## 📁 Structure

```
root-project/
│
├── docker-compose.dev.yml        # Local development
├── docker-compose.prod.yml       # Production (PM2 support)
├── .env.dev                      # RabbitMQ configuration for local
├── .gitignore                    # Ignore build artifacts, .env, etc.
│
├── microservicio1/
│   ├── Dockerfile
│   ├── Dockerfile.dev
│   ├── .env.example
│   └── src/
│
└── microservicio2/
    ├── Dockerfile
    ├── Dockerfile.dev
    ├── .env.example
    └── src/
```

---

## 🚀 Getting Started

### 📦 Production (Server with PM2)

```bash
cp .env.dev .env
docker-compose -f docker-compose.prod.yml up --build -d
pm2 start ecosystem.config.js --env production
```

### 📦 Develop (Server with PM2)

```bash
cp .env.dev .env
docker-compose -f docker-compose.dev.yml up -d
pm2 start ecosystem.config.js --env development
pm2 save
pm2 startup
```

### 🧪 Local Development

```bash
cp .env.dev .env
docker-compose -f docker-compose.dev.yml up --build
```

---

## 🔁 RabbitMQ UI Access

Once running, visit:  
📍 `http://localhost:15672`  
Login with:

- **Username:** `admin`  
- **Password:** `admin123`

---

## ➕ Adding a New Microservice

1. Create a new folder `microservicioX`
2. Add `Dockerfile`, `Dockerfile.dev`, `.env.example`
3. Include it in both compose files (`docker-compose.dev.yml` and `docker-compose.prod.yml`):

**Production:**

```yaml
  microservice-*:
    build:
      context: ./microservice-*
      dockerfile: Dockerfile
    container_name: container_name
    depends_on:
      - rabbitmq
    environment:
      RABBITMQ_URI: ${RABBITMQ_URI}
    command: ["pm2-runtime", "dist/main.js"]
```

**Development:**

```yaml
  microservice-*:
    build:
      context: ./microservice-*
      dockerfile: Dockerfile.dev
    volumes:
      - ./microservice:/app
      - /app/node_modules
    depends_on:
      - rabbitmq
    environment:
      RABBITMQ_URI: ${RABBITMQ_URI}
    command: npm run start:dev
```

4. Use same `RABBITMQ_URI` and `.env` strategy

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
```

You can place a `.gitignore` inside each microservice as well to ignore `node_modules`, `dist`, etc.

---

Happy coding! 🎯
