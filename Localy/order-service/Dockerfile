# Use a multi-stage build strategy

# Stage 1: Build the application using a JDK image with build tools
# 빌드 환경 설정 - JDK와 빌드 도구(Gradle 또는 Maven)가 포함된 이미지 사용
FROM eclipse-temurin:17-jdk-alpine AS builder
# JDK 17 Alpine Linux 이미지 사용 (가볍고 좋음)

# 애플리케이션 소스 코드가 위치할 작업 디렉토리 설정
WORKDIR /app

# Gradle Wrapper 파일, 설정 파일, 빌드 스크립트 복사
# 의존성 캐싱을 위해 소스 코드보다 먼저 복사하는 것이 좋음
COPY gradlew .
COPY gradle ./gradle
COPY build.gradle .

# 애플리케이션 소스 코드 복사
COPY src ./src

# gradlew 실행 권한 부여
RUN chmod +x gradlew

# Gradle을 사용하여 애플리케이션 빌드
# -x test는 테스트 실행을 건너뛰어 빌드 시간 단축 (이미지 빌드 시에는 일반적으로 테스트 스킵)
RUN ./gradlew clean build -x test

# Stage 2: Create the final runtime image using a smaller JRE image
# 실행 환경 설정 - 애플리케이션 실행에 필요한 JRE만 포함된 더 가벼운 이미지 사용
FROM eclipse-temurin:17-jre-alpine
# JRE 17 Alpine Linux 이미지 사용

# 최종 이미지의 작업 디렉토리 설정
WORKDIR /app

# 빌드 스테이지에서 생성된 실행 가능한 JAR 파일 복사
# build/libs/*.jar 경로는 Gradle의 기본 빌드 결과 JAR 파일 위치입니다.
# Maven 프로젝트라면 target/*.jar 일 것입니다.
COPY --from=builder /app/build/libs/*.jar app.jar

# 애플리케이션이 리스닝할 포트 노출 (실제 네트워크 설정에 필수적이지는 않으나 문서화 목적)
# 이 포트 번호는 각 서비스의 application.yml 파일에 설정된 server.port와 일치해야 합니다!
EXPOSE 8091

# 컨테이너 시작 시 실행될 명령어 설정
# 복사한 app.jar 파일을 java -jar 명령어로 실행합니다.
ENTRYPOINT ["java", "-jar", "app.jar"]

# 선택 사항: 보안 강화를 위해 root 사용자가 아닌 별도 사용자 사용
# RUN adduser -u 1001 -D appuser
# USER appuser