// test.cpp
//
//

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtest.h"

#include <iostream>

Vtest *top;                      // Instantiation of module

unsigned int main_time = 0;     // Current simulation time

double sc_time_stamp () {       // Called by $time in Verilog
    return main_time;
}

int main(int argc, char** argv)
{
    VerilatedVcdC* tfp = NULL;
    Verilated::commandArgs(argc, argv);   // Remember args

    top = new Vtest;             // Create instance

    if (0) {
	    Verilated::traceEverOn(true);
	    VL_PRINTF("Enabling waves...\n");
	    tfp = new VerilatedVcdC;
	    top->trace(tfp, 99);	// Trace 99 levels of hierarchy
	    tfp->open("test.vcd");	// Open the dump file
    }

    while (!Verilated::gotFinish()) {

	// Resets
	if (main_time < 500) {
	    if (main_time == 10) {
		    VL_PRINTF("reset on\n");
		    top->v__DOT__reset = 1;
	    }
	    if (main_time == 240) {
		    VL_PRINTF("boot on\n");
		    top->v__DOT__boot = 1;
	    }
	    if (main_time == 250) {
		    VL_PRINTF("reset off\n");
		    top->v__DOT__reset = 0;
	    }
	    if (main_time == 260) {
		    //VL_PRINTF("boot off\n");
		    top->v__DOT__boot = 0;
	    }
	}

	// Toggle clock
	top->v__DOT__clk = ~top->v__DOT__clk;

	// Evaluate model
        top->eval();

        if (top->v__DOT__clk &&
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

	if (tfp)
		tfp->dump(main_time);

        main_time++;
    }

    top->final();

    if (tfp)
	    tfp->close();
}
