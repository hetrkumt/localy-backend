$services = @("cart-service", "edge-service", "order-service", "payment-service", "store-service", "user-service")

foreach ($svc in $services) {
    $gradlePath = "C:\Users\dev\LocalyMSAApplicationModernization\Localy-app\Localy\$svc\build.gradle"
    $yamlPath = "C:\Users\dev\LocalyMSAApplicationModernization\Localy-app\Localy\$svc\src\main\resources\application.yml"
    
    $gradleAppend = "
// --- [Phase 1: Observability Injection] ---
dependencies {
    implementation 'io.micrometer:micrometer-tracing-bridge-otel'
    implementation 'io.micrometer:micrometer-registry-prometheus'"
    
    if ($svc -eq "order-service" -or $svc -eq "payment-service") {
        $gradleAppend += "
    // --- [Phase 1: AWS IAM DB Auth & Kafka] ---
    implementation 'software.amazon.jdbc:aws-advanced-jdbc-wrapper:2.3.2'
    implementation 'org.springframework.kafka:spring-kafka'"
    }
    if ($svc -eq "cart-service") {
        $gradleAppend += "
    // --- [Phase 1: Kafka] ---
    implementation 'org.springframework.kafka:spring-kafka'"
    }
    $gradleAppend += "
}
"
    
    [System.IO.File]::AppendAllText($gradlePath, $gradleAppend, [System.Text.Encoding]::UTF8)

    $yamlAppend = "
# --- [Phase 1: Common Observability & Graceful Shutdown Injection] ---
server:
  shutdown: graceful

spring:
  lifecycle:
    timeout-per-shutdown-phase: 45s

management:
  tracing:
    sampling:
      probability: 0.1
  otlp:
    tracing:
      endpoint: ${OTEL_EXPORTER_OTLP_ENDPOINT:http://otel-collector.observability.svc.cluster.local:4318/v1/traces}
  metrics:
    tags:
      application: ${spring.application.name}
"
    
    if ($svc -eq "order-service" -or $svc -eq "payment-service") {
        $yamlAppend += "
# --- [Phase 1: AWS IAM DB Auth (JPA)] ---
spring:
  datasource:
    url: jdbc:aws-wrapper:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:localy}
    hikari:
      max-lifetime: 600000
"
    }
    if ($svc -eq "store-service") {
        $yamlAppend += "
# --- [Phase 1: R2DBC Connection Lifecycle] ---
spring:
  r2dbc:
    pool:
      max-life-time: 10m
"
    }
    
    $yamlAppend += "
management:
  endpoints:
    web:
      exposure:
        include: health,prometheus
"
    
    [System.IO.File]::AppendAllText($yamlPath, $yamlAppend, [System.Text.Encoding]::UTF8)
}
Write-Output "Patch completed successfully."
