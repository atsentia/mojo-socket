"""
Pure Mojo TCP Socket implementation.

Provides a high-level, Mojo-friendly API for TCP networking
using C FFI to call POSIX socket functions directly.

No Python dependency!
"""

from memory import UnsafePointer
from .constants import (
    AF_INET, SOCK_STREAM, IPPROTO_TCP,
    SOL_SOCKET, SO_REUSEADDR, SO_KEEPALIVE, SO_RCVTIMEO, SO_SNDTIMEO,
    DEFAULT_BACKLOG, DEFAULT_RECV_BUFFER,
    SHUT_RD, SHUT_WR, SHUT_RDWR,
    SOCKET_ERROR, INVALID_SOCKET,
)
from .ffi import (
    SockAddrIn, Timeval,
    htons, ntohs, htonl, ntohl, parse_ipv4,
    c_socket, c_bind, c_listen, c_accept, c_connect,
    c_recv, c_send, c_close, c_shutdown, c_setsockopt, c_errno,
)


# =============================================================================
# Socket Error
# =============================================================================

struct SocketError:
    """Represents a socket error."""
    var code: Int32
    var message: String

    fn __init__(out self, code: Int32, message: String):
        self.code = code
        self.message = message

    fn __init__(out self, message: String):
        self.code = c_errno()
        self.message = message

    fn __str__(self) -> String:
        return "SocketError(" + str(self.code) + "): " + self.message


# =============================================================================
# Socket Address
# =============================================================================

struct SocketAddress:
    """Represents a socket address (host:port)."""
    var host: String
    var port: Int

    fn __init__(out self, host: String, port: Int):
        self.host = host
        self.port = port

    fn __init__(out self, port: Int):
        """Bind to all interfaces (0.0.0.0)."""
        self.host = "0.0.0.0"
        self.port = port

    fn __str__(self) -> String:
        return self.host + ":" + str(self.port)

    fn to_sockaddr(self) -> SockAddrIn:
        """Convert to C sockaddr_in structure."""
        var addr = SockAddrIn()
        addr.sin_family = UInt8(AF_INET)
        addr.sin_port = htons(UInt16(self.port))
        addr.sin_addr = parse_ipv4(self.host)
        return addr


# =============================================================================
# TCP Socket
# =============================================================================

