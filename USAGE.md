# Usage Guide

## Starting the Server

### Method 1: Using the startup script
```bash
./start_server.sh
```

### Method 2: Manual start
```bash
# Compile all modules
erlc -o ebin src/*.erl

# Start the server
erl -pa ebin -eval "chat_app:start(8080)" -noshell
```

The server will start on:
- **HTTP**: `http://localhost:8080` (serves frontend)
- **WebSocket**: `ws://localhost:8081` (real-time messaging)

## Using the Chat Application

1. Open your web browser and navigate to `http://localhost:8080`
2. Enter a username (2-20 characters)
3. Click "Join Chat"
4. Start chatting in the "general" room!

## Testing Concurrency

To see Erlang's concurrency in action:

1. Open multiple browser tabs/windows
2. Join with different usernames in each
3. Send messages simultaneously
4. Watch real-time updates across all clients

Each user runs in their own Erlang process, and messages are processed concurrently!

## Stopping the Server

Press `Ctrl+C` twice in the terminal where the server is running, or:

```bash
# In Erlang shell
chat_app:stop().
```

## Troubleshooting

### Port Already in Use
If you get "address already in use" errors:
```bash
# Find and kill the process using the port
lsof -i :8080
kill -9 <PID>

# Or for port 8081
lsof -i :8081
kill -9 <PID>
```

### Connection Issues
- Make sure both ports 8080 and 8081 are available
- Check your firewall settings
- Ensure Erlang is properly installed

### Browser Compatibility
The application requires a modern browser with WebSocket support:
- Chrome/Edge 16+
- Firefox 11+
- Safari 7+

## Development

### Project Structure
```
ErlangBasic/
├── src/                   # Erlang source code
├── priv/static/          # Frontend files
├── ebin/                 # Compiled .beam files
├── start_server.sh       # Startup script
└── README.md            # Documentation
```

### Modifying the Code

After making changes to Erlang files:
```bash
erlc -o ebin src/MODULE_NAME.erl
```

After making changes to frontend files:
Just refresh your browser - no compilation needed!

### Hot Code Reloading

One of Erlang's powerful features is hot code reloading. To reload a module without stopping the server:

```erlang
% In a new Erlang shell connected to the running server
code:purge(module_name).
code:load_file(module_name).
```

## Learning Resources

- [Official Erlang Documentation](https://www.erlang.org/doc/)
- [Learn You Some Erlang](http://learnyousomeerlang.com/)
- [Erlang OTP Principles](https://www.erlang.org/doc/design_principles/des_princ.html)

## Next Steps

Ideas for extending this project:
- Add private messaging between users
- Implement multiple chat rooms
- Add message persistence (database)
- Implement user authentication
- Add file sharing capabilities
- Create a mobile-responsive design
- Add emoji support
- Implement message search
- Add typing indicators
- Create admin functions (kick, ban, etc.)
