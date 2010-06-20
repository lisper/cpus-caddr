
module support(sysclk, clk, reset, interrupt, boot, halt);

   input sysclk;
   output clk;
   output reset;
   output interrupt;
   output boot;
   output halt;


   assign clk = sysclk;
   assign reset = 1'b0;
   assign interrupt = 1'b0;
   assign boot = 1'b0;
   assign halt = 1'b0;
   
endmodule

   
   