struct TcpSocket:
    """
    A TCP socket for network communication.

    Example:
        var socket = TcpSocket()
        socket.bind(SocketAddress(8080))
        socket.listen()
        var client = socket.accept()
        var data = client.recv(1024)
        client.send("HTTP/1.1 200 OK\r\n\r\nHello!")
        client.close()
        socket.close()
    """
    var fd: Int32
    var is_bound: Bool
    var is_listening: Bool
    var is_connected: Bool
    var local_address: SocketAddress
    var remote_address: SocketAddress

    fn __init__(out self):
        """Create a new TCP socket."""
        self.fd = c_socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
        self.is_bound = False
        self.is_listening = False
        self.is_connected = False
        self.local_address = SocketAddress("0.0.0.0", 0)
        self.remote_address = SocketAddress("0.0.0.0", 0)

    fn __init__(out self, fd: Int32, remote: SocketAddress):
        """Create socket from existing file descriptor (for accepted connections)."""
        self.fd = fd
        self.is_bound = False
        self.is_listening = False
        self.is_connected = True
        self.local_address = SocketAddress("0.0.0.0", 0)
        self.remote_address = remote

    fn __del__(owned self):
        """Close socket on destruction."""
        if self.fd != INVALID_SOCKET:
            _ = c_close(self.fd)

    fn is_valid(self) -> Bool:
        """Check if socket file descriptor is valid."""
        return self.fd != INVALID_SOCKET

    # =========================================================================
    # Socket Options
    # =========================================================================

    fn set_reuse_address(inout self, enabled: Bool) raises:
        """Enable/disable SO_REUSEADDR option."""
        var value: Int32 = 1 if enabled else 0
        var value_ptr = UnsafePointer[Int32].address_of(value)
        var result = c_setsockopt(
            self.fd, SOL_SOCKET, SO_REUSEADDR, value_ptr, 4
        )
        if result == SOCKET_ERROR:
            raise Error("Failed to set SO_REUSEADDR: " + str(c_errno()))

    fn set_keepalive(inout self, enabled: Bool) raises:
        """Enable/disable TCP keepalive."""
        var value: Int32 = 1 if enabled else 0
        var value_ptr = UnsafePointer[Int32].address_of(value)
        var result = c_setsockopt(
            self.fd, SOL_SOCKET, SO_KEEPALIVE, value_ptr, 4
        )
        if result == SOCKET_ERROR:
            raise Error("Failed to set SO_KEEPALIVE: " + str(c_errno()))

    fn set_recv_timeout(inout self, seconds: Int) raises:
        """Set receive timeout in seconds."""
        var tv = Timeval(Int64(seconds), 0)
        var tv_ptr = UnsafePointer[Timeval].address_of(tv)
        # Cast to expected type for setsockopt
        var result = c_setsockopt(
            self.fd, SOL_SOCKET, SO_RCVTIMEO,
            tv_ptr.bitcast[Int32](), UInt32(sizeof[Timeval]())
        )
        if result == SOCKET_ERROR:
            raise Error("Failed to set SO_RCVTIMEO: " + str(c_errno()))

    fn set_send_timeout(inout self, seconds: Int) raises:
        """Set send timeout in seconds."""
        var tv = Timeval(Int64(seconds), 0)
        var tv_ptr = UnsafePointer[Timeval].address_of(tv)
        var result = c_setsockopt(
            self.fd, SOL_SOCKET, SO_SNDTIMEO,
            tv_ptr.bitcast[Int32](), UInt32(sizeof[Timeval]())
        )
        if result == SOCKET_ERROR:
            raise Error("Failed to set SO_SNDTIMEO: " + str(c_errno()))

    # =========================================================================
    # Server Operations
    # =========================================================================

    fn bind(inout self, address: SocketAddress) raises:
        """Bind socket to a local address."""
        if not self.is_valid():
            raise Error("Invalid socket")

        var addr = address.to_sockaddr()
        var addr_ptr = UnsafePointer[SockAddrIn].address_of(addr)

        var result = c_bind(self.fd, addr_ptr, 16)  # sizeof(sockaddr_in) = 16
        if result == SOCKET_ERROR:
            raise Error("Failed to bind to " + str(address) + ": " + str(c_errno()))

        self.is_bound = True
        self.local_address = address

    fn listen(inout self, backlog: Int = DEFAULT_BACKLOG) raises:
        """Start listening for connections."""
        if not self.is_bound:
            raise Error("Socket not bound")

        var result = c_listen(self.fd, Int32(backlog))
        if result == SOCKET_ERROR:
            raise Error("Failed to listen: " + str(c_errno()))

        self.is_listening = True

    fn accept(self) raises -> TcpSocket:
        """Accept an incoming connection."""
        if not self.is_listening:
            raise Error("Socket not listening")

        var client_addr = SockAddrIn()
        var addr_len: UInt32 = 16
        var addr_ptr = UnsafePointer[SockAddrIn].address_of(client_addr)
        var len_ptr = UnsafePointer[UInt32].address_of(addr_len)

        var client_fd = c_accept(self.fd, addr_ptr, len_ptr)
        if client_fd == INVALID_SOCKET:
            raise Error("Failed to accept connection: " + str(c_errno()))

        # Extract client address
        var port = Int(ntohs(client_addr.sin_port))
        var ip = ntohl(client_addr.sin_addr)
        var ip_str = (
            str((ip >> 24) & 0xFF) + "." +
            str((ip >> 16) & 0xFF) + "." +
            str((ip >> 8) & 0xFF) + "." +
            str(ip & 0xFF)
        )

        return TcpSocket(client_fd, SocketAddress(ip_str, port))

    # =========================================================================
    # Client Operations
    # =========================================================================

    fn connect(inout self, address: SocketAddress) raises:
        """Connect to a remote address."""
        if not self.is_valid():
            raise Error("Invalid socket")

        var addr = address.to_sockaddr()
        var addr_ptr = UnsafePointer[SockAddrIn].address_of(addr)

        var result = c_connect(self.fd, addr_ptr, 16)
        if result == SOCKET_ERROR:
            raise Error("Failed to connect to " + str(address) + ": " + str(c_errno()))

        self.is_connected = True
        self.remote_address = address

    # =========================================================================
    # Data Transfer
    # =========================================================================

    fn recv(self, max_bytes: Int = DEFAULT_RECV_BUFFER) raises -> String:
        """Receive data from the socket."""
        var buffer = UnsafePointer[UInt8].alloc(max_bytes)

        var bytes_received = c_recv(self.fd, buffer, max_bytes, 0)
        if bytes_received < 0:
            buffer.free()
            raise Error("Failed to receive data: " + str(c_errno()))

        if bytes_received == 0:
            buffer.free()
            return ""  # Connection closed

        # Convert to String
        var result = String()
        for i in range(bytes_received):
            result += chr(Int(buffer[i]))

        buffer.free()
        return result

    fn recv_bytes(self, max_bytes: Int = DEFAULT_RECV_BUFFER) raises -> List[UInt8]:
        """Receive raw bytes from the socket."""
        var buffer = UnsafePointer[UInt8].alloc(max_bytes)

        var bytes_received = c_recv(self.fd, buffer, max_bytes, 0)
        if bytes_received < 0:
            buffer.free()
            raise Error("Failed to receive data: " + str(c_errno()))

        var result = List[UInt8]()
        for i in range(bytes_received):
            result.append(buffer[i])

        buffer.free()
        return result

    fn send(self, data: String) raises -> Int:
        """Send string data to the socket."""
        var length = len(data)
        var buffer = UnsafePointer[UInt8].alloc(length)

        for i in range(length):
            buffer[i] = UInt8(ord(data[i]))

        var bytes_sent = c_send(self.fd, buffer, length, 0)
        buffer.free()

        if bytes_sent < 0:
            raise Error("Failed to send data: " + str(c_errno()))

        return bytes_sent

    fn send_bytes(self, data: List[UInt8]) raises -> Int:
        """Send raw bytes to the socket."""
        var length = len(data)
        var buffer = UnsafePointer[UInt8].alloc(length)

        for i in range(length):
            buffer[i] = data[i]

        var bytes_sent = c_send(self.fd, buffer, length, 0)
        buffer.free()

        if bytes_sent < 0:
            raise Error("Failed to send data: " + str(c_errno()))

        return bytes_sent

    fn send_all(self, data: String) raises:
        """Send all data, handling partial sends."""
        var remaining = data
        while len(remaining) > 0:
            var sent = self.send(remaining)
            if sent == 0:
                raise Error("Connection closed during send")
            remaining = remaining[sent:]

    # =========================================================================
    # Connection Management
    # =========================================================================

    fn shutdown(inout self, how: Int32 = SHUT_RDWR) raises:
        """Shutdown socket for reading, writing, or both."""
        var result = c_shutdown(self.fd, how)
        if result == SOCKET_ERROR:
            raise Error("Failed to shutdown socket: " + str(c_errno()))

    fn close(inout self):
        """Close the socket."""
        if self.fd != INVALID_SOCKET:
            _ = c_close(self.fd)
            self.fd = INVALID_SOCKET
            self.is_bound = False
            self.is_listening = False
            self.is_connected = False


