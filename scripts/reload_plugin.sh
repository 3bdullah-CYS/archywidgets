#!/usr/bin/env bash
set -euo pipefail

readonly SHELL_CLI="/usr/share/omarchy/bin/omarchy-shell"
readonly SHELL_RESTART="/usr/share/omarchy/bin/omarchy-restart-shell"
readonly PLUGIN_ID="io.github.3bdullah-cys.archywidgets"

if [[ ! -x "$SHELL_RESTART" ]]; then
  printf 'ArchyWidgets reload failed: Omarchy shell restart helper is unavailable.\n' >&2
  exit 1
fi

"$SHELL_RESTART"

shell_ready=false
for ((attempt = 0; attempt < 50; attempt++)); do
  if "$SHELL_CLI" shell ping >/dev/null 2>&1; then
    shell_ready=true
    break
  fi
  sleep 0.2
done

if [[ "$shell_ready" != true ]]; then
  printf 'ArchyWidgets reload failed: the restarted Omarchy shell did not respond within ten seconds.\n' >&2
  exit 1
fi

plugin_list="$("$SHELL_CLI" shell listPlugins)"
if [[ "$plugin_list" != *"$PLUGIN_ID"* ]]; then
  printf 'ArchyWidgets reload failed: %s is not present after the shell restart.\n' "$PLUGIN_ID" >&2
  exit 1
fi

printf 'ArchyWidgets plugin source reloaded through an Omarchy shell restart.\n'
