"""
POSIX socket constants for C FFI.

These map directly to the C socket.h constants.
"""


# Address families
alias AF_UNSPEC: Int32 = 0
alias AF_UNIX: Int32 = 1
alias AF_INET: Int32 = 2      # IPv4
alias AF_INET6: Int32 = 30    # IPv6 (macOS value)

# Socket types
alias SOCK_STREAM: Int32 = 1  # TCP
alias SOCK_DGRAM: Int32 = 2   # UDP
alias SOCK_RAW: Int32 = 3

# Protocol
alias IPPROTO_TCP: Int32 = 6
alias IPPROTO_UDP: Int32 = 17

# Socket options level
alias SOL_SOCKET: Int32 = 0xFFFF  # macOS value

# Socket options
alias SO_REUSEADDR: Int32 = 0x0004
alias SO_KEEPALIVE: Int32 = 0x0008
alias SO_BROADCAST: Int32 = 0x0020
alias SO_LINGER: Int32 = 0x0080
alias SO_RCVBUF: Int32 = 0x1002
alias SO_SNDBUF: Int32 = 0x1001
alias SO_RCVTIMEO: Int32 = 0x1006
alias SO_SNDTIMEO: Int32 = 0x1005

# TCP options
alias TCP_NODELAY: Int32 = 1

# Special addresses
alias INADDR_ANY: UInt32 = 0
alias INADDR_LOOPBACK: UInt32 = 0x7F000001  # 127.0.0.1

# Backlog for listen()
alias DEFAULT_BACKLOG: Int32 = 128

# Buffer sizes
alias DEFAULT_RECV_BUFFER: Int = 4096
alias DEFAULT_SEND_BUFFER: Int = 4096

# Shutdown options
alias SHUT_RD: Int32 = 0    # No more receives
alias SHUT_WR: Int32 = 1    # No more sends
alias SHUT_RDWR: Int32 = 2  # No more receives or sends

# Error codes
alias SOCKET_ERROR: Int32 = -1
alias INVALID_SOCKET: Int32 = -1
