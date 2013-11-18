//

module ide_disk(ide_data_in, ide_data_out,
		ide_dior, ide_diow, ide_cs, ide_da);

   input [15:0]  ide_data_in;
   output [15:0] ide_data_out;
   reg [15:0] 	 ide_data_out;
   input 	 ide_dior;
   input 	 ide_diow;
   input [1:0] 	 ide_cs;
   input [2:0] 	 ide_da;

   wire [4:0] 	 addr;

   reg [15:0] 	 fifo[0:1023];
   reg [15:0] 	 status;
   reg [15:0] 	 reg_seccnt;
   reg [15:0] 	 reg_secnum;
   reg [15:0] 	 reg_cyllow;
   reg [15:0] 	 reg_cylhigh;
   reg [15:0] 	 reg_drvhead;
   
   parameter [4:0]
	       ATA_ALTER    = 5'h0e,
	       ATA_DEVCTRL  = 5'h0e,
	       ATA_DATA     = 5'h10,
	       ATA_ERROR    = 5'h11,
	       ATA_FEATURE  = 5'h11,
	       ATA_SECCNT   = 5'h12,
	       ATA_SECNUM   = 5'h13,
	       ATA_CYLLOW   = 5'h14,
	       ATA_CYLHIGH  = 5'h15,
	       ATA_DRVHEAD  = 5'h16,
	       ATA_STATUS   = 5'h17,
	       ATA_COMMAND  = 5'h17;

   parameter IDE_STATUS_BSY = 8'h80,
	       IDE_STATUS_DRDY = 8'h40,
	       IDE_STATUS_DWF = 8'h20,
	       IDE_STATUS_DSC = 8'h10,
	       IDE_STATUS_DRQ = 8'h08,
	       IDE_STATUS_CORR = 8'h04,
	       IDE_STATUS_IDX = 8'h02,
	       IDE_STATUS_ERR = 8'h01;
   
   
   integer fifo_depth, fifo_rd, fifo_wr;
   integer lba;
   integer i;
   integer bsy_count;
   
   assign addr = { ide_cs, ide_da };

   initial
     begin
	status = IDE_STATUS_DRDY | IDE_STATUS_DSC;
	fifo_depth = 0;
	fifo_rd = 0;
	fifo_wr = 0;

	for (i = 0; i < 512; i = i + 1)
	  fifo[i] = 0;
     end

   task do_ide_read;
      begin
	 lba = { 4'b0, reg_drvhead[3:0],
		 reg_cylhigh[7:0],
		 reg_cyllow[7:0],
		 reg_secnum[7:0] };

	 $display("ide: lba 0x%x (%d), seccnt %d (read)",
		  lba, lba, reg_seccnt);

	 // read
	 fifo[0] = 16'h414c;
	 fifo[1] = 16'h4c42;
	 fifo[2] = 16'h0001;
	 fifo[3] = 16'h0000;
	 fifo[4] = 16'h032f;
	 fifo[5] = 16'h0000;
	 fifo[6] = 16'h0013;
	 fifo[7] = 16'h0000;
	 fifo[8] = 16'h0011;
	 fifo[9] = 16'h0000;
	 fifo[10] = 16'h0143;
	 fifo[11] = 16'h0000;
	 fifo[12] = 16'h434d;
	 fifo[13] = 16'h3152;
	 fifo[14] = 16'h4f4c;
	 fifo[15] = 16'h3144;
	 fifo[16] = 16'h0000;
	 fifo[17] = 16'h0000;
	 fifo[18] = 16'h0000;
	 fifo[19] = 16'h0000;
	 fifo[20] = 16'h0000;
	 fifo[21] = 16'h0000;
	 fifo[22] = 16'h0000;
	 fifo[23] = 16'h0000;

