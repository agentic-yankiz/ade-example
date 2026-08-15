#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="$repo_root/site/rendered"
chrome_bin="${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
preview_port="${ADE_EXAMPLE_RENDER_PORT:-4178}"
preview_url="http://127.0.0.1:$preview_port"

if [[ ! -x "$chrome_bin" ]]; then
  echo "Google Chrome was not found at $chrome_bin" >&2
  exit 1
fi

mkdir -p "$output_dir"

python3 -m http.server "$preview_port" --bind 127.0.0.1 --directory "$repo_root/site" >/tmp/ade-example-render-server.log 2>&1 &
preview_pid=$!
trap 'kill "$preview_pid" 2>/dev/null || true' EXIT

for _ in 1 2 3 4 5; do
  if curl --silent --fail "$preview_url/" >/dev/null; then
    break
  fi
  sleep 1
done

boards=(
  "command:01-command-center.png"
  "trainings:02-trainings.png"
  "eval:03-eval-drilldown.png"
  "investigation:04-investigation.png"
  "work:05-work-kanban.png"
  "research:06-research-lab.png"
  "context:07-context-studio.png"
  "release:08-release-observation.png"
  "safety:09-safety-gates.png"
  "plan:10-full-plan.png"
)

for item in "${boards[@]}"; do
  board="${item%%:*}"
  filename="${item#*:}"
  "$chrome_bin" \
    --headless=new \
    --disable-gpu \
    --hide-scrollbars \
    --force-device-scale-factor=1 \
    --window-size=1600,1000 \
    --screenshot="$output_dir/$filename" \
    "$preview_url/?board=$board"
done

"$chrome_bin" \
  --headless=new \
  --disable-gpu \
  --hide-scrollbars \
  --force-device-scale-factor=1 \
  --window-size=1400,2640 \
  --screenshot="$output_dir/00-contact-sheet.png" \
  "$preview_url/contact-sheet.html"
