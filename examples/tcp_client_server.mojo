"""
Example: Pure Mojo TCP Sockets (C FFI)

Demonstrates:
- Creating a TCP listener (server)
- Accepting client connections
- TCP client connection
- Sending and receiving data
- Zero Python dependencies!
"""

from mojo_socket import TcpListener, TcpStream, TcpSocket, SocketAddress


fn run_server() raises:
    """Simple TCP server that echoes received data."""
    print("=== TCP Server Example ===")

    # Bind to port 9000
    var listener = TcpListener.bind(9000)
    print("Server listening on port 9000...")

    # Accept one connection (for demo)
    var client = listener.accept()
    print("Client connected!")

    # Receive data
    var data = client.recv(1024)
    print("Received: " + data)

    # Echo back with prefix
    var response = "Echo: " + data
    client.send(response)
    print("Sent response")

    # Close connection
    client.close()
    listener.close()
    print("Server closed")


fn run_client() raises:
    """Simple TCP client that sends a message."""
    print("=== TCP Client Example ===")

    # Connect to server
    var stream = TcpStream.connect("127.0.0.1", 9000)
    print("Connected to server")

    # Send data
    var message = "Hello from mojo-socket!"
    stream.send(message)
    print("Sent: " + message)

    # Receive response
    var response = stream.recv(1024)
    print("Received: " + response)

    # Close connection
    stream.close()
    print("Client closed")


fn http_client_example() raises:
    """Make a simple HTTP request using raw TCP."""
    print("=== HTTP Client Example ===")

    # Connect to httpbin.org
    var stream = TcpStream.connect("httpbin.org", 80)

    # Send HTTP request
    var request = "GET /get HTTP/1.1\r\nHost: httpbin.org\r\nConnection: close\r\n\r\n"
    stream.send(request)

    # Receive response
    var response = stream.recv(4096)
    print("HTTP Response (first 500 chars):")
    print(response[:500] if len(response) > 500 else response)

    stream.close()


fn main() raises:
    print("mojo-socket: Pure Mojo TCP via C FFI\n")

    # Run HTTP client example (doesn't need local server)
    http_client_example()

    print("\n" + "=" * 50)
    print("To test client/server locally:")
    print("  1. Run server: mojo run examples/tcp_server.mojo")
    print("  2. Run client: mojo run examples/tcp_client.mojo")
