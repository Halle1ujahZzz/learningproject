#include <stdio.h>       
#include <stdlib.h>      
#include <string.h>      
#include <unistd.h>      
#include <arpa/inet.h>   
#include <pthread.h>     
#include <fcntl.h>       
#include <sys/types.h>   
#include <sys/stat.h>    
#include <dirent.h>      

#include "protocol.h"    
#include "server_tool.h"

// 全局变量定义
ClientNode *online_list = NULL;
pthread_mutex_t online_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t file_io_mutex = PTHREAD_MUTEX_INITIALIZER;

// 用户名密码校验函数
int is_alphanumeric(const char *str) {
    if (!str || strlen(str) == 0) 
    	return 0;                     
    for (int i = 0; str[i]; i++) {                              
        if (!((str[i] >= 'a' && str[i] <= 'z') ||              
              (str[i] >= 'A' && str[i] <= 'Z') ||              
              (str[i] >= '0' && str[i] <= '9'))) {            
            return 0;                                           
        }
    }
    return 1;                                                   
}

//服务器后台打印函数
void print_online_users() {
    printf("\n--- 当前在线用户 ---\n");
    pthread_mutex_lock(&online_mutex);                     
    ClientNode *p = online_list;
    int count = 0;
    if (!p) {
        printf("（无用户在线）\n");
    } else {
        while (p) {
            printf("  %s\n", p->username);
            p = p->next;
            count++;
        }
    }
    pthread_mutex_unlock(&online_mutex);
    printf("共 %d 人在线\n", count);
    printf("--------------------\n\n");
}

void print_all_users() {
    printf("\n=== 已注册用户列表 ===\n");
    pthread_mutex_lock(&file_io_mutex);                         
    FILE *f = fopen(USER_FILE, "r");
    if (!f) {
        printf("（暂无注册用户）\n");
        pthread_mutex_unlock(&file_io_mutex);
        printf("========================\n\n");
        return;
    }
    char line[256];
    int count = 0;
    while (fgets(line, sizeof(line), f)) {
        char username[MAX_USERNAME_LEN];
        if (sscanf(line, "%63[^:]", username) == 1) {
            int is_online = (find_online_fd(username) != -1);
            printf("  %s %s\n", username, is_online ? "[在线]" : "[离线]");
            count++;
        }
    }
    fclose(f);
    pthread_mutex_unlock(&file_io_mutex);
    printf("共 %d 名注册用户\n", count);
    printf("========================\n\n");
}

void print_all_groups() {
    printf("\n=== 群聊列表 ===\n");
    DIR *dir = opendir(".");
    if (!dir) {
        printf("（无法读取目录）\n");
        printf("==================\n\n");
        return;
    }

    struct dirent *entry;
    int count = 0;
    while ((entry = readdir(dir)) != NULL) {
        if (strncmp(entry->d_name, "group_", 6) == 0 && strstr(entry->d_name, ".txt")) {
            char groupname[MAX_GROUP_NAME_LEN];
            sscanf(entry->d_name, "group_%63[^.]", groupname);

            pthread_mutex_lock(&file_io_mutex);               
            char path[128];
            snprintf(path, sizeof(path), "group_%s.txt", groupname);
            FILE *gf = fopen(path, "r");
            char creator[MAX_USERNAME_LEN] = "未知";
            if (gf && fgets(creator, sizeof(creator), gf)) {
                creator[strcspn(creator, "\n")] = 0;
            }
            if (gf) fclose(gf);
            pthread_mutex_unlock(&file_io_mutex);

            printf("  群名: %s  (创建者: %s)\n", groupname, creator);
            count++;
        }
    }
    closedir(dir);

    if (count == 0) {
        printf("（暂无群聊）\n");
    } else {
        printf("共 %d 个群聊\n", count);
    }
    printf("==================\n\n");
}

//基础工具函数
void safe_strcpy(char *dest, const char *src, size_t size) {
    strncpy(dest, src, size - 1);
    dest[size - 1] = '\0'; 
}

void simple_hash(const char *pass, char *out) {
    unsigned long hash = 5381;
    int c;
    while ((c = *pass++)) hash = ((hash << 5) + hash) + c;
    sprintf(out, "%lu", hash);
}

// 账号管理函数
int user_exists(const char *username) {
    pthread_mutex_lock(&file_io_mutex);
    FILE *f = fopen(USER_FILE, "r");
    int exists = 0;
    if (f) {
        char line[256];
        while (fgets(line, sizeof(line), f)) {
            char u[MAX_USERNAME_LEN];
            if (sscanf(line, "%63[^:]", u) == 1 && strcmp(u, username) == 0) {
                exists = 1;
                break;
            }
        }
        fclose(f);
    }
    pthread_mutex_unlock(&file_io_mutex);
    return exists;
}

