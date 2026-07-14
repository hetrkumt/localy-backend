# Use a multi-stage build strategy

# Stage 1: Build the application using a JDK image with build tools
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

# Gradle Wrapper 파일, 설정 파일, 빌드 스크립트 복사
COPY gradlew .
COPY gradle ./gradle
COPY build.gradle .
COPY settings.gradle .

# 애플리케이션 소스 코드 복사
COPY src ./src

# gradlew 실행 권한 부여
RUN chmod +x gradlew

# Gradle을 사용하여 애플리케이션 빌드 (테스트 건너뜀)
RUN ./gradlew clean build -x test

# Stage 2: Create the final runtime image using a smaller JRE image
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# 런타임 내부 디버깅을 위한 curl 도구 설치 및 비루트 계정(appuser) 생성
RUN apk add --no-cache curl && \
    adduser -u 1001 -D appuser

# 빌드 완료된 jar 파일을 복사할 때 소유권을 appuser로 강제 제한
COPY --chown=appuser:appuser --from=builder /app/build/libs/*.jar app.jar

EXPOSE 9001

# 컨테이너 실행 권한을 Root에서 appuser(비루트)로 강제 위임
USER appuser

ENTRYPOINT ["java", "-jar", "app.jar"]