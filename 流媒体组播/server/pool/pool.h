#ifndef __POOL_H__
#define __POOL_H__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <pthread.h>
#include "./queue/queue.h"

enum st {BLANK, FREE, BUSY};

typedef struct {
	pthread_t tid;
	enum st state;
}working_thr_t;

typedef struct {
	void *(*job_fun)(void *s);
	void *arg;
}task_t;

typedef struct {
	pthread_t admin_thr; // 管理者线程
	working_thr_t *worker_thrs; // 工作线程起始地址
	pthread_mutex_t working_mut; // 工作线程结构状态互斥量
	pthread_cond_t working_cond; // 工作线程状态变化

	int min_thrs; // 最少保留线程个数
	int max_thrs; // 最多并法线程个数
	int live_thrs; // 工作的线程个数
	int busy_thrs; // 有工作线程
	int exit_thrs; // exit_thrs > min_thrs,线程结束任务优先终止,也可以由管理者线程决定
	int shutdown; // shutdown == 1 关闭
	
	queue_t *task_queue; // 任务队列
	pthread_mutex_t queue_mut; // 多线程存取任务同步
	pthread_cond_t queue_not_empty; // 任务队列不空条件	
	pthread_cond_t queue_not_full; // 任务队列不满的条件
}thr_pool_t;

// 池初始化
int thr_pool_init(thr_pool_t **mypool, int min_thrs, int max_thrs, int queue_size);

// 添加任务
int thr_pool_add_task(thr_pool_t *mypool, const task_t *t);

// 关闭池
int thr_pool_shutdown(thr_pool_t *mypool);

// 销毁池
void thr_pool_destroy(thr_pool_t **mypool);

#endif
