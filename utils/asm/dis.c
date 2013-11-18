/*
 * disassemble CADR microcode
 * or at least, try to :-)
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned long long u64;
#define NOP_MASK 03777777777767777LL

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>
#include <unistd.h>

//#include "ucode.h"

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

#define ucw_t u64

void
disassemble_m_src(ucw_t u, int m_src, FILE *out)
{
	if (m_src & 040) {
		switch (m_src & 037) {
		case 0:
			fprintf(out, "dispatch-constant "); break;
		case 1:
			fprintf(out, "SPC-ptr, spc-data ");
			break;
		case 2:
			fprintf(out, "PDL-ptr %o ", (int)u & 01777);
			break;
		case 3:
			fprintf(out, "PDL-index %o ", (int)u & 01777);
			break;
		case 5:
			fprintf(out, "PDL-buffer ");
			break;
		case 6:
			fprintf(out, "OPC register %o ",
				(int)u & 017777);
			break;
		case 7:
			fprintf(out, "Q ");
			break;
		case 010:
			fprintf(out, "VMA ");
			break;
		case 011:
			fprintf(out, "MAP[MD] ");
			break;
		case 012:
			fprintf(out, "MD ");
			break; 
		case 013:
			fprintf(out, "LC ");
			break; 
		case 014:
			fprintf(out, "SPC pointer and data, pop ");
			break; 
		case 024:
			fprintf(out, "PDL[Pointer], pop ");
			break;
		case 025:
			fprintf(out, "PDL[Pointer] ");
			break; 
		}
	} else {
		fprintf(out, "m[%o] ", m_src);
	}
}

void
disassemble_dest(int dest, FILE *out)
{
	if (dest & 04000) {
		fprintf(out, "->a_mem[%o] ", dest & 01777);
	} else {
		switch (dest >> 5) {
		case 0: fprintf(out, "-><none>"); break;
		case 1: fprintf(out, "->LC "); break;
		case 2: fprintf(out, "->IC "); break;
		case 010: fprintf(out, "->PDL[ptr] "); break;
		case 011: fprintf(out, "->PDL[ptr],push "); break;
		case 012: fprintf(out, "->PDL[index] "); break;
		case 013: fprintf(out, "->PDL index "); break;
		case 014: fprintf(out, "->PDL ptr "); break;

		case 015: fprintf(out, "->SPC data,push "); break;

		case 016: fprintf(out, "->OA-reg-lo "); break;
		case 017: fprintf(out, "->OA-reg-hi "); break;

		case 020: fprintf(out, "->VMA "); break;
		case 021: fprintf(out, "->VMA,start-read "); break;
		case 022: fprintf(out, "->VMA,start-write "); break;
		case 023: fprintf(out, "->VMA,write-map "); break;

		case 030: fprintf(out, "->MD "); break;
		case 031: fprintf(out, "->MD,start-read "); break;
		case 032: fprintf(out, "->MD,start-write "); break;
		case 033: fprintf(out, "->MD,write-map "); break;
		}

		fprintf(out, ",m[%o] ", dest & 037);
	}
}

void
disassemble_ucode_loc(int loc, ucw_t u, FILE *out)
{
	int a_src, m_src, new_pc, dest, alu_op;
	int r_bit, p_bit, n_bit, ir8, ir7;
	int widthm1, pos;
	int mr_sr_bits;
	int jump_op;

	int disp_cont, disp_addr;
	int map, len, rot;
	int out_bus;

	if (out == NULL)
		return;

	if ((u >> 42) & 1)
		fprintf(out, "popj; ");

	if ((u >> 10) & 3) {
		fprintf(out, "misc=%d; ", (int)((u >> 10) & 3));
	}

	switch ((u >> 43) & 03) {
	case 0: /* alu */
		fprintf(out, "(alu) ");

		if ((u & NOP_MASK) == 0) {
			fprintf(out, "no-op");
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
				fprintf(out, "%s ", alu_bool_op[alu_op]);
			} else {
				fprintf(out, "%s ", alu_arith_op[alu_op]);
			}
		} else {
			switch (alu_op) {
			case 0: fprintf(out, "mult-step "); break;
			case 1: fprintf(out, "div-step "); break;
			case 5: fprintf(out, "rem-corr "); break;
			case 011: fprintf(out, "init-div-step "); break;
			}
		}

		fprintf(out, "a=%o m=%o ", a_src, m_src);
		disassemble_m_src(u, m_src, out);

		if ((u >> 2) & 1)
			fprintf(out, "C=1 ");
		else
			fprintf(out, "C=0 ");

		switch (out_bus) {
		case 1: fprintf(out, "alu-> "); break;
		case 2: fprintf(out, "alu>>+s "); break;
		case 3: fprintf(out, "alu<<+q31 "); break;
		}

		switch (u & 3) {
		case 1: fprintf(out, "<<Q "); break;
		case 2: fprintf(out, ">>Q "); break;
		case 3: fprintf(out, "Q-R "); break;
		}

		disassemble_dest(dest, out);
		break;
	case 1: /* jump */
		fprintf(out, "(jump) ");

		a_src = (u >> 32) & 01777;
		m_src = (u >> 26) & 077;
		new_pc = (u >> 12) & 037777;

		jump_op = (u >> 14) & 3;

		fprintf(out, "a=%o m=", a_src);
		disassemble_m_src(u, m_src, out);

		r_bit = (u >> 9) & 1;
		p_bit = (u >> 8) & 1;
		n_bit = (u >> 7) & 1;

		fprintf(out, "pc %o, %s%s",
		       new_pc,
		       r_bit ? "R " : "",
		       p_bit ? "P " : "");

		if (n_bit)
			/* INHIBIT-XCT-NEXT */
			fprintf(out, "!next ");
		if (u & (1<<6))
			/* INVERT-JUMP-SENSE */
			fprintf(out, "!jump ");

		if (u & (1<<5)) {
			switch (u & 017) {
			case 0:
			case 1: fprintf(out, "M-src < A-src "); break;
			case 2: fprintf(out, "M-src <= A-src "); break;
			case 3: fprintf(out, "M-src = A-src "); break;
			case 4: fprintf(out, "pf "); break;
			case 5: fprintf(out, "pf/int "); break;
			case 6: fprintf(out, "pf/int/seq "); break;
			case 7:
				fprintf(out, "jump-always "); break;
			}
		} else {
			fprintf(out, "m-rot<< %o", (int)u & 037);
		}

