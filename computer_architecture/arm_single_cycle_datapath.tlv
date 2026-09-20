\m5_TLV_version 1d: tl-x.org
\m5
   // ============================================================================
   // Live Doc checkpoint: just extract & render Figure 4.2 (p.343, LEGv8 basic
   // datapath w/ control) as a static figure -- no animation yet. Confirms the
   // extracted geometry renders correctly in Makerchip VIZ before wiring up
   // per-cycle wire-value bubbles.
   // ============================================================================
   use(m5-1.0)
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;

   // ------------------------------------------------------------------------
   // Same tiny 7-instruction "microprogram" as the p.342 demo, looping forever:
   //   pc=0 ADDI R1,R0,#5   pc=4 LW   R4,[0]
   //   pc=1 ADDI R2,R0,#3   pc=5 SUB  R5,R3,R2
   //   pc=2 ADD  R3,R1,R2   pc=6 BEQ  R1,R1,#0  (always taken -> loop to 0)
   //   pc=3 SW   R3,[0]
   // ------------------------------------------------------------------------
   $pc[2:0] = $reset ? 3'd0 : (>>1$pc == 3'd6) ? 3'd0 : (>>1$pc + 3'd1);
   $pc_plus1[2:0] = $pc + 3'd1;

   // Control signals, decoded per instruction (hardcoded by pc, as in a real
   // control unit's opcode decode).
   $reg_write = ($pc==3'd0)||($pc==3'd1)||($pc==3'd2)||($pc==3'd4)||($pc==3'd5);
   $mem_write = ($pc==3'd3);
   $mem_read  = ($pc==3'd4);
   $mem_to_reg = ($pc==3'd4);
   $alu_src    = ($pc==3'd0)||($pc==3'd1)||($pc==3'd3)||($pc==3'd4);  // 1=immediate, 0=register
   $branch     = ($pc==3'd6);
   $alu_sub    = ($pc==3'd5)||($pc==3'd6);  // 1=subtract, 0=add

   // Register-file port indices (Read reg1/2, Write reg) -- R0 is always 0.
   $reg_read1_idx[2:0] = ($pc==3'd2) ? 3'd1 : ($pc==3'd5) ? 3'd3 : ($pc==3'd6) ? 3'd1 : 3'd0;
   $reg_read2_idx[2:0] = ($pc==3'd2) ? 3'd2 : ($pc==3'd3) ? 3'd3 : ($pc==3'd5) ? 3'd2 : ($pc==3'd6) ? 3'd1 : 3'd0;
   $reg_write_idx[2:0] = ($pc==3'd0) ? 3'd1 : ($pc==3'd1) ? 3'd2 : ($pc==3'd2) ? 3'd3 :
                         ($pc==3'd4) ? 3'd4 : ($pc==3'd5) ? 3'd5 : 3'd0;
   $imm[7:0] = ($pc==3'd0) ? 8'd5 : ($pc==3'd1) ? 8'd3 : 8'd0;  // ADDI immediates; SW/LW base addr 0

   // Register file (R1..R5; R0 reads as 0). Written back from $write_back_data.
   $r1[7:0] = $reset ? 8'd0 : ($reg_write && $reg_write_idx==3'd1) ? $write_back_data : >>1$r1;
   $r2[7:0] = $reset ? 8'd0 : ($reg_write && $reg_write_idx==3'd2) ? $write_back_data : >>1$r2;
   $r3[7:0] = $reset ? 8'd0 : ($reg_write && $reg_write_idx==3'd3) ? $write_back_data : >>1$r3;
   $r4[7:0] = $reset ? 8'd0 : ($reg_write && $reg_write_idx==3'd4) ? $write_back_data : >>1$r4;
   $r5[7:0] = $reset ? 8'd0 : ($reg_write && $reg_write_idx==3'd5) ? $write_back_data : >>1$r5;

   $read_data1[7:0] = ($reg_read1_idx==3'd1) ? $r1 : ($reg_read1_idx==3'd2) ? $r2 :
                      ($reg_read1_idx==3'd3) ? $r3 : ($reg_read1_idx==3'd4) ? $r4 :
                      ($reg_read1_idx==3'd5) ? $r5 : 8'd0;
   $read_data2[7:0] = ($reg_read2_idx==3'd1) ? $r1 : ($reg_read2_idx==3'd2) ? $r2 :
                      ($reg_read2_idx==3'd3) ? $r3 : ($reg_read2_idx==3'd4) ? $r4 :
                      ($reg_read2_idx==3'd5) ? $r5 : 8'd0;

   // ALUSrc mux -> ALU -> Zero
   $alu_in2[7:0] = $alu_src ? $imm : $read_data2;
   $alu_result[7:0] = $alu_sub ? ($read_data1 - $alu_in2) : ($read_data1 + $alu_in2);
   $zero = $alu_result == 8'd0;
   $branch_taken = $branch && $zero;

   // Data memory (one byte-wide slot at address 0, addressed by the ALU result).
   $mem_addr[7:0] = $alu_result;
   $mem_write_data[7:0] = $read_data2;
   $mem0[7:0] = $reset ? 8'd0 : $mem_write ? $mem_write_data : >>1$mem0;
   $mem_read_data[7:0] = $mem_read ? $mem0 : 8'd0;

   // MemtoReg mux -> register write-back data.
   $write_back_data[7:0] = $mem_to_reg ? $mem_read_data : $alu_result;

   \viz_js
      box: {left: 0, top: 0, width: 460, height: 380, fill: "#ffffff"},

      init() {
         let widgets = {}

         widgets.title = new fabric.Text(
            "Figure 4.2 (CoD ARM Ed., p.343) -- basic LEGv8 datapath, animated",
            {left: 4, top: 2, fontSize: 8, fontFamily: "Roboto", fill: "#555"}
         )

         let figure = new fabric.Group([], {
            originX: "left", originY: "top", selectable: false, evented: false
         })
         widgets.figure = figure

         widgets.loading = new fabric.Text("extracting figure from PDF...", {
            left: 12, top: 100, fontSize: 9, fontFamily: "Roboto", fill: "#999"
         })
         widgets.status = new fabric.Text("", {
            left: 4, top: 360, fontSize: 8, fontFamily: "Roboto",
            fill: "#1565c0", selectable: false, evented: false
         })
         widgets.instrLine = new fabric.Text("", {
            left: 4, top: 344, fontSize: 10, fontFamily: "monospace",
            fill: "#000", fontWeight: "bold", selectable: false, evented: false
         })

         const OFFX = 4, OFFY = 30
         this._pdfReady = false

         // Served locally: LiveDocExploration/page343.pdf via cloudflared quick tunnel.
         const PDF_URL = "https://human-timeline-overview-rates.trycloudflare.com/page343.pdf" //temporary

         // A "bubble" is a small rounded pill (rect + text) that sits on a wire
         // and shows that wire's live value, redrawn every cycle. Created here
         // (off-canvas placeholder position) so the framework registers them as
         // top-level widgets; buildFigure repositions them once ready.
         const mkBubble = (color) => {
            const bg = new fabric.Rect({
               left: -100, top: -100, width: 24, height: 12, rx: 5, ry: 5,
               fill: color, opacity: 0.15, stroke: color, strokeWidth: 1,
               selectable: false, evented: false
            })
            const txt = new fabric.Text("", {
               left: -100, top: -100, originX: "center", originY: "center",
               fontSize: 7, fontFamily: "monospace", fontWeight: "bold",
               fill: color, selectable: false, evented: false
            })
            return {bg, txt}
         }

         const BUBBLE_COLORS = [
            ["pcAddr","#1565c0"], ["instr","#2e7d32"],
            ["reg1","#6a1b9a"], ["reg2","#6a1b9a"], ["regw","#6a1b9a"],
            ["regData1","#0277bd"], ["regData2","#0277bd"], ["writeData","#0277bd"],
            ["aluIn2","#0277bd"], ["aluResult","#c62828"], ["zero","#ef6c00"],
            ["memAddr","#1565c0"], ["memWData","#0277bd"], ["memRData","#0277bd"],
            ["wbData","#0277bd"], ["pcPlus1","#1565c0"], ["pcMux","#1565c0"],
            ["control","#6a1b9a"],
         ]
         const B = {}
         for (const [name, color] of BUBBLE_COLORS) {
            B[name] = mkBubble(color)
            widgets[name + "_bg"] = B[name].bg
            widgets[name + "_txt"] = B[name].txt
         }
         this._bubbles = B

         this.global.pdf.buildFigure(fabric, {url: PDF_URL}, {
            page: 1, select: {mode: "largest"}, clip: true,
            left: OFFX, top: OFFY, into: figure
         }).then(({fig}) => {
            // Anchor points, read off the extracted labels/primitives (figure space);
            // fig() maps them into this box's coordinate space to match the geometry.
            const pos = {
               pcAddr:     fig(30, 178),   // PC -> instruction-memory address
               instr:      fig(99, 178),   // fetched instruction
               reg1:       fig(165, 160),  // Read register 1 #
               reg2:       fig(165, 180),  // Read register 2 #
               regw:       fig(165, 200),  // Write register #
               regData1:   fig(232, 160),  // Read data 1 out
               regData2:   fig(232, 180),  // Read data 2 out
               writeData:  fig(232, 200),  // Write data in
               aluIn2:     fig(268, 100),  // ALUSrc mux output -> ALU
               aluResult:  fig(320, 168),  // ALU result
               zero:       fig(316, 188),  // Zero flag
               memAddr:    fig(336, 176),  // data-memory address
               memWData:   fig(337, 227),  // data-memory write data
               memRData:   fig(366, 194),  // data-memory read data
               wbData:     fig(267, 187),  // MemtoReg mux output -> write-back
               pcPlus1:    fig(77, 100),   // PC+ adder result
               pcMux:      fig(93, 30),    // PC-source mux output
               control:    fig(173, 278),  // control-unit summary
            }

            for (const [name] of BUBBLE_COLORS) {
               const p = pos[name]
               B[name].bg.set({left: p.x - 12, top: p.y - 6})
               B[name].txt.set({left: p.x, top: p.y})
            }

            this._instrLabel = widgets.instrLine
            this._statusLabel = widgets.status

            widgets.loading.set({visible: false})
            this._pdfReady = true
            this.getCanvas().requestRenderAll()
         }).catch((e) => {
            console.error("PDF figure extraction failed:", e)
            widgets.loading.set({text: "PDF extraction failed: " + e.message, fill: "#c00"})
            this.getCanvas().requestRenderAll()
         })

         return widgets
      },

      render() {
         if (!this._pdfReady) return []

         const MNEMONICS = [
            "ADDI R1,R0,#5", "ADDI R2,R0,#3", "ADD  R3,R1,R2", "SW   R3,[0]",
            "LW   R4,[0]",   "SUB  R5,R3,R2", "BEQ  R1,R1,#0 (loop)",
         ]

         const pc = '$pc'.asInt()
         const instr = MNEMONICS[pc]
         const regWrite = '$reg_write'.asInt()
         const memWrite = '$mem_write'.asInt()
         const memRead  = '$mem_read'.asInt()
         const branch   = '$branch'.asInt()
         const branchTaken = '$branch_taken'.asInt()
         const zero = '$zero'.asInt()

         const hex = (v) => "0x" + (v & 0xff).toString(16).padStart(2, "0")
         const B = this._bubbles

         const setBubble = (b, text, active) => {
            b.txt.set({text})
            b.bg.set({opacity: active ? 0.35 : 0.1})
         }

         setBubble(B.pcAddr,    hex(pc), true)
         setBubble(B.instr,     "I" + pc, true)
         setBubble(B.reg1,      "#" + '$reg_read1_idx'.asInt(), true)
         setBubble(B.reg2,      "#" + '$reg_read2_idx'.asInt(), true)
         setBubble(B.regw,      regWrite ? ("#" + '$reg_write_idx'.asInt()) : "-", regWrite)
         setBubble(B.regData1,  hex('$read_data1'.asInt()), true)
         setBubble(B.regData2,  hex('$read_data2'.asInt()), true)
         setBubble(B.writeData, regWrite ? hex('$write_back_data'.asInt()) : "-", regWrite)
         setBubble(B.aluIn2,    hex('$alu_in2'.asInt()), true)
         setBubble(B.aluResult, hex('$alu_result'.asInt()), true)
         setBubble(B.zero,      zero ? "Z=1" : "Z=0", zero)
         setBubble(B.memAddr,   (memWrite || memRead) ? hex('$mem_addr'.asInt()) : "-", memWrite || memRead)
         setBubble(B.memWData,  memWrite ? hex('$mem_write_data'.asInt()) : "-", memWrite)
         setBubble(B.memRData,  memRead ? hex('$mem_read_data'.asInt()) : "-", memRead)
         setBubble(B.wbData,    regWrite ? hex('$write_back_data'.asInt()) : "-", regWrite)
         setBubble(B.pcPlus1,   hex('$pc_plus1'.asInt()), true)
         setBubble(B.pcMux,     "pc=" + pc, true)
         setBubble(B.control,   (regWrite?"RW ":"") + (memWrite?"MW ":"") + (memRead?"MR ":"") + (branch?"BR":""), regWrite||memWrite||memRead||branch)

         this._instrLabel.set({
            text: instr + (branchTaken ? "   <-- branch taken" : ""),
            fill: branchTaken ? "#c62828" : "#000"
         })
         this._statusLabel.set({
            text: "cycle=" + this.getCycle() + "  pc=" + pc + (branchTaken ? "  branch taken -> pc=0" : "")
         })

         return []
      }
\SV
   endmodule
