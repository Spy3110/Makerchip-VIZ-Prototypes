\m5_TLV_version 1d: tl-x.org
\m5
   //TLV FSM: Soda Vending Machine (State-Based Design)
\SV
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   // Connect SV inputs to TLV pipesignals.
   $reset = *reset;
   
   |vending
      @1  
         $coin_5 = (*cyc_cnt == 4);
         $coin_10 = (*cyc_cnt == 6) || (*cyc_cnt == 10) || (*cyc_cnt == 12);
         $state[2:0] = $reset ? 3'b000 : $next_state>>1;
         
         $next_state = $reset ? 3'b000 :
                        //first we are at state 0, means 0 rupees
                        ($state == 3'b000) ? (
                        $coin_5 ? 3'b001 :
                        $coin_10 ? 3'b010 :
                        3'b000 )
                        :
                        //we are at state 1, 5 rupees
                        ($state == 3'b001) ? (
                        $coin_5 ? 3'b010 :
                        $coin_10 ? 3'b011 :
                        3'b001 )
                        :
                        //we are at state 2, 10 rupees
                        ($state == 3'b010) ? (
                        $coin_5 ? 3'b011 :
                        $coin_10 ? 3'b100 :
                        3'b010 )
                        :
                        //at state 3 or 4, so we have to dispense and for this, unconditional jump
                        3'b000 ;
                        
         $dispense_soda = ($state == 3'b011) || ($state == 3'b100);
         $dispense_coin = $state == 3'b100 ;

   // Assert these to end simulation (before the cycle limit).
   *passed = *cyc_cnt > 20;
   *failed = 1'b0;
\SV
   endmodule
