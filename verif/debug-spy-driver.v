
module spy_port_test(sysclk, clk, reset, rs232_rxd, rs232_txd,
		     spy_in, spy_out, dbread, dbwrite, eadr);
   

   input sysclk;
   input clk;
   input reset;

   input rs232_rxd;
   output rs232_txd;
   
   input [15:0] spy_in;

   output [15:0] spy_out;
   reg [15:0] 	 spy_out;

   output 	 dbread;
   reg 		 dbread;
   
   output 	 dbwrite;
   reg 		 dbwrite;
   
   output [3:0]	 eadr;
   reg [3:0] 	 eadr;

   //
   reg [15:0] data;
   reg      start_read;
   reg      start_write;
   reg [3:0]  reg_addr;
   reg [15:0] response;

   assign 	 rs232_txd = 1;

   task do_spy_read;
      input [3:0] r;
      output [15:0] result;
      begin
	 reg_addr = r;
	 @(posedge clk);
	 start_read = 1;
	 @(posedge clk);
	 start_read = 0;
	 @(posedge clk);
	 @(posedge clk);
	 result = response;
	 $display("do_spy_read: r %o -> %x; %t", r, response, $time);
      end
   endtask

   task do_spy_write;
      input [3:0] r;
      input [15:0] value;
      begin
	 reg_addr = r;
	 data = value;
	 @(posedge clk);
	 start_write = 1;
	 @(posedge clk);
	 start_write = 0;
	 $display("do_spy_write: r %o <- %x; %t", r, value, $time);
      end
   endtask
   
   task debug_clock;
      begin
	 do_spy_write(3, 4'o12);
	 @(posedge test.cpu.prefetch_out);
 	 do_spy_write(3, 0);
      end
   endtask
   
   task noop_debug_clock;
      begin
	 do_spy_write(3, 4'o16);
	 @(posedge test.cpu.prefetch_out);
 	 do_spy_write(3, 0);
      end
   endtask
   
   task clock;
      begin
	 do_spy_write(3, 4'o02);
	 @(posedge test.cpu.prefetch_out);
 	 do_spy_write(3, 0);
      end
   endtask
   
   task noop_clock;
      begin
	 do_spy_write(3, 4'o06);
	 @(posedge test.cpu.prefetch_out);
 	 do_spy_write(3, 0);
      end
   endtask
   
   task write_ir;
      input [47:0] ir;
      begin
	 $display("ir <- %o (0x%x)", ir, ir);
	 do_spy_write(2, ir[47:32]);
	 do_spy_write(1, ir[31:16]);
	 do_spy_write(0, ir[15:0]);
      end
   endtask
   
   task execute_w;
      input [47:0] ir;
      begin
	 write_ir(ir);
	 noop_debug_clock;
	 clock;
	 noop_clock;
      end
   endtask
   
   task execute_r;
      input [47:0] ir;
      begin
	 write_ir(ir);
	 noop_debug_clock;
debug_clock;
      end
   endtask
   
   task read_obus;
      output [31:0] result;
      reg [15:0]    r7, r6;
      begin
	 do_spy_read(7, r7);
	 do_spy_read(6, r6);
	 result = { r7, r6 };
      end
   endtask

   task read_vma;
      output [31:0] result;
      begin
	 execute_r(48'h00000000a0001018);
	 read_obus(result);
      end
   endtask

   task read_md;
      output [31:0] result;
      begin
	 execute_r(48'h00000000a8001018);
	 read_obus(result);
      end
   endtask

   task write_shift_md_1;
	 execute_w(48'h00000000a8c010fc);
   endtask

   task write_shift_md_0;
	 execute_w(48'h00000000a8c010f8);
   endtask

   task read_a_mem;
      input [9:0] addr;
      output [31:0] result;
      begin
	 execute_w(48'h0000000000001028 | {addr, 32'b0});
	 read_obus(result);
      end
   endtask // read_a_mem

   task write_a_mem;
      input [9:0] addr;
      input [31:0] val;
      begin
	 write_md(val);
	 $display("a-ins %o", 48'h00000000aa001018 + (addr << 14));
	 execute_w(48'h00000000aa001018 + (addr << 14));
      end
   endtask // read_a_mem

   task write_md;
      input [31:0] val;
      integer 	   i;
      begin
	 execute_w(48'h0000000000c01078);
	 for (i = 31; i >= 0; i = i - 1)
	   begin
	      if (val[i])
		write_shift_md_1;
	      else
		write_shift_md_0;
	   end
      end
   endtask

   task write_vma;
      input [31:0] val;
      begin
	 write_md(val);
	 execute_w(48'h00000000a8801018);
      end
   endtask

   task w;
      begin
	 @(posedge test.cpu.clk);
	 @(posedge test.cpu.clk); 
	 @(posedge test.cpu.clk);
	 @(posedge test.cpu.clk);
      end
   endtask
   
   initial
     begin
     end

   always @(posedge clk)
     if (reset)
       begin
	  spy_out <= 0;
	  dbwrite <= 0;
	  dbread <= 0;
	  eadr <= 0;
	  response <= 0;

	  start_read <= 0;
	  start_write <= 0;
	  data <= 0;
	  reg_addr <= 0;
       end
     else
       begin
	  spy_out <= start_write ? data : 16'h0000;
	  dbwrite <= start_write;
	  dbread <= start_read;
	  eadr <= (start_read || start_write) ? reg_addr : 0;
       end

   always @(posedge clk)
     if (reset)
       response <= 0;
     else
       if (dbread)
	 begin
	    response <= spy_in;
	    $display("response %x; %t", response, $time);
	 end

   always @(posedge clk)
     begin
	if (dbread)
	  $display("SPY: read %o", eadr);
	if (dbwrite)
	  $display("SPY: write %o <- %o", eadr, data);
     end

   reg [15:0] result16;
   reg [31:0] result;

   integer    i;
   
   initial
     begin
	while (test.cpu.lpc !== 13'o364)
	  begin
	     @(posedge test.cpu.clk);
	  end
	
	do_spy_write(0, 0);

	if (0)
	  begin

	     for (i = 0; i < 16; i = i + 1)
	       begin
		  do_spy_read(i, result16);
		  $display("spy-reg %2o -> %o", i, result16);
	       end
	  end

	if (0)
	  begin
	     write_vma(32'h87654321);
	     read_vma(result);
	     $display("vma = %o (0x%x)", result, result);

	     write_md(32'h12345678);
	     read_md(result);
	     $display("md = %o (0x%x)", result, result);
	  end

	if (0)
	  begin
	     write_a_mem(1, 32'h11223344);
	     write_a_mem(2, 32'h55667788);
	     
	     read_a_mem(0, result);
	     $display("A[0] = %o (%x)", result, result);
	     read_a_mem(1, result);
	     $display("A[1] = %o (%x)", result, result);
	     read_a_mem(2, result);
	     $display("A[2] = %o (%x)", result, result);
	  end

	if (1)
	  begin
	     $display("---------------- vm read --------------------");
	     
	     execute_r(48'o04000100042310050); w;
	     read_md(result); $display("md = %o", result);
	     execute_r(48'o00002003042310310); w;
	     read_md(result); $display("md = %o", result);
	     execute_r(48'o00002003000310310); w;
	     read_md(result); $display("md = %o", result);
	     execute_r(48'o00000003042010030); w;
	     read_md(result); $display("md = %o", result);
	   
	     read_md(result);
	     $display("sdram[0]=%o", result);
	     read_md(result);
	     $display("sdram[0]=%o", result);

	end

	#2000;
	$finish;
	
     end
   
endmodule
