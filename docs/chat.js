/**
 * WhatsApp-like Chat Client
 * Pure vanilla JavaScript - no frameworks
 * Handles WebSocket communication with Erlang backend OR runs in demo mode
 */

class ChatClient {
    constructor() {
        this.ws = null;
        this.username = null;
        this.currentRoom = 'general';
        this.isConnected = false;
        this.demoMode = false;
        this.demoUsers = [];
        this.demoMessages = [];
        
        this.initElements();
        this.attachEventListeners();
    }

    /**
     * Initialize DOM element references
     */
    initElements() {
        // Screens
        this.loginScreen = document.getElementById('login-screen');
        this.chatScreen = document.getElementById('chat-screen');
        
        // Login elements
        this.usernameInput = document.getElementById('username-input');
        this.joinButton = document.getElementById('join-button');
        this.loginError = document.getElementById('login-error');
        
        // Chat elements
        this.messagesContainer = document.getElementById('messages-container');
        this.messageInput = document.getElementById('message-input');
        this.sendButton = document.getElementById('send-button');
        this.usersList = document.getElementById('users-list');
        this.userCount = document.getElementById('user-count');
        this.currentUsernameDisplay = document.getElementById('current-username');
        this.logoutButton = document.getElementById('logout-button');
        this.connectionStatus = document.getElementById('connection-status');
    }

