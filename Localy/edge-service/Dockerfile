# Multi-stage build with dependency-layer cache + Non-Root runtime (Wave 1+2)

FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app

COPY gradlew .
COPY gradle ./gradle
COPY build.gradle .
COPY settings.gradle .
RUN chmod +x gradlew \
 && ./gradlew dependencies --no-daemon

COPY src ./src
RUN ./gradlew clean build -x test --no-daemon

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

RUN adduser -u 1001 -D appuser
COPY --chown=appuser:appuser --from=builder /app/build/libs/*.jar app.jar

EXPOSE 9000
USER appuser
ENTRYPOINT ["java", "-jar", "app.jar"]
