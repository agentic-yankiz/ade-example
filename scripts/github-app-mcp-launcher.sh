#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
token_script="${YANKI_GITHUB_APP_TOKEN_SCRIPT:-$script_dir/github-app-token.sh}"
image="${GITHUB_MCP_IMAGE:-ghcr.io/github/github-mcp-server}"

if [[ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" || -n "${GITHUB_PAT:-}" || -n "${GH_TOKEN:-}" ]]; then
  echo "Refusing PAT or ambient GitHub token input; GitHub MCP must mint a yankihermesapp installation token." >&2
  exit 2
fi

installation_token="$($token_script)"
if [[ -z "$installation_token" ]]; then
  echo "GitHub App token helper returned an empty installation token." >&2
  exit 1
fi

export GITHUB_PERSONAL_ACCESS_TOKEN="$installation_token"
unset installation_token

exec docker run --interactive --rm \
  --env GITHUB_PERSONAL_ACCESS_TOKEN \
  "$image" stdio
