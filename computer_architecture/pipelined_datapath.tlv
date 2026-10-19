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
                     >>3$pcsrc ? >>3$branch_target :
                     $pc_plus_four;
         $pc_plus_four[63:0] = >>1$pc + 64'd4;
         
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
         $is_add  = ($opcode == 11'b10001011000);
         $is_sub  = ($opcode == 11'b11001011000);
         $is_ldur = ($opcode == 11'b11111000010);
         $is_stur = ($opcode == 11'b11111000000);
         $is_cbz  = ($instr[31:24] == 8'b10110100);
         $is_r    = $is_add || $is_sub;
         
         $rn[4:0] = $instr[9:5]; //read reg 1
         $rm[4:0] = $instr[20:16]; //read reg 2
         $rt[4:0] = $instr[4:0]; //destination reg
         
         $imm19[18:0] = $instr[23:5];
         $sign_ext_imm[63:0] = {{45{$imm19[18]}}, $imm19};
         //for LDUR/STUR
         $imm9_ext[63:0] = {{55{$instr[20]}}, $instr[20:12]};
         
         $read_reg2[4:0] = $instr[28] ? $rt : $rm; //deciding from 28th bit
         
         //control unit-----------
         $branch   = $is_cbz;
         $memread  = $is_ldur;
         $memtoreg = $is_ldur;
         $memwrite = $is_stur;
         $alusrc   = $is_ldur || $is_stur;
         $regwrite = $is_r || $is_ldur;
         $aluop[1:0] = $is_r   ? 2'b10 :
                       $is_cbz ? 2'b01 :
                                 2'b00;
         
         //-----the register file--------
         /xreg[31:0]
            $wr_en = |cpu>>3$regwrite &&
                     (|cpu>>3$rt == #xreg) &&
                     (#xreg != 5'b11111);
            $val[63:0] = (|cpu$reset) ? 64'b0 :
                         $wr_en  ? |cpu>>3$wr_data :
                             $RETAIN;

         $rs1_data[63:0] = ($rn == 5'd31) ? 64'b0 : /xreg[$rn]$val; //i didnt quite get it...
         $rs2_data[63:0] = ($read_reg2 == 5'd31) ? 64'b0 : /xreg[$read_reg2]$val;

         
      @2
         //EX stage
         $branch_target[63:0] = >>1$pc + (>>2$sign_ext_imm << 2);
         $alu_in2[63:0] = ($alusrc == 1'b1) ? $imm9_ext : $rs2_data;
         
         //alu control
         $alu_ctrl[3:0] = ($aluop == 2'b00) ? 4'b0010 : //D format: ADD
                          ($aluop == 2'b01) ? 4'b0011 : //CBZ: Pass-B
                          $instr[30]        ? 4'b0110 : //SUB
                          $instr[29]        ? 4'b0001 : //ORR
                          $instr[24]        ? 4'b0010 : //ADD
                                              4'b0000; //AND
         
         //alu actions
         $and[63:0] = >>1$rs1_data & $alu_in2;
         $orr[63:0] = >>1$rs1_data | $alu_in2;
         $add[63:0] = >>1$rs1_data + $alu_in2;
         $sub[63:0] = >>1$rs1_data - $alu_in2;
         
         //result
         $alu_result[63:0] = ($alu_ctrl == 4'b0000) ? $and :
                             ($alu_ctrl == 4'b0001) ? $orr :
                             ($alu_ctrl == 4'b0010) ? $add :
                             ($alu_ctrl == 4'b0110) ? $sub :
                             ($alu_ctrl == 4'b0011) ? $alu_in2 :
                                                      64'b0;
         //zero flagg
         $zero = ($alu_result == 64'b0);
      @3
         //MEM stage
         $pcsrc = >>1$zero && >>2$branch;
         
         //------data memory------		--
         /dmem[63:0]
            $wr_en = |cpu>>2$memwrite && (|cpu>>1$alu_result[5:0] == #dmem);
            $val[63:0] = (|cpu$reset) ? 64'b0 :
                      $wr_en  ? |cpu>>2$rs2_data :
                                $RETAIN;

         $dmem_rd_data[63:0] = $memread ? /dmem[$alu_result[5:0]]$val : 64'b0;
      @4
         //WB stage
         //We want to write data to register.
         $wr_data[63:0] = >>3$memtoreg ? >>1$dmem_rd_data : >>2$alu_result;
      
   
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
