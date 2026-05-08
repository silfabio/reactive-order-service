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

## 🛠 Architecture Highlights

- **Reactive Pipeline:** End-to-end non-blocking flow from the API layer to the database.
- **Event-Driven:** Asynchronous order processing and status updates via Kafka.
- **Scalability:** Designed to handle high-concurrency workloads with minimal thread blocking.

## 💎 Quality Standards

- **Functional Style:** Leveraging Kotlin's expressive syntax and functional programming patterns.
- **Clean Code:** Adhering to SOLID principles and a clear separation of concerns.
- **Validation:** Robust request validation using Spring Boot Validation.

## 🏁 Getting Started

### 1. Prerequisites
- **Java 21** (Required for the JVM Toolchain)
- **Docker & Docker Compose**

### 2. Start Infrastructure
Spin up PostgreSQL, Kafka, Prometheus, Zipkin, and Grafana:

### 3. Run the Application
Start the Spring Boot service:

## ⌨️ Useful Commands Cheat Sheet

### Infrastructure Management

| Action | Command |
| :--- | :--- |
| Start all services (detached) | `docker compose up -d` |
| Stop all services | `docker compose stop` |
| Stop and remove containers | `docker compose down` |
| Full Reset (Clean volumes) | `docker compose down -v --remove-orphans` |
| View Infrastructure Logs | `docker compose logs -f` |
| View specific service logs | `docker compose logs -f my-kafka` |

### Application Development
| Action | Command |
| :--- | :--- |
| Run Unit & Integration Tests | `./gradlew test` |
| Build Executable JAR | `./gradlew build` |
| Clean Build Assets | `./gradlew clean` |
| Check Dependency Updates | `./gradlew dependencyUpdates` |

### Troubleshooting
If the application fails to connect to Kafka or Postgres on first boot:
1. Ensure containers are healthy: `docker compose ps`
2. Check for port conflicts (5432, 9092, 8080)
3. Verify the "Service Connection" labels in `docker-compose.yml`

## 🌐 Local Services & Dashboards

Once the infrastructure is up and the application is running, you can access these local services:

- **Spring Boot Application:** http://localhost:8080
- **Spring Boot Actuator:** http://localhost:8080/actuator
- **Prometheus:** http://localhost:9090
- **Prometheus Targets:** http://localhost:9090/targets (Verify scraping status)
- **Grafana:** http://localhost:3000 (Default login: `admin`/`admin`)
- **Zipkin Tracing:** http://localhost:9411
- **PostgreSQL:** `localhost:5432` (User: `user`, Password: `password`, DB: `orders_db`)

## 🗺️ Roadmap & Future Enhancements

This project serves as a strong foundation. The following features are planned for future iterations to evolve it into a fully production-grade microservice:

-   **📖 API Documentation:** Integrate `SpringDoc OpenAPI` to automatically generate and host interactive API documentation (Swagger UI).
-   **📊 Custom Metrics:** Enhance observability by adding custom business metrics with Micrometer (e.g., `orders.created.count`, `orders.processing.time`).
-   **💪 Resilience:** Implement fault tolerance patterns using `Resilience4j` (e.g., `CircuitBreaker` for downstream service calls, `Retry` for transient failures).
-   **☁️ Infrastructure as Code (IaC):** Manage cloud infrastructure (e.g., on AWS) using `Terraform` and test it locally with `LocalStack`.
-   **🔒 Secret Management:** Externalize secrets (database passwords, API keys) from configuration files into `HashiCorp Vault`.
-   **🚀 CI/CD Pipeline:** Automate testing, building, and deployment using `GitHub Actions`.
