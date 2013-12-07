// test.cpp
//
//

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtest.h"

#include <iostream>

//#define RC_SYNC_CHECK
#define LOAD_MEMORIES
//#define RC_MEM
//#define MODEL_MEM

Vtest *top;                      // Instantiation of module

static unsigned long long main_time = 0;     // Current simulation time

double sc_time_stamp () {       // Called by $time in Verilog
    return main_time;
}

int init_memories(const char *filename, int show)
{
#ifdef LOAD_MEMORIES
    FILE *in;
    in = fopen(filename, "r");
    if (in == NULL)
	    return -1;
    if (in) {
	    char ch;
	    int a;
	    unsigned long long vl;
	    unsigned int v, h, l;
	    while (fscanf(in, "%c %o %llo\n", &ch, &a, &vl) == 3) {
		    if (show) VL_PRINTF("%c %o %llo\n", ch, a, vl);
		    v = vl;
		    switch (ch) {
		    case 'A':
			    top->v__DOT__cpu__DOT__i_AMEM__DOT__ram[a] = v;
			    break;
		    case 'M':
			    top->v__DOT__cpu__DOT__i_MMEM__DOT__ram[a] = v;
			    break;
		    case 'D':
			    top->v__DOT__cpu__DOT__i_DRAM__DOT__ram[a] = v;
			    break;
		    case 'I':
			    int a1h, a1l, a2h, a2l;
			    unsigned char v1h, v1l, v2h, v2l;

#ifdef RC_MEM
			    h = vl >> 32;
			    l = vl & 0xffffffff;
			    
			    if (0)
			    VL_PRINTF("test.cpp: write I @ %o %llo (%o %o)\n",
				      a, vl, h, l);

			    a1h = 0x20000 | (a << 1);
			    a1l = a2h = a2l = a1h;

			    v1h = h >> 24;
			    v1l = h >> 16;
			    v2h = h >> 8;
			    v2l = h >> 0;

			    top->v__DOT__ram__DOT__ram1__DOT__ram_h[a1h] = v1h;
			    top->v__DOT__ram__DOT__ram1__DOT__ram_l[a1l] = v1l;
			    top->v__DOT__ram__DOT__ram2__DOT__ram_h[a2h] = v2h;
			    top->v__DOT__ram__DOT__ram2__DOT__ram_l[a2l] = v2l;
			    if (0) VL_PRINTF("test.cpp: write I @ %o\n", a1h);

			    a1h++; a1l++; a2h++; a2l++;

			    v1h = l >> 24;
			    v1l = l >> 16;
			    v2h = l >> 8;
			    v2l = l >> 0;

			    top->v__DOT__ram__DOT__ram1__DOT__ram_h[a1h] = v1h;
			    top->v__DOT__ram__DOT__ram1__DOT__ram_l[a1l] = v1l;
			    top->v__DOT__ram__DOT__ram2__DOT__ram_h[a2h] = v2h;
			    top->v__DOT__ram__DOT__ram2__DOT__ram_l[a2l] = v2l;
			    if (0) VL_PRINTF("test.cpp: write I @ %o\n", a1h);
#endif
#ifdef MODEL_MEM
			    top->v__DOT__cpu__DOT__i_IRAM__DOT__ram[a] = vl;
#endif
			    break;
		    case '0':
			    top->v__DOT__cpu__DOT__i_VMEM0__DOT__ram[a] = v;
			    break;
		    case '1':
			    top->v__DOT__cpu__DOT__i_VMEM1__DOT__ram[a] = v;
			    break;
		    }
	    }
	    fclose(in);
    }
#endif

    return 0;
}

#ifdef RC_SYNC_CHECK
int rc_sync_check(void)
{
        if (top->v__DOT__sysclk &&
	    top->v__DOT__rc__DOT__state != 2)
	{
		if (top->v__DOT__cpu__DOT__state == 8 && /* state_write */
		    top->v__DOT__rc__DOT__state != 1) /* S1 */
		{
			VL_PRINTF("out of sync: cpu %d rc %d; %lld\n",
				  top->v__DOT__cpu__DOT__state,
				  top->v__DOT__rc__DOT__state,
				  main_time);
			vl_finish("test.cpp",__LINE__,"");
		}
	}
}
#endif

