#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <sys/socket.h>
#include <stdarg.h>

#include "protocol.h"
#include "client_tool.h"

int sock_fd = -1;
char my_username[MAX_USERNAME_LEN] = {0};

int g_mode = 0;  // 0主菜单, 1私聊, 2群聊
char g_target_private[MAX_USERNAME_LEN] = {0};
char g_target_group[MAX_GROUP_NAME_LEN] = {0};

void safe_strcpy(char *dest, const char *src, size_t size) {
    strncpy(dest, src, size - 1);
    dest[size - 1] = '\0';
}

int send_message(uint8_t type, const void *body, uint16_t body_len) {
    uint16_t total_len = sizeof(struct chat_header) + body_len;
    uint8_t *buf = malloc(total_len);
    if (!buf) return -1;

    struct chat_header *h = (struct chat_header *)buf;
    h->magic   = CHAT_MAGIC;
    h->version = CHAT_VERSION;
    h->type    = type;
    h->length  = total_len;

    if (body && body_len) 
        memcpy(buf + sizeof(struct chat_header), body, body_len);

    int ret = (write(sock_fd, buf, total_len) == total_len) ? 0 : -1;
    free(buf);
    return ret;
}

int recv_full(void *buf, size_t len) {
    size_t recvd = 0;
    while (recvd < len) {
        ssize_t r = read(sock_fd, (uint8_t*)buf + recvd, len - recvd);
        if (r <= 0) 
            return -1;
        recvd += r;
    }
    return 0;
}

struct chat_message *recv_message() {
    struct chat_header header;
    if (recv_full(&header, sizeof(header)) != 0) 
        return NULL;

    if (header.magic != CHAT_MAGIC || header.version != CHAT_VERSION || \
        header.length < sizeof(header) || header.length > RECV_BUF_SIZE) {
        return NULL;
    }

    uint16_t body_len = header.length - sizeof(header);
    struct chat_message *msg = malloc(header.length);
    if (!msg) 
        return NULL;

    memcpy(msg, &header, sizeof(header));
    if (body_len && recv_full((uint8_t*)msg + sizeof(header), body_len) != 0) {
        free(msg);
        return NULL;
    }
    return msg;
}

void clear_line() {
    printf("\r\033[K");
    fflush(stdout);
}

void print_server(const char *msg) {
    clear_line();
    printf("[服务器] %s\n", msg);
    fflush(stdout);
}

void print_system(const char *fmt, ...) {
    clear_line();
    printf("[系统] ");
    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
    printf("\n");
    fflush(stdout);
}

void show_main_menu() {
    printf("\n");
    printf("=== 聊天系统主菜单 ===\n");
    printf("1. 查看好友列表\n");
    printf("2. 添加好友\n");
    printf("3. 私聊好友\n");
    printf("4. 创建群聊\n");
    printf("5. 加入群聊\n");
    printf("6. 查看我的群聊并进入\n");
    printf("7. 删除好友\n");
    printf("8. 退出群聊\n");
    printf("9. 退出登录\n");
    printf("> ");
    fflush(stdout);
}
