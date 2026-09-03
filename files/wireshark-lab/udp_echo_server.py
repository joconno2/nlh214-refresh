#!/usr/bin/env python3
"""Simple UDP echo server for Wireshark comparison with TCP."""
import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", 7777))
print("UDP echo server listening on port 7777  (Ctrl+C to stop)")

while True:
    data, addr = sock.recvfrom(1024)
    print(f"  [{addr[0]}:{addr[1]}] {data.decode(errors='replace')}")
    sock.sendto(data, addr)
