import subprocess

# Start Bluetooth service if not already started
subprocess.run(['sudo', 'service', 'bluetooth', 'start'], check=True)

def scan():
    # Launch xterm window and run hcitool scan inside it
    subprocess.run(['xterm', '-e', 'hcitool scan'], check=True)

def l2ping():
    # Launch xterm window and run l2ping command inside it
    addr = input(" Enter Bluetooth Device Address: ")
    subprocess.run(['xterm', '-e', f'l2ping -c 1 -s 1 {addr}'], check=True)

def rfcomm():
    # Launch xterm window and run rfcomm command inside it
    addr = input(" Enter Bluetooth device address: ")
    cmd = ['rfcomm', 'connect', addr , '1']

    for i in range(0, 1001):
        try:
            # Attempt to connect to the device
            subprocess.run(['xterm', '-e', ' '.join(cmd)], check=True)
            print(  " Connected to device {} on RFCOMM".format(addr))
        except subprocess.CalledProcessError:
            print(  " Failed to connect to device {} on RFCOMM".format(addr))
        print(  ' Connecting...')


def main():
    scan()

if __name__ == "__main__":
    print("running main")
    main() 