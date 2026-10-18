\m5_TLV_version 1d: tl-x.org
\m5
   //Simplest pipelined ARM datapath
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;
   
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
