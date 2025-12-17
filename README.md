# ErlangBasic - WhatsApp-like Chat Application

A real-time chat application built with **Erlang backend** and **vanilla JavaScript frontend**, demonstrating Erlang's powerful concurrency model and OTP principles.

## 🎯 Project Overview

This project is designed as a **beginner-friendly** introduction to Erlang, showcasing:
- Process-based concurrency (each user in their own process)
- OTP supervisor patterns for fault tolerance
- WebSocket communication for real-time messaging
- ETS (Erlang Term Storage) for fast in-memory data storage
- Clean, production-ready code architecture

## 🏗️ Architecture

### Backend (Erlang)

The application follows WhatsApp-inspired architecture with these key components:

```
┌─────────────────────────────────────────────┐
│           chat_supervisor (OTP)             │
│  (Monitors and restarts failed processes)   │
└────────┬────────────┬────────────┬──────────┘
         │            │            │
    ┌────▼───┐   ┌────▼───┐   ┌────▼───────┐
    │ User   │   │ Room   │   │  Message   │
    │Manager │   │Manager │   │   Router   │
    └────────┘   └────────┘   └────────────┘
         │            │            │
    ┌────▼────────────▼────────────▼────┐
    │      ETS Tables (Fast Storage)    │
    │  - Users    - Rooms   - Messages  │
    └───────────────────────────────────┘
```

#### Key Modules

1. **chat_app** - Entry point, starts all services
2. **chat_supervisor** - OTP supervisor managing child processes
3. **chat_user_manager** - Manages connected users (one process per user)
4. **chat_room_manager** - Handles chat rooms and memberships
5. **chat_message_router** - Routes messages with concurrent processing
6. **chat_websocket_handler** - WebSocket protocol implementation
7. **chat_http_server** - Serves static files
8. **json_util** - Simple JSON encoder/decoder (no external dependencies)

#### Concurrency Model

- **Process-per-user**: Each connected user runs in a separate Erlang process
- **Concurrent message routing**: Each message is processed in its own process
- **Supervisor tree**: Automatic restart of failed components
- **ETS tables**: Shared memory for fast, concurrent data access

### Frontend (HTML/JavaScript)

Pure vanilla JavaScript implementation:
- WebSocket client for real-time communication
- Responsive, WhatsApp-inspired UI
- Real-time user list updates
- Message history display
- Clean, modern design

## 🚀 Getting Started

### Prerequisites

