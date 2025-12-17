/**
 * WhatsApp-like Chat Client
 * Pure vanilla JavaScript - no frameworks
 * Handles WebSocket communication with Erlang backend
 */

class ChatClient {
    constructor() {
        this.ws = null;
        this.username = null;
        this.currentRoom = 'general';
        this.isConnected = false;
        
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
     * Connect to WebSocket server
     */
    connect() {
        try {
            // Connect to WebSocket on port 8081
            this.ws = new WebSocket('ws://localhost:8081');
            
            this.ws.onopen = () => this.handleConnectionOpen();
            this.ws.onmessage = (event) => this.handleMessage(event);
            this.ws.onclose = () => this.handleConnectionClose();
            this.ws.onerror = (error) => this.handleConnectionError(error);
            
        } catch (error) {
            this.showLoginError('Failed to connect to server');
            this.resetJoinButton();
        }
    }

    /**
     * Handle WebSocket connection opened
     */
    handleConnectionOpen() {
        console.log('WebSocket connection established');
        this.updateConnectionStatus('Connected', 'connected');
        
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
        
        if (!this.isConnected) {
            this.showLoginError('Could not connect to server. Make sure the server is running.');
            this.resetJoinButton();
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
        
        // Send message to server
        this.sendToServer({
            type: 'message',
            room: this.currentRoom,
            content: content
        });
        
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
