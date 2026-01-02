"""
C FFI bindings for POSIX socket functions.

Uses Mojo's external_call to interface with C socket library.
"""

from sys.ffi import external_call
from memory import UnsafePointer


# =============================================================================
# C Struct Definitions
# =============================================================================

@register_passable("trivial")
struct SockAddrIn:
    """
    C sockaddr_in structure for IPv4 addresses.

    struct sockaddr_in {
        sa_family_t    sin_family;   // AF_INET
        in_port_t      sin_port;     // Port (network byte order)
        struct in_addr sin_addr;     // IPv4 address
        char           sin_zero[8];  // Padding
    };
    """
    var sin_len: UInt8       # Length (BSD-style, macOS)
    var sin_family: UInt8    # Address family (AF_INET)
    var sin_port: UInt16     # Port number (network byte order)
    var sin_addr: UInt32     # IPv4 address (network byte order)
    var sin_zero: UInt64     # Padding (8 bytes as UInt64)

    fn __init__(out self):
        self.sin_len = 16      # sizeof(sockaddr_in)
        self.sin_family = 2    # AF_INET
        self.sin_port = 0
        self.sin_addr = 0
        self.sin_zero = 0

    fn __init__(out self, family: UInt8, port: UInt16, addr: UInt32):
        self.sin_len = 16
        self.sin_family = family
        self.sin_port = port
        self.sin_addr = addr
        self.sin_zero = 0


@register_passable("trivial")
struct Timeval:
    """C timeval structure for socket timeouts."""
    var tv_sec: Int64   # Seconds
    var tv_usec: Int32  # Microseconds

    fn __init__(out self, seconds: Int64, microseconds: Int32):
        self.tv_sec = seconds
        self.tv_usec = microseconds


# =============================================================================
# Byte Order Conversion (Network byte order is big-endian)
# =============================================================================

fn htons(value: UInt16) -> UInt16:
    """Host to network short (16-bit)."""
    # Swap bytes for little-endian systems (ARM64/x86_64)
    return ((value & 0xFF) << 8) | ((value >> 8) & 0xFF)


fn ntohs(value: UInt16) -> UInt16:
    """Network to host short (16-bit)."""
    return htons(value)  # Same operation


fn htonl(value: UInt32) -> UInt32:
    """Host to network long (32-bit)."""
    return (
        ((value & 0xFF) << 24) |
        ((value & 0xFF00) << 8) |
        ((value & 0xFF0000) >> 8) |
        ((value >> 24) & 0xFF)
    )


fn ntohl(value: UInt32) -> UInt32:
    """Network to host long (32-bit)."""
    return htonl(value)  # Same operation


# =============================================================================
# IP Address Parsing
# =============================================================================

fn parse_ipv4(ip_str: String) -> UInt32:
    """
    Parse IPv4 address string to network byte order UInt32.

    Example: "127.0.0.1" -> 0x7F000001 (in network byte order)
    """
    if ip_str == "0.0.0.0":
        return 0

    if ip_str == "127.0.0.1" or ip_str == "localhost":
        return htonl(0x7F000001)

    # Parse dotted decimal notation
    var parts = ip_str.split(".")
    if len(parts) != 4:
        return 0

    var result: UInt32 = 0
    try:
        var a = Int(parts[0])
        var b = Int(parts[1])
        var c = Int(parts[2])
        var d = Int(parts[3])
        result = UInt32((a << 24) | (b << 16) | (c << 8) | d)
        return htonl(result)
    except:
        return 0


# =============================================================================
# Socket System Calls (C FFI)
# =============================================================================

fn c_socket(domain: Int32, sock_type: Int32, protocol: Int32) -> Int32:
    """
    Create a socket.

    int socket(int domain, int type, int protocol);
    """
    return external_call["socket", Int32, Int32, Int32, Int32](
        domain, sock_type, protocol
    )


fn c_bind(sockfd: Int32, addr: UnsafePointer[SockAddrIn], addrlen: UInt32) -> Int32:
    """
    Bind socket to address.

    int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
    """
    return external_call["bind", Int32, Int32, UnsafePointer[SockAddrIn], UInt32](
        sockfd, addr, addrlen
    )


fn c_listen(sockfd: Int32, backlog: Int32) -> Int32:
    """
    Listen for connections.

    int listen(int sockfd, int backlog);
    """
    return external_call["listen", Int32, Int32, Int32](sockfd, backlog)


fn c_accept(sockfd: Int32, addr: UnsafePointer[SockAddrIn], addrlen: UnsafePointer[UInt32]) -> Int32:
    """
    Accept incoming connection.

    int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
    """
    return external_call["accept", Int32, Int32, UnsafePointer[SockAddrIn], UnsafePointer[UInt32]](
        sockfd, addr, addrlen
    )


fn c_connect(sockfd: Int32, addr: UnsafePointer[SockAddrIn], addrlen: UInt32) -> Int32:
    """
    Connect to remote address.

    int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
    """
    return external_call["connect", Int32, Int32, UnsafePointer[SockAddrIn], UInt32](
        sockfd, addr, addrlen
    )


fn c_recv(sockfd: Int32, buf: UnsafePointer[UInt8], length: Int, flags: Int32) -> Int:
    """
    Receive data from socket.

    ssize_t recv(int sockfd, void *buf, size_t len, int flags);
    """
    return external_call["recv", Int, Int32, UnsafePointer[UInt8], Int, Int32](
        sockfd, buf, length, flags
    )


fn c_send(sockfd: Int32, buf: UnsafePointer[UInt8], length: Int, flags: Int32) -> Int:
    """
    Send data to socket.

    ssize_t send(int sockfd, const void *buf, size_t len, int flags);
    """
    return external_call["send", Int, Int32, UnsafePointer[UInt8], Int, Int32](
        sockfd, buf, length, flags
    )


fn c_close(fd: Int32) -> Int32:
    """
    Close file descriptor.

    int close(int fd);
    """
    return external_call["close", Int32, Int32](fd)


fn c_shutdown(sockfd: Int32, how: Int32) -> Int32:
    """
    Shutdown socket.

    int shutdown(int sockfd, int how);
    """
    return external_call["shutdown", Int32, Int32, Int32](sockfd, how)


fn c_setsockopt(
    sockfd: Int32,
    level: Int32,
    optname: Int32,
    optval: UnsafePointer[Int32],
    optlen: UInt32
) -> Int32:
    """
    Set socket options.

    int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);
    """
    return external_call["setsockopt", Int32, Int32, Int32, Int32, UnsafePointer[Int32], UInt32](
        sockfd, level, optname, optval, optlen
    )


fn c_getsockopt(
    sockfd: Int32,
    level: Int32,
    optname: Int32,
    optval: UnsafePointer[Int32],
    optlen: UnsafePointer[UInt32]
) -> Int32:
    """
    Get socket options.

    int getsockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen);
    """
    return external_call["getsockopt", Int32, Int32, Int32, Int32, UnsafePointer[Int32], UnsafePointer[UInt32]](
        sockfd, level, optname, optval, optlen
    )


fn c_errno() -> Int32:
    """Get last error number."""
    # Note: errno is thread-local, we access it via __error on macOS
    var errno_ptr = external_call["__error", UnsafePointer[Int32]]()
    return errno_ptr[]
