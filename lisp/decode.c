/*
 * decode.c
 *
 * disassemble CADR microcode
 * or at least, try to :-)
 *
 * $Id: decode.c 61 2006-04-01 01:25:14Z brad $
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>

#if defined(LINUX) || defined(OSX)
#include <unistd.h>
#endif

typedef long long int64;
typedef unsigned long long uint64;
typedef uint64 ucw_t;

#define NOP_MASK 03777777777767777LL

#define l48(n)		((uint64)(n))
#define mask(v, n)	(l48(v) << (n))
#define bit(n)		(l48(1) << (n))

char *alu_bool_op[] = {
	"SETZ",
	"AND",
	"ANDCA",
	"SETM",
	"ANDCM",
	"SETA",
	"XOR",
	"IOR",
	"ANDCB",
	"EQV",
	"SETCA",
	"ORCA",
	"SETCM",
	"ORCM",
	"ORCB",
	"SETO"
};

char *alu_arith_op[] = {
	"-1",
	"(M&A)-1",
	"(M&~A)-1",
	"M-1",
	"M|~A",
	"(M|~A)+(M&A)",
	"M-A-1 [M-A-1]",
	"(M|~A)+M",
	"M|A",
	"M+A [ADD]",
	"(M|A)+(M&~A)",
	"(M|A)+M",
	"M",
	"M+(M&A)",
	"M+(M|~A)",
	"M+M"
};

void
disassemble_m_src(ucw_t u, int m_src)
{
	if (m_src & 040) {
		switch (m_src & 037) {
		case 0:
			printf("dispatch-constant "); break;
		case 1:
			printf("SPC-ptr, spc-data ");
			break;
		case 2:
			printf("PDL-ptr %o ", (int)u & 01777);
			break;
		case 3:
			printf("PDL-index %o ", (int)u & 01777);
			break;
		case 5:
			printf("PDL-buffer ");
			break;
		case 6:
			printf("OPC register %o ",
			       (int)u & 017777);
			break;
		case 7:
			printf("Q ");
			break;
		case 010:
			printf("VMA ");
			break;
		case 011:
			printf("MAP[MD] ");
			break;
		case 012:
			printf("MD ");
			break; 
		case 013:
			printf("LC ");
			break; 
		case 014:
			printf("SPC pointer and data, pop ");
			break; 
		case 024:
			printf("PDL[Pointer], pop ");
			break;
		case 025:
			printf("PDL[Pointer] ");
			break; 
		}
	} else {
		printf("m[%o] ", m_src);
	}
}

void
disassemble_dest(int dest)
{
	if (dest & 04000) {
		printf("->a_mem[%o] ", dest & 01777);
	} else {
		switch (dest >> 5) {
		case 0: printf("-><none>"); break;
		case 1: printf("->LC "); break;
		case 2: printf("->IC "); break;
		case 010: printf("->PDL[ptr] "); break;
		case 011: printf("->PDL[ptr],push "); break;
		case 012: printf("->PDL[index] "); break;
		case 013: printf("->PDL index "); break;
		case 014: printf("->PDL ptr "); break;

		case 015: printf("->SPC data,push "); break;

		case 016: printf("->OA-reg-lo "); break;
		case 017: printf("->OA-reg-hi "); break;

		case 020: printf("->VMA "); break;
		case 021: printf("->VMA,start-read "); break;
		case 022: printf("->VMA,start-write "); break;
		case 023: printf("->VMA,write-map "); break;

		case 030: printf("->MD "); break;
		case 031: printf("->MD,start-read "); break;
		case 032: printf("->MD,start-write "); break;
		case 033: printf("->MD,write-map "); break;
		}

		printf(",m[%o] ", dest & 037);
	}
}

void
disassemble_ucode_loc(int loc, ucw_t u)
{
	int a_src, m_src, new_pc, dest, alu_op;
	int r_bit, p_bit, n_bit, ir8, ir7;
	int widthm1, pos;
	int mr_sr_bits;
	int jump_op;

	int disp_cont, disp_addr;
	int map, len, rot;
	int out_bus;

	if ((u >> 42) & 1)
		printf("popj; ");

	switch ((u >> 43) & 03) {
	case 0: /* alu */
		printf("(alu) ");

		if ((u & NOP_MASK) == 0) {
			printf("no-op");
			goto done;
		}

		a_src = (u >> 32) & 01777;
		m_src = (u >> 26) & 077;
		dest = (u >> 14) & 07777;
		out_bus = (u >> 12) & 3;
		ir8 = (u >> 8) & 1;
		ir7 = (u >> 7) & 1;

		alu_op = (u >> 3) & 017;
		if (ir8 == 0) {
			if (ir7 == 0) {
				printf("%s ", alu_bool_op[alu_op]);
			} else {
				printf("%s ", alu_arith_op[alu_op]);
			}
		} else {
			switch (alu_op) {
			case 0: printf("mult-step "); break;
			case 1: printf("div-step "); break;
			case 5: printf("rem-corr "); break;
			case 011: printf("init-div-step "); break;
			}
		}

		printf("a=%o m=%o ", a_src, m_src);
		disassemble_m_src(u, m_src);

		if ((u >> 2) & 1)
			printf("C=1 ");
		else
			printf("C=0 ");

		switch (out_bus) {
		case 1: printf("alu-> "); break;
		case 2: printf("alu>>+s "); break;
		case 3: printf("alu<<+q31 "); break;
		}

		switch (u & 3) {
		case 1: printf("<<Q "); break;
		case 2: printf(">>Q "); break;
		case 3: printf("Q-R "); break;
		}

		disassemble_dest(dest);
		break;
	case 1: /* jump */
		printf("(jump) ");

		a_src = (u >> 32) & 01777;
		m_src = (u >> 26) & 077;
		new_pc = (u >> 12) & 037777;

		jump_op = (u >> 14) & 3;

		printf("a=%o m=", a_src);
		disassemble_m_src(u, m_src);

		r_bit = (u >> 9) & 1;
		p_bit = (u >> 8) & 1;
		n_bit = (u >> 7) & 1;

		printf("pc %o, %s%s",
		       new_pc,
		       r_bit ? "R " : "",
		       p_bit ? "P " : "");

		if (n_bit)
			/* INHIBIT-XCT-NEXT */
			printf("!next ");
		if (u & (1<<6))
			/* INVERT-JUMP-SENSE */
			printf("!jump ");

		if (u & (1<<5)) {
			switch (u & 017) {
			case 0:
			case 1: printf("M-src < A-src "); break;
			case 2: printf("M-src <= A-src "); break;
			case 3: printf("M-src = A-src "); break;
			case 4: printf("pf "); break;
			case 5: printf("pf/int "); break;
			case 6: printf("pf/int/seq "); break;
			case 7:
				printf("jump-always "); break;
			}
		} else {
			printf("m-rot<< %o", (int)u & 037);
		}

