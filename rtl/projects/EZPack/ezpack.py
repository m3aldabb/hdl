"""
ezpack.py - Python library for EZPack protocol over UART
"""

import serial
import time


class EZPack:
    START = 0xAA
    END = 0x55

    def __init__(self, port, baudrate=9600, timeout=1, debug=False):
        """
        Initialize the EZPack serial connection.

        :param port: Serial port (e.g., '/dev/ttyUSB0' or 'COM3')
        :param baudrate: Baud rate (default 9600)
        :param timeout: Serial read timeout in seconds (default 1)
        :param debug: If True, print debug messages
        """
        self.debug = debug
        self.ser = serial.Serial(
            port=port,
            baudrate=baudrate,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=timeout
        )
        if self.debug:
            print(f"[INFO] Serial port opened: {port} at {baudrate} bps")

    @staticmethod
    def _compute_checksum(pkt_type, payload):
        chk = pkt_type ^ len(payload)
        for b in payload:
            chk ^= b
        return chk

    def build_packet(self, pkt_type, payload):
        """
        Build an EZPack packet from type and payload.

        :param pkt_type: Packet type (0-255)
        :param payload: List of payload bytes
        :return: bytes object of full packet
        """
        checksum = self._compute_checksum(pkt_type, payload)
        packet = bytes([self.START, pkt_type, len(payload)] + payload + [checksum, self.END])
        if self.debug:
            print(f"[BUILD] Packet built: {packet.hex(' ').upper()}")
        return packet

    def send_packet(self, pkt_type, payload):
        """
        Build and send an EZPack packet over UART.

        :param pkt_type: Packet type (0-255)
        :param payload: List of payload bytes
        """
        packet = self.build_packet(pkt_type, payload)
        self.ser.write(packet)
        if self.debug:
            print(f"[SEND] Sent packet: {packet.hex(' ').upper()}")

    def receive_packet(self, timeout=None):
        """
        Wait for and read an EZPack packet from UART.

        :param timeout: Timeout in seconds to wait for a complete packet (default None = use serial timeout)
        :return: tuple (pkt_type, payload) if valid, or None if timeout or invalid
        """
        start_time = time.time()
        buffer = bytearray()

        while True:
            if self.ser.in_waiting:
                buffer += self.ser.read(self.ser.in_waiting)

            start_index = buffer.find(bytes([self.START]))
            end_index = buffer.find(bytes([self.END]), start_index + 1)

            if start_index != -1 and end_index != -1 and end_index > start_index:
                packet = buffer[start_index:end_index + 1]
                pkt_type = packet[1]
                length = packet[2]
                payload = list(packet[3:3 + length])
                checksum = packet[3 + length]
                expected_chk = self._compute_checksum(pkt_type, payload)

                if checksum == expected_chk:
                    if self.debug:
                        print(f"[RECV] Received valid packet: {packet.hex(' ').upper()}")
                    return pkt_type, payload
                else:
                    if self.debug:
                        print(f"[WARN] Checksum mismatch: {packet.hex(' ').upper()}")
                    # remove bad packet from buffer
                    buffer = buffer[end_index + 1:]
            else:
                # check timeout
                if timeout and (time.time() - start_time) > timeout:
                    if self.debug:
                        print("[INFO] Timeout waiting for packet")
                    return None
                # small pause to avoid busy loop
                time.sleep(0.5)

    def close(self):
        """Close the serial port."""
        self.ser.close()
        if self.debug:
            print("[INFO] Serial port closed")


# ------------------------------
# Example usage
# ------------------------------
if __name__ == "__main__":
    ezp = EZPack(port="/dev/ttyUSB1", baudrate=9600, debug=True)

    payloads = [
        [0xAA, 0xAA],
        [0xBB, 0xBB],
        [0xCC, 0xCC]
    ]

    for pl in payloads:
        ezp.send_packet(pkt_type=0x01, payload=pl)
        pkt = ezp.receive_packet(timeout=1)
        if pkt:
            pkt_type, payload = pkt
            print(f"Received type={pkt_type}, payload={payload}")

    ezp.close()
