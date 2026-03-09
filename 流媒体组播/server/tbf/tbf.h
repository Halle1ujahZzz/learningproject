#ifndef __TBF_H__
#define __TBF_H__

#define	TBF_MAX	1024
#include <pthread.h>

extern pthread_mutex_t tbf_mut;
typedef struct {
	int cps;
	int token;
	int burst;
}tbf_t;

int tbf_init(int cps, int burst);

int tbf_fetch_token(int tb, int ntokens);

void tbf_destroy(int tb);

void tbf_destroy_all(void);

#endif

