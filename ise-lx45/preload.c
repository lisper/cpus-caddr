//
// gcc -Wall -fPIC -DPIC -c preload.c
// ld -shared -o preload.so preload.o -ldl
//
#define _GNU_SOURCE
#include <time.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

void __attribute__((constructor)) my_init(void)
{
	printf("INIT preload\n");
	dlopen(getenv("LD_PRELOAD"), RTLD_NOLOAD | RTLD_DEEPBIND | RTLD_GLOBAL | RTLD_NOW);
}


int nanosleep(const struct timespec *req, struct timespec *rem)
{
	struct timespec t;
	//printf("HOOKED nanosleep\n");
	int (*f)() = dlsym(RTLD_NEXT, "nanosleep");
	t.tv_sec = 0;
	t.tv_nsec = 0;
	int ret = f(&t, rem);
	return ret;
}

int __nanosleep(const struct timespec *req, struct timespec *rem)
{
	struct timespec t;
	printf("HOOKED __nanosleep\n");
	int (*f)() = dlsym(RTLD_NEXT, "nanosleep");
	t.tv_sec = 0;
	t.tv_nsec = 0;
	int ret = f(&t, rem);
	return ret;
}
