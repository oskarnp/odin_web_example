// +build linux, darwin
package example_sock

import "core:c"
import "core:fmt"
import "core:strings"
import "core:mem"
import "core:os"

foreign import libc "system:c"

Sock_Addr :: struct {
	family: c.ushort,
	data:   [14] byte,
}

Addr_Info :: struct {
	flags:     c.int,
	family:    c.int,
	socktype:  c.int,
	protocol:  c.int,
	addrlen:   c.uint,
	canonname: cstring,
	addr:      ^Sock_Addr,
	next:      ^Addr_Info,
}

@(default_calling_convention="c")
foreign libc {
	@(link_name="socket")
	_posix_socket :: proc(domain, type, protocol: c.int) -> c.int ---

	@(link_name="send")
	_posix_send :: proc(socket: c.int, buffer: rawptr, length: c.size_t, flags: c.int) -> c.int ---

	@(link_name="recv")
	_posix_recv :: proc(socket: c.int, buffer: rawptr, length: c.size_t, flags: c.int) -> c.ssize_t ---

	@(link_name="connect")
	_posix_connect :: proc(socket: c.int, address: ^Sock_Addr, address_len: c.uint) -> c.int ---

	@(link_name="getaddrinfo")
	_posix_getaddrinfo :: proc(hostname, servname: cstring, hints: ^Addr_Info, res: ^^Addr_Info) -> c.int ---

	@(link_name="freeaddrinfo")
	_posix_freeaddrinfo :: proc(ai: ^Addr_Info) ---
}

Socket :: struct {
	handle: i32
}

_temp_cstring :: proc(s: string) -> cstring {
	return strings.clone_to_cstring(s, context.temp_allocator);
}

tcp_open :: proc(host, port: string) -> (s: Socket, ok: bool) {
	r:     c.int;
	hints: Addr_Info;
	res:   ^Addr_Info;

	AF_UNSPEC   :: 0;
	SOCK_STREAM :: 1;

	hints.family = AF_UNSPEC;
	hints.socktype = SOCK_STREAM;

	r = _posix_getaddrinfo(_temp_cstring(host), _temp_cstring(port), &hints, &res);
	defer _posix_freeaddrinfo(res);
	if r != 0 || res == nil do return {}, false;

	for ai := res; ai != nil && !ok; ai = ai.next {
		sfd := _posix_socket(ai.family, ai.socktype, ai.protocol);
		if sfd == -1 do continue;

		r = _posix_connect(sfd, ai.addr, ai.addrlen);
		if r == -1 {
			os.close(os.Handle(sfd));
			continue;
		}

		s = Socket{handle = sfd};
		ok = true;
	}

	return;
}

send :: proc{send_string, send_data};

send_string :: proc(s: Socket, str: string) -> (nsent: int, ok: bool) {
	return send_data(s, transmute([]byte) str);
}

send_data :: proc(s: Socket, data: []byte) -> (nsent: int, ok: bool) {
	data := data;
	for len(data) > 0 {
		n := _posix_send(s.handle, mem.raw_slice_data(data), c.size_t(len(data)), 0);
		if n <= 0 {
			fmt.println("error: send() failed");
			return;
		}
		nsent += int(n);
		data = data[n:];
	}
	ok = true;
	return;
}

recv :: proc(s: Socket, buf: []byte) -> (int, bool) {
	n := _posix_recv(s.handle, &buf[0], c.size_t(len(buf)), 0);
	switch {
		case n > 0:   return n, true;
		case n ==  0: return 0, true;
		case n == -1: return 0, false;
	}
	return 0, false;
}

close :: proc(s: Socket) {
	os.close(os.Handle(s.handle));
}