int main(int argc, char** argv)
{
    VerilatedVcdC* tfp = NULL;
    Verilated::commandArgs(argc, argv);   // Remember args

    int load_memories = 0;
    int show_waves = 0;
    int show_pc = 0;
    int show_min_time = 0;
    int show_max_time = 0;
    int show_memories = 0;
    int force_mcram = 0;
    int force_debug = 0;
    int force_debug_ram = 0;
    int clocks_100 = 0;
    int clocks_25 = 0;
    int clocks_12 = 0;
    int clocks_6 = 0;
    int clocks_1x = 0;
    int clocks_all = 0;

    int reset_mult = 1;
    int loop_count = 0;
    int wait_count = 0;
    int max_loop = 20;
    char *mem_filename;
    int result = 0;

    top = new Vtest;             // Create instance

    printf("built on: %s %s\n", __DATE__, __TIME__);

    mem_filename = (char *)"output";

    // process local args
    for (int i = 0; i < argc; i++) {
	    if (argv[i][0] == '+') {
		    switch (argv[i][1]) {
		    case 'l':
			    load_memories++;
			    mem_filename = strdup(argv[++i]);
			    break;
		    case 'm': show_memories++; break;
		    case 'w': show_waves++; break;
		    case 'p': show_pc++; break;
		    case 'f': force_mcram++; break;
		    case 'd': force_debug++; break;
		    case 'r': force_debug_ram++; break;
		    case 'c':
			    switch (argv[i][2]) {
			    case '0': clocks_1x++; break;
			    case '1': clocks_100++; break;
			    case '3': clocks_25++; break;
			    case '4': clocks_12++; break;
			    case '5': clocks_6++; break;
			    case 'a': clocks_all++; break;
			    }
			    break;
		    case 'b': show_min_time = atoi(argv[i]+2); break;
		    case 'e': show_max_time = atoi(argv[i]+2); break;
		    default:
			    fprintf(stderr, "bad arg? %s\n", argv[i]);
			    exit(1);
		    }
	    }
    }

#ifdef VM_TRACE
    if (show_waves) {
	    Verilated::traceEverOn(true);
	    VL_PRINTF("Enabling waves...\n");
	    tfp = new VerilatedVcdC;
	    top->trace(tfp, 99);	// Trace 99 levels of hierarchy
	    tfp->open("test.vcd");	// Open the dump file

	    if (show_min_time)
		    printf("show_min_time=%d\n", (int)show_min_time);
	    if (show_max_time)
		    printf("show_max_time=%d\n", (int)show_max_time);
    }
#endif

    float hp50, hp100, hp108;
    float t50, t100, t108;
    hp50 =  ((1.0 / 50000000.0)  * 1000000000.0) / 2.0;
    hp100 = ((1.0 / 100000000.0) * 1000000000.0) / 2.0;
    hp108 = ((1.0 / 108000000.0) * 1000000000.0) / 2.0;

    if (force_debug) {
	    printf("force debug\n");
    }

    // main loop
    int clk25, clk12, clk6;

    if (clocks_100 || clocks_25 || clocks_12)
	    max_loop = 200;
    if (clocks_6)
	    max_loop = 500;
    if (clocks_all)
	    max_loop = 5000;

    while (!Verilated::gotFinish()) {

        if (load_memories && main_time == 1) {
	    if (init_memories(mem_filename, show_memories)) {
		perror(mem_filename);
		fprintf(stderr, "memory initialization failed\n");
		exit(1);
	    }
	}

	// toggle clock(s)
	if (clocks_1x) {
		reset_mult = 1;
		top->v__DOT__clk1x = top->v__DOT__clk1x ? 0 : 1;
		top->v__DOT__clk50 = top->v__DOT__clk1x;
		top->v__DOT__clk100 = top->v__DOT__clk1x;
	}

	if (clocks_100) {
		reset_mult = 10;

		top->v__DOT__clk100 = top->v__DOT__clk100 ? 0 : 1;
		if (top->v__DOT__clk100) {
			top->v__DOT__clk50 = top->v__DOT__clk50 ? 0 : 1;
			if (top->v__DOT__clk50)
				top->v__DOT__clk1x = top->v__DOT__clk1x ? 0 : 1;
		}
	}

	if (clocks_25) {
		reset_mult = 10;

		top->v__DOT__clk100 = top->v__DOT__clk100 ? 0 : 1;
		if (top->v__DOT__clk100) {
			top->v__DOT__clk50 = top->v__DOT__clk50 ? 0 : 1;
			if (top->v__DOT__clk50) {
				clk25 = clk25 ? 0 : 1;
				if (clk25)
					top->v__DOT__clk1x = top->v__DOT__clk1x ? 0 : 1;
			}
		}
	}

	if (clocks_12) {
		reset_mult = 10;

		top->v__DOT__clk100 = top->v__DOT__clk100 ? 0 : 1;
		top->v__DOT__pixclk = top->v__DOT__clk100;
		if (top->v__DOT__clk100) {
			top->v__DOT__clk50 = top->v__DOT__clk50 ? 0 : 1;
			if (top->v__DOT__clk50) {
				clk25 = clk25 ? 0 : 1;
				if (clk25) {
					clk12 = clk12 ? 0 : 1;
					if (clk12)
						top->v__DOT__clk1x =
							top->v__DOT__clk1x ? 0 : 1;
				}
			}
		}
	}

	if (clocks_6) {
		reset_mult = 10;

		top->v__DOT__clk100 = top->v__DOT__clk100 ? 0 : 1;
		top->v__DOT__pixclk = top->v__DOT__clk100;
		if (top->v__DOT__clk100) {
			top->v__DOT__clk50 = top->v__DOT__clk50 ? 0 : 1;
			if (top->v__DOT__clk50) {
				clk25 = clk25 ? 0 : 1;
				if (clk25) {
					clk12 = clk12 ? 0 : 1;
					if (clk12) {
						clk6 = clk6 ? 0 : 1;
						if (clk6) {
							top->v__DOT__clk1x =
							top->v__DOT__clk1x ?
								0 : 1;
						}
					}
				}
			}
		}
	}

	if (clocks_all) {
		reset_mult = 40;
		if (t50 >= hp50) {
			t50 = 0.0;
			top->v__DOT__clk50 = top->v__DOT__clk50 ? 0 : 1;
			if (top->v__DOT__clk50)
				top->v__DOT__clk1x = top->v__DOT__clk1x ? 0 : 1;
		}

		if (t100 >= hp100) {
			t100 = 0.0;
			top->v__DOT__clk100 = top->v__DOT__clk100 ? 0 : 1;
		}

		if (t108 >= hp108) {
			t108 = 0.0;
			top->v__DOT__pixclk = top->v__DOT__pixclk ? 0 : 1;
		}

		t50 += 0.25;
		t100 += 0.25;
		t108 += 0.25;
	}

	// resets
	if (main_time < 500*reset_mult) {
	    if (main_time == 10*reset_mult) {
		    VL_PRINTF("reset on\n");
		    top->v__DOT__reset = 1;
	    }
	    if (main_time == 240*reset_mult) {
		    VL_PRINTF("boot on\n");
		    top->v__DOT__boot = 1;
	    }
	    if (main_time == 250*reset_mult) {
		    VL_PRINTF("reset off\n");
		    top->v__DOT__reset = 0;
	    }
	    if (main_time == 260*reset_mult) {
		    VL_PRINTF("boot off\n");
		    top->v__DOT__boot = 0;
		    top->v__DOT__cycles = 0;
	    }
	}

	// evaluate model
        top->eval();

	if (force_mcram) {
		top->v__DOT__cpu__DOT__set_promdisable = 1;
		top->v__DOT__cpu__DOT__promdisable = 1;
	}

	if (force_debug) {
		top->v__DOT__cpu__DOT__busint__DOT__disk__DOT__debug = 1;
//		top->v__DOT__cpu__DOT__busint__DOT__dram__DOT__debug = 1;
		top->v__DOT__cpu__DOT__debug = 1;
	}

	if (force_debug || force_debug_ram) {
		top->v__DOT__cpu__DOT__i_AMEM__DOT__debug = 2;
		top->v__DOT__cpu__DOT__i_MMEM__DOT__debug = 1;
		top->v__DOT__cpu__DOT__i_SPC__DOT__debug = 2;
		top->v__DOT__cpu__DOT__i_PDL__DOT__debug = 2;
#ifdef MODEL_MEM
		top->v__DOT__cpu__DOT__i_IRAM__DOT__debug = 1;
#endif
		top->v__DOT__cpu__DOT__i_VMEM0__DOT__debug = 2;
		top->v__DOT__cpu__DOT__i_VMEM1__DOT__debug = 2;
	}

	int old_clk1x;

	if (top->v__DOT__reset)
		int old_clk1x = 1;

	if (force_debug && 0) {
		printf("clk %d %d state %d\n",
		       top->v__DOT__clk1x, old_clk1x,
		       top->v__DOT__cpu__DOT__state);
	}

#if 0
	if (top->v__DOT__clk1x == 1 &&
	    top->v__DOT__cpu__DOT__promdisable == 0 &&
	    top->v__DOT__cpu__DOT__lpc == 0402)
	{
		vl_finish("test.cpp",__LINE__,"");
		result = 3;
	}
#endif

	if (top->v__DOT__clk1x && old_clk1x == 0 &&
	    top->v__DOT__cpu__DOT__state == 4)
	{
#if 0
		if (top->v__DOT__cpu__DOT__promdisable == 1 &&
		    top->v__DOT__cpu__DOT__lpc == 024047)
		{
			show_pc = 1;
			force_debug = 1;
		}
#endif

		if (show_pc)
			VL_PRINTF("%llu; %o %017llo A=%011o M=%011o N%d R=%011o LC=%011o\n",
				  main_time,
				  top->v__DOT__cpu__DOT__lpc,
				  (QData)top->v__DOT__cpu__DOT__ir,
				  top->v__DOT__cpu__DOT__i_AMEM__DOT__out_a,
				  top->v__DOT__cpu__DOT__m,
				  top->v__DOT__cpu__DOT__n,
				  top->v__DOT__cpu__DOT__r,
				  top->v__DOT__cpu__DOT__lc);

		if (0)
			VL_PRINTF("%o promdisable %d, promdisabled %d, set_promdisable %d\n",
				  top->v__DOT__cpu__DOT__lpc,
				  top->v__DOT__cpu__DOT__promdisable,
				  top->v__DOT__cpu__DOT__promdisabled,
				  top->v__DOT__cpu__DOT__set_promdisable);

		if (0)
			VL_PRINTF("vma: vma %o ob %o alu %llo\n",
				  top->v__DOT__cpu__DOT__vma,
				  top->v__DOT__cpu__DOT__ob,
				  top->v__DOT__cpu__DOT__alu);

//		if (show_pc)
//			VL_PRINTF("cycle %lu\n", (unsigned long int)top->v__DOT__cycles);

		/* debug hack */
		if ((QData)top->v__DOT__cpu__DOT__ir & 010000000000000000LL) {
			if ((QData)top->v__DOT__cpu__DOT__ir & 0xffLL) {
				VL_PRINTF("MC STOP ERROR ");
				result = 1;
			} else
				VL_PRINTF("MC STOP OK ");
			vl_finish("test.cpp",__LINE__,"");
		}

	}

	old_clk1x = top->v__DOT__clk1x;

	/* catch prom looping at error locations */
	if (top->v__DOT__cpu__DOT__state == 32) {
		if (top->v__DOT__reset == 0 &&
		    top->v__DOT__cpu__DOT__promdisable == 0 &&
		    top->v__DOT__cpu__DOT__lpc < 0100 &&
		    main_time > 10000) {
			loop_count++;
		} else
			loop_count = 0;
	}

	if (loop_count > max_loop) {
		VL_PRINTF("MC STOP ERROR PROM; lpc %o, main_time %lld\n",
			  top->v__DOT__cpu__DOT__lpc, main_time);
		vl_finish("test.cpp",__LINE__,"");
		result = 2;
	}

	/* catch looping on disk */
	if (top->v__DOT__cpu__DOT__state == 32) {
		if (top->v__DOT__cpu__DOT__lpc == 0610)
			wait_count = 0;
		if (top->v__DOT__cpu__DOT__lpc == 0614)
			wait_count++;
	}

	if (wait_count > 10000) {
		VL_PRINTF("MC WAIT DISK; lpc %o, main_time %lld\n",
			  top->v__DOT__cpu__DOT__lpc, main_time);
		vl_finish("test.cpp",__LINE__,"");
		result = 2;
	}

#ifdef RC_SYNC_CHECK
	rc_sync_check();
#endif

#ifdef VM_TRACE
	if (tfp) {
		if (show_min_time == 0 && show_max_time == 0)
			tfp->dump(main_time);
		else
			if (show_min_time && main_time > show_min_time)
				tfp->dump(main_time);

		if (show_max_time && main_time > show_max_time)
			vl_finish("test.cpp",__LINE__,"");
	}
#endif

        main_time++;
    }

    top->final();

    if (tfp)
	    tfp->close();

    if (result)
	    exit(result);

    exit(0);
}
