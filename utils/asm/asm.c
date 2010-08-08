#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned long long u64;

unsigned long long opcode;
unsigned int pc;

u64 mem[01000];
char set[01000];

int wordis(char *s1, char *s2)
{
	return strcmp(s1, s2) == 0;
}

int prefixis(char *s1, char *s2)
{
	int l2 = strlen(s2);
	return memcmp(s1, s2, l2) == 0;
}

char *
getword(char *p, char *w)
{
	if (*p == 0)
		return NULL;

	while (*p) {
		if (*p != ' ' && *p != '\t')
			break;
		p++;
	}
	while (*p) {
		if (*p == ' ' || *p == ',')
			break;
		*w++ = *p++;
	}
	*w = 0;

	return p;
}

int
process_line(char *line)
{
	int n;
	char *p;
	char word[256];

	opcode = 0;

	if (line[0] == '#' || !line[0]) {
		printf("%s\n", line);
		return 0;
	}

	p = line;
	while ((p = getword(p, word))) {

		if (0) printf("word '%s'\n", word);

		if (wordis(word, ".org")) {
			printf("%s\n", line);
			n = sscanf(p+1, "%o", &pc);
			return 0;
		}

		if (wordis(word, ".op")) {
			n = sscanf(p+1, "%llo", &opcode);
			goto ok;
		}

		if (wordis(word, "noop")) {
			opcode = 010000;
			break;
		}

		if (wordis(word, "alu")) {
			char alu[256];

			p = getword(p, alu);
			if (prefixis(alu, "seta")) {
				opcode |= 05LL << 3;
			}
			if (prefixis(alu, "m+a")) {
				opcode |= 1LL << 7;
				opcode |= 011LL << 3;
			}
			if (prefixis(alu, "setz")) {
			}
		}

		if (wordis(word, "jump"))
			opcode |= 1LL << 43;

		if (wordis(word, "dispatch"))
			opcode |= 2LL << 43;

		if (wordis(word, "byte"))
			opcode |= 3LL << 43;

		if (wordis(word, "aluout"))
			opcode |= 1LL << 12;

		if (prefixis(word, "a=")) {
			int a;
			sscanf(word, "a=%o", &a);
			if (0) printf("a=%o\n", a);
			opcode |= (u64)a << 32;
		}

		if (prefixis(word, "m=")) {
			int a;
			n = sscanf(word, "m=%o", &a);
			if (n == 1) {
				if (0) printf("m=%o\n", a);
				opcode |= (u64)a << 26;
			} else {
				opcode |= (u64)1 << 31;

				n = sscanf(word, "m=%s", word);
				printf("m %s\n", word);
				if (wordis(word, "md"))
					opcode |= (u64)012 << 26;
			}
		}

		if (prefixis(word, "->")) {
			int a, m;
			char dest[256];
			p = &word[2];

			while ((p = getword(p, dest))) {
				if (prefixis(dest, "a[")) {
					opcode |= (u64)1 << 25;
					n = sscanf(dest, "a[%o]", &a);
					opcode |= (u64)a << 14;
				}
				if (prefixis(dest, "m[")) {
					opcode |= (u64)1 << 25;
					n = sscanf(dest, "m[%o]", &m);
					opcode |= (u64)m << 14;
				}
				if (wordis(dest, "vma")) {
					opcode |= (u64)020 << 19;
				}
				if (wordis(dest, "vma+read")) {
					opcode |= (u64)021 << 19;
				}
				if (wordis(dest, "vma+write")) {
					opcode |= (u64)022 << 19;
				}
				if (wordis(dest, "md")) {
					opcode |= (u64)030 << 19;
				}
				if (wordis(dest, "md+read")) {
					opcode |= (u64)031 << 19;
				}
				if (wordis(dest, "md+write")) {
					opcode |= (u64)032 << 19;
				}
			}
		}

		if (!p)
			break;
	}

ok:
	printf("%03o %016llo %s\n", pc, opcode, line);

	printf("\t");
	disassemble_ucode_loc(pc, opcode);

	printf("\n");

	mem[pc] = opcode;
	set[pc]++;

	pc++;
	return 0;
}

main(int argc, char *argv[])
{
	int i;
	char line[1024];

	while (fgets(line, sizeof(line), stdin)) {
		int l = strlen(line);
		if (l && line[l-1] == '\n')
			line[l-1] = 0;
		process_line(line);
	}

	for (i = 0; i < 01000; i++) {
		if (set[i]) {
			printf("%03o\t%016llo\n", i, mem[i]);
		}
	}

	exit(0);
}
