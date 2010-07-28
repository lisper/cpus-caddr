#include <stdio.h>
#include <stdlib.h>

main()
{
	char line[1024];

	while (fgets(line, sizeof(line), stdin)) {
		unsigned int vaddr, v;
		unsigned int d1, d2, d3, d4, d5, d6;

/*write_mem(vaddr=77051557) l1[3742]=21, l2[1063]=263036123, pn=36123 offset=157; v 0 */
		if (line[0] == 'w' &&
		    line[1] == 'r' &&
		    line[2] == 'i' &&
		    line[3] == 't' &&
		    line[4] == 'e' &&
		    line[5] == '_' &&
		    line[6] == 'm')
		{
			sscanf(line, "write_mem(vaddr=%o) l1[%o]=%o, l2[%o]=%o, pn=%o offset=%o; v %o",
			       &vaddr, &d1, &d2, &d3, &d4, &d5, &d6, &v);

			vaddr &= 077777777;
			if ((vaddr & 077770000) == 077050000) {
				vaddr &= 077777;
				if (vaddr == 051765)
					continue;
				if (vaddr == 051763)
					continue;
				printf("%08o %011o\n", vaddr, v);
			}
		}

/*vram: W addr 37100 <- 00000000000;            477667578*/
		if (line[0] == 'v' &&
		    line[1] == 'r' &&
		    line[2] == 'a' &&
		    line[3] == 'm' &&
		    line[4] == ':' &&
		    line[5] == ' ' &&
		    line[6] == 'W')
		{
			sscanf(line, "vram: W addr %o <- %o;", &vaddr, &v);

			if (vaddr < 050000)
				continue;
			if (vaddr == 051765)
				continue;
			if (vaddr == 051763)
				continue;
//if (v == 0) continue;
			printf("%08o %011o\n", vaddr, v);
		}
	}
	exit(0);
}
