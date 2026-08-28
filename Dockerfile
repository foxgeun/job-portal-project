# ── Runtime Stage ──────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# 보안: non-root 사용자 생성
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# 빌드 결과물 복사 (CI에서 이미 빌드된 JAR 파일 이용)
COPY backend/build/libs/job-portal.jar app.jar

# 로그 디렉토리
RUN mkdir -p /var/log/app && chown appuser:appgroup /var/log/app

USER appuser

EXPOSE 8080

# 메모리 최적화 JVM 옵션
ENTRYPOINT ["java", \
    "-Xms256m", "-Xmx512m", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-jar", "app.jar"]
