#ifndef CLIENT_TOOL_H
#define CLIENT_TOOL_H

#include <stdint.h>
#include "protocol.h"

#define RECV_BUF_SIZE 4096
#define MAX_GROUP_NAME_LEN 32

extern int sock_fd;
extern char my_username[MAX_USERNAME_LEN];
extern int g_mode;
extern char g_target_private[MAX_USERNAME_LEN];
extern char g_target_group[MAX_GROUP_NAME_LEN];

void safe_strcpy(char *dest, const char *src, size_t size);
int send_message(uint8_t type, const void *body, uint16_t body_len);
int recv_full(void *buf, size_t len);
struct chat_message *recv_message();
void clear_line();
void print_server(const char *msg);
void print_system(const char *fmt, ...);
void show_main_menu();

#endif
