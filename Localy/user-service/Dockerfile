# Use a multi-stage build strategy

# Stage 1: Build the application using a JDK image with build tools
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

# Gradle Wrapper ?Œì¼, ?¤ì • ?Œì¼, ë¹Œë“œ ?¤í¬ë¦½íŠ¸ ë³µì‚¬
COPY gradlew .
COPY gradle ./gradle
COPY build.gradle .
COPY settings.gradle .

# ? í”Œë¦¬ì??´ì…˜ ?ŒìŠ¤ ì½”ë“œ ë³µì‚¬
COPY src ./src

# gradlew ?¤í–‰ ê¶Œí•œ ë¶€??
RUN chmod +x gradlew

# Gradle???¬ìš©?˜ì—¬ ? í”Œë¦¬ì??´ì…˜ ë¹Œë“œ (?ŒìŠ¤??ê±´ë„ˆ?€)
RUN ./gradlew clean build -x test

# Stage 2: Create the final runtime image using a smaller JRE image
FROM eclipse-temurin:17-jre-alpine

# Patch OS packages before runtime (Trivy HIGH with fixes: libexpat/p11-kit etc.)
RUN apk upgrade --no-cache

WORKDIR /app

# ?°í????´ë? ?”ë²„ê¹…ì„ ?„í•œ curl ?„êµ¬ ?¤ì¹˜ ë°?ë¹„ë£¨??ê³„ì •(appuser) ?ì„±
RUN apk add --no-cache curl && \
    adduser -u 1001 -D appuser

# ë¹Œë“œ ?„ë£Œ??jar ?Œì¼??ë³µì‚¬?????Œìœ ê¶Œì„ appuserë¡?ê°•ì œ ?œí•œ
COPY --chown=appuser:appuser --from=builder /app/build/libs/*.jar app.jar

EXPOSE 9001

# ì»¨í…Œ?´ë„ˆ ?¤í–‰ ê¶Œí•œ??Root?ì„œ appuser(ë¹„ë£¨??ë¡?ê°•ì œ ?„ì„
USER appuser

ENTRYPOINT ["java", "-jar", "app.jar"]