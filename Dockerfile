FROM eclipse-temurin:21-jre-jammy
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1001 appgroup \
    && useradd --uid 1001 --gid 1001 --no-create-home appuser
WORKDIR /app
COPY --chown=appuser:appgroup build/libs/reactive-order-service-*.jar app.jar
EXPOSE 8080 5005
HEALTHCHECK --interval=10s --timeout=5s --start-period=60s --retries=10 \
  CMD curl -sf http://localhost:8080/actuator/health || exit 1
USER appuser
ENTRYPOINT ["java", \
  "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005", \
  "-jar", "app.jar"]