/*
  switch (jump_op) {
  case 0: printf("jump-xct-next "); break;
  case 1: printf("jump "); break;
  case 2: printf("call-xct-next "); break;
  case 3: printf("call "); break;
  }
*/
		break;
	case 2: /* dispatch */
		printf("(dispatch) ");

		disp_cont = (u >> 32) & 01777;
		m_src = (u >> 26) & 077;

		if ((u >> 25) & 1) printf("!N+1 ");
		if ((u >> 24) & 1) printf("ISH ");
		disp_addr = (u >> 12) & 03777;
		map = (u >> 8) & 3;
		len = (u >> 5) & 07;
		rot = u & 037;

		printf("m=%o ", m_src);
		disassemble_m_src(u, m_src);

		printf("disp-const %o, disp-addr %o, map %o, len %o, rot %o ",
		       disp_cont, disp_addr, map, len, rot);
		break;
	case 3: /* byte */
		printf("(byte) ");

		a_src = (u >> 32) & 01777;
		m_src = (u >> 26) & 077;
		dest = (u >> 14) & 07777;
		mr_sr_bits = (u >> 12) & 3;

		widthm1 = (u >> 5) & 037;
		pos = u & 037;

		printf("a=%o m=", a_src);
		disassemble_m_src(u, m_src);

		switch (mr_sr_bits) {
		case 0:
			break;
		case 1: /* ldb */
			printf("ldb pos=%o, width=%o ",
			       pos, widthm1+1);
			break;
		case 2:
			printf("sel dep (a<-m&mask) pos=%o, width=%o ",
			       pos, widthm1+1);
			break;
		case 3: /* dpb */
			printf("dpb pos=%o, width=%o ",
			       pos, widthm1+1);
			break;
		}

		disassemble_dest(dest);
		break;
	}

 done:
	printf("\n");
}

