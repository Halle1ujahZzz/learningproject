// protocol.h
#ifndef CHAT_PROTO_H
#define CHAT_PROTO_H

#include <stdint.h>
#include <string.h>

#define CHAT_MAGIC      0xCAFE
#define CHAT_VERSION    1

#define MAX_USERNAME_LEN    64
#define MAX_PASSWORD_LEN    64
#define MAX_CONTENT_LEN     1024
#define MAX_ERROR_MSG_LEN   256
#define MAX_GROUP_NAME_LEN  32

typedef enum {
    MSG_TYPE_REGISTER           ,
    MSG_TYPE_REGISTER_RESP      ,
    MSG_TYPE_LOGIN              ,
    MSG_TYPE_LOGIN_RESP         ,
    MSG_TYPE_ADD_FRIEND         ,
    MSG_TYPE_ADD_FRIEND_RESP    ,
    MSG_TYPE_REMOVE_FRIEND      ,   
    MSG_TYPE_REMOVE_FRIEND_RESP ,
    MSG_TYPE_CHAT_SEND          ,
    MSG_TYPE_CHAT_DELIVER       ,
    MSG_TYPE_FRIEND_LIST_REQ    ,
    MSG_TYPE_FRIEND_LIST_RESP   ,
    MSG_TYPE_FRIEND_ONLINE      ,
    MSG_TYPE_FRIEND_OFFLINE     ,

    MSG_TYPE_GROUP_CREATE       ,
    MSG_TYPE_GROUP_CREATE_RESP  ,
    MSG_TYPE_GROUP_JOIN         ,
    MSG_TYPE_GROUP_JOIN_RESP    ,
    MSG_TYPE_LEAVE_GROUP        , 
    MSG_TYPE_LEAVE_GROUP_RESP   ,
    MSG_TYPE_GROUP_LIST_REQ     ,
    MSG_TYPE_GROUP_LIST_RESP    ,
    MSG_TYPE_GROUP_SEND         ,
    MSG_TYPE_GROUP_DELIVER      ,
} msg_type_t;

#define RESP_OK                     0
#define RESP_ERR_UNKNOWN            1
#define RESP_ERR_USER_EXIST         2
#define RESP_ERR_USER_NOT_EXIST     3
#define RESP_ERR_PASSWORD           4
#define RESP_ERR_ALREADY_FRIEND     5
#define RESP_ERR_TARGET_OFFLINE     6
#define RESP_ERR_GROUP_EXIST        7
#define RESP_ERR_GROUP_NOT_EXIST    8
#define RESP_ERR_ALREADY_IN_GROUP   9

struct chat_header {
    uint16_t magic;
    uint8_t  version;
    uint8_t  type;
    uint16_t length;
} __attribute__((packed));

struct msg_register {
    char username[MAX_USERNAME_LEN];
    char password[MAX_PASSWORD_LEN];
} __attribute__((packed));

struct msg_login {
    char username[MAX_USERNAME_LEN];
    char password[MAX_PASSWORD_LEN]; 
} __attribute__((packed));

struct msg_add_friend { // 复用给了添加群
    char target[MAX_USERNAME_LEN]; 
} __attribute__((packed));  

struct generic_resp { 
    uint8_t status;
    char errmsg[MAX_ERROR_MSG_LEN];
} __attribute__((packed));

struct msg_chat_send {
    char target[MAX_USERNAME_LEN];
    char content[MAX_CONTENT_LEN]; 
} __attribute__((packed));

struct msg_chat_deliver {
    char from[MAX_USERNAME_LEN];
    char content[MAX_CONTENT_LEN];
} __attribute__((packed));

struct friend_entry {
    uint8_t online;
    uint8_t len;
    char    name[0];
} __attribute__((packed));

struct msg_friend_list_resp {
    uint16_t count;
    struct friend_entry entries[0];
} __attribute__((packed));

struct msg_friend_status {
    char username[MAX_USERNAME_LEN];
    uint8_t online;
} __attribute__((packed));

union chat_body {
    struct msg_register          reg;
    struct msg_login             login;
    struct generic_resp          resp;
    struct msg_add_friend        add_friend;
    struct msg_chat_send         chat_send;
    struct msg_chat_deliver      chat_deliver;
    struct msg_friend_list_resp  friend_list_resp;
    struct msg_friend_status     friend_status;
};

struct chat_message {
    struct chat_header header;
    union chat_body    body;
} __attribute__((packed));

#endif