void store_user(const char *username, const char *password) {
    pthread_mutex_lock(&file_io_mutex);
    char hash[64];
    simple_hash(password, hash);
    FILE *f = fopen(USER_FILE, "a");
    if (f) {
        fprintf(f, "%s:%s\n", username, hash);
        fclose(f);
    }
    char path[128];
    snprintf(path, sizeof(path), "%s_friends.txt", username);
    close(open(path, O_CREAT | O_WRONLY, 0644));
    snprintf(path, sizeof(path), "%s_groups.txt", username);
    close(open(path, O_CREAT | O_WRONLY, 0644));
    pthread_mutex_unlock(&file_io_mutex);

    printf("[注册] 新用户: %s\n", username);
    print_all_users();
}

int authenticate_user(const char *username, const char *password) {
    pthread_mutex_lock(&file_io_mutex);
    FILE *f = fopen(USER_FILE, "r");
    int auth = 0;
    if (f) {
        char hash[64];
        simple_hash(password, hash);
        char line[256];
        while (fgets(line, sizeof(line), f)) {
            char u[MAX_USERNAME_LEN], h[64];
            if (sscanf(line, "%63[^:]:%63s", u, h) == 2 &&
                strcmp(u, username) == 0 && strcmp(h, hash) == 0) {
                auth = 1;
                break;
            }
        }
        fclose(f);
    }
    pthread_mutex_unlock(&file_io_mutex);
    return auth;
}

//好友管理函数
int is_friend(const char *user, const char *target) {
    pthread_mutex_lock(&file_io_mutex);
    char path[128];
    snprintf(path, sizeof(path), "%s_friends.txt", user);
    FILE *f = fopen(path, "r");
    int found = 0;
    if (f) {
        char line[MAX_USERNAME_LEN];
        while (fgets(line, sizeof(line), f)) {
            line[strcspn(line, "\n")] = 0;
            if (strcmp(line, target) == 0) {
                found = 1;
                break;
            }
        }
        fclose(f);
    }
    pthread_mutex_unlock(&file_io_mutex);
    return found;
}

void add_friend_both(const char *a, const char *b) {
    pthread_mutex_lock(&file_io_mutex);
    char path_a[128], path_b[128];
    snprintf(path_a, sizeof(path_a), "%s_friends.txt", a);
    snprintf(path_b, sizeof(path_b), "%s_friends.txt", b);
    FILE *fa = fopen(path_a, "a");
    if (fa) { 
		fprintf(fa, "%s\n", b); fclose(fa); 
	}
    FILE *fb = fopen(path_b, "a");
    if (fb) { 
		fprintf(fb, "%s\n", a); fclose(fb); 
	}
    pthread_mutex_unlock(&file_io_mutex);
}

void remove_friend_both(const char *a, const char *b) {
    pthread_mutex_lock(&file_io_mutex);
    char path[128], temp[140];

    // 删除 a 的好友文件中 b 的记录
    snprintf(path, sizeof(path), "%s_friends.txt", a);
    snprintf(temp, sizeof(temp), "%s.tmp", path);
    FILE *f = fopen(path, "r");
    if (f) {
        FILE *tmpf = fopen(temp, "w");
        if (tmpf) {
            char line[MAX_USERNAME_LEN];
            while (fgets(line, sizeof(line), f)) {
                line[strcspn(line, "\n")] = 0;
                if (strcmp(line, b) != 0) {
                    fprintf(tmpf, "%s\n", line);
                }
            }
            fclose(tmpf);
        }
        fclose(f);
        rename(temp, path);
    }

    // 删除 b 的好友文件中 a 的记录
    snprintf(path, sizeof(path), "%s_friends.txt", b);
    snprintf(temp, sizeof(temp), "%s.tmp", path);
    f = fopen(path, "r");
    if (f) {
        FILE *tmpf = fopen(temp, "w");
        if (tmpf) {
            char line[MAX_USERNAME_LEN];
            while (fgets(line, sizeof(line), f)) {
                line[strcspn(line, "\n")] = 0;
                if (strcmp(line, a) != 0) {
                    fprintf(tmpf, "%s\n", line);
                }
            }
            fclose(tmpf);
        }
        fclose(f);
        rename(temp, path);
    }
    pthread_mutex_unlock(&file_io_mutex);
}

int load_friend_list(const char *username, char friends[][MAX_USERNAME_LEN]) {
    pthread_mutex_lock(&file_io_mutex);
    char path[128];
    snprintf(path, sizeof(path), "%s_friends.txt", username);
    FILE *f = fopen(path, "r");
    int count = 0;
    if (f) {
        while (fgets(friends[count], MAX_USERNAME_LEN, f) && count < MAX_FRIENDS) {
            friends[count][strcspn(friends[count], "\n")] = 0;
            if (strlen(friends[count]) > 0) count++;
        }
        fclose(f);
    }
    pthread_mutex_unlock(&file_io_mutex);
    return count;
}

