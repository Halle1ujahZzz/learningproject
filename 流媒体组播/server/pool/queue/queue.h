#ifndef __QUEUE_H__
#define __QUEUE_H__

// 结构struct queue--->queue_t
typedef struct {
	void *arr; // 起始地址
	int front;
	int tail;
	int capacity;
	int size;
}queue_t;

// 功能
// 初始化
int queue_init(queue_t **q, int capacity, int size);

// 空队
int queue_empty(const queue_t *q);

// 满队
int queue_full(const queue_t *q);

// 入队
int queue_enter(queue_t *q, const void *data);

// 出队
int queue_deq(queue_t *q, void *data);

// 销毁队
void queue_destroy(queue_t **q);

#endif

