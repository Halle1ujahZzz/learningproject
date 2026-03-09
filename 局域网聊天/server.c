#include <stdio.h>       
#include <stdlib.h>      
#include <string.h>      
#include <unistd.h>      
#include <arpa/inet.h>   
#include <pthread.h>     

#include "protocol.h"    
#include "server_tool.h"

// 线程函数声明
void *handle_client(void *arg);

int main() {
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) { perror("socket"); exit(1); }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);
    addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(server_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind");
        exit(1);
    }
    if (listen(server_fd, BACKLOG) < 0) {
        perror("listen");
        exit(1);
    }

    printf("聊天服务器已启动，监听端口 %d\n", PORT);
    print_all_users();
    print_online_users();
    print_all_groups();

    while (1) {
        struct sockaddr_in client_addr;
        socklen_t len = sizeof(client_addr);
        int client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &len);
        if (client_fd < 0) continue;

        int *pfd = malloc(sizeof(int));
        *pfd = client_fd;
        pthread_t tid;
        pthread_create(&tid, NULL, handle_client, pfd);
        pthread_detach(tid);
    }

    close(server_fd);
    return 0;
}

void *handle_client(void *arg) {
    int fd = *(int*)arg;
    free(arg);
    char username[MAX_USERNAME_LEN] = {0};

    while (1) {
        struct chat_message *msg = recv_message(fd);
        if (!msg) break;

        switch (msg->header.type) {
            // 注册
            case MSG_TYPE_REGISTER: {
                struct msg_register *b = &msg->body.reg;
                struct generic_resp resp = {0};

                if (!is_alphanumeric(b->username)) {
                    resp.status = RESP_ERR_UNKNOWN;
                    safe_strcpy(resp.errmsg, "用户名只能包含英文和数字", MAX_ERROR_MSG_LEN);
                } else if (!is_alphanumeric(b->password)) {
                    resp.status = RESP_ERR_UNKNOWN;
                    safe_strcpy(resp.errmsg, "密码只能包含英文和数字", MAX_ERROR_MSG_LEN);
                } else if (user_exists(b->username)) {
                    resp.status = RESP_ERR_USER_EXIST;
                    safe_strcpy(resp.errmsg, "用户名已存在", MAX_ERROR_MSG_LEN);
                } else {
                    store_user(b->username, b->password);
                    resp.status = RESP_OK;
                    safe_strcpy(resp.errmsg, "注册成功", MAX_ERROR_MSG_LEN);
                }
                send_message(fd, MSG_TYPE_REGISTER_RESP, &resp, sizeof(resp));
                break;
            }
            // 登录
            case MSG_TYPE_LOGIN: { 
                struct msg_login *b = &msg->body.login;
                struct generic_resp resp = {0};

                if (!is_alphanumeric(b->username) || !is_alphanumeric(b->password)) {
                    resp.status = RESP_ERR_PASSWORD;
                    safe_strcpy(resp.errmsg, "用户名或密码格式错误（只能英文数字）", MAX_ERROR_MSG_LEN);
                } else if (!authenticate_user(b->username, b->password)) {
                    resp.status = RESP_ERR_PASSWORD;
                    safe_strcpy(resp.errmsg, "用户名或密码错误", MAX_ERROR_MSG_LEN);
                } else {
                    safe_strcpy(username, b->username, MAX_USERNAME_LEN);
                    add_online(fd, username);
                    resp.status = RESP_OK;
                    safe_strcpy(resp.errmsg, "登录成功", MAX_ERROR_MSG_LEN);
                    notify_friend_status(username, 1);
                }
                send_message(fd, MSG_TYPE_LOGIN_RESP, &resp, sizeof(resp));
                break;
            }
            // 添加
            case MSG_TYPE_ADD_FRIEND: { 
                const char *target = msg->body.add_friend.target;
                struct generic_resp resp = {0};

                if (strcmp(username, target) == 0) {
                    resp.status = RESP_ERR_UNKNOWN;
                    safe_strcpy(resp.errmsg, "不能添加自己为好友", MAX_ERROR_MSG_LEN);
                } else if (!user_exists(target)) {
                    resp.status = RESP_ERR_USER_NOT_EXIST;
                    safe_strcpy(resp.errmsg, "用户不存在", MAX_ERROR_MSG_LEN);
                } else if (is_friend(username, target)) {
                    resp.status = RESP_ERR_ALREADY_FRIEND;
                    safe_strcpy(resp.errmsg, "对方已是你的好友", MAX_ERROR_MSG_LEN);
                } else {
                    add_friend_both(username, target);
                    resp.status = RESP_OK;
                    snprintf(resp.errmsg, MAX_ERROR_MSG_LEN, "已成功添加好友 %s", target);
                }
                send_message(fd, MSG_TYPE_ADD_FRIEND_RESP, &resp, sizeof(resp));
                break;
            }
            // 删除好友
            case MSG_TYPE_REMOVE_FRIEND: { 
                const char *target = msg->body.add_friend.target;
                struct generic_resp resp = {0};
                if (!user_exists(target)) {
                    resp.status = RESP_ERR_USER_NOT_EXIST;
                    safe_strcpy(resp.errmsg, "用户不存在", MAX_ERROR_MSG_LEN);
                } else {
                    remove_friend_both(username, target);
                    resp.status = RESP_OK;
                    snprintf(resp.errmsg, MAX_ERROR_MSG_LEN, "已删除好友 %s", target);
                }
                send_message(fd, MSG_TYPE_REMOVE_FRIEND_RESP, &resp, sizeof(resp));
                break;
            }
            // 回显列表
            case MSG_TYPE_FRIEND_LIST_REQ: { 
                char friends[MAX_FRIENDS][MAX_USERNAME_LEN];
                int count = load_friend_list(username, friends);
                size_t body_size = sizeof(uint16_t) + count * (2 + MAX_USERNAME_LEN);
                uint8_t *body = malloc(body_size);
                uint16_t *pc = (uint16_t*)body;
                *pc = count;
                uint8_t *ptr = body + sizeof(uint16_t);
                for (int i = 0; i < count; i++) {
                    uint8_t on = (find_online_fd(friends[i]) != -1);
                    size_t len = strlen(friends[i]);
                    *ptr++ = on;
                    *ptr++ = (uint8_t)len;
                    memcpy(ptr, friends[i], len);
                    ptr += len;
                }
                send_message(fd, MSG_TYPE_FRIEND_LIST_RESP, body, ptr - body);
                free(body);
                break;
            }
            // 聊天
            case MSG_TYPE_CHAT_SEND: { 
                const char *target = msg->body.chat_send.target;
                const char *content = msg->body.chat_send.content;
                
                  struct generic_resp resp = {0};
                  resp.status = RESP_ERR_UNKNOWN;

                if (strcmp(username, target) == 0) {
                    safe_strcpy(resp.errmsg, "不能和自己聊天", MAX_ERROR_MSG_LEN);
                    send_message(fd, MSG_TYPE_CHAT_DELIVER, &resp, sizeof(resp));
                    break;
                }

                if (!is_friend(username, target) || !is_friend(target, username)) {
                    safe_strcpy(resp.errmsg, "你们已不是好友关系，无法发送消息", MAX_ERROR_MSG_LEN);
                    send_message(fd, MSG_TYPE_CHAT_DELIVER, &resp, sizeof(resp));
                    break;
                }

                int tfd = find_online_fd(target);
                if (tfd != -1) {
                    struct msg_chat_deliver d;
                    safe_strcpy(d.from, username, MAX_USERNAME_LEN);
                    safe_strcpy(d.content, content, MAX_CONTENT_LEN);
                    send_message(tfd, MSG_TYPE_CHAT_DELIVER, &d, sizeof(d));
                }
                break;
            }
            // 创建群聊
            case MSG_TYPE_GROUP_CREATE: { 
                const char *g = msg->body.add_friend.target;
                struct generic_resp resp = {0};
                if (group_exists(g)) {
                    resp.status = RESP_ERR_GROUP_EXIST;
                    safe_strcpy(resp.errmsg, "群聊已存在", MAX_ERROR_MSG_LEN);
                } else {
                    create_group(g, username);
                    resp.status = RESP_OK;
                    snprintf(resp.errmsg, MAX_ERROR_MSG_LEN, "成功创建群聊 [%s]", g);
                }
                send_message(fd, MSG_TYPE_GROUP_CREATE_RESP, &resp, sizeof(resp));
                break;
            }
            // 加入群聊
            case MSG_TYPE_GROUP_JOIN: {
                const char *g = msg->body.add_friend.target;
                struct generic_resp resp = {0};
                if (!group_exists(g)) {
                    resp.status = RESP_ERR_GROUP_NOT_EXIST;
                    safe_strcpy(resp.errmsg, "群聊不存在", MAX_ERROR_MSG_LEN);
                } else if (is_in_group(g, username)) {
                    resp.status = RESP_ERR_ALREADY_IN_GROUP;
                    safe_strcpy(resp.errmsg, "已在该群中", MAX_ERROR_MSG_LEN);
                } else {
                    join_group(g, username);
                    resp.status = RESP_OK;
                    snprintf(resp.errmsg, MAX_ERROR_MSG_LEN, "成功加入群聊 [%s]", g);
                }
                send_message(fd, MSG_TYPE_GROUP_JOIN_RESP, &resp, sizeof(resp));
                break;
            }
            // 退出群聊
            case MSG_TYPE_LEAVE_GROUP: { 
                const char *g = msg->body.add_friend.target;
                struct generic_resp resp = {0};
                if (!group_exists(g)) {
                    resp.status = RESP_ERR_GROUP_NOT_EXIST;
                    safe_strcpy(resp.errmsg, "群聊不存在", MAX_ERROR_MSG_LEN);
                } else if (!is_in_group(g, username)) {
                    resp.status = RESP_ERR_UNKNOWN;
                    safe_strcpy(resp.errmsg, "你不在该群中", MAX_ERROR_MSG_LEN);
                } else {
                    leave_group(g, username);
                    resp.status = RESP_OK;
                    snprintf(resp.errmsg, MAX_ERROR_MSG_LEN, "已退出群聊 [%s]", g);
                }
                send_message(fd, MSG_TYPE_LEAVE_GROUP_RESP, &resp, sizeof(resp));
                break;
            }
            // 回显群列表
            case MSG_TYPE_GROUP_LIST_REQ: {
                char groups[MAX_GROUPS][MAX_GROUP_NAME_LEN];
                int count = load_group_list(username, groups);
                size_t body_size = sizeof(uint16_t) + count * (2 + MAX_GROUP_NAME_LEN);
                uint8_t *body = malloc(body_size);
                uint16_t *pc = (uint16_t*)body;
                *pc = count;
                uint8_t *ptr = body + sizeof(uint16_t);
                for (int i = 0; i < count; i++) {
                    size_t len = strlen(groups[i]);
                    *ptr++ = 0;
                    *ptr++ = (uint8_t)len;
                    memcpy(ptr, groups[i], len);
                    ptr += len;
                }
                send_message(fd, MSG_TYPE_GROUP_LIST_RESP, body, ptr - body);
                free(body);
                break;
            }
            // 群发送
            case MSG_TYPE_GROUP_SEND: { /* 处理群聊消息发送 */
                const char *g = msg->body.chat_send.target;
                const char *content = msg->body.chat_send.content;
                if (is_in_group(g, username)) {
                    notify_group_members(g, username, content);
                } else {
                    struct generic_resp resp = {0};
                    resp.status = RESP_ERR_UNKNOWN;
                    safe_strcpy(resp.errmsg, "你不在该群，无法发送消息", MAX_ERROR_MSG_LEN);
                    send_message(fd, MSG_TYPE_GROUP_JOIN_RESP, &resp, sizeof(resp));
                }
                break;
            }
            default:
                break;
        }
        free(msg);
    }

    if (strlen(username) > 0) {
        notify_friend_status(username, 0);
        remove_online(fd);
    }
    close(fd);
    return NULL;
}
