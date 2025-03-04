import asyncio
import websockets
import json
import os
import logging
import base64

# Configure logging
logging.basicConfig(
    filename='websocket.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger()

class WebSocketServer:
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.clients = set()
        self.file_dir = "files"  # Directory to store uploaded files
        self.users = {}  # Dictionary to store connected users
        os.makedirs(self.file_dir, exist_ok=True)  # Create directory if it doesn't exist

    async def on_open(self, websocket):
        print("[!] Client connected")
        logger.info(f"[+] Client connected: {websocket.remote_address}")
        self.clients.add(websocket)

    async def on_message(self, websocket, message):
        try:
            data = json.loads(message)
            action = data.get("action")

            if action == "upload":
                await self.handle_upload(data)
            elif action == "download":
                await self.handle_download(websocket, data)
            elif action == "list":
                await self.handle_list(websocket)
            elif action == "chat":
                await self.handle_chat(websocket, data)
            elif action == "new-user":
                await self.handle_new_user(websocket, data)
            else:
                logger.error(f"[-] Unknown action: {action}")
        except json.JSONDecodeError as e:
            logger.error(f"[-] Invalid message format: {e}")

    async def handle_upload(self, data):
        """Handle file upload from client."""
        file_name = data.get("fileName")
        file_content = data.get("fileContent")
        if not file_name or not file_content:
            logger.error("[-] Missing file name or content")
            return

        # Decode base64 content and save to file
        try:
            file_path = os.path.join(self.file_dir, file_name)
            with open(file_path, "wb") as f:
                f.write(base64.b64decode(file_content))
            logger.info(f"[+] File uploaded: {file_name}")
        except Exception as e:
            logger.error(f"[-] Failed to save file: {e}")

    async def handle_download(self, websocket, data):
        """Handle file download request from client."""
        file_name = data.get("fileName")
        if not file_name:
            logger.error("[-] Missing file name")
            return

        file_path = os.path.join(self.file_dir, file_name)
        if not os.path.exists(file_path):
            logger.error(f"[-] File not found: {file_name}")
            return

        # Read file and send base64 content to client
        try:
            with open(file_path, "rb") as f:
                file_content = base64.b64encode(f.read()).decode("utf-8")
            response = {
                "action": "download",
                "fileName": file_name,
                "fileContent": file_content
            }
            await websocket.send(json.dumps(response))
            logger.info(f"[+] File sent: {file_name}")
        except Exception as e:
            logger.error(f"[-] Failed to read file: {e}")

    async def handle_list(self, websocket):
        """Handle file list request from client."""
        try:
            files = os.listdir(self.file_dir)
            response = {
                "action": "list",
                "files": files
            }
            await websocket.send(json.dumps(response))
            logger.info("[+] Sent file list to client")
        except Exception as e:
            logger.error(f"[-] Failed to list files: {e}")

    async def handle_chat(self, websocket, data):
        """Handle chat messages from client."""
        user_name = self.users.get(websocket, "Unknown")
        message = data.get("message")
        if not message:
            logger.error("[-] Missing message")
            return

        # Broadcast the message to all clients
        response = {
            "action": "chat",
            "user": user_name,
            "message": message
        }
        await self.broadcast(json.dumps(response))
        logger.info(f"[+] Chat message from {user_name}: {message}")

    async def handle_new_user(self, websocket, data):
        """Handle new user connection."""
        user_name = data.get("user_name")
        if not user_name:
            logger.error("[-] Missing user name")
            return

        # Store the user name
        self.users[websocket] = user_name

        # Notify all clients about the new user
        response = {
            "action": "user-connected",
            "user_name": user_name
        }
        await self.broadcast(json.dumps(response))
        logger.info(f"[+] New user connected: {user_name}")

    async def on_error(self, websocket, error):
        print(f"[-] Error: {error}")
        logger.error(f"[-] Error: {error}")

    async def on_close(self, websocket):
        print("[!] Client disconnected")
        logger.info(f"[-] Client disconnected: {websocket.remote_address}")
        self.clients.remove(websocket)

        # Notify all clients about the disconnected user
        user_name = self.users.get(websocket, "Unknown")
        if user_name:
            response = {
                "action": "user-disconnected",
                "user_name": user_name
            }
            await self.broadcast(json.dumps(response))
            logger.info(f"[+] User disconnected: {user_name}")

    async def handler(self, websocket, path):
        await self.on_open(websocket)
        try:
            async for message in websocket:
                await self.on_message(websocket, message)
        except websockets.ConnectionClosed:
            await self.on_close(websocket)

    async def broadcast(self, message):
        """Broadcast a message to all connected clients."""
        for client in self.clients:
            try:
                await client.send(message)
            except Exception as e:
                logger.error(f"[-] Failed to send message to client: {e}")

    async def start(self):
        print(f"[!] Starting WebSocket server on ws://{self.host}:{self.port}")
        logger.info(f"[!] Starting WebSocket server on ws://{self.host}:{self.port}")
        async with websockets.serve(self.handler, self.host, self.port):
            await asyncio.Future()  # Run forever

if __name__ == "__main__":
    server = WebSocketServer("0.0.0.0", 6969)
    asyncio.run(server.start())