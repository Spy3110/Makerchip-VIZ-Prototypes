\m5_TLV_version 1d: tl-x.org
\m5
   //use(m5-1.0)
      /*
        WELCOME TO THE SILICON BAKERY!
      IF: we take your order
      ID: we give it to our best chefs
      EX: they start cooking it for you in the Oven
      MEM: we will frost and decorate it with love
      WB: your cake is ready! Dont forget to pay~
      */
\SV
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   $reset = *reset;
   `BOGUS_USE($reset)
   |bakery
      @0
         //taking order
         $order[15:0] = $rand[15:0];
         $stg0_uid[7:0] = $uid; //for tracking
         
      @1
         //decoding the order
         $flavor[1:0]   = $order[1:0];
         $size[1:0]     = $order[3:2];
         $add_frosting  = $order[4];
         $base_price[7:0] = $order[15:8];
         `BOGUS_USE($flavor)
         $stg1_uid[7:0] = >>1$stg0_uid;
         
      @2
         //putting it on oven lol
         $size_ext[7:0] = {6'b0, $size};
         $baked_cake_val[7:0] = ($size == 2'd3) ? 8'd255 : ($size_ext * 8'd50);      
         $stg2_uid[7:0] = >>1$stg1_uid;
      @3
         //frosting and moneyyyy
         $topping_val[7:0] = $add_frosting ? 8'd25 : 8'd0;
         $final_cake_val[7:0] = $baked_cake_val + $topping_val;
         $stg3_uid[7:0] = >>1$stg2_uid;
      @4
         $reg_write_data[7:0] = $final_cake_val + $base_price;
         `BOGUS_USE($reg_write_data)
         $stg4_uid[7:0] = >>1$stg3_uid;

      
      
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
