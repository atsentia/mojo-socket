"""
mojo-socket

Pure Mojo TCP sockets via C FFI - no Python required!

This library provides TCP socket functionality using Mojo's C FFI
to call POSIX socket functions directly. Zero Python dependencies.

Architecture:
    ┌──────────────────────────────────────────────────┐
    │              mojo-socket (Pure Mojo)              │
    ├──────────────────────────────────────────────────┤
    │                                                  │
    │  ┌──────────────┐  ┌──────────────┐             │
    │  │  TcpSocket   │  │  TcpListener │             │
    │  │  TcpStream   │  │  (server)    │             │
    │  └──────────────┘  └──────────────┘             │
    │         │                 │                      │
    │         ▼                 ▼                      │
    │  ┌──────────────────────────────────────────┐   │
    │  │         C FFI (external_call)             │   │
    │  │  socket(), bind(), listen(), accept()     │   │
    │  │  connect(), recv(), send(), close()       │   │
    │  └──────────────────────────────────────────┘   │
    │                      │                          │
    └──────────────────────┼──────────────────────────┘
                           ▼
    ┌──────────────────────────────────────────────────┐
    │           POSIX Sockets (libc)                    │
    └──────────────────────────────────────────────────┘

Usage (Server):
    from mojo_socket import TcpListener, TcpSocket

    fn main() raises:
        var listener = TcpListener.bind(8080)
        print("Listening on port 8080...")

        while True:
            var client = listener.accept()
            var request = client.recv(4096)
            client.send("HTTP/1.1 200 OK\\r\\n\\r\\nHello from Mojo!")
            client.close()

Usage (Client):
    from mojo_socket import TcpStream

    fn main() raises:
        var stream = TcpStream.connect("httpbin.org", 80)
        stream.send("GET /get HTTP/1.1\\r\\nHost: httpbin.org\\r\\n\\r\\n")
        var response = stream.recv(4096)
        print(response)
        stream.close()
"""

# Constants
from .constants import (
    # Address families
    AF_INET,
    AF_INET6,
    AF_UNIX,
    # Socket types
    SOCK_STREAM,
    SOCK_DGRAM,
    # Socket options
    SOL_SOCKET,
    SO_REUSEADDR,
    SO_KEEPALIVE,
    SO_RCVTIMEO,
    SO_SNDTIMEO,
    TCP_NODELAY,
    # Shutdown options
    SHUT_RD,
    SHUT_WR,
    SHUT_RDWR,
    # Special addresses
    INADDR_ANY,
    INADDR_LOOPBACK,
    # Defaults
    DEFAULT_BACKLOG,
    DEFAULT_RECV_BUFFER,
)

# FFI utilities (for advanced use)
from .ffi import (
    SockAddrIn,
    Timeval,
    htons,
    ntohs,
    htonl,
    ntohl,
    parse_ipv4,
)

# High-level socket API
from .socket import (
    SocketError,
    SocketAddress,
    TcpSocket,
    TcpListener,
    TcpStream,
)
