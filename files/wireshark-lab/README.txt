COM315 Wireshark Lab — Network Traffic Analysis
================================================

Arena server is running on grid (136.244.224.30:9000)
Web spectator: http://136.244.224.30:9001

EXERCISES
---------

Exercise 1: TCP Three-Way Handshake
  Start Wireshark (capture on any interface, filter: tcp.port == 9000)
  Run:  python3 arena/simple_client.py 136.244.224.30 9000 YourName
  Find the SYN, SYN-ACK, ACK packets at the start of the connection.
  Q1: What port did your client use? What port did the server use?
  Q2: What is the initial sequence number in the SYN packet?

Exercise 2: Application Layer Protocol Analysis
  With the arena client still running, right-click a packet -> Follow TCP Stream.
  Q3: What are the first two messages exchanged? (command names)
  Q4: What format is the GAMESTATE data in? How often does it arrive?
  Q5: List all command types you can see the client sending.

Exercise 3: Protocol Exploration
  The arena server accepts more commands than what the simple client uses.
  Start a NEW Wireshark capture (filter: tcp.port == 9000)
  Connect with netcat and send commands manually:
    nc 136.244.224.30 9000
    JOIN YourName
  Note: The server sends GAMESTATE updates 15 times per second, so your
  terminal will flood with JSON. That's normal. Use WIRESHARK to read
  the responses, not the terminal. Useful filters:
    tcp.port == 9000 && !data contains "GAMESTATE"
    tcp.port == 9000 && data contains "SCAN"
    tcp.port == 9000 && data contains "ERROR"
  Q6: What happens if you send a command the server doesn't recognize?
  Q7: Can you find any commands beyond MOVE, STOP, SHOOT, and CHAT?
      Try common command names (HELP, SCAN, PLAYERS, ADMIN, DEBUG, etc.)
      and check Wireshark for non-GAMESTATE responses.

Exercise 4: DNS Resolution
  Start a NEW capture (filter: dns)
  Run:  dig google.com A
  Run:  dig google.com AAAA
  Run:  dig google.com MX
  Q8: What UDP port does DNS use?
  Q9: How many bytes is a typical DNS query vs response?
  Q10: What is the difference between the A, AAAA, and MX responses?

Exercise 5: HTTP in Cleartext
  Start a NEW capture (filter: tcp.port == 8080)
  In one terminal:  python3 -m http.server 8080
  In another:       curl http://localhost:8080/
  Q11: Find the GET request. What HTTP version and headers did curl send?
  Q12: What did the server respond with? Find the Content-Type header.
  Stop the http.server (Ctrl+C).

Exercise 6: UDP vs TCP
  Start a NEW capture (filter: udp.port == 7777)
  In one terminal:  python3 udp_echo_server.py
  In another:       python3 udp_echo_client.py
  Q13: How does UDP connection setup differ from TCP? (hint: count packets)
  Q14: Is there a handshake? How does the client know the server received its message?

Exercise 7: ICMP (Ping and Traceroute)
  Start a NEW capture (filter: icmp)
  Run:  ping -c 4 136.244.224.30
  Run:  traceroute -n 136.244.224.30
  Q15: What ICMP types do you see for ping? (check the Type field)
  Q16: How does traceroute use ICMP and TTL to map the network path?

BONUS: Packet Comparison
  Save one capture from each exercise as a .pcapng file.
  For each, identify the protocol stack layers visible in Wireshark's
  packet detail pane (Frame / Ethernet / IP / TCP or UDP / Application).
  Which exercises show encrypted vs plaintext application data?
