# 编译器和标志
CC = gcc
CFLAGS = -pthread

client: client.c client_tool.c client_tool.h protocol.h
	$(CC) $(CFLAGS) -o client client.c client_tool.c

server: server.c server_tool.c server_tool.h protocol.h
	$(CC) $(CFLAGS) -o server server.c server_tool.c

clean:
	rm -f client server

.PHONY: client server
