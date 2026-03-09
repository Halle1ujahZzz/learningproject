#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <pthread.h>

#include "pool.h"


/* ==================== 辅助函数：找 BLANK 位置 ==================== */
static int __get_free_pos(thr_pool_t *mypool)
{
    for (int i = 0; i < mypool->max_thrs; i++) {
        if (mypool->worker_thrs[i].state == BLANK)
            return i;
    }
    return -1;
}

/* ==================== 工作线程函数 ==================== */
static void *worker_fun(void *arg)
{
    thr_pool_t *mypool = (thr_pool_t *)arg;

    while (1) {
        pthread_mutex_lock(&mypool->queue_mut);

        /* 检查是否关闭 */
        if (mypool->shutdown) {
            pthread_mutex_unlock(&mypool->queue_mut);
            pthread_exit(NULL);
        }

        /* 找到自己在数组中的位置 */
        int my_pos = -1;
        for (int i = 0; i < mypool->max_thrs; i++) {
            if (mypool->worker_thrs[i].state != BLANK &&
                pthread_equal(mypool->worker_thrs[i].tid, pthread_self())) {
                my_pos = i;
                break;
            }
        }

        /* 管理员要求裁员，且自己空闲 → 自我牺牲 */
        if (my_pos != -1 &&
            mypool->worker_thrs[my_pos].state == FREE &&
            mypool->exit_thrs > 0) {

            mypool->exit_thrs--;
            mypool->live_thrs--;
            mypool->worker_thrs[my_pos].state = BLANK;

            pthread_cond_signal(&mypool->working_cond);

            pthread_mutex_unlock(&mypool->queue_mut);
            pthread_exit(NULL);
        }

        /* 等待任务（条件严谨，能及时响应裁员） */
        while (queue_empty(mypool->task_queue) &&
               !mypool->shutdown &&
               !(my_pos != -1 &&
                 mypool->worker_thrs[my_pos].state == FREE &&
                 mypool->exit_thrs > 0)) {
            pthread_cond_wait(&mypool->queue_not_empty, &mypool->queue_mut);
        }

        /* 醒来后再次检查关闭和裁员 */
        if (mypool->shutdown) {
            pthread_mutex_unlock(&mypool->queue_mut);
            pthread_exit(NULL);
        }
        if (my_pos != -1 &&
            mypool->worker_thrs[my_pos].state == FREE &&
            mypool->exit_thrs > 0) {
            mypool->exit_thrs--;
            mypool->live_thrs--;
            mypool->worker_thrs[my_pos].state = BLANK;
            pthread_cond_signal(&mypool->working_cond);
            pthread_mutex_unlock(&mypool->queue_mut);
            pthread_exit(NULL);
        }

        /* 取出任务 */
        task_t task;
        queue_deq(mypool->task_queue, &task);

        /* 唤醒可能等待队列空间的生产者 */
        pthread_cond_signal(&mypool->queue_not_full);

        pthread_mutex_unlock(&mypool->queue_mut);

        /* 标记为 BUSY */
        if (my_pos != -1) {
            mypool->worker_thrs[my_pos].state = BUSY;
            pthread_mutex_lock(&mypool->working_mut);
            pthread_cond_signal(&mypool->working_cond);
            pthread_mutex_unlock(&mypool->working_mut);
        }

        /* 执行任务 */
        task.job_fun(task.arg);

        /* 任务完成，标记为 FREE */
        if (my_pos != -1) {
            pthread_mutex_lock(&mypool->working_mut);
            mypool->worker_thrs[my_pos].state = FREE;
            pthread_cond_signal(&mypool->working_cond);
            pthread_mutex_unlock(&mypool->working_mut);
        }
    }

    return NULL;
}

/* ==================== 管理员线程函数 ==================== */
static void *admin_fun(void *arg)
{
    thr_pool_t *mypool = (thr_pool_t *)arg;
    int busy, i, pos;

    pthread_mutex_lock(&mypool->working_mut);

    while (!mypool->shutdown) {
        /* 统计忙碌线程数 */
        busy = 0;
        for (i = 0; i < mypool->max_thrs; i++) {
            if (mypool->worker_thrs[i].state == BUSY)
                busy++;
        }

        /* 空闲太多 → 裁员（不低于 min_thrs） */
        if (busy * 2 < mypool->live_thrs && mypool->live_thrs > mypool->min_thrs) {
            int idle = mypool->live_thrs - busy;
            int to_exit = idle / 2;
            if (mypool->live_thrs - to_exit < mypool->min_thrs)
                to_exit = mypool->live_thrs - mypool->min_thrs;
            mypool->exit_thrs = to_exit;
        }

        /* 所有线程都忙 → 扩容 */
        if (busy == mypool->live_thrs && mypool->live_thrs < mypool->max_thrs) {
            pthread_mutex_unlock(&mypool->working_mut);  // 必须解锁

            for (i = 0; i < mypool->min_thrs && mypool->live_thrs < mypool->max_thrs; i++) {
                pos = __get_free_pos(mypool);
                if (pos == -1) break;

                if (pthread_create(&mypool->worker_thrs[pos].tid, NULL, worker_fun, mypool) == 0) {
                    mypool->worker_thrs[pos].state = FREE;
                    mypool->live_thrs++;
                }
            }

            pthread_mutex_lock(&mypool->working_mut);
        }

        pthread_cond_wait(&mypool->working_cond, &mypool->working_mut);
    }

    pthread_mutex_unlock(&mypool->working_mut);
    return NULL;
}

