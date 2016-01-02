//
//
//
module niox_cpu ( clk, ext_int, ext_reset, ext_boot, ext_halt,

	       spy_in, spy_out, dbread, dbwrite, eadr, spy_reg, spy_rd, spy_wr,

	       pc_out, state_out, machrun_out,
	       prefetch_out, fetch_out,
	       disk_state_out, bus_state_out,
	       
	       mcr_addr, mcr_data_out, mcr_data_in,
	       mcr_ready, mcr_write, mcr_done,

	       sdram_addr, sdram_data_in, sdram_data_out,
	       sdram_req, sdram_ready, sdram_write, sdram_done,

	       vram_addr, vram_data_in, vram_data_out,
	       vram_req, vram_ready, vram_write, vram_done,

	       bd_cmd, bd_start, bd_bsy, bd_rdy, bd_err, bd_addr,
	       bd_data_in, bd_data_out, bd_rd, bd_wr, bd_iordy, bd_state_in,

	       kb_data, kb_ready,
	       ms_x, ms_y, ms_button, ms_ready );

   input clk;
   input ext_int;
   input ext_reset;
   input ext_boot;
   input ext_halt;

   input [15:0] spy_in;
   output [15:0] spy_out;
   input 	dbread;
   input 	dbwrite;
   input [3:0] 	eadr;
   output [3:0] spy_reg;
   output 	spy_rd;
   output 	spy_wr;
   
   output [13:0] pc_out;
   output [5:0]  state_out;
   output [4:0]  disk_state_out;
   output [3:0]  bus_state_out;
   output 	 machrun_out;
   output 	 prefetch_out;
   output 	 fetch_out;

   output [13:0] mcr_addr;
   output [48:0] mcr_data_out;
   input [48:0]  mcr_data_in;
   input 	 mcr_ready;
   output 	 mcr_write;
   input 	 mcr_done;

   output [21:0]  sdram_addr;
   output [31:0] sdram_data_out;
   input [31:0]  sdram_data_in;
   output 	 sdram_req;
   input 	 sdram_ready;
   output 	 sdram_write;
   input 	 sdram_done;

   output [14:0] vram_addr;
   output [31:0] vram_data_out;
   input [31:0]  vram_data_in;
   output 	 vram_req;
   input 	 vram_ready;
   output 	 vram_write;
   input 	 vram_done;
   
   output [1:0]  bd_cmd;	/* generic block device interface */
   output 	 bd_start;
   input 	 bd_bsy;
   input 	 bd_rdy;
   input 	 bd_err;
   output [23:0] bd_addr;
   input [15:0]  bd_data_in;
   output [15:0] bd_data_out;
   output 	 bd_rd;
   output 	 bd_wr;
   input 	 bd_iordy;
   input [11:0]  bd_state_in;

   input [15:0]  kb_data;
   input 	 kb_ready;
   
   input [11:0]  ms_x, ms_y;
   input [2:0] 	 ms_button;
   input 	 ms_ready;

   // ------------------------------------------------------------

