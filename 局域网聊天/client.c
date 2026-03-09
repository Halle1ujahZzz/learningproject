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

static void *receive_messages(void *arg);

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "用法: %s <服务器IP> <端口>\n", argv[0]);
        return 1;
    }

    sock_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (sock_fd < 0) {
        perror("socket 创建失败");
        return 1;
    }

    struct sockaddr_in serv_addr = {0};
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(atoi(argv[2]));
    if (inet_pton(AF_INET, argv[1], &serv_addr.sin_addr) <= 0) {
        perror("无效的IP地址");
        return 1;
    }

    if (connect(sock_fd, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) < 0) {
        perror("连接服务器失败");
        return 1;
    }
    printf("已连接到服务器 %s:%s\n", argv[1], argv[2]);

    pthread_t recv_tid;
    pthread_create(&recv_tid, NULL, receive_messages, NULL);
    pthread_detach(recv_tid);

    char input[1024];
    int logged_in = 0;

    while (!logged_in) {
        printf("\n");
        printf("╔══════════════════════════╗\n");
        printf("║      欢迎使用聊天系统      ║\n");
        printf("╚══════════════════════════╝\n");
        printf(" 1. 注册新账号\n");
        printf(" 2. 登录现有账号\n");
        printf(" 3. 退出程序\n");
        printf("> ");
        fflush(stdout);

        if (!fgets(input, sizeof(input), stdin)) break;
        input[strcspn(input, "\n")] = '\0';

        if (strcmp(input, "1") == 0) {
            printf("\n--- 注册新账号 ---\n");
            printf("用户名: ");
            fgets(input, sizeof(input), stdin);
            input[strcspn(input, "\n")] = '\0';
            if (strlen(input) == 0) continue;

            char pwd[MAX_PASSWORD_LEN];
            printf("密码: ");
            fgets(pwd, sizeof(pwd), stdin);
            pwd[strcspn(pwd, "\n")] = '\0';

            struct msg_register reg;
            safe_strcpy(reg.username, input, MAX_USERNAME_LEN);
            safe_strcpy(reg.password, pwd, MAX_PASSWORD_LEN);
            send_message(MSG_TYPE_REGISTER, &reg, sizeof(reg));

        } else if (strcmp(input, "2") == 0) {
            printf("\n--- 登录账号 ---\n");
            printf("用户名: ");
            fgets(input, sizeof(input), stdin);
            input[strcspn(input, "\n")] = '\0';
            if (strlen(input) == 0) continue;

            char pwd[MAX_PASSWORD_LEN];
            printf("密码: ");
            fgets(pwd, sizeof(pwd), stdin);
            pwd[strcspn(pwd, "\n")] = '\0';

            struct msg_login login_msg;
            safe_strcpy(login_msg.username, input, MAX_USERNAME_LEN);
            safe_strcpy(login_msg.password, pwd, MAX_PASSWORD_LEN);
            send_message(MSG_TYPE_LOGIN, &login_msg, sizeof(login_msg));

            safe_strcpy(my_username, input, MAX_USERNAME_LEN);
            logged_in = 1;

        } else if (strcmp(input, "3") == 0) {
            printf("再见！\n");
            close(sock_fd);
            return 0;
        }
    }

    printf("\n=== 登录成功！欢迎，%s ===\n", my_username);
    printf("输入菜单数字使用功能，祝你聊天愉快！\n");

    while (1) {
        if (g_mode == 0) {
            show_main_menu();
        } else if (g_mode == 1) {
            printf("[私聊 -> %s]: ", g_target_private);
            fflush(stdout);
        } else if (g_mode == 2) {
            printf("[群聊:%s] > ", g_target_group);
            fflush(stdout);
        }

        if (!fgets(input, sizeof(input), stdin)) break;
        input[strcspn(input, "\n")] = '\0';

        if (g_mode != 0) {
            if (strcmp(input, "/back") == 0 || strcmp(input, "/quit") == 0) {
                printf("已返回主菜单\n");
                g_mode = 0;
                continue;
            }
            if (strlen(input) == 0) continue;

            struct msg_chat_send chat;
            safe_strcpy(chat.content, input, MAX_CONTENT_LEN);
            if (g_mode == 1) {
                safe_strcpy(chat.target, g_target_private, MAX_USERNAME_LEN);
                send_message(MSG_TYPE_CHAT_SEND, &chat, sizeof(chat));
            } else {
                safe_strcpy(chat.target, g_target_group, MAX_GROUP_NAME_LEN);
                send_message(MSG_TYPE_GROUP_SEND, &chat, sizeof(chat));
            }
            continue;
        }

        if (strcmp(input, "1") == 0) {
            send_message(MSG_TYPE_FRIEND_LIST_REQ, NULL, 0);

        } else if (strcmp(input, "2") == 0) {
            printf("要添加的好友用户名: ");
            fgets(input, sizeof(input), stdin);
            input[strcspn(input, "\n")] = '\0';
            if (strlen(input)) {
                struct msg_add_friend af;
                safe_strcpy(af.target, input, MAX_USERNAME_LEN);
                send_message(MSG_TYPE_ADD_FRIEND, &af, sizeof(af));
            }

        } else if (strcmp(input, "3") == 0) {
            printf("要私聊的好友用户名: ");
            fgets(input, sizeof(input), stdin);
            input[strcspn(input, "\n")] = '\0';
            if (strlen(input)) {
                safe_strcpy(g_target_private, input, MAX_USERNAME_LEN);
                g_mode = 1;
                printf("\n>>> 正在与 %s 私聊（输入 /back 返回）<<<\n", g_target_private);
            }

        } else if (strcmp(input, "4") == 0) {
            printf("群聊名称（创建）: ");
            fgets(input, sizeof(input), stdin);
            input[strcspn(input, "\n")] = '\0';
            if (strlen(input)) {
                struct msg_add_friend af;
                safe_strcpy(af.target, input, MAX_GROUP_NAME_LEN);
                send_message(MSG_TYPE_GROUP_CREATE, &af, sizeof(af));
            }

        } else if (strcmp(input, "5") == 0) {
            printf("要加入的群名称: ");
            fgets(input, sizeof(input), stdin);
            input[strcspn(input, "\n")] = '\0';
            if (strlen(input)) {
                struct msg_add_friend af;
                safe_strcpy(af.target, input, MAX_GROUP_NAME_LEN);
                send_message(MSG_TYPE_GROUP_JOIN, &af, sizeof(af));
            }

        } else if (strcmp(input, "6") == 0) {
            send_message(MSG_TYPE_GROUP_LIST_REQ, NULL, 0);
            printf("要进入的群名称: ");
            fgets(input, sizeof(input), stdin);
            input[strcspn(input, "\n")] = '\0';
            if (strlen(input)) {
                safe_strcpy(g_target_group, input, MAX_GROUP_NAME_LEN);
                g_mode = 2;
                printf("\n>>> 已进入群聊 [%s]（输入 /back 返回）<<<\n", g_target_group);
            }

        } else if (strcmp(input, "7") == 0) {
            printf("要删除的好友用户名: ");
            fgets(input, sizeof(input), stdin);
            input[strcspn(input, "\n")] = '\0';
            if (strlen(input)) {
                struct msg_add_friend af;
                safe_strcpy(af.target, input, MAX_USERNAME_LEN);
                send_message(MSG_TYPE_REMOVE_FRIEND, &af, sizeof(af));
            }

        } else if (strcmp(input, "8") == 0) {
            printf("要退出的群名称: ");
            fgets(input, sizeof(input), stdin);
            input[strcspn(input, "\n")] = '\0';
            if (strlen(input)) {
                struct msg_add_friend af;
                safe_strcpy(af.target, input, MAX_GROUP_NAME_LEN);
                send_message(MSG_TYPE_LEAVE_GROUP, &af, sizeof(af));
            }

        } else if (strcmp(input, "9") == 0) {
            printf("正在退出登录...\n");
            break;
        }
    }

    close(sock_fd);
    printf("谢谢使用，再见！\n");
    return 0;
}

