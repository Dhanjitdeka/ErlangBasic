# GitHub Pages Deployment Guide

This guide will walk you through deploying the chat application demo to GitHub Pages.

## Prerequisites

- A GitHub account
- This repository pushed to your GitHub account

## Step-by-Step Deployment

### 1. Navigate to Repository Settings

1. Go to your repository on GitHub: `https://github.com/[YourUsername]/ErlangBasic`
2. Click on **Settings** tab (top right of the repository page)

### 2. Access GitHub Pages Settings

1. In the left sidebar, scroll down and click on **Pages**
2. You should see "GitHub Pages" configuration options

### 3. Configure Source

Under "Build and deployment" section:

1. **Source**: Select **Deploy from a branch**
2. **Branch**: 
   - Select `main` (or your default branch)
   - Select `/docs` folder from the dropdown
3. Click **Save**

### 4. Wait for Deployment

- GitHub will automatically build and deploy your site
- This usually takes 1-2 minutes
- You'll see a blue banner saying "GitHub Pages source saved"
- Refresh the page after a minute to see the deployment URL

### 5. Access Your Live Demo

Your chat application will be available at:
```
https://[YourUsername].github.io/ErlangBasic/
```

For example: `https://dhanjitdeka.github.io/ErlangBasic/`

## What Gets Deployed?

The `/docs` folder contains:
- `index.html` - Main page with demo banner
- `style.css` - Styling
- `chat.js` - JavaScript with demo mode
- `README.md` - Documentation

## How Demo Mode Works

When users visit your GitHub Pages site:

1. ✅ Page loads normally
2. ✅ User enters username and clicks "Join Chat"
3. ✅ JavaScript attempts to connect to WebSocket server (port 8081)
4. ✅ Connection fails (no backend on GitHub Pages)
5. ✅ Demo mode automatically activates
6. ✅ User can chat with simulated users

## Troubleshooting

### Site Not Loading

- Wait a few minutes and try again
- Check that you selected the `/docs` folder, not the root
- Verify the branch is correct (usually `main`)

### 404 Error

- Make sure the branch name is correct
- Ensure the `/docs` folder exists in your repository
- Check that all files are committed and pushed

### Demo Mode Not Activating

- Open browser console (F12) to check for errors
- Verify `chat.js` file is loading correctly
- Clear browser cache and try again

## Custom Domain (Optional)

If you want to use a custom domain:

1. In GitHub Pages settings, enter your custom domain
2. Add a `CNAME` file to the `/docs` folder with your domain
3. Configure your DNS provider to point to GitHub Pages

## Updating the Demo

To update the demo after making changes:

1. Make changes to files in `/docs` folder
2. Commit and push to GitHub
3. GitHub Pages will automatically redeploy (1-2 minutes)

## Disabling GitHub Pages

To remove the deployed site:

1. Go to Settings → Pages
2. Under "Source", select **None**
3. Click **Save**

## Local Testing

Before deploying, test the demo locally:

```bash
cd docs
python3 -m http.server 8000
# or
npx http-server -p 8000
```

Open `http://localhost:8000` in your browser.

## Security Notes

- Demo mode runs entirely in the browser
- No sensitive data is transmitted
- Messages are not stored or shared
- Safe to share publicly

## Sharing Your Demo

Once deployed, share the URL with:
- Potential employers (portfolio piece)
- Students learning Erlang
- Anyone interested in the chat interface
- Social media with hashtags: #Erlang #WebDev #ChatApp

## Need Help?

- Check [GitHub Pages documentation](https://docs.github.com/en/pages)
- Open an issue in the repository
- Review the main [README.md](../README.md)

---

**Note**: For the full application with real-time messaging between users, you need to run the Erlang backend server locally. GitHub Pages only hosts the demo mode.
