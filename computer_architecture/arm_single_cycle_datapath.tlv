\m5_TLV_version 1d: tl-x.org
\m5
   //blaw 
   use(m5-1.0)
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;

   // ---------- PC Register & Next PC Mux ----------
   $pc_plus_4[63:0] = >>1$pc + 64'd4;
   $branch_target[63:0] = >>1$pc + ($sign_ext_imm << 2);
   
   $pc[63:0] = $reset ? 64'd0 :
               >>1$pcsrc ? >>1$branch_target :
                           $pc_plus_4;

   // ---------- Instruction ROM ----------
   $instr[31:0] =
      ($pc[5:2] == 4'd3) ? 32'h8B030041 :   // ADD  X1, X2, X3
      ($pc[5:2] == 4'd2) ? 32'hCB010044 :   // SUB  X4, X2, X1
      ($pc[5:2] == 4'd4) ? 32'hF8400005 :   // LDUR X5, [X0, #0]
      ($pc[5:2] == 4'd5) ? 32'hF8000003 :   // STUR X3, [X0, #0]
      ($pc[5:2] == 4'd6) ? 32'hB4000041 :   // CBZ  X1, #2
                           32'hB4000044;   // CBZ  X4, #2

   // ---------- Decode & Field Slicing ----------
   $op11[10:0] = $instr[31:21];
   $is_add  = ($op11 == 11'b10001011000);
   $is_sub  = ($op11 == 11'b11001011000);
   $is_ldur = ($op11 == 11'b11111000010);
   $is_stur = ($op11 == 11'b11111000000);
   $is_cbz  = ($instr[31:24] == 8'b10110100);
   $is_r    = $is_add || $is_sub;

   // Register Field Extraction
   $rn[4:0] = $instr[9:5];                  // Read Reg 1
   $rm[4:0] = $instr[20:16];                 // Read Reg 2 candidate 1
   $rt[4:0] = $instr[4:0];                  // Read Reg 2 candidate 2 / Write Reg

   // Immediate Sign Extension (for CBZ)
   $imm19[18:0] = $instr[23:5];
   $sign_ext_imm[63:0] = {{45{$imm19[18]}}, $imm19};

   // ---------- Control Unit ----------
   $reg2loc  = $is_stur || $is_cbz;
   $alusrc   = $is_ldur || $is_stur;
   $memtoreg = $is_ldur;
   $regwrite = $is_r || $is_ldur;
   $memread  = $is_ldur;
   $memwrite = $is_stur;
   $branch   = $is_cbz;
   $aluop[1:0] = $is_r   ? 2'b10 :
                 $is_cbz ? 2'b01 :
                           2'b00;

   // Read Register 2 Mux
   $read_reg2[4:0] = $reg2loc ? $rt : $rm;

   // Pretend ALU Zero output for testing branch taken
   $zero = ($pc[5:2] == 4'd4);
   $pcsrc = $branch && $zero;

   // ---------- VIZ: diagram fetched by reference + glow overlays ----------
   \viz_js
      box: {left: 0, top: 0, width: 480, height: 372, fill: "#ffffff", stroke: "#cccccc", strokeWidth: 1},

      init() {
         const PDF_URL = "https://star-being-proportion-professor.trycloudflare.com/page361.pdf"
         const OFFX = 15, OFFY = 12
         const OR = "#ff7a00"
         const ACTIVE_WIRE_WIDTH = 1

         // Primitive index groups (from the extractFigure dump). Wire + its arrowhead/dots.
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
         // Label index groups (block names, control signal names, mux input digits).
         const LABS = {
            t_regs: [4], t_alu: [5], t_add: [6], t_add_pc4: [20],
            t_sign: [12, 13], t_shift: [37, 38], t_imem: [42, 43], t_ctrl: [64],
            t_dmem: [33, 34], t_alucl: [51, 52],
            c_reg2loc: [56], c_branch: [57], c_memread: [58], c_memtoreg: [59],
            c_aluop: [60], c_memwrite: [61], c_alusrc: [62], c_regwrite: [63],
            m_r0: [74], m_r1: [75], m_a0: [47], m_a1: [48],
            m_w1: [45], m_w0: [46], m_p0: [49], m_p1: [50]
         }

         let figure = new fabric.Group([], {originX: "left", originY: "top", selectable: false, evented: false})
         let status = new fabric.Text("loading diagram...", {left: 15, top: 332, fontSize: 11, fill: "#222222", fontFamily: "monospace"})
         let status2 = new fabric.Text("", {left: 15, top: 348, fontSize: 8, fill: "#555555", fontFamily: "monospace"})
         let credit = new fabric.Text("Diagram fetched at runtime from the PDF URL in the code (not copied into this file).", {left: 15, top: 362, fontSize: 6, fill: "#999999", fontFamily: "monospace"})
         // Extra segment: Instruction[4-0] bus from x=111 to the Reg2Loc mux branch point (x=152.3).
         let ex1 = new fabric.Line([0, 0, 1, 1], {stroke: OR, strokeWidth: 2.4, visible: false, selectable: false, evented: false})

         this._ready = false
         this._state = null
         this._fig = figure
         this._ex1 = ex1

         this._paint = () => {
            if (!this._ready || !this._state) { return }
            const S = this._state
            const E = this._el
            const R = S.r, L = S.ld, ST = S.st, C = S.cb
            const usesRn = R || L || ST
            const usesImm = L || ST || C

            const lit = (name, on) => {
               [].concat(E[name]).forEach((o) => {
                  if (!o) { return }
                  const b = o.__base
                  if (b.sw > 0) { o.set({stroke: on ? OR : b.stroke, strokeWidth: on ? ACTIVE_WIRE_WIDTH : b.sw}) }
                  else { o.set({fill: on ? OR : b.fill}) }
                  o.set({dirty: true})
                  if (o.group) { o.group.set({dirty: true}) }
               })
            }
            // mode: 1 = active (orange bold), 0 = normal, -1 = dimmed
            const tx = (name, mode) => {
               [].concat(E[name]).forEach((o) => {
                  if (!o) { return }
                  o.set({fill: mode > 0 ? OR : (mode < 0 ? "#b0b0b0" : "#111111"),
                         fontWeight: mode > 0 ? "bold" : "normal", dirty: true})
                  if (o.group) { o.group.set({dirty: true}) }
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
            this._ex1.set({visible: (ST || C)})
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
            // Control signal names light up when asserted
            tx("c_reg2loc", S.reg2loc ? 1 : 0); tx("c_branch", S.branch ? 1 : 0)
            tx("c_memread", S.memread ? 1 : 0); tx("c_memtoreg", S.memtoreg ? 1 : 0)
            tx("c_aluop", 1); tx("c_memwrite", S.memwrite ? 1 : 0)
            tx("c_alusrc", S.alusrc ? 1 : 0); tx("c_regwrite", S.regwrite ? 1 : 0)

            this._fig.set({dirty: true})
            this.getCanvas().requestRenderAll()
         }

         this.global.pdf.buildFigure(fabric, {url: PDF_URL}, {
            page: 1,
            select: {mode: "largest"},
            clip: true,
            left: OFFX, top: OFFY,
            into: figure,
            primitives: PRIMS,
            labels: LABS
         }).then((res) => {
            this._el = res.elements
            Object.keys(PRIMS).forEach((k) => {
               [].concat(this._el[k]).forEach((o) => {
                  if (o) { o.__base = {stroke: o.stroke, sw: o.strokeWidth, fill: o.fill} }
               })
            })
            const A = res.fig(111, 200.8)
            const B = res.fig(152.3, 200.8)
            ex1.set({x1: A.x, y1: A.y, x2: B.x, y2: B.y})
            this._ready = true
            this._paint()
         }).catch((e) => {
            console.error("PDF extraction failed:", e)
         })

         return {figure: figure, ex1: ex1, status: status, status2: status2, credit: credit}
      },

         render() {
         // Fetch raw instruction hex directly from the TL-Verilog signal!
         let raw_instr = this.sigRef(`$instr`, 0).asBigInt(0n)
         let pc_big    = this.sigRef(`$pc`, 0).asBigInt(0n)

         let S = {
            r:        this.sigRef(`$is_r`, 0).asInt(0) == 1,
            ld:       this.sigRef(`$is_ldur`, 0).asInt(0) == 1,
            st:       this.sigRef(`$is_stur`, 0).asInt(0) == 1,
            cb:       this.sigRef(`$is_cbz`, 0).asInt(0) == 1,
            reg2loc:  this.sigRef(`$reg2loc`, 0).asInt(0) == 1,
            alusrc:   this.sigRef(`$alusrc`, 0).asInt(0) == 1,
            memtoreg: this.sigRef(`$memtoreg`, 0).asInt(0) == 1,
            regwrite: this.sigRef(`$regwrite`, 0).asInt(0) == 1,
            memread:  this.sigRef(`$memread`, 0).asInt(0) == 1,
            memwrite: this.sigRef(`$memwrite`, 0).asInt(0) == 1,
            branch:   this.sigRef(`$branch`, 0).asInt(0) == 1,
            pcsrc:    this.sigRef(`$pcsrc`, 0).asInt(0) == 1
         }
         let aluop = this.sigRef(`$aluop`, 0).asInt(0)
         let zero  = this.sigRef(`$zero`, 0).asInt(0)
         this._state = S

         // Dynamic instruction type disassembler string
         let inst_type = S.r  ? "R-type" :
                         S.ld ? "LDUR (load)" :
                         S.st ? "STUR (store)" :
                         S.cb ? "CBZ (branch)" : "UNKNOWN / NOP"

         let hex_str = "0x" + raw_instr.toString(16).padStart(8, "0").toUpperCase()

         const b = (v) => v ? 1 : 0

         // Status banner now updates dynamically based on $instr!
         this.getObjects().status.set({ 
            text: "PC: 0x" + pc_big.toString(16).toUpperCase() + " | INSTR: " + hex_str + " (" + inst_type + ")"
         })

         this.getObjects().status2.set({ text:
            "Reg2Loc=" + b(S.reg2loc) + " ALUSrc=" + b(S.alusrc) + " MemtoReg=" + b(S.memtoreg) +
            " RegWrite=" + b(S.regwrite) + " MemRead=" + b(S.memread) + " MemWrite=" + b(S.memwrite) +
            " Branch=" + b(S.branch) + " ALUOp=" + aluop.toString(2).padStart(2, "0") +
            " Zero=" + zero + " PCSrc=" + b(S.pcsrc)
         })

         this._paint()
         return []
      }
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
