# =============================================================
# Multi-stage Dockerfile for Spring Boot Application
# Stage 1: Build  |  Stage 2: Runtime (minimal JRE)
# =============================================================

# ---- Stage 1: Build ----
FROM maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /app

# Cache Maven dependencies before copying source
COPY pom.xml .
RUN mvn dependency:go-offline -B --no-transfer-progress

# Copy source and build
COPY src ./src
RUN mvn clean package -DskipTests -B --no-transfer-progress \
    && ls -lh target/*.jar

# ---- Stage 2: Runtime ----
FROM eclipse-temurin:21-jre-alpine

# Security hardening: non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy built artifact
COPY --from=builder /app/target/*.jar app.jar

# Ensure correct ownership
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

# Spring Boot Actuator health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-Dspring.profiles.active=${SPRING_PROFILE:=default}", \
  "-jar", "app.jar"]
