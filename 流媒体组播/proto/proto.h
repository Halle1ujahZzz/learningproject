#ifndef __NET_PROTO_H__
#define __NET_PROTO_H__

#define GROUP_ADDR		"224.2.3.7"
#define RCV_PORT	    1122
#define CHN_LIST_ID		0
#define CHN_DATA_MIN	1
#define CHN_NR			200
#define CHN_DATA_MAX	((CHN_DATA_MIN) + (CHN_NR) - 1)
#define MSG_SIZE		8192

// 列表
/*
 	0
		1               儿童音乐
		2		流行音乐 
		3 		交通广播
		4		ktv必点金曲......
 */
struct chn_list_entry {
	int8_t chnid; /*CHN_DATA_MIN, CHN_DATA_MAX*/
	int8_t len; // 自述长度
	char descr[1]; // 变长
}__attribute__((packed));

struct chn_list {
	int8_t chnid; // MUST BE CHN_LIST_ID
	struct chn_list_entry entry[1]; // 有多少个频道就有多少个struct chn_list_entry
}__attribute__((packed));

// 数据
struct chn_data {
	int8_t chnid; /*CHN_DATA_MIN, CHN_DATA_MAX*/
	char msg[MSG_SIZE];
}__attribute__((packed));

union chn_buf {
	int8_t chnid;
	struct chn_list list;
	struct chn_data data;
};

#endif

