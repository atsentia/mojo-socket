# mojo-socket

Pure Mojo TCP sockets via C FFI - **no Python required!**

## Architecture

```
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
```

**Python Usage**: 0% (pure Mojo + C FFI)

## Features

- **Pure Mojo**: No Python dependencies
- **C FFI**: Direct POSIX socket calls via `external_call`
- **High-Level API**: `TcpSocket`, `TcpListener`, `TcpStream`
- **Socket Options**: SO_REUSEADDR, SO_KEEPALIVE, timeouts
- **IPv4 Support**: Address parsing, byte order conversion
- **Cross-Platform**: macOS ARM64, Linux x86_64

## Installation

Add to your `pixi.toml`:

```toml
[workspace.dependencies]
mojo-socket = { path = "../mojo-libs/mojo-socket" }
```

## Usage

### TCP Server

```mojo
from mojo_socket import TcpListener, TcpSocket

fn main() raises:
    # Create server socket
    var listener = TcpListener.bind(8080)
    print("Listening on port 8080...")

    while True:
        # Accept connection
        var client = listener.accept()
        print("Client connected from: " + str(client.remote_address))

        # Receive request
        var request = client.recv(4096)
        print("Received: " + request[:50] + "...")

        # Send response
        var response = "HTTP/1.1 200 OK\r\n"
        response += "Content-Type: text/plain\r\n"
        response += "Content-Length: 13\r\n"
        response += "\r\n"
        response += "Hello, Mojo!"
        _ = client.send(response)

        # Close connection
        client.close()
```

### TCP Client

```mojo
from mojo_socket import TcpStream

fn main() raises:
    # Connect to server
    var stream = TcpStream.connect("httpbin.org", 80)

    # Send HTTP request
    var request = "GET /get HTTP/1.1\r\n"
    request += "Host: httpbin.org\r\n"
    request += "Connection: close\r\n"
    request += "\r\n"
    stream.send_all(request)

    # Receive response
    var response = stream.recv(4096)
    print(response)

    stream.close()
```

### Low-Level Socket API

```mojo
from mojo_socket import TcpSocket, SocketAddress

fn main() raises:
    # Create socket
    var socket = TcpSocket()

    # Set options
    socket.set_reuse_address(True)
    socket.set_keepalive(True)
    socket.set_recv_timeout(30)  # 30 seconds

    # Bind and listen
    socket.bind(SocketAddress("0.0.0.0", 8080))
    socket.listen(128)  # backlog of 128 connections

    # Accept connections
    var client = socket.accept()
    print("Client IP: " + client.remote_address.host)
    print("Client Port: " + str(client.remote_address.port))

    # Receive/send data
    var data = client.recv(1024)
    _ = client.send("Response")

    # Cleanup
    client.close()
    socket.close()
```

## API Reference

### TcpSocket

| Method | Description |
|--------|-------------|
| `TcpSocket()` | Create new TCP socket |
| `is_valid()` | Check if socket FD is valid |
| `set_reuse_address(enabled)` | Enable SO_REUSEADDR |
| `set_keepalive(enabled)` | Enable TCP keepalive |
| `set_recv_timeout(seconds)` | Set receive timeout |
| `set_send_timeout(seconds)` | Set send timeout |
| `bind(address)` | Bind to local address |
| `listen(backlog)` | Start listening |
| `accept()` | Accept connection, returns TcpSocket |
| `connect(address)` | Connect to remote address |
| `recv(max_bytes)` | Receive string data |
| `recv_bytes(max_bytes)` | Receive raw bytes |
| `send(data)` | Send string, returns bytes sent |
| `send_bytes(data)` | Send raw bytes |
| `send_all(data)` | Send all data (handles partial) |
| `shutdown(how)` | Shutdown socket |
| `close()` | Close socket |

### TcpListener

| Method | Description |
|--------|-------------|
| `TcpListener.bind(port)` | Bind to all interfaces |
| `TcpListener.bind(host, port)` | Bind to specific host |
| `accept()` | Accept connection |
| `close()` | Close listener |

### TcpStream

| Method | Description |
|--------|-------------|
| `TcpStream.connect(host, port)` | Connect to host |
| `recv(max_bytes)` | Receive data |
| `send(data)` | Send data |
| `send_all(data)` | Send all data |
| `close()` | Close connection |

### SocketAddress

| Property/Method | Description |
|-----------------|-------------|
| `host` | IP address string |
| `port` | Port number |
| `SocketAddress(port)` | Bind to 0.0.0.0 |
| `SocketAddress(host, port)` | Specific address |
| `to_sockaddr()` | Convert to C struct |

## C FFI Functions

The library wraps these POSIX socket functions:

```c
int socket(int domain, int type, int protocol);
int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
int listen(int sockfd, int backlog);
int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
ssize_t recv(int sockfd, void *buf, size_t len, int flags);
ssize_t send(int sockfd, const void *buf, size_t len, int flags);
int close(int fd);
int shutdown(int sockfd, int how);
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);
```

## Constants

```mojo
# Address families
AF_INET   # IPv4
AF_INET6  # IPv6

# Socket types
SOCK_STREAM  # TCP
SOCK_DGRAM   # UDP

# Socket options
SO_REUSEADDR
SO_KEEPALIVE
SO_RCVTIMEO
SO_SNDTIMEO
TCP_NODELAY

# Shutdown options
SHUT_RD     # No more receives
SHUT_WR     # No more sends
SHUT_RDWR   # Both

# Defaults
DEFAULT_BACKLOG = 128
DEFAULT_RECV_BUFFER = 4096
```

## Byte Order Functions

```mojo
from mojo_socket import htons, ntohs, htonl, ntohl, parse_ipv4

# Port conversion
var port = htons(8080)           # Host to network short
var host_port = ntohs(port)      # Network to host short

# Address conversion
var addr = htonl(0x7F000001)     # Host to network long
var host_addr = ntohl(addr)      # Network to host long

# IP parsing
var ip = parse_ipv4("192.168.1.1")  # Returns network byte order
```

## Error Handling

All methods that can fail use Mojo's `raises` mechanism:

```mojo
fn main() raises:
    try:
        var socket = TcpSocket()
        socket.bind(SocketAddress(8080))
    except e:
        print("Socket error: " + str(e))
```

## Platform Support

| Platform | Status |
|----------|--------|
| macOS ARM64 (M1/M2/M3) | ✅ Tested |
| Linux x86_64 | ✅ Supported |
| Linux ARM64 | ✅ Supported |
| Windows | ❌ Not supported (uses POSIX) |

## Comparison to Python

| Feature | Python `socket` | mojo-socket |
|---------|-----------------|-------------|
| Language | Python | Pure Mojo |
| Implementation | C extension | C FFI |
| Type Safety | Runtime | Compile-time |
| Performance | Interpreted | Compiled |
| Dependencies | Python runtime | None |

## Roadmap

- [ ] IPv6 support (AF_INET6)
- [ ] UDP sockets (SOCK_DGRAM)
- [ ] Unix domain sockets (AF_UNIX)
- [ ] Non-blocking I/O
- [ ] epoll/kqueue integration
- [ ] TLS support (via OpenSSL FFI)

## License

MIT
