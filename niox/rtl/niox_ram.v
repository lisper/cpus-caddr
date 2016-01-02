//

//`define BEHAVIORAL
//`define BEHAVIORAL1
`define BEHAVIORAL2
//`define ISE_BLOCK

module niox_ram(
		input 	      clk_i,
		input 	      rst_i,
		input [31:0]  data_i,
		output [31:0] data_o,
		input [31:0]  addr_i,
		input [3:0]   be_i,
		input 	      we_i,
		input 	      sel_i,
		output 	      ack_o
		);

`ifdef BEHAVIORAL
   reg ack;
   reg [31:0] data;
   
   reg [7:0] mem0[0:4095];
   reg [7:0] mem1[0:4095];
   reg [7:0] mem2[0:4095];
   reg [7:0] mem3[0:4095];

   wire [11:0]   addr;
   
   assign addr = addr_i[13:2];

   always @(posedge clk_i)
     if (rst_i)
	  ack <= 1'b0;
     else
       begin
       	  if (we_i || sel_i)
	    begin
	       if (ack)
		   ack <= 1'b0;
		 else
		   ack <= 1'b1;
`ifdef debug
	       if (ack && we_i)
		 $display("ram: addr %x (%x) be %b <= data %x",
			  addr_i, addr, be_i, data_i);

	       if (ack && sel_i)
		 $display("ram: addr %x (%x) => data %x",
			  addr_i, addr, {mem3[addr], mem2[addr], mem1[addr], mem0[addr]});
`endif
	       
	    end
	  else
	    ack <= 1'b0;
       end

   always @(posedge clk_i)
     if (rst_i)
       begin
	  data <= 32'b0;
       end
     else
       begin
	  if (we_i & be_i[3])
	    mem3[addr] <= data_i[31:24];
	  if (we_i & be_i[2])
	    mem2[addr] <= data_i[23:16];
	  if (we_i & be_i[1])
	    mem1[addr] <= data_i[15: 8];
	  if (we_i & be_i[0])
	    mem0[addr] <= data_i[ 7: 0];

	  if (sel_i)
	    data[31:24] <= mem3[addr];
	  if (sel_i)
	    data[23:16] <= mem2[addr];
	  if (sel_i)
	    data[15: 8] <= mem1[addr];
	  if (sel_i)
	    data[ 7: 0] <= mem0[addr];
       end

   assign ack_o = ack;
   assign data_o = data;
   
   initial
     begin
	$display("READING data ram...");

	$readmemh("niox_dram3.hex", mem3);
	$readmemh("niox_dram2.hex", mem2);
	$readmemh("niox_dram1.hex", mem1);
	$readmemh("niox_dram0.hex", mem0);

	$display("READING data ram done");
     end
`endif //  `ifdef BEHAVIORAL

`ifdef BEHAVIORAL1
   reg ack;
   reg [31:0] data;
   
   (* ram_style="block" *) reg [7:0] mem0[0:4095];
   (* ram_style="block" *) reg [7:0] mem1[0:4095];
   (* ram_style="block" *) reg [7:0] mem2[0:4095];
   (* ram_style="block" *) reg [7:0] mem3[0:4095];

   wire [11:0]   addr;
   wire 	 ena;
   
   assign addr = addr_i[13:2];

   always @(posedge clk_i)
     if (rst_i)
	  ack <= 1'b0;
     else
       begin
       	  if (we_i || sel_i)
	    begin
	       if (ack)
		   ack <= 1'b0;
		 else
		   ack <= 1'b1;
`ifdef debug
	       if (ack && we_i)
		 $display("ram: addr %x (%x) be %b <= data %x",
			  addr_i, addr, be_i, data_i);

	       if (ack && sel_i)
		 $display("ram: addr %x (%x) => data %x",
			  addr_i, addr, {mem3[addr], mem2[addr], mem1[addr], mem0[addr]});
