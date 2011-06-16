#include <pspkernel.h>

PSP_MODULE_INFO("cpu test", 0, 1, 1);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER);

#define OP(TYPE) int __attribute__((noinline)) op_##TYPE(int x, int y) { int result; asm volatile(#TYPE " %0, %1, %2" : "=r"(result) : "r"(x), "r"(y)); return result; }

#define OP_TEST(TYPE, a, b) Kprintf("%s %d, %d, %d\n", #TYPE, a, b, op_##TYPE(a, b));

OP(add)
OP(max)

int main(int argc, char *argv[]) {
	OP_TEST(max, 1, 7);
	OP_TEST(max, 3, 1);
	OP_TEST(max, -1, 0);
	OP_TEST(max, -1, -10);
	OP_TEST(max, 0, 0);

	OP_TEST(add, 1, 7);
	OP_TEST(add, 3, 1);
	OP_TEST(add, -1, 0);
	OP_TEST(add, -1, -10);
	OP_TEST(add, 0, 0);

	return 0;
}