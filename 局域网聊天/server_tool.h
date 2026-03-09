#ifndef SERVER_TOOL_H
#define SERVER_TOOL_H

#include <stdint.h>
#include <pthread.h>
#include "protocol.h"

#define PORT            8888   
#define USER_FILE       "users.txt"
#define BACKLOG         10     
#define RECV_BUF_SIZE   4096    
#define MAX_FRIENDS     200     
#define MAX_GROUPS      50      

// 在线用户链表
typedef struct ClientNode {
    int fd;                          
    char username[MAX_USERNAME_LEN]; 
    struct ClientNode *next;         
} ClientNode;

extern ClientNode *online_list;
extern pthread_mutex_t online_mutex;
extern pthread_mutex_t file_io_mutex;

int is_alphanumeric(const char *str);
void print_online_users();
void print_all_users();
void print_all_groups();
void safe_strcpy(char *dest, const char *src, size_t size);
void simple_hash(const char *pass, char *out);
int user_exists(const char *username);
void store_user(const char *username, const char *password);
int authenticate_user(const char *username, const char *password);
int is_friend(const char *user, const char *target);
void add_friend_both(const char *a, const char *b);
void remove_friend_both(const char *a, const char *b);
int load_friend_list(const char *username, char friends[][MAX_USERNAME_LEN]);
int group_exists(const char *groupname);
void create_group(const char *groupname, const char *creator);
void join_group(const char *groupname, const char *username);
void leave_group(const char *groupname, const char *username);
int is_in_group(const char *groupname, const char *username);
int load_group_list(const char *username, char groups[][MAX_GROUP_NAME_LEN]);
void notify_group_members(const char *groupname, const char *sender, const char *content);
int find_online_fd(const char *username);
void add_online(int fd, const char *username);
void remove_online(int fd);
void notify_friend_status(const char *username, uint8_t online);
int recv_full(int fd, void *buf, size_t len);
struct chat_message *recv_message(int fd);
int send_message(int fd, uint8_t type, const void *body, uint16_t body_len);

#endif