`endif
	       
	    end
	  else
	    ack <= 1'b0;
       end

   assign ena = we_i || sel_i;
   wire [3:0] be_w;

   assign be_w = be_i & { we_i, we_i, we_i, we_i };
   
   always @(posedge clk_i)
     if (rst_i)
       begin
	  data <= 32'b0;
       end
     else
       begin
	  if (ena)
	    begin
	       if (be_w[3])
		 mem3[addr] <= data_i[31:24];
	       if (be_w[2])
		 mem2[addr] <= data_i[23:16];
	       if (be_w[1])
		 mem1[addr] <= data_i[15: 8];
	       if (be_w[0])
		 mem0[addr] <= data_i[ 7: 0];

	       data[31:24] <= mem3[addr];
	       data[23:16] <= mem2[addr];
	       data[15: 8] <= mem1[addr];
	       data[ 7: 0] <= mem0[addr];
	    end
       end

   assign ack_o = ack;
   assign data_o = data;
	      
   initial
     begin
	$display("READING data ram...");

	$readmemh("niox_dram3.hex", mem3);
	$readmemh("niox_dram2.hex", mem2);
	$readmemh("niox_dram1.hex", mem1);
	$readmemh("niox_dram0.hex", mem0);

	$display("READING data ram done");
     end
`endif //  `ifdef BEHAVIORAL

`ifdef BEHAVIORAL2
   reg ack;
   wire [7:0] data0, data1, data2, data3;
   reg [7:0] out0, out1, out2, out3;
   reg [7:0] hold0, hold1, hold2, hold3;

   (* ram_style = "block" *) reg [7:0] mem0[0:4095];
   (* ram_style = "block" *) reg [7:0] mem1[0:4095];
   (* ram_style = "block" *) reg [7:0] mem2[0:4095];
   (* ram_style = "block" *) reg [7:0] mem3[0:4095];

   wire [11:0]   addr;

   assign addr = addr_i[13:2];

   always @(posedge clk_i)
     if (rst_i)
	  ack <= 1'b0;
     else
       begin
       	  if (we_i || sel_i)
	    begin
	       if (ack)
		   ack <= 1'b0;
		 else
		   ack <= 1'b1;
`ifdef debug
	       if (ack && we_i)
		 $display("ram: addr %x (%x) be %b <= data %x",
			  addr_i, addr, be_i, data_i);

	       if (ack && sel_i)
		 $display("ram: addr %x (%x) => data %x",
			  addr_i, addr, {mem3[addr], mem2[addr], mem1[addr], mem0[addr]});
`endif
	       
	    end
	  else
	    ack <= 1'b0;
       end

   // mem3
   always @(posedge clk_i)
     if (rst_i)
       out3 <= 8'b0;
     else
       out3 <= mem3[addr];

   always @(posedge clk_i)
     if (we_i & be_i[3])
       mem3[addr] <= data_i[31:24];

   // mem2
   always @(posedge clk_i)
     if (rst_i)
       out2 <= 8'b0;
     else
       out2 <= mem2[addr];

   always @(posedge clk_i)
     if (we_i & be_i[2])
       mem2[addr] <= data_i[23:16];

   // mem1
   always @(posedge clk_i)
     if (rst_i)
       out1 <= 8'b0;
     else
       out1 <= mem1[addr];

   always @(posedge clk_i)
     if (we_i & be_i[1])
       mem1[addr] <= data_i[15: 8];

   // mem0
   always @(posedge clk_i)
     if (rst_i)
       out0 <= 8'b0;
     else
       out0 <= mem0[addr];

   always @(posedge clk_i)
     if (we_i & be_i[0])
       mem0[addr] <= data_i[ 7: 0];

   //
   assign data3 = sel_i ? out3 : hold3;
   assign data2 = sel_i ? out2 : hold2;
   assign data1 = sel_i ? out1 : hold1;
   assign data0 = sel_i ? out0 : hold0;

   reg sel_i_d;
   always @(posedge clk_i)
     if (rst_i)
       sel_i_d <= 0;
     else
       sel_i_d <= sel_i;
   
   always @(posedge clk_i)
     if (rst_i)
       hold3 <= 8'b0;
     else
       hold3 <= sel_i_d ? out3 : hold3;

   always @(posedge clk_i)
     if (rst_i)
       hold2 <= 8'b0;
     else
       hold2 <= sel_i_d ? out2 : hold2;

   always @(posedge clk_i)
     if (rst_i)
       hold1 <= 8'b0;
     else
       hold1 <= sel_i_d ? out1 : hold1;

   always @(posedge clk_i)
     if (rst_i)
       hold0 <= 8'b0;
     else
       hold0 <= sel_i_d ? out0 : hold0;
   
   //
   assign ack_o = ack;
   assign data_o = { data3, data2, data1, data0 };

   initial
     begin
	$display("READING data ram...");

	$readmemh("niox_dram3.hex", mem3);
	$readmemh("niox_dram2.hex", mem2);
	$readmemh("niox_dram1.hex", mem1);
	$readmemh("niox_dram0.hex", mem0);

	$display("READING data ram done");
     end
`endif // unmatched `else, `elsif or `endif
   