// 群聊管理函数 
int group_exists(const char *groupname) {
    pthread_mutex_lock(&file_io_mutex);
    char path[128];
    snprintf(path, sizeof(path), "group_%s.txt", groupname);
    int exists = access(path, F_OK) == 0;
    pthread_mutex_unlock(&file_io_mutex);
    return exists;
}

void create_group(const char *groupname, const char *creator) {
    pthread_mutex_lock(&file_io_mutex);
    char path[128];
    snprintf(path, sizeof(path), "group_%s.txt", groupname);
    FILE *f = fopen(path, "w");
    if (f) { 
		fprintf(f, "%s\n", creator); 
		fclose(f); 
	}
    snprintf(path, sizeof(path), "%s_groups.txt", creator);
    FILE *uf = fopen(path, "a");
    if (uf) { 
		fprintf(uf, "%s\n", groupname); 
		fclose(uf); 
	}
    pthread_mutex_unlock(&file_io_mutex);
}

void join_group(const char *groupname, const char *username) {
    pthread_mutex_lock(&file_io_mutex);
    char path[128];
    snprintf(path, sizeof(path), "group_%s.txt", groupname);
    FILE *f = fopen(path, "a");
    if (f) { 
  	  fprintf(f, "%s\n", username); fclose(f); 
    }
    snprintf(path, sizeof(path), "%s_groups.txt", username);
    FILE *uf = fopen(path, "a");
    if (uf) { 
    	fprintf(uf, "%s\n", groupname); fclose(uf); 
    	}
    pthread_mutex_unlock(&file_io_mutex);
}

void leave_group(const char *groupname, const char *username) {
    pthread_mutex_lock(&file_io_mutex);
    char path[128], temp[140];

    snprintf(path, sizeof(path), "group_%s.txt", groupname);
    snprintf(temp, sizeof(temp), "%s.tmp", path);
    FILE *f = fopen(path, "r");
    if (f) {
        FILE *tmpf = fopen(temp, "w");
        if (tmpf) {
            char line[MAX_USERNAME_LEN];
            while (fgets(line, sizeof(line), f)) {
                line[strcspn(line, "\n")] = 0;
                if (strcmp(line, username) != 0) {
                    fprintf(tmpf, "%s\n", line);
                }
            }
            fclose(tmpf);
        }
        fclose(f);
        rename(temp, path);
    }

    snprintf(path, sizeof(path), "%s_groups.txt", username);
    snprintf(temp, sizeof(temp), "%s.tmp", path);
    f = fopen(path, "r");
    if (f) {
        FILE *tmpf = fopen(temp, "w");
        if (tmpf) {
            char line[MAX_GROUP_NAME_LEN];
            while (fgets(line, sizeof(line), f)) {
                line[strcspn(line, "\n")] = 0;
                if (strcmp(line, groupname) != 0) {
                    fprintf(tmpf, "%s\n", line);
                }
            }
            fclose(tmpf);
        }
        fclose(f);
        rename(temp, path);
    }
    pthread_mutex_unlock(&file_io_mutex);
}

int is_in_group(const char *groupname, const char *username) {
    pthread_mutex_lock(&file_io_mutex);
    char path[128];
    snprintf(path, sizeof(path), "group_%s.txt", groupname);
    FILE *f = fopen(path, "r");
    int in_group = 0;
    if (f) {
        char line[MAX_USERNAME_LEN];
        while (fgets(line, sizeof(line), f)) {
            line[strcspn(line, "\n")] = 0;
            if (strcmp(line, username) == 0) {
                in_group = 1;
                break;
            }
        }
        fclose(f);
    }
    pthread_mutex_unlock(&file_io_mutex);
    return in_group;
}

int load_group_list(const char *username, char groups[][MAX_GROUP_NAME_LEN]) {
    pthread_mutex_lock(&file_io_mutex);
    char path[128];
    snprintf(path, sizeof(path), "%s_groups.txt", username);
    FILE *f = fopen(path, "r");
    int count = 0;
    if (f) {
        while (fgets(groups[count], MAX_GROUP_NAME_LEN, f) && count < MAX_GROUPS) {
            groups[count][strcspn(groups[count], "\n")] = 0;
            if (strlen(groups[count]) > 0) count++;
        }
        fclose(f);
    }
    pthread_mutex_unlock(&file_io_mutex);
    return count;
}

