#include <stdlib.h>
#include <time.h>
#include <pthread.h>
#include "tbf.h"

#define TBF_MAX	1024

static tbf_t *tbf_lib[TBF_MAX] = {NULL};
static int inited = 0;

// 全局互斥锁，保护 tbf_lib 和 last_update
pthread_mutex_t tbf_mut = PTHREAD_MUTEX_INITIALIZER;

// 上一次更新时间
static time_t last_update = 0;

static int __get_free_pos(void)
{
    int pos;
    pthread_mutex_lock(&tbf_mut);
    for (pos = 0; pos < TBF_MAX; pos++) {
        if (tbf_lib[pos] == NULL) {
            pthread_mutex_unlock(&tbf_mut);
            return pos;
        }
    }
    pthread_mutex_unlock(&tbf_mut);
    return -1;
}

int tbf_init(int cps, int burst)
{
    tbf_t *me = NULL;
    int pos;

    pthread_mutex_lock(&tbf_mut);
    if (!inited) {
        last_update = time(NULL);
        inited = 1;
    }
    pthread_mutex_unlock(&tbf_mut);

    me = malloc(sizeof(tbf_t));
    if (me == NULL)
        return -1;

    me->cps = cps;
    me->burst = burst;
    me->token = 0;

    pos = __get_free_pos();
    if (pos == -1) {
        free(me);
        return -1;
    }

    pthread_mutex_lock(&tbf_mut);
    tbf_lib[pos] = me;
    pthread_mutex_unlock(&tbf_mut);

    return pos;
}

int tbf_fetch_token(int tb, int ntokens)
{
    if (tb < 0 || tb >= TBF_MAX) {
        return -1;
    }

    pthread_mutex_lock(&tbf_mut);

    if (tbf_lib[tb] == NULL) {
        pthread_mutex_unlock(&tbf_mut);
        return -1;
    }

    tbf_t *me = tbf_lib[tb];

    // 懒增加 token
    time_t now = time(NULL);
    long seconds = now - last_update;
    if (seconds > 0) {
        long add = seconds * me->cps;
        me->token += add;
        if (me->token > me->burst) {
            me->token = me->burst;
        }
        last_update = now;
    }

    int available = me->token;
    if (available == 0) {
        pthread_mutex_unlock(&tbf_mut);
        return 0;
    }

    int ret = ntokens;
    if (available < ntokens) {
        ret = available;
    }

    me->token -= ret;

    pthread_mutex_unlock(&tbf_mut);
    return ret;
}

void tbf_destroy(int tb)
{
    pthread_mutex_lock(&tbf_mut);
    if (tb >= 0 && tb < TBF_MAX && tbf_lib[tb]) {
        free(tbf_lib[tb]);
        tbf_lib[tb] = NULL;
    }
    pthread_mutex_unlock(&tbf_mut);
}

void tbf_destroy_all(void)
{
    pthread_mutex_lock(&tbf_mut);
    for (int i = 0; i < TBF_MAX; i++) {
        if (tbf_lib[i]) {
            free(tbf_lib[i]);
            tbf_lib[i] = NULL;
        }
    }
    pthread_mutex_unlock(&tbf_mut);
}
