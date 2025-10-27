#!/usr/bin/env bash

# Requires a zellij fork with:
# zellij ls --active
# zellij print-session-layout <session_name>

# Use ZELLIJ environment variable if set, otherwise use 'zellij' from PATH
ZELLIJ="${ZELLIJ:-zellij}"

# Function to select and attach to a session
select_and_attach() {
    local border_label="$1"
    # Explanation:
    # Print the session layout for this session name
    # Followed by Attached Clients: <Number of Clients>
    # tail skips the headers
    # wc counts the lines
    # xargs removes the whitespace
    preview_cmd='$ZELLIJ print-session-layout {1} && \
        echo -n "Attched Clients: " && \
        $ZELLIJ --session {1} action list-clients 2>/dev/null | tail -n +2 | wc -l | xargs'

    $ZELLIJ ls --no-formatting | fzf \
        --border rounded \
        --preview "$preview_cmd" \
        --preview-label "Session Preview" \
        --border-label "$border_label" | awk '{print $1}' | xargs -o $ZELLIJ attach
}

# Get all active sessions
active_sessions=$($ZELLIJ ls --short --active 2>/dev/null)

if [ -z "$active_sessions" ]; then
    select_and_attach "No active sessions"
    exit 1
fi

# Array to store sessions without clients
sessions_without_clients=()

# Parse session names and check each for existing clients
while IFS= read -r session; do
    # Get clients for this session
    output=$($ZELLIJ --session "$session" action list-clients 2>/dev/null)

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
    exec $ZELLIJ attach "$session"
else
    select_and_attach "Multiple active sessions found"
fi
