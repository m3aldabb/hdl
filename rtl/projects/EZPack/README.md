# EZPack Protocol

**EZPack** is a lightweight, simple, and universal protocol for structured communication between two serial interfaces — for example, an FPGA and a computer. It is designed for simplicity, reusability, and versatility, enabling reliable data transfer over UART or other serial connections.

---

## Features

- Minimal and easy-to-use packet protocol.
- Works over UART.
- Supports structured packets.
- Versatile: can be reused across projects and devices.

---

## Packet Structure

Each EZPack packet is structured as follows:

[start | pkttype | pktlength | payload | checksum | end]


- **Start (0xAA):** Marks beginning of packet  
- **Pkt Type:** Application-defined packet type  
- **Pkt Len:** Length of the payload in bytes  
- **Payload:** Actual data content  
- **Checksum:** XOR of `pkttype`, `pktlength`, and all payload bytes  
- **End (0x55):** Marks end of packet  

---

## Project Files
- **`ezp_encode.sv`**  
  Packet encoder. Converts a stream of raw input bytes into a fully structured EZPack packet with start, type, length, payload, checksum, and end markers.  
  - Input: single bytes with `i_valid/i_ready`  
  - Output: full packet vector (`o_data`) with `o_valid/o_ready`  

- **`ezp_decode.sv`**  
  Packet decoder. Accepts a full encoded EZPack packet and emits the packet back as a stream of bytes. Useful for parsing and handling packet data on FPGA.  
  - Input: full packet (`i_data`) with handshake  
  - Output: single decoded bytes with handshake  

- **`ezp_uart_tx.sv`**  
  UART transmitter module that takes EZPack packets and shifts them out serially to the TX line.  

- **`ezp_uart_rx.sv`**  
  UART receiver module that reads incoming serial data from RX line and buffers them into EZPack-compatible format. 

- **`ezpack_top.sv`**  
  Top-level FPGA module demonstrating a full EZPack example:  
  - Integrates `ezp_uart_rx` and `ezp_uart_tx` to receive and send packets over UART.  
  - Extracts 2-byte payload from received packets and drives a 7-segment display (`ssd_ctrl`) to show payload values.  
  - Performs a **loopback**, immediately sending any received packet back out via UART TX.  
  - Handles all internal EZPack signals (`o_data`, `o_valid`, `num_bcd`, `payload`) automatically.  
  - Inputs/Outputs:  
    - `clk`, `rst` — system clock and reset  
    - `rx` — UART RX input  
    - `tx` — UART TX output  
    - `seg`, `an` — 7-segment display outputs  

- **`ezpack.py`**  
Python library for building, sending, and receiving EZPack packets over UART:  
  - Provides easy-to-use methods:  
    - `send_packet(pkt_type, payload)` — builds and sends a packet  
    - `receive_packet(timeout)` — waits for a valid packet and returns `(pkt_type, payload)`  
  - Automatically handles **start/end markers** and **checksum verification**.  
  - Designed for simple usage: user only provides serial port and baud rate.  
  - Supports optional debug printing to monitor sent and received packets.  

## How to Use

### Sending a Packet to FPGA from Serial Terminal on Computer

To send a packet from your computer to the FPGA using EZPack:

1. **Connect your PC to the FPGA UART:**
   - Use a USB-to-UART adapter if your FPGA board does not have a native USB serial port.  
   - Identify the COM port (Windows) or `/dev/ttyUSBx` (Linux/macOS).

2. **Construct a valid EZPack packet:**

   **Example:** 2-byte payload packet

   - **Start byte:** `0xAA` (always first)  
   - **Packet type:** `0x01` (application-defined, e.g., command ID)  
   - **Packet length:** `0x02` (number of bytes in payload)  
   - **Payload:** `0x12 0x34` (example data bytes)  
   - **Checksum:** XOR of `pkt type ^ pkt length ^ payload bytes`  
     ```
     0x01 ^ 0x02 ^ 0x12 ^ 0x34 = 0x35
     ```  
   - **End byte:** `0x55` (always last)

   **Full Packet to Send:** `0xAA 0x01 0x02 0x12 0x34 0x35 0x55`


3. **Send the packet using a serial terminal or script:**
- **Python / pyserial example:**
  ```python
  import serial
  ser = serial.Serial('/dev/ttyUSB0', 9600)  # adjust port and baud rate
  packet = bytes([0xAA, 0x01, 0x02, 0x12, 0x34, 0x35, 0x55])
  ser.write(packet)
  ser.close()
  ```
- You can also use Tera Term, PuTTY, or other serial terminal software:
  - Set baud rate (matching FPGA, e.g., 9600)  
  - Select "Send binary" or "Send file" mode  
  - Send the packet bytes exactly as shown  

4. **FPGA will receive the packet:**
- `ezp_uart_rx` reads each byte from UART  
- Once the full packet is received, `o_data` outputs the packet as a vector  
- `o_valid` goes high to indicate the packet is ready to process

---

### Receiving a Packet from FPGA to Serial Terminal on Computer

To receive data sent from the FPGA:

1. **Construct a packet on FPGA** (e.g., using `ezp_uart_tx`):
- Provide `i_data` = full EZPack packet `[Start | Type | Length | Payload | Checksum | End]`  
- Set `i_valid` high when packet is ready  
- Wait for `i_ready` from `ezp_uart_tx` before sending the next packet  

2. **Transmit the packet over UART:**
- `ezp_uart_tx` shifts out one byte at a time over the TX line  
- Each byte appears on your PC serial terminal in the order LSB-first: Start → Type → Length → Payload → Checksum → End

3. **Read the packet on your PC:**
- Use a serial terminal or script to capture bytes:  
  - **Python example:**
    ```python
    import serial
    ser = serial.Serial('/dev/ttyUSB0', 9600)
    data = ser.read(7)  # read 7 bytes (example packet length)
    print(data)
    ser.close()
    ```
- Check the **Start byte (`0xAA`)** and **End byte (`0x55`)** to validate the packet  
- Extract `Pkt Type`, `Pkt Length`, `Payload`, and verify checksum (XOR)

---

## Loopback Example on FPGA

In the file `top.sv`, there is a tested example showing how to use `ezp_uart_rx` and `ezp_uart_tx` together:

- **Receives packets over UART:**  
`ezp_uart_rx` listens to the RX line and outputs full packets as a vector.  

- **Extracts 2-byte payload:**  
In this example, the payload is used to drive a 7-segment display.  

- **Displays payload on a 7-segment display:**  
Each nibble of the 2-byte payload is shown as one hexadecimal digit.  

- **Loops the packet back over UART TX:**  
  Received packets are immediately sent back out using `ezp_uart_tx` as a simple loopback test.  
  These packets can be received on your PC’s serial port and viewed using a Python script or a serial terminal.

