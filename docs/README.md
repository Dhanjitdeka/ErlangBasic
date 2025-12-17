# GitHub Pages Demo

This folder contains a **demo version** of the WhatsApp-like Chat Application that can be hosted on GitHub Pages.

## What's Different?

The GitHub Pages version includes all the frontend files (HTML, CSS, JavaScript) with a **demo mode** that simulates the chat functionality without requiring the Erlang backend server.

### Demo Mode Features

- ✅ Works entirely in the browser (no backend required)
- ✅ Simulates multiple users (Alice, Bob, Charlie)
- ✅ Auto-generates responses to your messages
- ✅ Shows the same UI and user experience
- ✅ Perfect for showcasing the frontend design
- ⚠️ Messages are not shared between browser sessions
- ⚠️ No persistent storage (refresh clears data)

## Hosting on GitHub Pages

### Method 1: Using the `docs` Folder (Recommended)

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Pages**
3. Under "Source", select **Deploy from a branch**
4. Under "Branch", select `main` and `/docs` folder
5. Click **Save**
6. Wait a few minutes for deployment
7. Your chat app will be live at: `https://[username].github.io/[repository-name]/`

### Method 2: Using GitHub Actions

If you prefer, you can set up GitHub Actions to deploy automatically. See [GitHub Pages documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site) for more details.

## Files in This Folder

- **index.html** - Main HTML file with demo banner
- **style.css** - Styling (same as original + demo banner styles)
- **chat.js** - JavaScript with demo mode fallback
- **README.md** - This file

## How Demo Mode Works

1. When you open the page, the JavaScript attempts to connect to a WebSocket server
2. If no server is found (like on GitHub Pages), it automatically activates **demo mode**
3. In demo mode:
   - Your messages are stored locally in the browser
   - Simulated users respond to your messages
   - All functionality is simulated client-side

## Running the Full Application

To run the **full application** with the Erlang backend:

1. See the main [README.md](../README.md) in the repository root
2. Start the Erlang server locally
3. Open `http://localhost:8080` to use the real WebSocket server

## Live Demo

Once deployed, you can share the GitHub Pages URL to let anyone try the demo without installing Erlang!

Example: `https://dhanjitdeka.github.io/ErlangBasic/`

## Limitations of Demo Mode

Since GitHub Pages only hosts static files, the demo mode:

- ❌ Cannot connect to real WebSocket servers
- ❌ Cannot share messages between different users/browsers
- ❌ Cannot persist data after page refresh
- ❌ Does not demonstrate Erlang's concurrency features

For the **full experience** with real-time messaging, run the Erlang server locally!

## Development

To test the demo locally:

```bash
# Simple HTTP server (Python 3)
cd docs
python3 -m http.server 8000

# Or using Node.js
npx http-server docs -p 8000
```

Then open `http://localhost:8000` in your browser.