static void *receive_messages(void *arg) {
    
    while (1) {
        struct chat_message *msg = recv_message();
        if (!msg) 
            break;

        switch (msg->header.type) {
            // 增删操作
            case MSG_TYPE_REGISTER_RESP:
            case MSG_TYPE_LOGIN_RESP:
            case MSG_TYPE_ADD_FRIEND_RESP:
            case MSG_TYPE_REMOVE_FRIEND_RESP:
            case MSG_TYPE_GROUP_CREATE_RESP:
            case MSG_TYPE_GROUP_JOIN_RESP:
            case MSG_TYPE_LEAVE_GROUP_RESP: {
                // 增删操作自动刷新对应列表
                struct generic_resp *resp = &msg->body.resp;
                print_server(resp->errmsg);

                if (msg->header.type == MSG_TYPE_ADD_FRIEND_RESP || msg->header.type == MSG_TYPE_REMOVE_FRIEND_RESP) {

                    send_message(MSG_TYPE_FRIEND_LIST_REQ, NULL, 0);
                } else if (msg->header.type == MSG_TYPE_GROUP_CREATE_RESP || \
                           msg->header.type == MSG_TYPE_GROUP_JOIN_RESP || \
                           msg->header.type == MSG_TYPE_LEAVE_GROUP_RESP) {
                    send_message(MSG_TYPE_GROUP_LIST_REQ, NULL, 0);
                }
                break;
            }
            case MSG_TYPE_CHAT_DELIVER: {
                struct msg_chat_deliver *d = &msg->body.chat_deliver;
                clear_line();
                printf("<%s> %s\n", d->from, d->content);
                if (g_mode == 1) printf("[私聊 -> %s]: ", g_target_private);
                else printf("> ");
                fflush(stdout);
                break;
            }
            case MSG_TYPE_GROUP_DELIVER: {
                struct msg_chat_deliver *d = &msg->body.chat_deliver;
                clear_line();
                printf("[群:%s] %s\n", d->from, d->content);
                if (g_mode == 2) printf("[群聊:%s] > ", g_target_group);
                fflush(stdout);
                break;
            }
            case MSG_TYPE_FRIEND_ONLINE:
            case MSG_TYPE_FRIEND_OFFLINE: {
                struct msg_friend_status *st = &msg->body.friend_status;
                print_system("好友 %s 已%s", st->username, st->online ? "上线" : "下线");
                break;
            }
            case MSG_TYPE_FRIEND_LIST_RESP: {
                struct msg_friend_list_resp *list = &msg->body.friend_list_resp;
                clear_line();
                printf("=== 好友列表 (%u) ===\n", list->count);
                uint8_t *ptr = (uint8_t*)&list->entries[0];
                for (uint16_t i = 0; i < list->count; i++) {
                    struct friend_entry *e = (struct friend_entry *)ptr;
                    char name[MAX_USERNAME_LEN] = {0};
                    memcpy(name, e->name, e->len);
                    name[e->len] = '\0';
                    printf("  %s %s\n", e->online ? "[在线]" : "[离线]", name);
                    ptr += 2 + e->len;
                }
                printf("=====================\n");
                break;
            }
            case MSG_TYPE_GROUP_LIST_RESP: {
                struct msg_friend_list_resp *list = &msg->body.friend_list_resp;
                clear_line();
                printf("=== 我的群聊 (%u) ===\n", list->count);
                uint8_t *ptr = (uint8_t*)&list->entries[0];
                for (uint16_t i = 0; i < list->count; i++) {
                    struct friend_entry *e = (struct friend_entry *)ptr;
                    char name[MAX_GROUP_NAME_LEN] = {0};
                    memcpy(name, e->name, e->len);
                    name[e->len] = '\0';
                    printf("  %s\n", name);
                    ptr += 2 + e->len;
                }
                printf("=====================\n");
                break;
            }
            default:
                break;
        }
        free(msg);
    }
    return NULL;
}
