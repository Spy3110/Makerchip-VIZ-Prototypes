\m5_TLV_version 1d: tl-x.org
\m5
   /*
   1-BIT ALU WITH TOP-DOWN CONTROL ROUTING
   */
\SV
   m5_makerchip_module  
\TLV
   $reset = *reset;
   `BOGUS_USE($reset)
   
   // Shared controls and 64-bit inputs.
   $ainvert  = 1'b0;
   $binvert  = 1'b0;
   $operation[1:0] = 2'b10; //adder or subtract

   // Try changing these inputs!
   $aa[63:0] = 64'h0123_4567_89AB_CDEF;
   $bb[63:0] = 64'hFEDC_BA98_7654_3210;

   /alu[63:0]
      $aa_bit = /top$aa[#alu];
      $bb_bit = /top$bb[#alu];

      // Input muxes (invert if needed).
      $a_mux = /top$ainvert ? !$aa_bit : $aa_bit;
      $b_mux = /top$binvert ? !$bb_bit : $bb_bit;

      // Bit 0 starts with Binvert; each later bit receives the prior carry.
      $carry_in = (#alu == 0) ? /top$binvert :
                  /alu[#alu-1]$carry_out;

      // Operations.
      $and = $a_mux & $b_mux;
      $or  = $a_mux | $b_mux;
      $sum = $a_mux ^ $b_mux ^ $carry_in;
      $carry_out = ($a_mux & $b_mux) |
                   ($carry_in & ($a_mux ^ $b_mux));

      // Output mux (supports the fourth operation: Pass-B).
      $result = (/top$operation == 2'b00) ? $and :
                (/top$operation == 2'b01) ? $or  :
                (/top$operation == 2'b10) ? $sum :
                                             $bb_bit;

   // Collect the per-bit results and expose the final carry.
   $result[63:0] = /alu[*]$result;
   $carry_out = /alu[63]$carry_out;
   `BOGUS_USE($carry_out)
   `BOGUS_USE($result)
   

   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
