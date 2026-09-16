# ==============================================================================
# Stage 1: Build the application using Maven and JDK 17
# ==============================================================================
FROM maven:3.9.6-eclipse-temurin-17-alpine AS builder
WORKDIR /build

# Cache dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build executable JAR
COPY src ./src
RUN mvn clean package -DskipTests

# ==============================================================================
# Stage 2: Production-ready minimal JRE runtime
# ==============================================================================
FROM eclipse-temurin:17-jre-alpine
LABEL maintainer="DevOps Team" \
      description="Automated CI/CD Pipeline Containerized Application"

WORKDIR /app

# Run as non-root user for security best practices
RUN addgroup -S devopsgroup && adduser -S devopsuser -G devopsgroup

# Copy compiled artifact from builder stage
COPY --from=builder /build/target/devops-cicd-app.jar app.jar
RUN chown -R devopsuser:devopsgroup /app

USER devopsuser

# Expose standard application port
EXPOSE 8080

# Built-in health check using Spring Actuator
HEALTHCHECK --interval=30s --timeout=5s --start-period=25s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Launch Spring Boot application
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
