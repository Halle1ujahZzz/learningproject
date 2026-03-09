#include <stdlib.h>
#include <string.h>

#include "queue.h"

int queue_init(queue_t **q, int capacity, int size)
{
	*q = malloc(sizeof(queue_t));
	if (NULL == *q)
		return -1;

	 (*q)->arr = calloc(capacity, size);
	if (NULL == (*q)->arr) {
		free(*q);
		*q = NULL;
		return -1;
	}
	(*q)->capacity = capacity;
	(*q)->size = size;
	(*q)->front = (*q)->tail = 0;

	return 0;
}

int queue_empty(const queue_t *q)
{
	return q->front == q->tail;
}

int queue_full(const queue_t *q)
{
	return (q->tail + 1) % q->capacity == q->front;
}

int queue_enter(queue_t *q, const void *data)
{
	if (queue_full(q))
		return -1;
	memcpy((char *)q->arr + q->tail * q->size, data, q->size);
	q->tail = (q->tail + 1) % q->capacity;

	return 0;
}

int queue_deq(queue_t *q, void *data)
{
	if (queue_empty(q))
		return -1;
	memcpy(data, (char *)q->arr + q->front * q->size, q->size);
	q->front = (q->front + 1) % q->capacity;

	return 0;
}

void queue_destroy(queue_t **q)
{
	free((*q)->arr);
	(*q)->arr = NULL;
	free(*q);
	*q = NULL;
}