# =============================================================================
# TCP Listener (Convenience wrapper)
# =============================================================================

struct TcpListener:
    """
    A TCP server socket for accepting connections.

    Example:
        var listener = TcpListener.bind(8080)
        while True:
            var client = listener.accept()
            handle_client(client)
    """
    var socket: TcpSocket
    var address: SocketAddress

    fn __init__(out self, address: SocketAddress) raises:
        """Create a TCP listener."""
        self.socket = TcpSocket()
        self.address = address
        self.socket.set_reuse_address(True)
        self.socket.bind(address)
        self.socket.listen()

    @staticmethod
    fn bind(port: Int) raises -> TcpListener:
        """Bind to all interfaces on the given port."""
        return TcpListener(SocketAddress("0.0.0.0", port))

    @staticmethod
    fn bind(host: String, port: Int) raises -> TcpListener:
        """Bind to specific host and port."""
        return TcpListener(SocketAddress(host, port))

    fn accept(self) raises -> TcpSocket:
        """Accept an incoming connection."""
        return self.socket.accept()

    fn close(inout self):
        """Close the listener."""
        self.socket.close()


# =============================================================================
# TCP Stream (Client connection)
# =============================================================================

struct TcpStream:
    """
    A TCP client connection.

    Example:
        var stream = TcpStream.connect("example.com", 80)
        stream.send("GET / HTTP/1.1\r\nHost: example.com\r\n\r\n")
        var response = stream.recv(4096)
        stream.close()
    """
    var socket: TcpSocket

    fn __init__(out self, socket: TcpSocket):
        self.socket = socket

    @staticmethod
    fn connect(host: String, port: Int) raises -> TcpStream:
        """Connect to a remote host."""
        var socket = TcpSocket()
        socket.connect(SocketAddress(host, port))
        return TcpStream(socket)

    fn recv(self, max_bytes: Int = DEFAULT_RECV_BUFFER) raises -> String:
        """Receive data."""
        return self.socket.recv(max_bytes)

    fn send(self, data: String) raises -> Int:
        """Send data."""
        return self.socket.send(data)

    fn send_all(self, data: String) raises:
        """Send all data."""
        self.socket.send_all(data)

    fn close(inout self):
        """Close the connection."""
        self.socket.close()
