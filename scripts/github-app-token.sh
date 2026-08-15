#!/usr/bin/env bash
# Canonical org copy: mint a short-lived yankihermesapp installation token.
set -euo pipefail

app_id="${YANKI_GITHUB_APP_ID:-${YANKIHERMES_APP_ID:-${GITHUB_APP_ID:-}}}"
installation_id="${YANKI_GITHUB_APP_INSTALLATION_ID:-${YANKIHERMES_INSTALLATION_ID:-${GITHUB_APP_INSTALLATION_ID:-}}}"
owner="${YANKI_GITHUB_APP_OWNER:-${YANKIHERMES_OWNER:-agentic-yankiz}}"
key_path="${YANKI_GITHUB_APP_PRIVATE_KEY_PATH:-${YANKIHERMES_PRIVATE_KEY_PATH:-${GITHUB_APP_PRIVATE_KEY_PATH:-}}}"
api_url="${GITHUB_API_URL:-https://api.github.com}"

if [[ -z "$app_id" || -z "$key_path" || ! -r "$key_path" ]]; then
  echo "GitHub App ID and readable private-key path are required" >&2
  exit 2
fi

base64url() { openssl base64 -A | sed 'y|+/|-_|' | tr -d '='; }
now="$(date +%s)"
header="$(jq -nc '{alg:"RS256",typ:"JWT"}' | base64url)"
payload="$(jq -nc --argjson iat "$((now - 60))" --argjson exp "$((now + 540))" --argjson iss "$app_id" '{iat:$iat,exp:$exp,iss:$iss}' | base64url)"
unsigned="$header.$payload"
signature="$(printf '%s' "$unsigned" | openssl dgst -sha256 -sign "$key_path" -binary | base64url)"
jwt="$unsigned.$signature"

if [[ -z "$installation_id" ]]; then
  installation_id="$(curl -fsSL -H 'Accept: application/vnd.github+json' -H "Authorization: Bearer $jwt" -H 'X-GitHub-Api-Version: 2022-11-28' "$api_url/app/installations" | jq -r --arg owner "$owner" '.[] | select(.account.login == $owner) | .id' | head -n 1)"
fi

curl -fsSL -X POST -H 'Accept: application/vnd.github+json' -H "Authorization: Bearer $jwt" -H 'X-GitHub-Api-Version: 2022-11-28' "$api_url/app/installations/$installation_id/access_tokens" | jq -r '.token'
