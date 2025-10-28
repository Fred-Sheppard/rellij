#!/usr/bin/env bash
# Requires a zellij fork with:
# zellij print-session-layout <session_name>
# zellij ls --active (optional: will grep for EXITED otherwise, accuracy may be reduced)

# Zellij is already attached
if [[ "$ZELLIJ" == "0" ]]; then
  exit 0
fi

# Use ZELLIJ_BIN environment variable if set, otherwise use 'zellij' from PATH
ZELLIJ_BIN="${ZELLIJ_BIN:-zellij}"

if ! command -v $ZELLIJ_BIN &>/dev/null; then
  echo "zellij executable not found at [$ZELLIJ_BIN]"
  exit 1
fi

# Early validation: Check if pretty-print-session command exists
if ! $ZELLIJ_BIN pretty-print-session --help &>/dev/null; then
  echo "Error: 'zellij pretty-print-session' command not found or not supported." >&2
  echo "This script requires a zellij fork with the pretty-print-session feature." >&2
  exit 1
fi

# Check if --active flag is supported and set the appropriate command
if $ZELLIJ_BIN ls --help 2>&1 | grep -q -- '--active'; then
  active_sessions_cmd="$ZELLIJ_BIN ls --short --active"
else
  active_sessions_cmd="$ZELLIJ_BIN ls --short | grep -v EXITED"
fi

# Function to select and attach to a session
select_and_attach() {
  local border_label="$1"
  # Explanation:
  # Print the session layout for this session name
  # Followed by Attached Clients: <Number of Clients>
  # tail skips the headers
  # wc counts the lines
  # xargs removes the whitespace
  preview_cmd="$ZELLIJ_BIN pretty-print-session {1} && \
        echo -n 'Attached Clients: ' && \
        o=\$($ZELLIJ_BIN --session {1} action list-clients 2>&1); \
        [[ \$(echo \"\$o\" | head -1) == *\"not found\"* ]] && echo 0 || echo \$((\$(echo \"\$o\" | wc -l) - 1))"

  session=$($ZELLIJ_BIN ls --no-formatting --reverse | fzf \
    --border rounded \
    --preview "$preview_cmd" \
    --preview-label "Session Preview" \
    --border-label "$border_label" | awk '{print $1}')

  if [ -n "$session" ]; then
    $ZELLIJ_BIN attach "$session"
  else
    $ZELLIJ_BIN
  fi
}

# Get all active sessions
active_sessions=$(eval "$active_sessions_cmd" 2>/dev/null)
exit_code=$?

if [ -z "$active_sessions" ]; then
  select_and_attach "No active sessions"
  exit 1
fi

# Array to store sessions without clients
sessions_without_clients=()

# Parse session names and check each for existing clients
while IFS= read -r session; do
  # Get clients for this session
  output=$($ZELLIJ_BIN --session "$session" action list-clients 2>/dev/null)

  # Count clients (lines after header)
  client_count=$(echo "$output" | tail -n +2 | grep -c '^')

  # If no clients, add to array
  if [ "$client_count" -eq 0 ]; then
    sessions_without_clients+=("$session")
  fi
done <<<"$active_sessions"

# Check how many sessions without clients we have
session_count=${#sessions_without_clients[@]}

if [ "$session_count" -eq 0 ]; then
  select_and_attach "No sessions found without clients attached"
  exit 1
elif [ "$session_count" -eq 1 ]; then
  # Only one session without clients, connect automatically
  session="${sessions_without_clients[0]}"
  echo "Attaching to session: $session"
  exec $ZELLIJ_BIN attach "$session"
else
  select_and_attach "Multiple active sessions found"
fi
