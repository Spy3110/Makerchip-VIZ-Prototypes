\m5_TLV_version 1d: tl-x.org
\m5
   //Simplest pipelined ARM datapath (5 stage)
\SV
   m5_makerchip_module
\TLV
   |cpu
      @0
         $reset = *reset;
         //IF stage
         $pc[63:0] = $reset ? 64'd0 :
                     $pc_branch ? >>1$branch_target :
                     $pc_plus_four;
         $pc_plus_four[63:0] = >>1$pc + 64'd4;
         $branch_target[63:0] = >>1$pc + ($sign_ext_imm << 2);
         
         //instruction memory
         $instr[31:0] = ($pc[5:2] == 4'd1) ? 32'h8B030041 : //ADD
                        ($pc[5:2] == 4'd2) ? 32'hCB010044 : //SUB
                        ($pc[5:2] == 4'd3) ? 32'hF84C8021 : //LDUR
                        ($pc[5:2] == 4'd4) ? 32'hF8000003 : //STUR
                        ($pc[5:2] == 4'd5) ? 32'hB4000044 : //CBZ
                                             32'hB4000041;
      @1
         //ID stage
         $opcode[10:0] = $instr[31:21];
         $is_add  = ($op11 == 11'b10001011000);
         $is_sub  = ($op11 == 11'b11001011000);
         $is_ldur = ($op11 == 11'b11111000010);
         $is_stur = ($op11 == 11'b11111000000);
         $is_cbz  = ($instr[31:24] == 8'b10110100);
         $is_r    = $is_add || $is_sub;
         
         $rn[4:0] = $instr[9:5]; //read reg 1
         $rm[4:0] = $instr[20:16]; //read reg 2
         $rt[4:0] = $instr[4:0]; //destination reg
      @2
         //EX stage
         
      @3
         //MEM stage
         
      @4
         //WB stage
         
      
   
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
