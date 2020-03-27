package web_example

import "core:fmt"
import "core:log"
import http "./http"
import sock "./sock"

main :: proc() {
	context.logger = log.create_console_logger();

	host := "example.com";

	request := http.build(host, "/", {
		method = "GET",
		header = {
			"Content-Type" = "text/plain",
		},
	});
	defer delete(request);

	log.info("Connecting...");
	socket, ok := sock.tcp_open(host, "http");
	if !ok do panic("Failed connect.");
	defer sock.close(socket);
	log.info("Connected.");

	log.info("Sending...");
	{
		n, ok := sock.send(socket, request);
		if !ok do panic("Failed send");
		log.infof("Sent %d bytes.", n);
	}

	log.info("Receiving...");
	{
		buffer: [4096] byte;
		total: int;
		for {
			n, ok := sock.recv(socket, buffer[:]);
			if n == 0 || !ok do break;
			fmt.println(string(buffer[:n]));
			total += n;
		}
		log.infof("Received %d bytes.\n", total);
	}
}