/*
  switch (jump_op) {
  case 0: fprintf(out, "jump-xct-next "); break;
  case 1: fprintf(out, "jump "); break;
  case 2: fprintf(out, "call-xct-next "); break;
  case 3: fprintf(out, "call "); break;
  }
*/
		break;
	case 2: /* dispatch */
		fprintf(out, "(dispatch) ");

		disp_cont = (u >> 32) & 01777;
		m_src = (u >> 26) & 077;

		if ((u >> 25) & 1) fprintf(out, "!N+1 ");
		if ((u >> 24) & 1) fprintf(out, "ISH ");
		disp_addr = (u >> 12) & 03777;
		map = (u >> 8) & 3;
		len = (u >> 5) & 07;
		rot = u & 037;

		fprintf(out, "m=%o ", m_src);
		disassemble_m_src(u, m_src, out);

		fprintf(out, "disp-const=%o, disp-addr=%o, map=%o, len=%o, rot=%o ",
		       disp_cont, disp_addr, map, len, rot);
		break;
	case 3: /* byte */
		fprintf(out, "(byte) ");

		a_src = (u >> 32) & 01777;
		m_src = (u >> 26) & 077;
		dest = (u >> 14) & 07777;
		mr_sr_bits = (u >> 12) & 3;

		widthm1 = (u >> 5) & 037;
		pos = u & 037;

		fprintf(out, "a=%o m=", a_src);
		disassemble_m_src(u, m_src, out);

		switch (mr_sr_bits) {
		case 0:
			break;
		case 1: /* ldb */
			fprintf(out, "ldb pos=%o, width=%o ",
			       pos, widthm1+1);
			break;
		case 2:
			fprintf(out, "sel dep (a<-m&mask) pos=%o, width=%o ",
			       pos, widthm1+1);
			break;
		case 3: /* dpb */
			fprintf(out, "dpb pos=%o, width=%o ",
			       pos, widthm1+1);
			break;
		}

		disassemble_dest(dest, out);
		break;
	}

 done:
	fprintf(out, "\n");
}


//		disassemble_ucode_loc(i, u);

