
import socket
import os
import time
from tqdm import tqdm
from colorama import Fore, Style, init
from dataclasses import dataclass

# Initialize colorama
init(autoreset=True)

# Define a dataclass to store the variables
@dataclass
class ServerConfig:
    local_ip: str
    port: int
    client_name: str
    ip: str
    server_socket: socket.socket

def get_local_ip():
    try:
        # Create a socket object
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

        # Connect to an external server (doesn't actually send data)
        s.connect(("8.8.8.8", 80))  # Google's public DNS server

        # Get the local IP address
        local_ip = s.getsockname()[0]

        # Close the socket
        s.close()

        return local_ip
    except Exception as e:
        return f"Error: {e}"

# Helper function to print styled messages
def print_styled(prefix, message, prefix_color=Fore.CYAN, message_color=Fore.WHITE):
    """Helper function to print styled messages."""
    print(f"{prefix_color}{prefix}{Style.RESET_ALL} {message_color}{message}{Style.RESET_ALL}")

# Initialize the server configuration
local_ip = get_local_ip()
PORT = 5555
client_name = socket.gethostname()
IP = socket.gethostbyname(client_name)
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

server_config = ServerConfig(
    local_ip=local_ip,
    port=PORT,
    client_name=client_name,
    ip=IP,
    server_socket=server_socket
)

# Print server configuration
print_styled("[SYS]", f"Connected to {Fore.GREEN}{server_config.client_name}{Style.RESET_ALL} with IP {Fore.YELLOW}{server_config.ip}{Style.RESET_ALL} at port: {Fore.MAGENTA}{server_config.port}")
print(f"Your local IP address is: {server_config.local_ip}")
print_styled("[SYS]", f"Initiating connection.. {Fore.BLUE}{server_config.server_socket}")
print_styled("[SYS]", f"Socket type: {Fore.BLUE}{type(server_config.server_socket)}")

# Bind the socket to the port
server_config.server_socket.bind((server_config.local_ip, server_config.port))
server_config.server_socket.listen(5)  # Set max queue to 5
print_styled("[SYSTEM]", f"Server is listening on {Fore.YELLOW}{server_config.server_socket.getsockname()}")

# Function to handle client connection
def handle_client(client_socket, addr):
    file_name = input(f"{Fore.GREEN}[SYSTEM]{Style.RESET_ALL} Enter File Name: ")
    file_size = os.path.getsize(file_name)

    print_styled("[SYSTEM]", f"Connected to {Fore.BLUE}{client_socket}{Style.RESET_ALL}, {Fore.YELLOW}{addr}")
    print_styled("[SYSTEM]", f"{Fore.CYAN}{file_name}{Style.RESET_ALL} is {Fore.YELLOW}{file_size}{Style.RESET_ALL} bytes large")

    # Send file name and size to client
    client_socket.send(file_name.encode())
    client_socket.send(str(file_size).encode())
    # Open and read file as binary for parsing
    with open(file_name, "rb", buffering=30000) as file:
        send_count = 0
        send_start = time.time()

        # Initialize progress bar
        progress = tqdm(total=file_size, unit='B', unit_scale=True, desc=f"{Fore.CYAN}Sending {file_name}{Style.RESET_ALL}", bar_format="{l_bar}%s{bar}%s{r_bar}" % (Fore.CYAN, Style.RESET_ALL))

        # Start loop
        while send_count < file_size:
            data = file.read(8192)
            if not data:
                break  # End of file
            client_socket.sendall(data)
            send_count += len(data)
            progress.update(len(data))

        progress.close()
        send_end = time.time()

    total_time = send_end - send_start
    print_styled("[SYSTEM]", f"{Fore.CYAN}{file_name}{Style.RESET_ALL} Transfer Complete in: {Fore.YELLOW}{total_time:.2f}{Style.RESET_ALL} seconds")
    client_socket.close()

# Main loop to listen for client connections indefinitely
minute_counter = 0
try:
    while True:
        print_styled("[SYSTEM]", f"Waiting for client connection... (Elapsed time: {Fore.YELLOW}{minute_counter}{Style.RESET_ALL} minutes)")
        client_socket, addr = server_config.server_socket.accept()
        print_styled("[SYSTEM]", f"Accepted connection from {Fore.YELLOW}{addr}")
        handle_client(client_socket, addr)
        minute_counter += 1
        time.sleep(60)  # Wait for a minute before accepting the next connection
except KeyboardInterrupt:
    print_styled("[SYSTEM]", "Server is shutting down...", Fore.RED)
finally:
    server_config.server_socket.close()