/* ==================== 初始化 ==================== */
int thr_pool_init(thr_pool_t **mypool, int min_thrs, int max_thrs, int queue_size)
{
    if (min_thrs <= 0 || max_thrs < min_thrs || queue_size <= 0) return -1;

    thr_pool_t *pool = calloc(1, sizeof(thr_pool_t));
    if (!pool) return -1;

    pool->worker_thrs = calloc(max_thrs, sizeof(working_thr_t));
    if (!pool->worker_thrs) {
        free(pool);
        return -1;
    }

    if (queue_init(&pool->task_queue, queue_size, sizeof(task_t)) != 0) {
        free(pool->worker_thrs);
        free(pool);
        return -1;
    }

    pthread_mutex_init(&pool->working_mut, NULL);
    pthread_cond_init(&pool->working_cond, NULL);
    pthread_mutex_init(&pool->queue_mut, NULL);
    pthread_cond_init(&pool->queue_not_empty, NULL);
    pthread_cond_init(&pool->queue_not_full, NULL);

    pool->min_thrs = min_thrs;
    pool->max_thrs = max_thrs;
    pool->live_thrs = 0;
    pool->exit_thrs = 0;
    pool->shutdown = 0;

    /* 创建管理员线程 */
    if (pthread_create(&pool->admin_thr, NULL, admin_fun, pool) != 0) {
        goto cleanup;
    }

    /* 创建最小数量的工作线程 */
    for (int i = 0; i < min_thrs; i++) {
        if (pthread_create(&pool->worker_thrs[i].tid, NULL, worker_fun, pool) != 0) {
            goto cleanup;
        }
        pool->worker_thrs[i].state = FREE;
        pool->live_thrs++;
    }

    /* 剩余槽位标记为 BLANK */
    for (int i = min_thrs; i < max_thrs; i++) {
        pool->worker_thrs[i].state = BLANK;
    }

    *mypool = pool;
    return 0;

cleanup:
    pool->shutdown = 1;
    pthread_cond_broadcast(&pool->queue_not_empty);
    pthread_cond_broadcast(&pool->working_cond);
    thr_pool_destroy(&pool);
    return -1;
}

/* ==================== 添加任务 ==================== */
int thr_pool_add_task(thr_pool_t *mypool, const task_t *t)
{
    if (!mypool || mypool->shutdown) return -1;

    pthread_mutex_lock(&mypool->queue_mut);

    while (queue_full(mypool->task_queue) && !mypool->shutdown) {
        pthread_cond_wait(&mypool->queue_not_full, &mypool->queue_mut);
    }

    if (mypool->shutdown) {
        pthread_mutex_unlock(&mypool->queue_mut);
        return -1;
    }

    queue_enter(mypool->task_queue, t);
    pthread_cond_signal(&mypool->queue_not_empty);

    pthread_mutex_unlock(&mypool->queue_mut);
    return 0;
}

/* ==================== 关闭线程池 ==================== */
int thr_pool_shutdown(thr_pool_t *mypool)
{
    if (!mypool || mypool->shutdown) return -1;

    pthread_mutex_lock(&mypool->queue_mut);
    mypool->shutdown = 1;
    pthread_cond_broadcast(&mypool->queue_not_empty);
    pthread_cond_broadcast(&mypool->queue_not_full);
    pthread_mutex_unlock(&mypool->queue_mut);

    pthread_cond_broadcast(&mypool->working_cond);

    return 0;
}

/* ==================== 销毁线程池 ==================== */
void thr_pool_destroy(thr_pool_t **mypool)
{
    if (!mypool || !*mypool) return;

    thr_pool_t *pool = *mypool;

    thr_pool_shutdown(pool);

    pthread_join(pool->admin_thr, NULL);

    for (int i = 0; i < pool->max_thrs; i++) {
        if (pool->worker_thrs[i].state != BLANK) {
            pthread_join(pool->worker_thrs[i].tid, NULL);
        }
    }

    queue_destroy(&pool->task_queue);

    pthread_mutex_destroy(&pool->working_mut);
    pthread_cond_destroy(&pool->working_cond);
    pthread_mutex_destroy(&pool->queue_mut);
    pthread_cond_destroy(&pool->queue_not_empty);
    pthread_cond_destroy(&pool->queue_not_full);

    free(pool->worker_thrs);
    free(pool);
    *mypool = NULL;
}
