import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    kotlin("jvm") version "1.9.24"
    kotlin("plugin.spring") version "1.9.24"
    id("org.springframework.boot") version "3.3.0"
    id("io.spring.dependency-management") version "1.1.5"
}

group = "com.fabio.orderservice"
version = "0.0.1-SNAPSHOT"
description = "reactive-order-service"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    // Web & Validation
    implementation("org.springframework.boot:spring-boot-starter-webflux")
    implementation("org.springframework.boot:spring-boot-starter-validation")

    // Kotlin & Coroutines
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    implementation("io.projectreactor.kotlin:reactor-kotlin-extensions")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-reactor")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")

    // Persistence
    implementation("org.springframework.boot:spring-boot-starter-data-r2dbc")
    runtimeOnly("org.postgresql:postgresql") // Required for Flyway JDBC migrations
    runtimeOnly("org.postgresql:r2dbc-postgresql") // Reactive driver

    // Database Migrations
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")

    // Kafka
    implementation("org.springframework.cloud:spring-cloud-stream")
    implementation("org.springframework.cloud:spring-cloud-stream-binder-kafka")

    // Observability
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    runtimeOnly("io.micrometer:micrometer-registry-prometheus") // For Prometheus metrics
    implementation("io.micrometer:micrometer-tracing-bridge-otel") // OpenTelemetry tracing bridge
    implementation("io.opentelemetry:opentelemetry-exporter-zipkin") // Zipkin exporter

    // R2DBC Proxy (for debugging/logging R2DBC queries)
    implementation("io.r2dbc:r2dbc-proxy")

    // Local Development Utilities
    developmentOnly("org.springframework.boot:spring-boot-docker-compose")

    // Testing
    testImplementation("org.springframework.boot:spring-boot-starter-test") {
        // Exclude Mockito to prevent classpath conflicts if MockK is preferred
        exclude(group = "org.mockito", module = "mockito-core")
        exclude(group = "org.mockito", module = "mockito-junit-jupiter")
    }
    testImplementation("io.projectreactor:reactor-test") // For reactive testing
    implementation("io.projectreactor:reactor-tools") // For debugging reactive streams

    // Kotlin Test Frameworks
    testImplementation("io.kotest:kotest-runner-junit5:5.9.0")
    testImplementation("io.kotest:kotest-assertions-core:5.9.0")
    testImplementation("io.kotest.extensions:kotest-extensions-spring:1.3.0")

    // Spring Cloud Stream Testing
    testImplementation("org.springframework.cloud:spring-cloud-stream-test-binder")

    // Embedded Database for Testing
    testImplementation("io.zonky.test:embedded-database-spring-test:2.8.0")
    testImplementation("io.zonky.test:embedded-postgres:2.2.2")
    testImplementation("org.springframework.boot:spring-boot-test-autoconfigure")

    // Mocking Frameworks
    testImplementation("io.mockk:mockk:1.13.10")
    testImplementation("com.ninja-squad:springmockk:4.0.2")
}

dependencyManagement {
    imports {
        mavenBom("org.springframework.cloud:spring-cloud-dependencies:2023.0.0")
    }
}

kotlin {
    compilerOptions {
        freeCompilerArgs.add("-Xjsr305=strict") // Treat JSR-305 annotations as strict for nullability
        jvmTarget.set(JvmTarget.JVM_21)
    }
}

tasks.withType<Test> {
    useJUnitPlatform()
    jvmArgs("-XX:+EnableDynamicAgentLoading")
}

configurations.all {
    resolutionStrategy.eachDependency {
        // Fix for commons-compress CVE
        if (requested.group == "org.apache.commons" && requested.name == "commons-compress") {
            useVersion("1.26.1")
        }
    }
}