`ifdef ISE_BLOCK
   reg ack;
   wire [11:0]   addr;

   assign addr = addr_i[13:2];

   always @(posedge clk_i)
     if (rst_i)
	  ack <= 1'b0;
     else
       begin
       	  if (we_i || sel_i)
	    begin
	       if (ack)
		   ack <= 1'b0;
		 else
		   ack <= 1'b1;
`ifdef debug
	       if (ack && we_i)
		 $display("ram: addr %x (%x) be %b <= data %x",
			  addr_i, addr, be_i, data_i);

	       if (ack && sel_i)
		 $display("ram: addr %x (%x) => data %x",
			  addr_i, addr, {mem3[addr], mem2[addr], mem1[addr], mem0[addr]});
`endif
	       
	    end
	  else
	    ack <= 1'b0;
       end

   assign ack_o = ack;


   //
   wire ena0, ena1, ena2, ena3;
   wire wea0, wea1, wea2, wea3;

   assign ena0 = we_i || sel_i;
   assign ena1 = we_i || sel_i;
   assign ena2 = we_i || sel_i;
   assign ena3 = we_i || sel_i;

   assign wea0 = we_i & be_i[0];
   assign wea1 = we_i & be_i[1];
   assign wea2 = we_i & be_i[2];
   assign wea3 = we_i & be_i[3];
   
   niox_ram_byte_ise mem0(
			  .clka(clk_i),
			  .ena(ena0),
			  .wea(wea0),
			  .addra(addr),
			  .dina(data_i[7:0]),
			  .douta(data_o[7:0])
			 );

   niox_ram_byte_ise mem1(
			  .clka(clk_i),
			  .ena(ena1),
			  .wea(wea1),
			  .addra(addr),
			  .dina(data_i[15:8]),
			  .douta(data_o[15:8])
			 );

   niox_ram_byte_ise mem2(
			  .clka(clk_i),
			  .ena(ena2),
			  .wea(wea2),
			  .addra(addr),
			  .dina(data_i[23:16]),
			  .douta(data_o[23:16])
			 );

   niox_ram_byte_ise mem3(
			  .clka(clk_i),
			  .ena(ena3),
			  .wea(wea3),
			  .addra(addr),
			  .dina(data_i[31:24]),
			  .douta(data_o[31:24])
			 );

   initial
     begin
	$display("READING data ram...");

//	$readmemh("niox_dram3.hex", mem3);
//	$readmemh("niox_dram2.hex", mem2);
//	$readmemh("niox_dram1.hex", mem1);
//	$readmemh("niox_dram0.hex", mem0);

	$display("READING data ram done");
     end
`endif

endmodule // niox_ram

