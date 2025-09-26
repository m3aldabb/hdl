import serial
import time

# Configure serial port (change COM3 -> your port, and baudrate if needed)
ser = serial.Serial(
    port="/dev/cu.usbserial-210183BB44B61",      # Windows: "COM3" / Linux: "/dev/ttyUSB0" / Mac: "/dev/tty.usbserial-xxxx"
    baudrate=9600,
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    timeout=1
)

# Define your packet as raw bytes
packet = bytes([0xAA, 0x01, 0x02, 0xAA, 0xAA, 0x00, 0x55])

print(f"Sending packet: {packet.hex(' ').upper()}")

# Send the packet
ser.write(packet)
time.sleep(0.5)

packet = bytes([0xAA, 0x01, 0x02, 0xBE, 0xEF, 0x00, 0x55])

print(f"Sending packet: {packet.hex(' ').upper()}")

# Send the packet
ser.write(packet)
time.sleep(0.5)

packet = bytes([0xAA, 0x01, 0x02, 0xDE, 0xAD, 0x00, 0x55])

print(f"Sending packet: {packet.hex(' ').upper()}")

# Send the packet
ser.write(packet)
time.sleep(0.5)

packet = bytes([0xAA, 0x01, 0x02, 0xBE, 0xEF, 0x00, 0x55])

print(f"Sending packet: {packet.hex(' ').upper()}")

# Send the packet
ser.write(packet)
time.sleep(0.5)


# (optional) wait a bit and try to read response
time.sleep(0.1)
if ser.in_waiting > 0:
    response = ser.read(ser.in_waiting)
    print(f"Received: {response.hex(' ').upper()}")

ser.close()
