
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <errno.h>

#include "../proto/proto.h"   

#define MAX_CHN 200           

// 全局变量：客户端的运行状态
static pid_t player_pid = 0;                    
static int8_t current_chnid = -1;               
static int pipe_fd[2] = {-1, -1};               

static int8_t valid_chns[MAX_CHN];               // 保存所有有效频道号
static char chn_descrs[MAX_CHN][256];            
static int chn_count = 0;                       
static int list_received = 0;                   // 是否已经收到过完整的频道列表

//安全停止播放器

static void stop_player(void)
{
    if (player_pid > 0) {
        kill(player_pid, SIGTERM);   
        waitpid(player_pid, NULL, 0); 
        player_pid = 0;
    }
    if (pipe_fd[1] != -1) {
        close(pipe_fd[1]);           
        pipe_fd[1] = -1;
    }
}


static void sig_handler(int sig)
{
    stop_player();
    printf("\n客户端已退出\n");
    exit(0);
}

static void start_player(int8_t chnid)
{
    stop_player();  

    if (pipe(pipe_fd) < 0) {  
        perror("pipe");
        exit(1);
    }

    player_pid = fork(); 

    if (player_pid < 0) {
        perror("fork");
        exit(1);
    }

    if (player_pid == 0) {  
        close(pipe_fd[1]);                    
        dup2(pipe_fd[0], STDIN_FILENO);       
        close(pipe_fd[0]);

        // 完全替换子进程为 mplayer，从 stdin 读取 MP3 流并播放
        execlp("mplayer", "mplayer",
               "-",                          // 从标准输入读取
               "-cache", "8192",             // 8MB 缓存，抗抖动
               "-cache-min", "2",            // 缓存填 2% 就播放
               "-really-quiet",            //是否展示myplayer播放参数  
               "-nolirc",
               "-noconsolecontrols",
               "-framedrop",
               "-nocorrect-pts",
               "-ao", "sdl",                 // 音频输出驱动
               "-idle",                      // 保持运行直到流结束
               (char *)NULL);

        perror("execlp mplayer");
        exit(1);
    }

    
    close(pipe_fd[0]);           
    pipe_fd[0] = -1;

    current_chnid = chnid;
    printf("\n>>> 正在播放频道 %d <<<\n", chnid);
    printf("输入新频道号切换，输入 q 退出\n");
}

int main(void)
{
    signal(SIGINT, sig_handler);
    signal(SIGTERM, sig_handler);
    signal(SIGPIPE, SIG_IGN);  

    int sd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sd < 0) {
        perror("socket()");
        exit(1);
    }

    int val = 1;
    setsockopt(sd, SOL_SOCKET, SO_REUSEADDR, &val, sizeof(val));

    struct sockaddr_in laddr = {};
    laddr.sin_family = AF_INET;
    laddr.sin_port = htons(RCV_PORT);
    laddr.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(sd, (struct sockaddr *)&laddr, sizeof(laddr)) < 0) {
        perror("bind()");
        exit(1);
    }

    struct ip_mreq mreq;
    inet_pton(AF_INET, GROUP_ADDR, &mreq.imr_multiaddr);
    mreq.imr_interface.s_addr = htonl(INADDR_ANY);
    setsockopt(sd, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(mreq));

    printf("正在接收频道列表，请稍等...\n");

    //用 select 同时监听网络数据和键盘输入
    char buf[MSG_SIZE + 10];
    fd_set readfds;
    struct timeval tv;

    while (1) {
        FD_ZERO(&readfds);
        FD_SET(STDIN_FILENO, &readfds);  // 监听键盘（标准输入）
        FD_SET(sd, &readfds);            // 监听网络套接字

        tv.tv_sec = 1;
        tv.tv_usec = 0;

        int ret = select(sd + 1, &readfds, NULL, NULL, &tv);
        if (ret < 0) {
            perror("select");
            break;
        }

        //处理网络数据（组播包到达）
        if (FD_ISSET(sd, &readfds)) {
            ssize_t len = recvfrom(sd, buf, sizeof(buf), 0, NULL, NULL);
            if (len <= 1) 
            	continue;

            int8_t chnid = buf[0];

            // 如果是频道列表包
            if (chnid == CHN_LIST_ID) {
                if (!list_received) {
                    // 解析并打印菜单
                    printf("\n=== 频道列表 ===\n");
                    const char *p = buf + 1;
                    const char *end = buf + len;
                    chn_count = 0;
                    while (p < end && chn_count < MAX_CHN) {
                        const struct chn_list_entry *e = (const struct chn_list_entry *)p;
                        printf("%3d: %s", e->chnid, e->descr);
                        valid_chns[chn_count] = e->chnid;
                        strncpy(chn_descrs[chn_count], e->descr, 255);
                        chn_descrs[chn_count][255] = '\0';
                        chn_count++;
                        p += sizeof(int8_t) + sizeof(int8_t) + e->len;
                    }
                    printf("================\n");
                    list_received = 1;

                    // 首次收到列表后，提示用户选择初始频道
                    if (current_chnid == -1) {
                        printf("\n请输入要播放的频道号 (1-%d): ", chn_count);
                        fflush(stdout);
                    }
                }
                continue;
            }

            // 如果是数据包，且是我们当前播放的频道
            if (current_chnid != -1 && chnid == current_chnid) {
                if (pipe_fd[1] != -1) {
                    ssize_t wr = write(pipe_fd[1], buf + 1, len - 1);
                    if (wr < 0 && errno == EPIPE) {
                        printf("播放器异常，重新启动...\n");
                        start_player(current_chnid);  // 自动重启
                    }
                }
            }
        }

        // 处理键盘输入（播放中切换频道）
        if (FD_ISSET(STDIN_FILENO, &readfds)) {
            char input[32];
            if (fgets(input, sizeof(input), stdin) == NULL) 
            	continue;

            input[strcspn(input, "\n")] = 0;  

            if (strcmp(input, "q") == 0 || strcmp(input, "quit") == 0) 
                break;  // 退出程序
            
            int choice = atoi(input);
            if (choice >= 1 && choice <= chn_count) {
                int8_t new_chnid = valid_chns[choice - 1];
                if (new_chnid != current_chnid) {
                    printf("切换到频道 %d: %s\n", choice, chn_descrs[choice - 1]);
                    start_player(new_chnid);
                }
            } else {
                printf("无效输入，请输入 1-%d 或 q 退出: ", chn_count);
                fflush(stdout);
            }
        }
    }

    // 4. 清理资源
    stop_player();
    close(sd);
    return 0;
}
