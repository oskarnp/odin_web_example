package example_http

import "core:strings"
import "core:os"

import sock "../sock"

Options :: struct {
	method: string,
	header: map[string]string,
}

build :: proc(host: string, path: string, options: Options, allocator := context.allocator) -> string {
	sb := strings.make_builder(allocator);
	strings.write_string(&sb, "GET" if options.method == "" else options.method);
	strings.write_string(&sb, " ");
	strings.write_string(&sb, path);
	strings.write_string(&sb, " HTTP/1.0\r\n");
	strings.write_string(&sb, "Host: ");
	strings.write_string(&sb, host);
	strings.write_string(&sb, "\r\n");
	for key, value in options.header {
		strings.write_string(&sb, key);
		strings.write_string(&sb, ": ");
		strings.write_string(&sb, value);
		strings.write_string(&sb, "\r\n");
	}
	strings.write_string(&sb, "\r\n");
	return strings.to_string(sb);
}