    /**
     * Attach event listeners to UI elements
     */
    attachEventListeners() {
        // Login
        this.joinButton.addEventListener('click', () => this.handleJoin());
        this.usernameInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.handleJoin();
        });
        
        // Chat
        this.sendButton.addEventListener('click', () => this.handleSendMessage());
        this.messageInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.handleSendMessage();
        });
        
        // Logout
        this.logoutButton.addEventListener('click', () => this.handleLogout());
    }

    /**
     * Handle user joining the chat
     */
    handleJoin() {
        const username = this.usernameInput.value.trim();
        
        if (!username) {
            this.showLoginError('Please enter a username');
            return;
        }
        
        if (username.length < 2) {
            this.showLoginError('Username must be at least 2 characters');
            return;
        }
        
        this.username = username;
        this.loginError.textContent = '';
        this.joinButton.disabled = true;
        this.joinButton.textContent = 'Connecting...';
        
        this.connect();
    }

    /**
     * Connect to WebSocket server OR activate demo mode
     */
    connect() {
        try {
            // Try to connect to WebSocket server
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const host = window.location.hostname || 'localhost';
            const wsUrl = `${protocol}//${host}:8081`;
            
            console.log('Attempting to connect to WebSocket:', wsUrl);
            this.ws = new WebSocket(wsUrl);
            
            // Set a timeout to detect if connection fails
            const connectionTimeout = setTimeout(() => {
                if (!this.isConnected) {
                    console.log('WebSocket connection timeout - activating demo mode');
                    this.activateDemoMode();
                }
            }, 3000);
            
            this.ws.onopen = () => {
                clearTimeout(connectionTimeout);
                this.handleConnectionOpen();
            };
            this.ws.onmessage = (event) => this.handleMessage(event);
            this.ws.onclose = () => {
                clearTimeout(connectionTimeout);
                if (!this.demoMode) {
                    this.handleConnectionClose();
                }
            };
            this.ws.onerror = (error) => {
                clearTimeout(connectionTimeout);
                console.log('WebSocket error - activating demo mode');
                this.activateDemoMode();
            };
            
        } catch (error) {
            console.log('WebSocket not available - activating demo mode');
            this.activateDemoMode();
        }
    }

    /**
     * Activate demo mode (no backend required)
     */
    activateDemoMode() {
        console.log('Demo mode activated');
        this.demoMode = true;
        this.isConnected = true;
        
        // Close any existing WebSocket
        if (this.ws) {
            try {
                this.ws.close();
            } catch (e) {}
            this.ws = null;
        }
        
        // Initialize demo users (simulate other users)
        this.demoUsers = [this.username, 'Alice', 'Bob', 'Charlie'];
        
        // Switch to chat screen
        this.loginScreen.classList.remove('active');
        this.chatScreen.classList.add('active');
        
        // Update UI
        this.currentUsernameDisplay.textContent = this.username;
        this.sendButton.disabled = false;
        this.messageInput.focus();
        this.updateConnectionStatus('Demo Mode (No Backend)', 'connected');
        
        // Add welcome message
        this.addSystemMessage(`Welcome to the demo, ${this.username}! This is a simulated chat (no backend server).`);
        this.addSystemMessage('Try sending messages - you\'ll see simulated responses from demo users.');
        
        // Update user list
        this.updateUsersList(this.demoUsers);
        
        // Add some demo messages
        setTimeout(() => {
            this.addDemoMessage('Alice', 'Hey everyone! Welcome to the chat!');
        }, 1000);
        
        setTimeout(() => {
            this.addDemoMessage('Bob', 'This is a demo of the Erlang chat app running on GitHub Pages!');
        }, 2000);
    }

    /**
     * Add a simulated message in demo mode
     */
    addDemoMessage(from, content) {
        if (!this.demoMode) return;
        
        const message = {
            type: 'message',
            from: from,
            content: content,
            timestamp: new Date().toISOString()
        };
        
        this.displayMessage(message);
    }

    /**
     * Simulate a response in demo mode
     */
    simulateDemoResponse() {
        if (!this.demoMode) return;
        
        const responses = [
            'That\'s interesting!',
            'I agree with you.',
            'Tell me more about that.',
            'That\'s a great point!',
            'I\'ve been thinking about that too.',
            'Nice! 👍',
            'Exactly what I was thinking!',
            'That makes sense.',
        ];
        
        const otherUsers = this.demoUsers.filter(u => u !== this.username);
        if (otherUsers.length === 0) return;
        
        // Random delay between 1-3 seconds
        const delay = Math.random() * 2000 + 1000;
        
        setTimeout(() => {
            const randomUser = otherUsers[Math.floor(Math.random() * otherUsers.length)];
            const randomResponse = responses[Math.floor(Math.random() * responses.length)];
            this.addDemoMessage(randomUser, randomResponse);
        }, delay);
    }

    /**
     * Handle WebSocket connection opened
     */
    handleConnectionOpen() {
        console.log('WebSocket connection established');
        this.updateConnectionStatus('Connected', 'connected');
        this.demoMode = false;
        
        // Send join message
        this.sendToServer({
            type: 'join',
            username: this.username,
            room: this.currentRoom
        });
    }

    /**
     * Handle incoming WebSocket message
     */
    handleMessage(event) {
        try {
            const message = JSON.parse(event.data);
            console.log('Received message:', message);
            
            switch (message.type) {
                case 'join_success':
                    this.handleJoinSuccess(message);
                    break;
                    
                case 'message':
                    this.displayMessage(message);
                    break;
                    
                case 'user_list':
                    this.updateUsersList(message.users);
                    break;
                    
                case 'error':
                    this.handleServerError(message);
                    break;
                    
                default:
                    console.log('Unknown message type:', message.type);
            }
        } catch (error) {
            console.error('Error parsing message:', error);
        }
    }

    /**
     * Handle successful join
     */
    handleJoinSuccess(message) {
        console.log('Successfully joined chat');
        this.isConnected = true;
        
        // Switch to chat screen
        this.loginScreen.classList.remove('active');
        this.chatScreen.classList.add('active');
        
        // Update UI
        this.currentUsernameDisplay.textContent = this.username;
        this.sendButton.disabled = false;
        this.messageInput.focus();
        
        // Add welcome message
        this.addSystemMessage(`Welcome to the chat, ${this.username}!`);
    }

    /**
     * Handle server error
     */
    handleServerError(message) {
        if (!this.isConnected) {
            this.showLoginError(message.message || 'Connection failed');
            this.resetJoinButton();
            if (this.ws) this.ws.close();
        } else {
            this.addSystemMessage('Error: ' + (message.message || 'Unknown error'));
        }
    }

    /**
     * Handle connection closed
     */
    handleConnectionClose() {
        console.log('WebSocket connection closed');
        this.isConnected = false;
        this.updateConnectionStatus('Disconnected', 'disconnected');
        this.sendButton.disabled = true;
        
        if (this.chatScreen.classList.contains('active')) {
            this.addSystemMessage('Connection lost. Please refresh to reconnect.');
        }
    }

    /**
     * Handle connection error
     */
    handleConnectionError(error) {
        console.error('WebSocket error:', error);
        this.updateConnectionStatus('Connection Error', 'error');
        
        if (!this.isConnected && !this.demoMode) {
            this.showLoginError('Could not connect to server. Activating demo mode...');
            // Demo mode will be activated by the timeout in connect()
        }
    }

    /**
     * Send message to server
     */
    sendToServer(data) {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            const jsonData = JSON.stringify(data);
            console.log('Sending to server:', jsonData);
            this.ws.send(jsonData);
        } else {
            console.error('WebSocket not ready. State:', this.ws ? this.ws.readyState : 'no ws');
        }
    }

    /**
     * Handle sending a chat message
     */
    handleSendMessage() {
        const content = this.messageInput.value.trim();
        
        if (!content) return;
        if (!this.isConnected) {
            this.addSystemMessage('Not connected to server');
            return;
        }
        
        if (this.demoMode) {
            // In demo mode, just display the message locally
            const message = {
                type: 'message',
                from: this.username,
                content: content,
                timestamp: new Date().toISOString()
            };
            this.displayMessage(message);
            
            // Simulate a response from other users
            this.simulateDemoResponse();
        } else {
            // Send message to real server
            this.sendToServer({
                type: 'message',
                room: this.currentRoom,
                content: content
            });
        }
        
        // Clear input
        this.messageInput.value = '';
    }

    /**
     * Display a chat message
     */
    displayMessage(message) {
        const messageDiv = document.createElement('div');
        messageDiv.className = 'message';
        
        // Mark own messages
        if (message.from === this.username) {
            messageDiv.classList.add('own-message');
        }
        
        // Format timestamp
        const time = new Date(message.timestamp).toLocaleTimeString([], {
            hour: '2-digit',
            minute: '2-digit'
        });
        
        messageDiv.innerHTML = `
            <div class="message-header">
                <span class="message-author">${this.escapeHtml(message.from)}</span>
                <span class="message-time">${time}</span>
            </div>
            <div class="message-content">${this.escapeHtml(message.content)}</div>
        `;
        
        this.messagesContainer.appendChild(messageDiv);
        this.scrollToBottom();
    }

    /**
     * Add a system message
     */
    addSystemMessage(text) {
        const messageDiv = document.createElement('div');
        messageDiv.className = 'message system-message';
        messageDiv.textContent = text;
        this.messagesContainer.appendChild(messageDiv);
        this.scrollToBottom();
    }

    /**
     * Update the users list
     */
    updateUsersList(users) {
        this.usersList.innerHTML = '';
        this.userCount.textContent = users.length;
        
        users.forEach(user => {
            const userDiv = document.createElement('div');
            userDiv.className = 'user-item';
            
            if (user === this.username) {
                userDiv.classList.add('current-user-item');
                userDiv.innerHTML = `
                    <span class="user-name">${this.escapeHtml(user)} (you)</span>
                    <span class="user-status">🟢</span>
                `;
            } else {
                userDiv.innerHTML = `
                    <span class="user-name">${this.escapeHtml(user)}</span>
                    <span class="user-status">🟢</span>
                `;
            }
            
            this.usersList.appendChild(userDiv);
        });
    }

    /**
     * Update connection status display
     */
    updateConnectionStatus(text, className) {
        this.connectionStatus.textContent = text;
        this.connectionStatus.className = 'status ' + className;
    }

    /**
     * Show login error
     */
    showLoginError(message) {
        this.loginError.textContent = message;
    }

    /**
     * Reset join button
     */
    resetJoinButton() {
        this.joinButton.disabled = false;
        this.joinButton.textContent = 'Join Chat';
    }

    /**
     * Handle logout
     */
    handleLogout() {
        if (this.ws) {
            this.ws.close();
        }
        
        // Reset state
        this.username = null;
        this.isConnected = false;
        this.demoMode = false;
        this.demoUsers = [];
        this.messagesContainer.innerHTML = '';
        this.usersList.innerHTML = '';
        this.messageInput.value = '';
        this.usernameInput.value = '';
        
        // Switch back to login screen
        this.chatScreen.classList.remove('active');
        this.loginScreen.classList.add('active');
        
        this.resetJoinButton();
    }

    /**
     * Scroll messages to bottom
     */
    scrollToBottom() {
        this.messagesContainer.scrollTop = this.messagesContainer.scrollHeight;
    }

    /**
     * Escape HTML to prevent XSS
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Initialize chat client when page loads
document.addEventListener('DOMContentLoaded', () => {
    const chat = new ChatClient();
    console.log('Chat client initialized');
});
