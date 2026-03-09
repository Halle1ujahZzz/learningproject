#ifndef __MLIB_H__
#define __MLIB_H__

#include <stdlib.h>
#include <unistd.h>
#include <glob.h>
#include <sys/types.h>
#include <dirent.h>
#include <stdio.h>
#include <string.h>

#define MLIB_PATH	"./medialib/"

struct mlib_st {
	int8_t chnid; // 频道号
	char *descrp; // 频道描述
};

// 频道列表的
int mlib_get_chn_list(struct mlib_st **mymlib, size_t *n);

// 提供频道数据
/*
chnid:要读的频道
buf:存储读取数据的数组
size:要读取的字节个数
return:
	读到的字节个数
*/

ssize_t mlib_read_chn_data(int8_t chnid, void *buf, size_t size);

#endif


