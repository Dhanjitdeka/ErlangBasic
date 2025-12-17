# Quick Start Guide

## Try the Application in Two Ways

### 🌐 Option 1: GitHub Pages Demo (No Installation)

**Best for:** Quick preview, sharing with others, portfolio showcase

1. Visit: `https://[username].github.io/ErlangBasic/`
2. Enter a username
3. Click "Join Chat"
4. Start chatting with simulated users!

**Features:**
- ✅ No installation required
- ✅ Works immediately in browser
- ✅ Shows full UI/UX
- ⚠️ Simulated users only
- ⚠️ No real-time messaging between browsers

---

### 🚀 Option 2: Full Application (With Erlang Backend)

**Best for:** Learning Erlang, understanding concurrency, real multi-user chat

#### Prerequisites
- Erlang/OTP 25+ installed
- Terminal/command line access

#### Installation & Running

```bash
# 1. Clone the repository
git clone https://github.com/Dhanjitdeka/ErlangBasic.git
cd ErlangBasic

# 2. Start the server (easy way)
./start_server.sh

# OR start manually:
erlc -o ebin src/*.erl
erl -pa ebin -eval "chat_app:start(8080)" -noshell
```

#### Access the Application

Open multiple browser tabs/windows to:
```
http://localhost:8080
```

**Features:**
- ✅ Real-time messaging between all connected users
- ✅ See Erlang's concurrency in action
- ✅ Multiple processes handling users
- ✅ Fault tolerance with OTP supervision
- ✅ ETS storage for messages
- ✅ True distributed chat experience

---

## Comparison

| Feature | GitHub Pages Demo | Full Application |
|---------|------------------|------------------|
| Installation | None | Erlang required |
| Setup Time | Instant | ~5 minutes |
| Multi-user Chat | ❌ Simulated | ✅ Real |
| Real-time Sync | ❌ | ✅ |
| Learning Erlang | ❌ | ✅ |
| Portfolio Demo | ✅ | ❌ |
| Share URL | ✅ | ❌ |
| Offline Work | ✅ | ❌ |

---

## Testing Scenarios

### Demo Mode (GitHub Pages)
1. ✅ Test the UI design
2. ✅ Preview message styling
3. ✅ Check responsive layout
4. ✅ Share with non-technical users
5. ✅ Portfolio demonstration

### Full Application
1. ✅ Open 3-5 browser tabs
2. ✅ Send messages from different tabs
3. ✅ Watch real-time updates
4. ✅ Test user join/leave
5. ✅ Learn Erlang concepts
6. ✅ Experiment with code changes

---

## Next Steps

### For Learners
1. Try the GitHub Pages demo first
2. If interested, install Erlang
3. Run the full application locally
4. Study the Erlang source code
5. Modify and experiment!

### For Developers
1. Deploy to GitHub Pages for portfolio
2. Run locally for development
3. Read [ARCHITECTURE.md](../ARCHITECTURE.md)
4. Explore OTP patterns
5. Contribute improvements

---

## Troubleshooting

### GitHub Pages Demo
- **Not loading?** Check if Pages is enabled in Settings
- **Demo not working?** Clear browser cache, check console (F12)

### Full Application
- **Server won't start?** Verify Erlang is installed: `erl -version`
- **Can't connect?** Check ports 8080/8081 are not in use
- **No messages?** Ensure WebSocket port 8081 is accessible

---

## Resources

- 📖 [Main README](../README.md) - Detailed information
- 🏗️ [Architecture Guide](../ARCHITECTURE.md) - System design
- 📚 [Deployment Guide](DEPLOYMENT.md) - GitHub Pages setup
- 💻 [Source Code](../src/) - Erlang implementation

---

## Questions?

- Open an issue on GitHub
- Check existing documentation
- Review code comments

**Happy Chatting! 🎉**
