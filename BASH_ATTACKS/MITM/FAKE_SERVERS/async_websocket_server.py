import asyncio
import websockets
import socket
import json
import logging
import logging.handlers

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

    def get_local_ip(self):
        try:
            # Get local IP address
            hostname = socket.gethostname()
            local_ip = socket.gethostbyname(hostname)
            logger.info(f"[+] Local IP detected: {local_ip}")
            return local_ip
        except Exception as e:
            logger.error(f"[-] Failed to get local IP: {e}")
            return "127.0.0.1"

    async def on_open(self, websocket):
        print("[!] Client connected")
        logger.info(f"[+] Client connected: {websocket.remote_address}")
        self.clients.add(websocket)

    async def on_message(self, websocket, message):
        try:
            data = json.loads(message)
            print(f"[+] Received message: {data}")
            logger.info(f"[+] Received message: {data}")

            # Broadcast the message to all connected clients
            await self.broadcast(json.dumps(data))
        except json.JSONDecodeError as e:
            print(f"[-] Invalid message format: {e}")
            logger.error(f"[-] Invalid message format: {e}")

    async def on_error(self, websocket, error):
        print(f"[-] Error: {error}")
        logger.error(f"[-] Error: {error}")

    async def on_close(self, websocket):
        print("[!] Client disconnected")
        logger.info(f"[-] Client disconnected: {websocket.remote_address}")
        self.clients.remove(websocket)

    async def broadcast(self, message):
        for client in self.clients:
            try:
                await client.send(message)
            except Exception as e:
                print(f"[-] Failed to broadcast message: {e}")
                logger.error(f"[-]{time.strftime('%Y-%m-%d %H:%M:%S')} Failed to broadcast message: {e}")

    async def handler(self, websocket, path):
        await self.on_open(websocket)
        try:
            async for message in websocket:
                await self.on_message(websocket, message)
        except websockets.ConnectionClosed:
            await self.on_close(websocket)

    async def start(self):
        print(f"[!] Starting WebSocket server on ws://{self.host}:{self.port}")
        logger.info(f"[!] Starting WebSocket server on ws://{self.host}:{self.port}")
        async with websockets.serve(self.handler, self.host, self.port):
            await asyncio.Future()  # Run forever

if __name__ == "__main__":
    server = WebSocketServer("0.0.0.0", 3001)
    asyncio.run(server.start())