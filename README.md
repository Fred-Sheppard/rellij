# Rellij

<img width="3032" height="1928" alt="image" src="https://github.com/user-attachments/assets/9941975a-4a0b-4c4b-87dc-57814737d6d1" />

A command-line fuzzy-finder that allows zellij sessions to be easily ressurrected.

## Prerequisites
- A fork of zellij that supports `zellij ls --active` and `zellij pretty-print-sessions`
- fzf

## Usage
Rellij demonstrates the following behaviour:
- If there are is one active session with no clients connected,
  it will automatically attach to this session
- If there are:
  - multiple active sessions with no clients
  - or all sessions have clients attached,
  - or there are no active sessions
 
  
then the fuzzy picker will open.
- The fuzzy picker allows you to hover over each session, both active and dead, and see their session layout
  and connected clients.
- Selecting a session will attach zellij to that session.
- If zellij is already running, the script will exit silently, meaning it is safe to put in a `.bashrc`.
