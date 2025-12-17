#!/bin/bash
# Startup script for the chat server

cd "$(dirname "$0")"

# Compile all Erlang modules
echo "Compiling Erlang modules..."
erlc -o ebin src/*.erl

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

echo "Starting chat server..."
echo ""

# Start Erlang with the chat application
erl -pa ebin -eval "chat_app:start(8080)" -noshell
