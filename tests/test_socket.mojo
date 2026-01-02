"""
Tests for mojo-socket library.
"""

from testing import assert_equal, assert_true, assert_false

from mojo_socket import (
    SocketAddress,
    TcpSocket,
    TcpListener,
    htons,
    ntohs,
    htonl,
    ntohl,
    parse_ipv4,
    AF_INET,
    SOCK_STREAM,
)


fn test_htons_ntohs():
    """Test byte order conversion for 16-bit values."""
    var port: UInt16 = 8080
    var network_order = htons(port)
    var host_order = ntohs(network_order)
    assert_equal(host_order, port)
    print("  [PASS] test_htons_ntohs")


fn test_htonl_ntohl():
    """Test byte order conversion for 32-bit values."""
    var addr: UInt32 = 0x7F000001  # 127.0.0.1
    var network_order = htonl(addr)
    var host_order = ntohl(network_order)
    assert_equal(host_order, addr)
    print("  [PASS] test_htonl_ntohl")


fn test_parse_ipv4_any():
    """Test parsing 0.0.0.0."""
    var addr = parse_ipv4("0.0.0.0")
    assert_equal(addr, UInt32(0))
    print("  [PASS] test_parse_ipv4_any")


fn test_parse_ipv4_localhost():
    """Test parsing 127.0.0.1."""
    var addr = parse_ipv4("127.0.0.1")
    var expected = htonl(0x7F000001)
    assert_equal(addr, expected)
    print("  [PASS] test_parse_ipv4_localhost")


fn test_socket_address():
    """Test SocketAddress creation and string conversion."""
    var addr = SocketAddress("127.0.0.1", 8080)
    assert_equal(addr.host, "127.0.0.1")
    assert_equal(addr.port, 8080)
    assert_equal(str(addr), "127.0.0.1:8080")
    print("  [PASS] test_socket_address")


fn test_socket_address_default():
    """Test SocketAddress with default host."""
    var addr = SocketAddress(8080)
    assert_equal(addr.host, "0.0.0.0")
    assert_equal(addr.port, 8080)
    print("  [PASS] test_socket_address_default")


fn test_socket_address_to_sockaddr():
    """Test conversion to C sockaddr_in."""
    var addr = SocketAddress("127.0.0.1", 8080)
    var sockaddr = addr.to_sockaddr()

    assert_equal(sockaddr.sin_family, UInt8(AF_INET))
    assert_equal(sockaddr.sin_port, htons(8080))
    print("  [PASS] test_socket_address_to_sockaddr")


fn test_tcp_socket_creation():
    """Test creating a TCP socket."""
    var socket = TcpSocket()
    assert_true(socket.is_valid())
    assert_false(socket.is_bound)
    assert_false(socket.is_listening)
    assert_false(socket.is_connected)
    socket.close()
    print("  [PASS] test_tcp_socket_creation")


fn test_tcp_socket_bind():
    """Test binding a socket to an address."""
    try:
        var socket = TcpSocket()
        socket.set_reuse_address(True)
        socket.bind(SocketAddress("127.0.0.1", 19876))
        assert_true(socket.is_bound)
        socket.close()
        print("  [PASS] test_tcp_socket_bind")
    except e:
        print("  [FAIL] test_tcp_socket_bind:", e)


fn test_tcp_socket_listen():
    """Test listening on a socket."""
    try:
        var socket = TcpSocket()
        socket.set_reuse_address(True)
        socket.bind(SocketAddress("127.0.0.1", 19877))
        socket.listen()
        assert_true(socket.is_listening)
        socket.close()
        print("  [PASS] test_tcp_socket_listen")
    except e:
        print("  [FAIL] test_tcp_socket_listen:", e)


fn test_tcp_listener_creation():
    """Test TcpListener convenience wrapper."""
    try:
        var listener = TcpListener.bind("127.0.0.1", 19878)
        assert_true(listener.socket.is_listening)
        listener.close()
        print("  [PASS] test_tcp_listener_creation")
    except e:
        print("  [FAIL] test_tcp_listener_creation:", e)


fn test_socket_options():
    """Test setting socket options."""
    try:
        var socket = TcpSocket()
        socket.set_reuse_address(True)
        socket.set_keepalive(True)
        socket.close()
        print("  [PASS] test_socket_options")
    except e:
        print("  [FAIL] test_socket_options:", e)


fn main():
    """Run all tests."""
    print("Running mojo-socket tests...")
    print()

    # Byte order tests
    test_htons_ntohs()
    test_htonl_ntohl()

    # IP parsing tests
    test_parse_ipv4_any()
    test_parse_ipv4_localhost()

    # SocketAddress tests
    test_socket_address()
    test_socket_address_default()
    test_socket_address_to_sockaddr()

    # TcpSocket tests
    test_tcp_socket_creation()
    test_tcp_socket_bind()
    test_tcp_socket_listen()
    test_tcp_listener_creation()
    test_socket_options()

    print()
    print("All tests passed!")
