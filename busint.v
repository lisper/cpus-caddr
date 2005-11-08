/*
 * $Id$
 */

module busint(bus, addr, spy, mclk, mempar_in, adrpar_n, req, ack_n,
		loadmd, ignpar, memgrant_n, wrcyc, int, mempar_out,
		reset_n);

	inout [31:0] bus;
//	inout [21:0] addr;
	input [21:0] addr;
	inout [15:0] spy;
	input mclk, adrpar_n, req, wrcyc;
	input mempar_out, reset_n;
	output ack_n, mempar_in, loadmd, ignpar, memgrant_n, int;

  reg req_delayed;
  reg [2:0] ack_delayed_n;
  reg [31:0] data;
  reg [31:0] disk_ma, disk_da, disk_ecc;

  initial
    begin
      req_delayed <= 0;
      ack_delayed_n[0] <= 0;
      ack_delayed_n[1] <= 0;
      ack_delayed_n[2] <= 0;

      data <= 0;
      disk_ma <= 0;
      disk_da <= 0;
      disk_ecc <= 0;
    end

  always @(reset_n)
    if (reset_n == 0)
      begin
        req_delayed = 0;
        ack_delayed_n[0] = 1;
        ack_delayed_n[1] = 1;
        ack_delayed_n[2] = 1;

        data = 0;
        disk_ma = 0;
        disk_da = 0;
        disk_ecc = 0;
      end

//  assign ack_n = ack_delayed_n[1];
//  assign ack_n = ack_delayed_n[0];
  assign ack_n = ~req_delayed;
  assign memgrant_n = ~req;
  assign loadmd = ~ack_n;

  assign bus = data;

  always @(posedge mclk)
    begin
//      req_delayed <= req;
      if (ack_delayed_n[2] == 1)
        req_delayed <= req;
      else
        req_delayed <= 0;
      ack_delayed_n[0] <= ~req_delayed;
      ack_delayed_n[1] <= ack_delayed_n[0];
      ack_delayed_n[2] <= ack_delayed_n[1];
    end

  always @(posedge req)
    begin
    if (wrcyc)
      begin
        #1 $display("xbus: write @%o", addr);
      end
    else
      begin
        #1 $display("xbus: read @%o", addr);
      end

    // disk controller registers
    if (!wrcyc)
      case (addr)
        22'o00000000: begin data <= 32'o0101; $display("dram: read 0"); end
        22'o00000001: begin data <= 32'o0011; $display("dram: read 1"); end
        22'o00000002: begin data <= 32'o0022; $display("dram: read 2"); end
        22'o00000003: begin data <= 32'o0033; $display("dram: read 3"); end

        22'o17377774: begin data <= 1; $display("disk: read status"); end
        22'o17377775: data <= disk_ma;
        22'o17377776: data <= disk_da;
        22'o17377777: data <= disk_ecc;
      endcase
    else
      case (addr)
        22'o17377775: disk_ma <= bus;
        22'o17377776: disk_da <= bus;
        22'o17377777: disk_ecc <= bus;
      endcase
    end

endmodule

/*
busy_n 		- asserted by bus device, on sync edge
extrq_n		- async, device wants bus
extgrant_in_n	- clocked on sync, shows device got bus
init_n		- reset all devices
sync_n		- clock for grants, falling edge
*/

