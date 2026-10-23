#!/usr/bin/env bash
set -euo pipefail

SP_NAME="${1:-}"
SP_SERV="${2:-}"
TENANT="${3:-}"
KEY_FIND="${4:-}"
IAC_CMD="${5:-}"
ACR_FQDN="${6:-}"

if [ -z "${SP_NAME}" ] || [ -z "${SP_SERV}" ] || [ -z "${TENANT}" ]; then
  echo "❌ Error: Missing required arguments."
  echo "Usage: $(basename "$0") <sp_name> <sp_service_name> <tenant_id> [key_find_cmd] [iac_cmd]"
  exit 1
fi

echo "🔐 Extracting pipeline credentials from macOS Keychain..."
# Safely extract credentials using key_find tool
APP_ID=$(${KEY_FIND} -a "${SP_NAME}-app-id" -s "${SP_SERV}" -w 2>/dev/null || true)
SECRET=$(${KEY_FIND} -a "${SP_NAME}-secret" -s "${SP_SERV}" -w 2>/dev/null || true)

if [ -z "${APP_ID}" ] || [ -z "${SECRET}" ]; then
  echo "❌ Error: Service Principal credentials not found. Run 'make sp-create-*' first."
  exit 1
fi

# Sanitize home directory path in IAC command for Docker compatibility
IAC="${IAC_CMD/\~\//${HOME}/}"

echo "🤝 Authenticating as '${SP_NAME}'..."
${IAC} az login --service-principal -u "${APP_ID}" -p "${SECRET}" --tenant "${TENANT}" > /dev/null

if [ -n "${ACR_FQDN}" ]; then
  echo "🐳 Authenticating Docker CLI to Container Registry '${ACR_FQDN}'..."
  echo "${SECRET}" | docker login "${ACR_FQDN}" --username "${APP_ID}" --password-stdin > /dev/null
fi

echo "✅ Logged in as Service Principal: ${APP_ID}"