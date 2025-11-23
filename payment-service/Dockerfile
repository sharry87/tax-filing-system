# Multi-stage Dockerfile for Payment Service

# =============================================
# Stage 1: Build
# =============================================
FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /app

# Copy parent POM
COPY pom.xml ../pom.xml
# Copy common-library
COPY common-library ../common-library

# Copy module POM and source
COPY payment-service/pom.xml ./
COPY payment-service/src ./src

# Build the application
RUN mvn clean package -DskipTests -pl :payment-service -am

# =============================================
# Stage 2: Runtime
# =============================================
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Install curl for healthcheck
RUN apk add --no-cache curl

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Expose port
EXPOSE 8083

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=5 \
  CMD curl -f http://localhost:8083/actuator/health || exit 1

# JVM options
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseContainerSupport"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
