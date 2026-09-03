#!/usr/bin/env python3
"""UDP echo client — sends a few messages so students can compare UDP vs TCP in Wireshark."""
import socket, time

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
messages = [
    "Hello from UDP!",
    "This is message 2",
    "No handshake needed",
    "No guaranteed delivery",
    "But it is fast",
]

print("Sending 5 UDP messages to localhost:7777 ...")
for i, msg in enumerate(messages, 1):
    sock.sendto(msg.encode(), ("127.0.0.1", 7777))
    data, _ = sock.recvfrom(1024)
    print(f"  Sent: {msg!r}  ->  Echo: {data.decode()!r}")
    time.sleep(0.5)

sock.close()
print("Done. Check your Wireshark capture.")