- Erlang/OTP (version 25 or higher recommended)
- Modern web browser with WebSocket support

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Dhanjitdeka/ErlangBasic.git
cd ErlangBasic
```

2. Start the server:
```bash
./start_server.sh
```

Or manually:
```bash
# Compile
erlc -o ebin src/*.erl

# Run
erl -pa ebin -eval "chat_app:start(8080)" -noshell
```

3. Open your browser:
```
http://localhost:8080
```

### Ports

- **8080**: HTTP server (serves frontend)
- **8081**: WebSocket server (real-time messaging)

## 🌐 GitHub Pages Demo

Want to try the app without installing Erlang? We've got you covered!

**[Try the Live Demo →](https://dhanjitdeka.github.io/ErlangBasic/)** *(Once deployed)*

The demo version runs entirely in your browser with simulated backend functionality. Perfect for:
- Quick preview of the UI/UX
- Testing the frontend without server setup
- Sharing with others easily

**Note:** The demo mode simulates chat functionality but doesn't provide real-time messaging between users. For the full experience with Erlang's concurrency, run the server locally!

### Deploying to GitHub Pages

This repository includes a `docs/` folder ready for GitHub Pages deployment:

1. Go to **Settings** → **Pages** on GitHub
2. Select **Deploy from a branch**
3. Choose `main` branch and `/docs` folder
4. Your demo will be live at `https://[username].github.io/ErlangBasic/`

See [docs/README.md](docs/README.md) for more details.

## 📖 How It Works

### User Connection Flow

1. User opens web page and enters username
2. WebSocket connection established to port 8081
3. Server creates dedicated process for user
4. User automatically joins "general" room
5. User list updated for all connected clients

### Message Flow

1. User sends message through WebSocket
2. Message router spawns process to handle message
3. Message stored in ETS table (history)
4. Router fetches room members
5. Message delivered concurrently to all members
6. Each client receives and displays message

### Concurrency Example

When 100 users send messages simultaneously:
- 100 separate user processes handle connections
- Up to 100 message routing processes spawn
- All operations run in parallel
- No blocking or waiting
- System remains responsive

## 🎓 Learning Points

### For Erlang Beginners

1. **OTP Behaviors**: See gen_server and supervisor in action
2. **Process Management**: Learn process spawning and message passing
3. **Fault Tolerance**: Observe supervisor restart strategies
4. **Concurrency**: Understand the actor model
5. **ETS Tables**: Learn efficient shared storage
6. **Pattern Matching**: See Erlang's powerful pattern matching
7. **Hot Code Loading**: Erlang's ability to update code without stopping

### Clean Code Principles

- **Single Responsibility**: Each module has one clear purpose
- **Documentation**: Comprehensive comments and @doc annotations
- **Error Handling**: Proper error messages and graceful failures
- **Modularity**: Loosely coupled, highly cohesive modules
- **Naming**: Clear, descriptive function and variable names

## 🔧 Code Structure

```
ErlangBasic/
├── src/                          # Erlang source files
│   ├── chat_app.erl             # Application entry point
│   ├── chat_supervisor.erl      # OTP supervisor
│   ├── chat_user_manager.erl    # User management
│   ├── chat_room_manager.erl    # Room management
│   ├── chat_message_router.erl  # Message routing
│   ├── chat_websocket_handler.erl # WebSocket handling
│   ├── chat_http_server.erl     # HTTP server
│   └── json_util.erl            # JSON utilities
├── priv/static/                 # Frontend files
│   ├── index.html               # Main HTML
│   ├── chat.js                  # JavaScript client
│   └── style.css                # Styles
├── ebin/                        # Compiled .beam files
├── start_server.sh              # Startup script
└── README.md                    # This file
```

## 🧪 Testing

Try these scenarios to see concurrency in action:

1. **Multiple Users**: Open multiple browser tabs, each with different username
2. **Concurrent Messages**: Send messages from multiple tabs simultaneously
3. **User Join/Leave**: Watch real-time user list updates
4. **Fault Tolerance**: Try stopping a process and see supervisor restart it

## 🔒 Production Considerations

This implementation includes production-ready patterns:

- ✅ Supervisor tree for fault tolerance
- ✅ Process isolation (crash in one user doesn't affect others)
- ✅ Efficient ETS storage
- ✅ Proper error handling
- ✅ Input validation and sanitization
- ✅ Clean shutdown procedures
- ✅ Configurable ports
- ✅ Comprehensive logging

For full production deployment, consider adding:
- SSL/TLS encryption
- Authentication and authorization
- Message persistence (database)
- Load balancing
- Rate limiting
- Monitoring and metrics

## 📚 Further Learning

### Erlang Concepts Demonstrated

- **Processes**: Lightweight concurrent processes
- **Message Passing**: Send/receive between processes
- **Pattern Matching**: Powerful data structure matching
- **OTP**: Open Telecom Platform framework
- **gen_server**: Generic server behavior
- **Supervisor**: Process supervision and restart
- **ETS**: In-memory storage tables
- **Hot Code Swapping**: Update code without stopping server

### Recommended Reading

- [Learn You Some Erlang](http://learnyousomeerlang.com/)
- [Erlang OTP Documentation](https://www.erlang.org/doc/)
- [Designing for Scalability with Erlang/OTP](https://www.oreilly.com/library/view/designing-for-scalability/9781449361556/)

## 🤝 Contributing

This is a learning project. Feel free to:
- Add features (private messages, file sharing, etc.)
- Improve error handling
- Enhance the UI
- Add tests
- Optimize performance

## 📝 License

This project is open source and available for educational purposes.

## 🙏 Acknowledgments

Inspired by WhatsApp's architecture and Erlang's philosophy of "let it crash" and fault-tolerant design.

---

**Happy Learning! 🚀**

For questions or suggestions, please open an issue on GitHub.