//xxxx
	 fifo[256] = 16'h0006;
	 fifo[257] = 16'h0000;
	 fifo[258] = 16'h0007;
	 fifo[259] = 16'h0000;
	 fifo[260] = 16'h434d;
	 fifo[261] = 16'h3152;
	 fifo[262] = 16'h0011;
	 fifo[263] = 16'h0000;
	 fifo[264] = 16'h0094;
	 fifo[265] = 16'h0000;
	 fifo[266] = 16'h2020;
	 fifo[267] = 16'h2020;
	 fifo[268] = 16'h2020;
	 fifo[269] = 16'h2020;
	 fifo[270] = 16'h2020;
	 fifo[271] = 16'h2020;
	 fifo[272] = 16'h2020;
	 fifo[273] = 16'h2020;
	 fifo[274] = 16'h434d;
	 fifo[275] = 16'h3252;
	 fifo[276] = 16'h00a5;
	 fifo[277] = 16'h0000;
	 fifo[278] = 16'h0094;
	 fifo[279] = 16'h0000;
	 fifo[280] = 16'h2020;
	 fifo[281] = 16'h2020;
	 fifo[282] = 16'h2020;
	 fifo[283] = 16'h2020;
	 fifo[284] = 16'h2020;
	 fifo[285] = 16'h2020;
	 fifo[286] = 16'h2020;
	 fifo[287] = 16'h2020;
	 
	 
	 fifo_depth = (512 * reg_seccnt) / 2;
	 fifo_rd = 0;
	 fifo_wr = 0;

	 status = IDE_STATUS_DRDY | IDE_STATUS_DSC | IDE_STATUS_DRQ;
	 bsy_count = 5;
      end
   endtask

   task do_ide_read_done;
      begin
         status = IDE_STATUS_DRDY | IDE_STATUS_DSC;
	 bsy_count = 0;
	 $display("ide: fifo empty");
      end
   endtask
   
   task do_ide_write;
      begin
	 lba = { 4'b0, reg_drvhead[3:0],
		 reg_cylhigh[7:0],
		 reg_cyllow[7:0],
		 reg_secnum[7:0] };

	 $display("ide: write prep; lba 0x%x (%d)\n", lba, lba);

	 fifo_depth = (512 * reg_seccnt) / 2;
	 fifo_rd = 0;
	 fifo_wr = 0;
	 
	 status = IDE_STATUS_DRDY | IDE_STATUS_DSC | IDE_STATUS_DRQ;
	 bsy_count = 0;
      end
   endtask

   task do_ide_write_done;
      begin
         status = IDE_STATUS_DRDY | IDE_STATUS_DSC;
	 bsy_count = 5;
	 $display("ide: fifo empty");
      end
   endtask
   
   task bus_read_fifo;
      output [15:0] data;
      begin
	 data = fifo[fifo_rd];
	 if (1) $display("ide: read fifo data [%d/%d] %o",
			 fifo_rd, fifo_depth, data);
	 if (fifo_rd < fifo_depth)
	   fifo_rd = fifo_rd + 1;
	 if (fifo_rd >= fifo_depth)
	   do_ide_read_done;
      end
   endtask

   task bus_write_fifo;
      input [15:0] data;
      begin
         fifo[fifo_wr] = data;
         if (0) $display("ide: write fifo data [%d/%d] %o",
			 fifo_wr, fifo_depth, data);
         if (fifo_wr < fifo_depth)
           fifo_wr = fifo_wr + 1;
         if (fifo_wr >= fifo_depth)
	   do_ide_write_done;
      end
   endtask

   always @(negedge ide_diow)
     #1 begin
	case (addr)
          ATA_DEVCTRL:
	    begin
               $display("ide: devctrl %x", ide_data_in);
	       if (ide_data_in[2])
		 begin
		    status = IDE_STATUS_BSY | IDE_STATUS_DRDY | IDE_STATUS_DSC;
		    bsy_count = 10;
		 end
	    end

//          ATA_ALTER: ;
//          ATA_FEATURE: ;
	  
          ATA_SECCNT: reg_seccnt = ide_data_in;
          ATA_SECNUM: reg_secnum = ide_data_in;
          ATA_CYLLOW: reg_cyllow = ide_data_in;
          ATA_CYLHIGH: reg_cylhigh = ide_data_in;
          ATA_DRVHEAD: reg_drvhead = ide_data_in;

          ATA_DATA: bus_write_fifo(ide_data_in);

          ATA_COMMAND:
	    begin
               $display("ide: command %x", ide_data_in);
               case (ide_data_in)
		 16'h0020:
		   begin
                      $display("ide: XXX READ");
                      do_ide_read;
		   end
		 16'h0030:
                   begin
		      $display("ide: XXX WRITE");
                      do_ide_write;
                   end
	       endcase
	    end
	endcase // case (addr)
     end
   
   always @(negedge ide_dior)
     begin
	case (addr)
	  ATA_DATA: bus_read_fifo(ide_data_out);
	  ATA_STATUS:
	    begin
	       $display("ide: read status %x", status);
	       ide_data_out <= status;

	       if (status[7])
		 begin
		    if (bsy_count == 0)
		      status[7] = 0;
		    else
		      bsy_count = bsy_count - 1;
		 end
	       
	    end
	endcase
     end

   always @(posedge ide_dior)
     ide_data_out <= 0;

   always @(posedge ide_diow)
     ide_data_out <= 0;
   
endmodule
