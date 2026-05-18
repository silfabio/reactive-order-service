# # Reactive Order Service

A high-performance, non-blocking order management microservice built with Kotlin and Reactive Programming.

## 🚀 Tech Stack

- **Runtime:** Kotlin & JDK 21
- **Framework:** Spring Boot 3.x (WebFlux)
- **Persistence:** R2DBC with PostgreSQL
- **Messaging:** Apache Kafka (Event-driven architecture)
- **Database Migration:** Flyway
- **Build Tool:** Gradle (Kotlin DSL)
- **Testing:** JUnit 5, MockK, Kotest
- **Diagramming:** Mermaid.js

## 🏛️ Architecture

The architecture is designed to be cloud-native, with a clear separation between the local development environment and the production goal. The diagram below illustrates the current state, the local observability stack, and the future production environment on AWS.

<div align="center">

![Architecture Diagram](docs/architecture/architecture.svg)

</div>

## 🛠 Architecture Highlights

- **Reactive Pipeline:** End-to-end non-blocking flow from the API layer to the database.
- **Event-Driven:** Asynchronous order processing and status updates via Kafka.
- **Scalability:** Designed to handle high-concurrency workloads with minimal thread blocking.
- **Diagrams as Code:** The architecture diagram is maintained as code using Mermaid.js, ensuring it stays in sync with the project's evolution.

## 💎 Quality Standards

- **Functional Style:** Leveraging Kotlin's expressive syntax and functional programming patterns.
- **Clean Code:** Adhering to SOLID principles and a clear separation of concerns.
- **Validation:** Robust request validation using Spring Boot Validation.

## 🏁 Getting Started

### 1. Prerequisites
- **Java 21** (Required for the JVM Toolchain)
- **Docker & Docker Compose**
- **Node.js & npm** (For rendering the architecture diagram)

### 2. Start Infrastructure
Spin up PostgreSQL, Kafka, Prometheus, Zipkin, and Grafana:

```sh
docker compose up -d
```

### 3. Run the Application
Start the Spring Boot service from your IDE.

## ✍️ Diagrams as Code

This project uses Mermaid.js to maintain the architecture diagram as code. This ensures the documentation is version-controlled and easy to update.

For detailed instructions on setup and rendering, see the [**Architecture README**](docs/architecture/README.md).

### Quick Render Command
To update the diagram after making changes to the source file (`docs/architecture/architecture.mmd`), navigate to the architecture directory and run the rendering script:

```sh
cd docs/architecture
npm run render
```

## ⌨️ Useful Commands Cheat Sheet

### Infrastructure Management

| Action | Command |
| :--- | :--- |
| Start all services (detached) | `docker compose up -d` |
| Stop all services | `docker compose stop` |
| Stop and remove containers | `docker compose down` |
| Full Reset (Clean volumes) | `docker compose down -v --remove-orphans` |
| View Infrastructure Logs | `docker compose logs -f` |
| View specific service logs | `docker compose logs -f kafka` |

### Application Development
| Action | Command |
| :--- | :--- |
| Run Unit & Integration Tests | `./gradlew test` |
| Build Executable JAR | `./gradlew build` |
| Clean Build Assets | `./gradlew clean` |

### Troubleshooting
If the application fails to connect to Kafka or Postgres on first boot:
1. Ensure containers are healthy: `docker compose ps`
2. Check for port conflicts (5432, 9092, 8080)
3. Verify the "Service Connection" labels in `docker-compose.yml`

## 🌐 Local Services & Dashboards

Once the infrastructure is up and the application is running, you can access these local services:

- **Spring Boot Application:** http://localhost:8080
- **Swagger UI (API Docs):** http://localhost:8080/swagger-ui.html
- **OpenAPI Spec (JSON):** http://localhost:8080/v3/api-docs
- **Spring Boot Actuator:** http://localhost:8080/actuator
- **Prometheus:** http://localhost:9090
- **Prometheus Targets:** http://localhost:9090/targets
- **Grafana:** http://localhost:3000 (Default login: `REDACTED`/`REDACTED`)
- **Zipkin Tracing:** http://localhost:9411
- **PostgreSQL:** `localhost:5432` (User: `user`, Password: `REDACTED`, DB: `orders_db`)