//   wire [31:0] 	 ilmb_datai;
   reg [31:0] 	 ilmb_datai;
   wire [31:0] 	 ilmb_addr;
   wire 	 ilmb_sel;
   wire 	 ilmb_ack;
   
   wire [31:0] 	 dlmb_datai;
   wire [31:0] 	 dlmb_datao;
   wire [31:0] 	 dlmb_addr;
   wire [3:0] 	 dlmb_be;
   wire 	 dlmb_we;
   wire 	 dlmb_sel;
   wire 	 dlmb_ack;
   wire [31:0] 	 irq;

   wire 	bus_int;
   assign irq = { 31'b0, bus_int };
   assign reset = ext_reset;

   //
   wire [31:0] 	 rom_datao;
   wire [31:0] 	 rom_addr;
   wire 	 rom_sel;
   wire 	 rom_ack;
   
   wire [31:0] 	 ram_datai;
   wire [31:0] 	 ram_datao;
   wire [31:0] 	 ram_addr;
   wire [3:0] 	 ram_be;
   wire 	 ram_we;
   wire 	 ram_sel;
   wire 	 ram_ack;

   wire [31:0] 	 bus_addr;
   wire [31:0] 	 bus_datai;
   wire [31:0] 	 bus_datao;
   wire 	 bus_ack;

   wire 	 bus_req;
   wire 	 bus_wr;
   wire 	 bus_load;
   reg [31:0] 	 bus_data;
   
   wire 	 rom_decode;
   wire 	 ram_decode;
   wire 	 bus_decode;
   wire 	 sdr_decode;

   wire 	 rom_access;
   wire 	 ram_access;
   wire 	 bus_access;
   wire 	 sdr_access;

   wire 	 fetch;

   /*
    * address map:
    * 0000_0000 - 0000_0000	rom	instruction space
    * 0001_0000 - 000f_ffff	ram 	data space
    * 0010_0000 - 003b_ffff	sdram	data space
    * 003c_0000 - 00ff_ffff	io	data space
    * 
    */
   assign rom_decode = ~fetch && (dlmb_addr <  32'h0001_0000) && (dlmb_addr[1:0] == 2'b00);
   assign ram_decode = ~fetch && (dlmb_addr >= 32'h0001_0000) && (dlmb_addr < 32'h0010_0000);
   assign sdr_decode = ~fetch && (dlmb_addr >= 32'h0010_0000) && (dlmb_addr < 32'h003b_ffff);
   assign bus_decode = ~fetch && (dlmb_addr >= 32'h00f0_0000) && (dlmb_addr < 32'h00ff_ffff);

   assign rom_access = rom_decode;
   assign ram_access = ram_decode;
   assign bus_access = bus_decode && (dlmb_sel || dlmb_we);
   assign sdr_access = sdr_decode && (dlmb_sel || dlmb_we);


   // data bus can access rom
   assign rom_addr = rom_access ? dlmb_addr : ilmb_addr;
   assign rom_sel = rom_access ? dlmb_sel : ilmb_sel;
//   assign ilmb_datai = rom_datao;
   assign ilmb_ack = rom_ack;

   // we should really register this inside niox.v
   always @(posedge clk)
     if (reset)
       ilmb_datai <= 0;
     else
       ilmb_datai <= rom_datao;

   always @(posedge clk)
     if (reset)
       bus_data <= 0;
     else
       bus_data <= bus_datao;
   
   assign ram_datai = dlmb_datao;
   assign ram_addr = dlmb_addr;
   assign ram_be = dlmb_be;
   assign ram_we = ram_access ? dlmb_we : 1'b0;
   assign ram_sel = ram_access ? dlmb_sel : 1'b0;

   assign dlmb_datai = ram_access ? ram_datao :
		       rom_access ? rom_datao :
		       bus_datao;
   
   assign dlmb_ack = ram_access ? ram_ack :
		     rom_access ? rom_ack :
		     bus_access ? bus_ack :
		     sdr_access ? bus_ack :
		     1'b1;

   assign bus_datai = dlmb_datao;
   assign bus_req = (bus_access | sdr_access);
   assign bus_addr = dlmb_addr;
   assign bus_wr = dlmb_we;

   
`ifdef debug
   always @(posedge clk)
     begin
	if ((bus_access | sdr_access) && ram_we)
	  $display("bus: addr %x <= data %x be %x", dlmb_addr, dlmb_datao, dlmb_be);
	if ((bus_access | sdr_access) && ram_sel)
	  $display("bus: addr %x => data %x", dlmb_addr, bus_datao);
     end
`endif

   // keyboard
   reg [15:0] key_scan;
   
   always @(posedge clk)
     if (reset)
       key_scan <= 0;
     else
       if (kb_ready)
	 key_scan <= kb_data;

   //
   niox_rom rom(
		.clk_i(clk),
		.rst_i(reset),  
		.data_o(rom_datao),
		.addr_i(rom_addr),
		.sel_i(rom_sel),
		.ack_o(rom_ack) 
		);
 
   niox_ram ram(
		.clk_i(clk),
		.rst_i(reset),  
		.data_i(ram_datai),
		.data_o(ram_datao),
		.addr_i(ram_addr),
		.be_i(ram_be),
		.we_i(ram_we),
		.sel_i(ram_sel),
		.ack_o(ram_ack) 
		);
 
   niox cpu( 
	     .clk(clk),
	     .clke(ilmb_ack),
	     .rst(reset),
	     .ifetch(fetch),

	     .ilmb_datai(ilmb_datai),
	     .ilmb_addr(ilmb_addr),
	     .ilmb_sel(ilmb_sel),

	     .dlmb_datai(dlmb_datai),
	     .dlmb_datao(dlmb_datao),
	     .dlmb_addr(dlmb_addr),
	     .dlmb_be(dlmb_be),
	     .dlmb_we(dlmb_we),
	     .dlmb_sel(dlmb_sel),
	     .dlmb_ack(dlmb_ack),

	     .irq(irq)
	     ); 

   // ------------------------------------------------------------

`define use_bus
`ifdef use_bus
   // *************
   // Bus Interface
   // *************

//   wire [15:0] spy_in;
//   wire [15:0] spy_out;

   wire        set_promdisable;

   wire [21:0] busint_addr;

   assign busint_addr = bus_access ? bus_addr[23:2] :
			sdr_access ? {4'b0, bus_addr[19:2]} :
			22'b0;

`ifdef debug
   always @(posedge clk)
     begin
	if (sdr_access)
	  $display("niox_cpu: sdr_access addr %x -> %x", bus_addr, busint_addr);
	if (bus_access)
	  $display("niox_cpu: bus_access addr %x -> %x", bus_addr, busint_addr);
     end
`endif

   busint bus(
	      .mclk(clk),
	      .reset(reset),
	      .addr(busint_addr),
	      .busin(bus_datai),
	      .busout(bus_datao),
	      .spyin(spy_in),
	      .spyout(spy_out),
	      .spyreg(spy_reg),
	      .spyrd(spy_rd),
	      .spywr(spy_wr),

	      .req(bus_req),
	      .ack(bus_ack),
	      .write(bus_wr),
	      .load(bus_load),
		 
	      .interrupt(bus_int),

	      .sdram_addr(sdram_addr),
	      .sdram_data_in(sdram_data_in),
	      .sdram_data_out(sdram_data_out),
	      .sdram_req(sdram_req),
	      .sdram_ready(sdram_ready),
	      .sdram_write(sdram_write),
	      .sdram_done(sdram_done),
      
	      .vram_addr(vram_addr),
	      .vram_data_in(vram_data_in),
	      .vram_data_out(vram_data_out),
	      .vram_req(vram_req),
	      .vram_ready(vram_ready),
	      .vram_write(vram_write),
	      .vram_done(vram_done),
      
	      .bd_cmd(bd_cmd),
	      .bd_start(bd_start),
	      .bd_bsy(bd_bsy),
	      .bd_rdy(bd_rdy),
	      .bd_err(bd_err),
	      .bd_addr(bd_addr),
	      .bd_data_in(bd_data_in),
	      .bd_data_out(bd_data_out),
	      .bd_rd(bd_rd),
	      .bd_wr(bd_wr),
	      .bd_iordy(bd_iordy),
	      .bd_state_in(bd_state_in),

	      .kb_data(kb_data),
	      .kb_ready(kb_ready),
	      .ms_x(ms_x),
	      .ms_y(ms_y),
	      .ms_button(ms_button),
	      .ms_ready(ms_ready),

	      .promdisable(set_promdisable),
	      .disk_state(disk_state_out),
	      .bus_state(bus_state_out)
	      );
`else
   assign bus_datao = 0;
   assign bus_ack = 1;
`endif
   
endmodule
