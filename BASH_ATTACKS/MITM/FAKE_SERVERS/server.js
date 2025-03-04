// Import the WebSocket library
const WebSocket = require('ws');

// Create a WebSocket server on port 6969
const wss = new WebSocket.Server({ port: 6969 });

// Event listener for new connections
wss.on('connection', (ws) => {
    console.log('Client connected');

    // Event listener for incoming messages
    ws.on('message', (message) => {
        console.log('Received:', message);
        // Echo the message back to the client
        ws.send(`Server received: ${message}`);
    });

    // Event listener for when the connection is closed
    ws.on('close', () => {
        console.log('Client disconnected');
    });
});