void notify_group_members(const char *groupname, const char *sender, const char *content) {
    pthread_mutex_lock(&file_io_mutex);
    char path[128];
    snprintf(path, sizeof(path), "group_%s.txt", groupname);
    FILE *f = fopen(path, "r");
    if (!f) {
        pthread_mutex_unlock(&file_io_mutex);
        return;
    }

    char member[MAX_USERNAME_LEN];
    char full_msg[MAX_CONTENT_LEN + MAX_USERNAME_LEN + 10];
    snprintf(full_msg, sizeof(full_msg), "%s: %s", sender, content);

    struct msg_chat_deliver deliver;
    safe_strcpy(deliver.from, groupname, MAX_USERNAME_LEN);
    safe_strcpy(deliver.content, full_msg, MAX_CONTENT_LEN);

    while (fgets(member, sizeof(member), f)) {
        member[strcspn(member, "\n")] = 0;
        if (strlen(member) == 0 || strcmp(member, sender) == 0) 
			continue;
        int fd = find_online_fd(member);
        if (fd != -1) {
            send_message(fd, MSG_TYPE_GROUP_DELIVER, &deliver, sizeof(deliver));
        }
    }
    fclose(f);
    pthread_mutex_unlock(&file_io_mutex);
}

// 在线用户管理函数
int find_online_fd(const char *username) {
    pthread_mutex_lock(&online_mutex);
    ClientNode *p = online_list;
    while (p) {
        if (strcmp(p->username, username) == 0) {
            pthread_mutex_unlock(&online_mutex);
            return p->fd;
        }
        p = p->next;
    }
    pthread_mutex_unlock(&online_mutex);
    return -1;
}

void add_online(int fd, const char *username) {
    pthread_mutex_lock(&online_mutex);
    ClientNode *node = malloc(sizeof(ClientNode));
    node->fd = fd;
    safe_strcpy(node->username, username, MAX_USERNAME_LEN);
    node->next = online_list;
    online_list = node;
    pthread_mutex_unlock(&online_mutex);

    printf("[上线] %s 已登录\n", username);
    print_online_users();
}

void remove_online(int fd) {
    pthread_mutex_lock(&online_mutex);
    ClientNode **pp = &online_list;
    while (*pp) {
        if ((*pp)->fd == fd) {
            printf("[下线] %s 已退出\n", (*pp)->username);
            ClientNode *tmp = *pp;
            *pp = tmp->next;
            free(tmp);
            break;
        }
        pp = &(*pp)->next;
    }
    pthread_mutex_unlock(&online_mutex);
    print_online_users();
}

void notify_friend_status(const char *username, uint8_t online) {
    char friends[MAX_FRIENDS][MAX_USERNAME_LEN];
    int count = load_friend_list(username, friends);
    struct msg_friend_status status_body;
    safe_strcpy(status_body.username, username, MAX_USERNAME_LEN);
    status_body.online = online;
    for (int i = 0; i < count; i++) {
        int fd = find_online_fd(friends[i]);
        if (fd != -1) {
            send_message(fd, online ? MSG_TYPE_FRIEND_ONLINE : MSG_TYPE_FRIEND_OFFLINE,
                         &status_body, sizeof(status_body));
        }
    }
}

// 网络收发封装函数 
int recv_full(int fd, void *buf, size_t len) {
    size_t recvd = 0;
    while (recvd < len) {
        ssize_t r = read(fd, (uint8_t*)buf + recvd, len - recvd);
        if (r <= 0) return -1;
        recvd += r;
    }
    return 0;
}

struct chat_message *recv_message(int fd) {
    struct chat_header header;
    if (recv_full(fd, &header, sizeof(header)) != 0) return NULL;
    if (header.magic != CHAT_MAGIC || header.version != CHAT_VERSION ||
        header.length < sizeof(header) || header.length > RECV_BUF_SIZE) {
        return NULL;
    }
    uint16_t body_len = header.length - sizeof(header);
    struct chat_message *msg = malloc(header.length);
    if (!msg) return NULL;
    memcpy(msg, &header, sizeof(header));
    if (body_len && recv_full(fd, (uint8_t*)msg + sizeof(header), body_len) != 0) {
        free(msg);
        return NULL;
    }
    return msg;
}

int send_message(int fd, uint8_t type, const void *body, uint16_t body_len) {
    uint16_t total_len = sizeof(struct chat_header) + body_len;
    uint8_t *buf = malloc(total_len);
    if (!buf) 
		return 0;

    struct chat_header *h = (struct chat_header *)buf;
    h->magic = CHAT_MAGIC;
    h->version = CHAT_VERSION;
    h->type = type;
    h->length = total_len;

    if (body && body_len > 0) 
		memcpy(buf + sizeof(struct chat_header), body, body_len);

    int ret = (write(fd, buf, total_len) == total_len);
    free(buf);
    return ret;
}
