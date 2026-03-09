// server.c - 最终稳定版：线程池 + 令牌桶限流的多频道组播流媒体服务器
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#include "../proto/proto.h"
#include "mlib.h"
#include "./pool/pool.h"
#include "./tbf/tbf.h"

#define CPS_PER_CHN     204800 
#define BURST_PER_CHN   2097152  

static int sockfd = -1;

static struct mlib_st *g_mlib_list = NULL;
static size_t g_chn_cnt = 0;

struct chn_sender_arg {
    int8_t chnid;
    int tbf_id;
};

static void send_chn_list(void)
{
    if (g_chn_cnt == 0) return;

    size_t total_size = sizeof(int8_t);
    for (size_t i = 0; i < g_chn_cnt; i++) {
        size_t len = strlen(g_mlib_list[i].descrp);
        if (len > 255) len = 255;
        total_size += sizeof(int8_t) + sizeof(int8_t) + len + 1;
    }

    struct chn_list *pkt = malloc(total_size);
    if (!pkt) return;

    pkt->chnid = CHN_LIST_ID;
    char *p = (char *)pkt->entry;

    for (size_t i = 0; i < g_chn_cnt; i++) {
        struct chn_list_entry *entry = (struct chn_list_entry *)p;
        size_t len = strlen(g_mlib_list[i].descrp);
        if (len > 255) len = 255;

        entry->chnid = g_mlib_list[i].chnid;
        entry->len = len + 1;
        memcpy(entry->descr, g_mlib_list[i].descrp, len);
        entry->descr[len] = '\0';

        p += sizeof(int8_t) + sizeof(int8_t) + entry->len;
    }

    struct sockaddr_in maddr = {};
    maddr.sin_family = AF_INET;
    maddr.sin_port = htons(RCV_PORT);
    inet_pton(AF_INET, GROUP_ADDR, &maddr.sin_addr);

    sendto(sockfd, pkt, total_size, 0, (struct sockaddr *)&maddr, sizeof(maddr));
    free(pkt);
}

static void *chn_sender(void *arg)
{
    struct chn_sender_arg *sarg = arg;
    int8_t chnid = sarg->chnid;
    int tbf = sarg->tbf_id;

    free(sarg);  

    char buf[MSG_SIZE];
    ssize_t len;

    while (1) {
        len = mlib_read_chn_data(chnid, buf, MSG_SIZE);
        if (len <= 0) {
            usleep(200000);  
            continue;
        }

        int fetched = 0;
        while (fetched < len) {
            int ret = tbf_fetch_token(tbf, len - fetched);
            if (ret > 0) {
                fetched += ret;
            } else {
                usleep(10000);  
            }
        }

        char pkt[1 + len];
        pkt[0] = chnid;
        memcpy(pkt + 1, buf, len);

        struct sockaddr_in maddr = {};
        maddr.sin_family = AF_INET;
        maddr.sin_port = htons(RCV_PORT);
        inet_pton(AF_INET, GROUP_ADDR, &maddr.sin_addr);

        sendto(sockfd, pkt, 1 + len, 0, (struct sockaddr *)&maddr, sizeof(maddr));
    }

    return NULL;
}

int main(void)
{
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("socket()");
        exit(1);
    }

    int val = 1;
    setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &val, sizeof(val));

    if (mlib_get_chn_list(&g_mlib_list, &g_chn_cnt) < 0 || g_chn_cnt == 0) {
        fprintf(stderr, "无法加载音乐库或没有有效频道\n");
        exit(1);
    }

    printf("服务器启动成功，共有 %zu 个频道，正在组播 %s:%d\n", g_chn_cnt, GROUP_ADDR, RCV_PORT);

    thr_pool_t *pool = NULL;
    if (thr_pool_init(&pool, 4, 20, 100) < 0) {
        perror("thr_pool_init()");
        exit(1);
    }

    for (size_t i = 0; i < g_chn_cnt; i++) {
        int8_t chnid = g_mlib_list[i].chnid;

        int tbf = tbf_init(CPS_PER_CHN, BURST_PER_CHN);
        if (tbf < 0) {
            fprintf(stderr, "频道 %d 创建令牌桶失败\n", (int)chnid);
            continue;
        }

        struct chn_sender_arg *arg = malloc(sizeof(*arg));
        if (!arg) {
            tbf_destroy(tbf);
            continue;
        }
        arg->chnid = chnid;
        arg->tbf_id = tbf;

        task_t task = {
            .job_fun = chn_sender,
            .arg = arg
        };

        if (thr_pool_add_task(pool, &task) < 0) {
            fprintf(stderr, "添加频道 %d 任务失败\n", (int)chnid);
            free(arg);
            tbf_destroy(tbf);
        }
    }

    while (1) {
        send_chn_list();
        sleep(10);
    }

    return 0;
}
