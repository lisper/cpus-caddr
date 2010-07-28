/*
 * $Id$
 */

module xbus_ram (
		 clk, reset,
		 addr, datain, dataout,
		 req, write, ack, decode,

		 sdram_addr, sdram_data_in, sdram_data_out,
		 sdram_req, sdram_ready, sdram_write, sdram_done
		);

   input reset;
   input clk;
   input [21:0] addr;
   input [31:0] datain;
   input 	req;
   input 	write;
   
   output [31:0] dataout;
   output 	 ack;
   output 	 decode;

   output [21:0]  sdram_addr;
   output [31:0] sdram_data_out;
   input [31:0]  sdram_data_in;
   output 	 sdram_req;
   input 	 sdram_ready;
   output 	 sdram_write;
   input 	 sdram_done;

   //
   reg [1:0] 	 ram_state;
   wire [1:0] 	 ram_state_next;

   parameter 	 RAM_IDLE = 0,
		   RAM_WRITE = 1,
		   RAM_READ = 2;

   wire 	 start_ram_write;
   wire 	 start_ram_read;

   wire 	 write_ram_done;
   wire 	 read_ram_done;
		   
   // need some dram address space at the end 
   // which is decoded but does not read/write...
   assign 	 decode = addr < 22'o11000000 ? 1'b1: 1'b0;
//   assign 	 decode = addr < 22'o01000000 ? 1'b1: 1'b0;

`ifdef never
   assign start_ram_write = req & decode & write && ram_state == RAM_IDLE;
   assign start_ram_read = req & decode & ~write && ram_state == RAM_IDLE;
   
   always @(posedge clk)
     begin
`ifdef debug
	if (start_ram_write)
	  $display("ddr: write @%o start <- %o", addr, datain);
	if (write_ram_done)
	  $display("ddr: write @%o done <- %o", addr, datain);
	if (start_ram_read)
	  $display("ddr: read @%o; %t", addr, $time);
`endif

	if (read_ram_done)
	  begin
	     dataout <= sdram_data_in;
`ifdef debug
	     $display("ddr: read @%o done -> %o (0x%x); %t",
		      addr, sdram_data_in, sdram_data_in, $time);
`endif
	  end
     end
   

   assign sdram_addr = addr;
   assign sdram_data_out = datain;
   assign sdram_write = start_ram_write;
   assign sdram_req = start_ram_read;

   /* simple state machine to wait for memory controller */
   always @(posedge clk)
     if (reset)
       ram_state <= RAM_IDLE;
     else
       begin
	  ram_state <= ram_state_next;

	  if (ram_state_next != ram_state)
	    begin
	       case (ram_state_next)
		 RAM_IDLE:  $display("xbus-ram: RAM_IDLE");
		 RAM_WRITE: $display("xbus-ram: RAM_WRITE");
		 RAM_READ:  $display("xbus-ram: RAM_READ");
	       endcase
	    end
       end

   assign write_ram_done = ram_state == RAM_WRITE && sdram_done;
   assign read_ram_done = ram_state == RAM_READ && sdram_ready;
   
   assign ram_state_next =
		 (ram_state == RAM_IDLE && start_ram_write) ? RAM_WRITE :
		 (ram_state == RAM_IDLE && start_ram_read) ? RAM_READ :
		 write_ram_done ? RAM_IDLE :
		 read_ram_done ? RAM_IDLE :
		 ram_state;

   assign ack = write_ram_done || read_ram_done;
`endif
   
   assign sdram_write = req & decode & write;
   assign sdram_req = req & decode & ~write;
   
   assign ack = sdram_done || sdram_ready;

   assign sdram_addr = addr;
   assign sdram_data_out = datain;
   assign dataout = sdram_data_in;

endmodule

