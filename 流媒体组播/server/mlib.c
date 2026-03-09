#include <errno.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dirent.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <glob.h>

#include "mlib.h"

#define BUFSIZE 128
#define MLIB_PATH "./medialib/"   // 确保这里是你音乐库的路径，结尾有 /

static int __get_chn_info(const char *path);

struct chn_context_st {
    struct mlib_st mlib_list;     // 存储该频道基本信息
    glob_t mp3_path;              // 所有 mp3 文件路径
    int cur_ind;                  // 当前正在播放的文件下标
    int fd;                       // 当前打开的文件描述符（初始 -1）
};

static struct chn_context_st *chn_context_p = NULL; // 所有频道上下文数组
static int chn_nr = 0;                                    // 频道数量

int mlib_get_chn_list(struct mlib_st **mymlib, size_t *n) 
{
    int i;
    DIR *dp = NULL;
    struct dirent *entry = NULL;
    char buf[BUFSIZE] = {};

    dp = opendir(MLIB_PATH);
    if(dp == NULL) {
        perror("opendir()");
        return -1;
    }

    while(1) {
        errno = 0;
        entry = readdir(dp);
        if(entry == NULL) {
            if(errno) {
                perror("readdir()");
                closedir(dp);
                return -1;
            }
            break;
        }
        // 正确跳过 . 和 ..
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
            continue;
        
        memset(buf, 0, BUFSIZE);
        strcpy(buf, MLIB_PATH);
        strcat(buf, entry->d_name);

        printf("parse...%s\n", buf);
        __get_chn_info(buf);
    }
    closedir(dp);

    printf("chr_nr:%d\n", chn_nr);
    
    *mymlib = calloc(chn_nr, sizeof(struct mlib_st));
    if (*mymlib == NULL) {
        return -1;
    }

    for(i = 0; i < chn_nr; i++) {
        (*mymlib)[i] = chn_context_p[i].mlib_list;
    }
    *n = chn_nr;

    return 0;
}
  
static int __get_chn_info(const char *path)
{
    static int index = 1; // 频道 id 从 1 开始
    char buf[BUFSIZE] = {};
    FILE *fp = NULL;
    size_t n = 0;
    struct chn_context_st mychn;

    // 构建 descr.txt 路径
    strcpy(buf, path);
    strcat(buf, "/descr.txt");

    fp = fopen(buf, "r");
    if (fp == NULL) {
        perror("fopen()");
        return -1;
    }

    // 读取描述文字
    if (getline(&mychn.mlib_list.descrp, &n, fp) < 0) {
        fclose(fp);
        return -1;
    }

    fclose(fp);

    // 构建 mp3 通配路径
    memset(buf, 0, BUFSIZE);
    strcpy(buf, path);
    strcat(buf, "/*.mp3");

    // glob 查找所有 mp3
    if (glob(buf, 0, NULL, &mychn.mp3_path) != 0) {
        free(mychn.mlib_list.descrp);
        return -1;
    }

    if(mychn.mp3_path.gl_pathc == 0) {
        fprintf(stderr, "没有音频文件: %s\n", path);
        globfree(&mychn.mp3_path);
        free(mychn.mlib_list.descrp);
        return -1;
    }

    // 扩展频道数组
    chn_context_p = realloc(chn_context_p, (chn_nr + 1) * sizeof(struct chn_context_st));
    if (chn_context_p == NULL) {
        globfree(&mychn.mp3_path);
        free(mychn.mlib_list.descrp);
        return -1;
    }

    // 保存信息
    chn_context_p[chn_nr] = mychn;
    chn_context_p[chn_nr].mlib_list.chnid = index++;
    chn_context_p[chn_nr].cur_ind = 0;
    chn_context_p[chn_nr].fd = -1;   // 重要：初始 fd 为 -1

    chn_nr++;

    return 0;
}

ssize_t mlib_read_chn_data(int8_t chnid, void *buf, size_t size)
{
    ssize_t cnt;
    int idx = chnid - 1;

    while (1) {
        if (chn_context_p[idx].fd == -1) {
            int next_ind = chn_context_p[idx].cur_ind;
            const char *path = chn_context_p[idx].mp3_path.gl_pathv[next_ind];

            chn_context_p[idx].fd = open(path, O_RDONLY);
            if (chn_context_p[idx].fd < 0) {
                perror("open next mp3");
                return -1;
            }
        }

        cnt = read(chn_context_p[idx].fd, buf, size);

        if (cnt < 0) {
            perror("read()");
            close(chn_context_p[idx].fd);
            chn_context_p[idx].fd = -1;
            return -1;
        }

        if (cnt == 0) {
            close(chn_context_p[idx].fd);
            chn_context_p[idx].fd = -1;

            chn_context_p[idx].cur_ind++;
            if (chn_context_p[idx].cur_ind >= chn_context_p[idx].mp3_path.gl_pathc) {
                chn_context_p[idx].cur_ind = 0;
            }
            continue;
        }

        return cnt;
    }
}
