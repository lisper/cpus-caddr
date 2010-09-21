// test.cpp
//
//

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtest.h"

#include <iostream>

Vtest *top;                      // Instantiation of module

static unsigned long long main_time = 0;     // Current simulation time

double sc_time_stamp () {       // Called by $time in Verilog
    return main_time;
}

int main(int argc, char** argv)
{
    VerilatedVcdC* tfp = NULL;
    Verilated::commandArgs(argc, argv);   // Remember args

    top = new Vtest;             // Create instance

    printf("built on: %s %s\n", __DATE__, __TIME__);

#ifdef TRACE
    if (0) {
	    Verilated::traceEverOn(true);
	    VL_PRINTF("Enabling waves...\n");
	    tfp = new VerilatedVcdC;
	    top->trace(tfp, 99);	// Trace 99 levels of hierarchy
	    tfp->open("test.vcd");	// Open the dump file
    }
#endif

    while (!Verilated::gotFinish()) {

	// Toggle clock(s)
#if 1
#define MULT 10
//	top->v__DOT__ext_osc = top->v__DOT__ext_osc ? 0 : 1;

	top->v__DOT__clk100 = top->v__DOT__clk100 ? 0 : 1;
	if (top->v__DOT__clk100) {
		top->v__DOT__clk50 = top->v__DOT__clk50 ? 0 : 1;
		if (top->v__DOT__clk50)
			top->v__DOT__clk1x = top->v__DOT__clk1x ? 0 : 1;
	}
#else
#define MULT 1
	top->v__DOT__clk1x = top->v__DOT__clk1x ? 0 : 1;
#endif

	// Resets
	if (main_time < 500*MULT) {
	    if (main_time == 10*MULT) {
		    VL_PRINTF("reset on\n");
		    top->v__DOT__reset = 1;
	    }
	    if (main_time == 240*MULT) {
		    VL_PRINTF("boot on\n");
		    top->v__DOT__boot = 1;
	    }
	    if (main_time == 250*MULT) {
		    VL_PRINTF("reset off\n");
		    top->v__DOT__reset = 0;
	    }
	    if (main_time == 260*MULT) {
		    //VL_PRINTF("boot off\n");
		    top->v__DOT__boot = 0;
	    }
	}

	// Evaluate model
        top->eval();

#if 0
        if (top->v__DOT__sysclk &&
	    top->v__DOT__cpu__DOT__state == 4)
	{
		if (top->v__DOT__cpu__DOT__lpc < 0100)
		VL_PRINTF("%o %017llo A=%08x M=%08x N%d R=%08x LC=%08x\n",
			  top->v__DOT__cpu__DOT__lpc,
			  (QData)top->v__DOT__cpu__DOT__ir,
			  top->v__DOT__cpu__DOT__a,
			  top->v__DOT__cpu__DOT__m,
			  top->v__DOT__cpu__DOT__n,
			  top->v__DOT__cpu__DOT__r,
			  top->v__DOT__cpu__DOT__lc);

		if (0)
		VL_PRINTF("vma: vma %o ob %o alu %llo\n",
			  top->v__DOT__cpu__DOT__vma,
			  top->v__DOT__cpu__DOT__ob,
			  top->v__DOT__cpu__DOT__alu);
	}
#endif

#if 0
        if (top->v__DOT__sysclk &&
	    top->v__DOT__rc__DOT__state != 2)
	{
		if (top->v__DOT__cpu__DOT__state == 4 && /* state_write */
		    top->v__DOT__rc__DOT__state != 1) /* S1 */
		{
			VL_PRINTF("out of sync: cpu %d rc %d; %d\n",
				  top->v__DOT__cpu__DOT__state,
				  top->v__DOT__rc__DOT__state,
				  main_time);
			vl_finish("test.cpp",__LINE__,"");
		}
	}
#endif

#ifdef TRACE
//#define MIN_TIME 0
//#define MAX_TIME 100000
//#define MIN_TIME 12000000
//#define MAX_TIME 14661688

#define MIN_TIME 15300000
#define MAX_TIME 15350000


	if (tfp) {
		if (main_time > MIN_TIME)
			tfp->dump(main_time);

		if (main_time > MAX_TIME)
			vl_finish("test.cpp",__LINE__,"");
	}
#endif

        main_time++;
    }

    top->final();

    if (tfp)
	    tfp->close();
}
