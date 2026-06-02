#!/usr/bin/env bash
# Runs a SonarQube analysis against the local SonarQube instance using Docker.
# Reads host URL and token from sonar-project.local.properties (gitignored).
set -euo pipefail

PROPS_FILE="sonar-project.local.properties"

if [[ ! -f "$PROPS_FILE" ]]; then
  echo "ERROR: '$PROPS_FILE' not found."
  echo "Copy 'sonar-project.local.properties.example' to '$PROPS_FILE' and fill in your token."
  exit 1
fi

HOST_URL=$(grep -E '^sonar\.host\.url=' "$PROPS_FILE" | cut -d= -f2-)
TOKEN=$(grep -E '^sonar\.(token|login)=' "$PROPS_FILE" | head -1 | cut -d= -f2-)

if [[ -z "$HOST_URL" || -z "$TOKEN" ]]; then
  echo "ERROR: Both 'sonar.host.url' and 'sonar.token' must be set in '$PROPS_FILE'."
  exit 1
fi

echo "==> Building project..."
./gradlew build

echo "==> Running SonarQube analysis against $HOST_URL ..."
docker run --rm \
  -v "$PWD:/usr/src" \
  sonarsource/sonar-scanner-cli:5 \
  -Dsonar.projectBaseDir=/usr/src \
  -Dsonar.host.url="$HOST_URL" \
  -Dsonar.token="$TOKEN"

echo "==> Analysis complete. View results at $HOST_URL"
