\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;

   // ---------- PC Register & Next PC Mux ----------
   $pc[63:0] = $reset ? 64'd0 :
               >>1$pcsrc ? >>1$branch_target :
                           $pc_plus_4;
   $pc_plus_4[63:0] = >>1$pc + 64'd4;
   $branch_target[63:0] = >>1$pc + ($sign_ext_imm << 2);

   // ---------- Instruction ROM ----------
   $instr[31:0] =
      ($pc[5:2] == 4'd3) ? 32'h8B030041 :   // ADD  X1, X2, X3
      ($pc[5:2] == 4'd2) ? 32'hCB010044 :   // SUB  X4, X2, X1
      ($pc[5:2] == 4'd4) ? 32'hF84C8021 :   // LDUR X1, [X1, #200]
      ($pc[5:2] == 4'd5) ? 32'hF8000003 :   // STUR X3, [X0, #0]
      ($pc[5:2] == 4'd6) ? 32'hB4000041 :   // CBZ  X1, #2
                           32'hB4000044;    // CBZ  X4, #2

   // ---------- Decode & Field Slicing ----------
   $op11[10:0] = $instr[31:21];
   $is_add  = ($op11 == 11'b10001011000);
   $is_sub  = ($op11 == 11'b11001011000);
   $is_ldur = ($op11 == 11'b11111000010);
   $is_stur = ($op11 == 11'b11111000000);
   $is_cbz  = ($instr[31:24] == 8'b10110100);
   $is_r    = $is_add || $is_sub;

   $rn[4:0] = $instr[9:5];     // Read Reg 1
   $rm[4:0] = $instr[20:16];   // Read Reg 2 candidate 1
   $rt[4:0] = $instr[4:0];     // Read Reg 2 candidate 2 / Write Reg

   // Immediate Sign Extension (for CBZ)
   $imm19[18:0] = $instr[23:5];
   $sign_ext_imm[63:0] = {{45{$imm19[18]}}, $imm19};
   // for LDUR/STUR
   $imm9_ext[63:0] = {{55{$instr[20]}}, $instr[20:12]};

   // ---------- Control Unit ----------
   $reg2loc  = $is_stur || $is_cbz;
   $branch   = $is_cbz;
   $memread  = $is_ldur;
   $memtoreg = $is_ldur;
   $memwrite = $is_stur;
   $alusrc   = $is_ldur || $is_stur;
   $regwrite = $is_r || $is_ldur;
   $aluop[1:0] = $is_r   ? 2'b10 :
                 $is_cbz ? 2'b01 :
                           2'b00;

   $read_reg2[4:0] = $reg2loc ? $rt : $rm;
   $pcsrc = $branch && $zero;

   //-----the register file--------
   /xreg[31:0]
      $wr_en = /top>>1$regwrite &&
               (/top>>1$rt == #xreg) &&
               (#xreg != 5'b11111);
      $val[63:0] = (/top$reset) ? 64'b0 :
                   $wr_en  ? /top>>1$wr_data :
                       $RETAIN;

   $rs1_data[63:0] = ($rn == 5'd31) ? 64'b0 : /xreg[$rn]$val;
   $rs2_data[63:0] = ($read_reg2 == 5'd31) ? 64'b0 : /xreg[$read_reg2]$val;

   $wr_data[63:0] = $memtoreg ? $dmem_rd_data : $alu_result;

   //----------ALU control-----------
   $alu_ctrl[3:0] = ($aluop == 2'b00) ? 4'b0010 : //D format: ADD
                    ($aluop == 2'b01) ? 4'b0011 : //CBZ: Pass-B
                    $instr[30]        ? 4'b0110 : //SUB
                    $instr[29]        ? 4'b0001 : //ORR
                    $instr[24]        ? 4'b0010 : //ADD
                                        4'b0000;  //AND

   //-----the ALU------------
   $alu_in2[63:0] = ($alusrc == 1'b1) ? $imm9_ext : $rs2_data;

   $and[63:0] = $rs1_data & $alu_in2;
   $orr[63:0] = $rs1_data | $alu_in2;
   $add[63:0] = $rs1_data + $alu_in2;
   $sub[63:0] = $rs1_data - $alu_in2;

   $alu_result[63:0] = ($alu_ctrl == 4'b0000) ? $and :
                       ($alu_ctrl == 4'b0001) ? $orr :
                       ($alu_ctrl == 4'b0010) ? $add :
                       ($alu_ctrl == 4'b0110) ? $sub :
                       ($alu_ctrl == 4'b0011) ? $alu_in2 :
                                                64'b0;

   $zero = ($alu_result == 64'b0);

   //------data memory--------
   /dmem[63:0]
      $wr_en = /top>>1$memwrite && (/top>>1$alu_result[5:0] == #dmem);
      $val[63:0] = (/top$reset) ? 64'b0 :
                   $wr_en  ? /top>>1$rs2_data :
                             $RETAIN;

   $dmem_rd_data[63:0] = /dmem[$alu_result[5:0]]$val;

   // ---------- VIZ: Live Doc (diagram fetched by reference) + glow overlays ----------
   \viz_js
      box: {left: 0, top: 0, width: 480, height: 372, fill: "#ffffff", stroke: "#cccccc", strokeWidth: 1},

      init() {
         const PDF_URL = "https://asks-handle-blacks-reno.trycloudflare.com/page361.pdf"
         const OFFX = 15, OFFY = 12
         const OR = "#ff7a00"
         const ACTIVE_WIRE_WIDTH = 1

         // Pool positions (from the extractFigure dump). Arrays of selectors -> arrays of elements.
         const PRIMS = {
            w_pc_imem: [42, 43, 59],
            w_pc_add: [46, 47],
            w_four: [12, 13],
            w_pcnext: [48, 49],
            w_pc_all: [69],
            w_pc4_arrow: [66],
            w_br_in_arrow: [67],
            w_imem_out: [28, 79, 83, 61, 71, 60],
            w_ctrl_in: [57, 58],
            w_rn: [72],
            w_rt0: [73, 74, 81],
            w_rt1: [77, 78, 84],
            w_rd: [75, 76, 24, 25, 82],
            w_r2mux_out: [70],
            w_rd1: [3, 4],
            w_rd2: [14, 65],
            w_rd2_arrow: [15],
            w_rd2_mem: [35, 36],
            w_sign_in: [44, 45, 20],
            w_se_alu: [21, 23, 64],
            w_se_alu_arrow: [22],
            w_shift: [37, 38],
            w_shift_out: [39, 40],
            w_bradd_out: [16, 17],
            w_alumux_out: [5, 6],
            w_alucl_in: [51, 52, 62],
            w_aluop: [55],
            w_alucl_out: [53],
            w_alu_dmem: [8, 9],
            w_alu_wb: [33, 34],
            w_alu_fork: [63],
            w_zero: [7],
            w_dmem_rd: [10, 11],
            w_wb: [26, 27],
            b_pc: [41],
            b_pcadd: [29],
            b_pcmux: [32],
            b_alumux: [30],
            b_wbmux: [31],
            b_r2mux: [80],
            b_dmem: [2],
            b_sign: [19],
            b_alucl: [0]
         }
         const LABS = {
            t_regs: [4], t_alu: [5], t_add: [6], t_add_pc4: [20],
            t_sign: [12, 13], t_shift: [37, 38], t_imem: [42, 43], t_ctrl: [64],
            t_dmem: [33, 34], t_alucl: [51, 52],
            c_reg2loc: [56], c_branch: [57], c_memread: [58], c_memtoreg: [59],
            c_aluop: [60], c_memwrite: [61], c_alusrc: [62], c_regwrite: [63],
            m_r0: [74], m_r1: [75], m_a0: [47], m_a1: [48],
            m_w1: [45], m_w0: [46], m_p0: [49], m_p1: [50]
         }

         // Extra segment (box space): Instruction[4-0] bus to the Reg2Loc mux branch point.
         const ex1 = new fabric.Line([0, 0, 1, 1], {stroke: OR, strokeWidth: 2.4, visible: false, selectable: false, evented: false})

         // extractToFabric returns the (initially empty) group synchronously.
         // Named elements land in this.liveDocElements once the PDF arrives.
         const figure = this.global.pdf.extractToFabric(this, {url: PDF_URL}, {
            extract: {page: 1, select: {mode: "largest"}, clip: true},
            build: {
               notice: "Diagram fetched at runtime from the PDF URL in the code (not copied into this file).",
               primitives: PRIMS,
               labels: LABS,
               onReady: ({elements, fig}) => {
                  // Remember each wire's original look so lit(false) can restore it.
                  Object.keys(PRIMS).forEach((k) => {
                     [].concat(elements[k]).forEach((o) => {
                        if (o) { o.__base = {stroke: o.stroke, sw: o.strokeWidth, fill: o.fill} }
                     })
                  })
                  // fig() maps figure coords -> box coords through the group's transform.
                  const A = fig(111, 200.8)
                  const B = fig(152.3, 200.8)
                  ex1.set({x1: A.x, y1: A.y, x2: B.x, y2: B.y})
                  // Live Doc calls this.rerender() right after onReady, so render() paints.
               },
               onError: (e) => { console.error("Live Doc extraction failed:", e) }
            }
         })
         figure.set({left: OFFX, top: OFFY})

         // ---- Box-space overlays and status text ----
         const status  = new fabric.Text("loading diagram...", {left: 15, top: 332, fontSize: 11, fill: "#222222", fontFamily: "monospace"})
         const status2 = new fabric.Text("", {left: 15, top: 348, fontSize: 8, fill: "#555555", fontFamily: "monospace"})
         const mkTxt = (s, l, t) => new fabric.Text(s, {left: l, top: t, fontSize: 6, fontFamily: "monospace", fill: "#FF0000"})
         const pcBubble    = new fabric.Text("PC=0x0", {left: 38, top: 200, fontSize: 9, fontFamily: "monospace", fill: "#FF0000"})
         const aluOpBubble = new fabric.Text("ALUOp=00", {left: 300, top: 290, fontSize: 9, fontFamily: "monospace", fill: "#FF0000"})
         const nextPcDot   = new fabric.Circle({left: 385, top: 40, radius: 9, fill: "#ffffff", stroke: "#aaaaaa", strokeWidth: 1})
         const nextPcTxt   = mkTxt("?", 387, 46)
         const alu_ctrlTxt = mkTxt("?", 310, 225)
         const rnTxt = mkTxt("Rn:00000", 130, 155)
         const rmTxt = mkTxt("Rm:00000", 130, 185)
         const rtTxt = mkTxt("Rt:00000", 130, 205)

         return {figure, ex1, status, status2,
                 pcBubble, aluOpBubble, nextPcDot, nextPcTxt,
                 alu_ctrlTxt, rnTxt, rmTxt, rtTxt}
      },

      render() {
         const OR = "#ff7a00"
         const ACTIVE_WIRE_WIDTH = 1
         const o = this.getObjects()

         // ---- Read signals ----
         let raw_instr = '$instr'.asBigInt(0n)
         let pc_big    = '$pc'.asBigInt(0n)
         let alu_ctrl  = '$alu_ctrl'.asInt(0)
         let rn        = '$rn'.asInt(0)
         let rm        = '$rm'.asInt(0)
         let rt        = '$rt'.asInt(0)
         let aluop     = '$aluop'.asInt(0)
         let zero      = '$zero'.asInt(0)
         let branchTargetBig = '$branch_target'.asBigInt(0n)

         const S = {
            r:        '$is_r'.asInt(0) == 1,
            ld:       '$is_ldur'.asInt(0) == 1,
            st:       '$is_stur'.asInt(0) == 1,
            cb:       '$is_cbz'.asInt(0) == 1,
            reg2loc:  '$reg2loc'.asInt(0) == 1,
            alusrc:   '$alusrc'.asInt(0) == 1,
            memtoreg: '$memtoreg'.asInt(0) == 1,
            regwrite: '$regwrite'.asInt(0) == 1,
            memread:  '$memread'.asInt(0) == 1,
            memwrite: '$memwrite'.asInt(0) == 1,
            branch:   '$branch'.asInt(0) == 1,
            pcsrc:    '$pcsrc'.asInt(0) == 1
         }
         const nextPc = S.pcsrc ? branchTargetBig : (pc_big + 4n)
         const b = (v) => v ? 1 : 0

         // ---- Box-space overlays (always safe to update) ----
         const inst_type = S.r  ? "R-type" :
                           S.ld ? "LDUR (load)" :
                           S.st ? "STUR (store)" :
                           S.cb ? "CBZ (branch)" : "UNKNOWN / NOP"
         const hex_str = "0x" + raw_instr.toString(16).padStart(8, "0").toUpperCase()

         o.status.set({text: "PC: 0x" + pc_big.toString(16).toUpperCase() + " | INSTR: " + hex_str + " (" + inst_type + ")"})
         o.status2.set({text:
            "Reg2Loc=" + b(S.reg2loc) + " ALUSrc=" + b(S.alusrc) + " MemtoReg=" + b(S.memtoreg) +
            " RegWrite=" + b(S.regwrite) + " MemRead=" + b(S.memread) + " MemWrite=" + b(S.memwrite) +
            " Branch=" + b(S.branch) + " ALUOp=" + aluop.toString(2).padStart(2, "0") +
            " Zero=" + zero + " PCSrc=" + b(S.pcsrc)})
         o.pcBubble.set({text: "PC=0x" + pc_big.toString(16).toUpperCase()})
         o.aluOpBubble.set({text: "ALUOp=" + aluop.toString(2).padStart(2, "0")})
         o.nextPcDot.set({fill: S.pcsrc ? "#ffc09a" : "#ffffff"})
         o.nextPcTxt.set({text: "0x" + nextPc.toString(16).toUpperCase()})
         o.alu_ctrlTxt.set({text: "Ctrl:" + alu_ctrl.toString(2).padStart(4, "0")})
         o.rnTxt.set({text: "Rn:" + rn.toString(2).padStart(5, "0")})
         o.rmTxt.set({text: "Rm:" + rm.toString(2).padStart(5, "0")})
         o.rtTxt.set({text: "Rt:" + rt.toString(2).padStart(5, "0")})

         // ---- PDF-figure elements: render() also runs before the PDF arrives ----
         const E = this.liveDocElements
         if (!E) { return [] }

         const R = S.r, L = S.ld, ST = S.st, C = S.cb
         const usesRn  = R || L || ST
         const usesImm = L || ST || C

         // Wires/boxes: orange when on, original style when off.
         const lit = (name, on) => {
            [].concat(E[name]).forEach((el) => {
               if (!el) { return }
               const base = el.__base
               if (base.sw > 0) { el.set({stroke: on ? OR : base.stroke, strokeWidth: on ? ACTIVE_WIRE_WIDTH : base.sw}) }
               else { el.set({fill: on ? OR : base.fill}) }
            })
         }
         // Text: 1 = active (orange bold), 0 = normal, -1 = dimmed.
         const tx = (name, mode) => {
            [].concat(E[name]).forEach((el) => {
               if (!el) { return }
               el.set({fill: mode > 0 ? OR : (mode < 0 ? "#b0b0b0" : "#111111"),
                       fontWeight: mode > 0 ? "bold" : "normal"})
            })
         }

         // Always-active fetch path
         lit("w_pc_imem", true); lit("w_pc_add", true); lit("w_four", true); lit("w_pcnext", true)
         lit("w_pc_all", true); lit("w_imem_out", true); lit("w_ctrl_in", true)
         lit("b_pc", true); lit("b_pcadd", true); lit("b_pcmux", true)
         tx("t_imem", 1); tx("t_ctrl", 1); tx("t_add_pc4", 1)
         // PC mux input that wins
         lit("w_pc4_arrow", !S.pcsrc)
         lit("w_br_in_arrow", C)
         lit("w_bradd_out", S.pcsrc)
         tx("m_p0", S.pcsrc ? -1 : 1); tx("m_p1", S.pcsrc ? 1 : -1)
         // Register read
         tx("t_regs", 1)
         lit("w_rn", usesRn); lit("w_rd1", usesRn)
         lit("w_rt0", R); lit("w_rt1", ST || C)
         lit("b_r2mux", !L); lit("w_r2mux_out", !L)
         tx("m_r0", S.reg2loc ? -1 : 1); tx("m_r1", S.reg2loc ? 1 : -1)
         o.ex1.set({visible: (ST || C)})
         // Sign-extend / shift / branch adder
         lit("w_sign_in", usesImm); lit("b_sign", usesImm); tx("t_sign", usesImm ? 1 : 0)
         lit("w_se_alu", usesImm); lit("w_se_alu_arrow", L || ST)
         lit("w_shift", C); lit("w_shift_out", C); tx("t_shift", C ? 1 : 0); tx("t_add", C ? 1 : 0)
         // ALU side
         lit("w_rd2", R || C || ST); lit("w_rd2_arrow", R || C)
         lit("b_alumux", true); lit("w_alumux_out", true)
         tx("m_a0", S.alusrc ? -1 : 1); tx("m_a1", S.alusrc ? 1 : -1)
         tx("t_alu", 1)
         lit("b_alucl", true); tx("t_alucl", 1)
         lit("w_aluop", true); lit("w_alucl_out", true); lit("w_alucl_in", R)
         lit("w_zero", C)
         // Memory
         lit("w_alu_fork", R || L || ST)
         lit("w_alu_dmem", L || ST); lit("b_dmem", L || ST); tx("t_dmem", (L || ST) ? 1 : 0)
         lit("w_rd2_mem", ST); lit("w_dmem_rd", L)
         // Write back
         lit("w_alu_wb", R); lit("b_wbmux", R || L); lit("w_wb", R || L)
         tx("m_w0", S.memtoreg ? -1 : 1); tx("m_w1", S.memtoreg ? 1 : -1)
         lit("w_rd", S.regwrite)
         // Control signal names
         tx("c_reg2loc", S.reg2loc ? 1 : 0); tx("c_branch", S.branch ? 1 : 0)
         tx("c_memread", S.memread ? 1 : 0); tx("c_memtoreg", S.memtoreg ? 1 : 0)
         tx("c_aluop", 1); tx("c_memwrite", S.memwrite ? 1 : 0)
         tx("c_alusrc", S.alusrc ? 1 : 0); tx("c_regwrite", S.regwrite ? 1 : 0)

         return []
      }

   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
