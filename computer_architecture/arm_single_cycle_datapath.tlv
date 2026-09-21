\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;

   // ---------- Instruction sequencer: cycles through 6 test instructions ----------
   $idx[2:0] = $reset ? 3'd5 :
               (>>1$idx == 3'd5) ? 3'd0 :
                                   >>1$idx + 3'd1;

   // ---------- Tiny instruction ROM (real LEGv8 encodings) ----------
   $instr[31:0] =
      ($idx == 3'd0) ? 32'h8B020023 :   // ADD  X3, X1, X2
      ($idx == 3'd1) ? 32'hCB010044 :   // SUB  X4, X2, X1
      ($idx == 3'd2) ? 32'hF8400005 :   // LDUR X5, [X0, #0]
      ($idx == 3'd3) ? 32'hF8000003 :   // STUR X3, [X0, #0]
      ($idx == 3'd4) ? 32'hB4000041 :   // CBZ  X1, #2  (pretend zero, taken)
                       32'hB4000044;    // CBZ  X4, #2  (pretend non-zero, not taken)

   // Pretend ALU Zero output (stimulus): only entry 4 is a taken branch.
   $zero = ($idx == 3'd4);

   // ---------- Decode ----------
   $op11[10:0] = $instr[31:21];
   $is_add  = ($op11 == 11'b10001011000);
   $is_sub  = ($op11 == 11'b11001011000);
   $is_ldur = ($op11 == 11'b11111000010);
   $is_stur = ($op11 == 11'b11111000000);
   $is_cbz  = ($instr[31:24] == 8'b10110100);
   $is_r    = $is_add || $is_sub;

   // ---------- Control unit ----------
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
   $pcsrc = $branch && $zero;

   // ---------- VIZ: diagram fetched by reference + glow overlays ----------
   \viz_js
      box: {left: 0, top: 0, width: 480, height: 372, fill: "#ffffff", stroke: "#cccccc", strokeWidth: 1},

      init() {
         const PDF_URL = "https://controversial-ads-gentleman-workstation.trycloudflare.com/page361.pdf"
         const OFFX = 15, OFFY = 12
         const OR = "#ff7a00"
         const GLOW_W = 1.7

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
            b_alucl: [0],
            x_c18: [18],
            x_c50: [50],
            x_c56: [56]
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
         // Cyan (control) prims that get a dashed style.
         const DASHED = ["w_zero", "w_alucl_out", "w_aluop", "x_c18", "x_c50", "x_c56"]
         // Order of the 8 control outputs, top to bottom on the Control ellipse.
         const CTRL_NAMES = ["reg2loc", "branch", "memread", "memtoreg", "aluop", "memwrite", "alusrc", "regwrite"]

         let figure = new fabric.Group([], {originX: "left", originY: "top", selectable: false, evented: false})
         let ovl = new fabric.Group([], {originX: "left", originY: "top", selectable: false, evented: false})
         let status = new fabric.Text("loading diagram...", {left: 15, top: 332, fontSize: 11, fill: "#222222", fontFamily: "monospace"})
         let status2 = new fabric.Text("", {left: 15, top: 348, fontSize: 8, fill: "#555555", fontFamily: "monospace"})
         let credit = new fabric.Text("Diagram fetched at runtime from the PDF URL in the code (not copied into this file).", {left: 15, top: 362, fontSize: 6, fill: "#999999", fontFamily: "monospace"})

         this._ready = false
         this._state = null
         this._fig = figure
         this._ovl = ovl
         this._ov = {}

         // ---- Split an SVG path string into subpaths (M / L / C / Q / Z, absolute only) ----
         const parseSubpaths = (d) => {
            const toks = []
            let buf = ""
            for (let k = 0; k < d.length; k++) {
               const ch = d.charAt(k)
               const isLetter = (ch >= "A" && ch <= "Z") || (ch >= "a" && ch <= "z")
               if (isLetter) {
                  if (buf !== "") { toks.push(buf); buf = "" }
                  toks.push(ch)
               } else if (ch === " " || ch === ",") {
                  if (buf !== "") { toks.push(buf); buf = "" }
               } else if (ch === "-") {
                  if (buf !== "") { toks.push(buf); buf = "" }
                  buf = "-"
               } else {
                  buf = buf + ch
               }
            }
            if (buf !== "") { toks.push(buf) }

            const subs = []
            let cur = null
            let cmd = ""
            let i = 0
            const num = () => parseFloat(toks[i++])
            while (i < toks.length) {
               const t = toks[i]
               if (isNaN(parseFloat(t))) {
                  cmd = t
                  i++
                  if ((cmd === "Z" || cmd === "z") && cur && cur.pts.length > 0) { cur.pts.push(cur.pts[0]) }
                  continue
               }
               if (cmd === "M") {
                  const x = num(); const y = num()
                  cur = {pts: [[x, y]], curve: false}
                  subs.push(cur)
                  cmd = "L"
               } else if (cmd === "L" && cur) {
                  const x = num(); const y = num()
                  cur.pts.push([x, y])
               } else if (cmd === "C" && cur) {
                  num(); num(); num(); num()
                  const x = num(); const y = num()
                  cur.curve = true
                  cur.pts.push([x, y])
               } else if (cmd === "Q" && cur) {
                  num(); num()
                  const x = num(); const y = num()
                  cur.curve = true
                  cur.pts.push([x, y])
               } else {
                  i++
               }
            }
            return subs
         }

         // ---- Build a glow polyline (figure coords in, box coords out), centered on its geometry ----
         const mkGlow = (res, ptsFig, dashed) => {
            const pts = []
            let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
            ptsFig.forEach((p) => {
               const q = res.fig(p[0], p[1])
               pts.push({x: q.x, y: q.y})
               if (q.x < x0) { x0 = q.x }
               if (q.y < y0) { y0 = q.y }
               if (q.x > x1) { x1 = q.x }
               if (q.y > y1) { y1 = q.y }
            })
            const poly = new fabric.Polyline(pts, {
               fill: "transparent", stroke: OR, strokeWidth: GLOW_W,
               strokeLineJoin: "round",
               strokeDashArray: dashed ? [3, 2] : null,
               originX: "center", originY: "center",
               left: (x0 + x1) / 2, top: (y0 + y1) / 2,
               selectable: false, evented: false, visible: false
            })
            ovl.addWithUpdate(poly)
            return poly
         }

         this._paint = () => {
            if (!this._ready || !this._state) { return }
            const S = this._state
            const E = this._el
            const R = S.r, L = S.ld, ST = S.st, C = S.cb
            const usesRn = R || L || ST
            const usesImm = L || ST || C

            // Wires: recolor + thicken, keeping the line centered on its original position.
            const lit = (name, on) => {
               [].concat(E[name]).forEach((o) => {
                  if (!o) { return }
                  const b = o.__base
                  if (b.sw > 0) {
                     const w = on ? Math.max(GLOW_W, b.sw + 0.9) : b.sw
                     const d = w - b.sw
                     o.set({stroke: on ? OR : b.stroke, strokeWidth: w, left: b.left - d / 2, top: b.top - d / 2})
                  } else {
                     o.set({fill: on ? OR : b.fill})
                  }
                  o.set({dirty: true})
                  if (o.group) { o.group.set({dirty: true}) }
               })
            }
            // Labels: mode 1 = active (orange bold), 0 = normal, -1 = dimmed
            const tx = (name, mode) => {
               [].concat(E[name]).forEach((o) => {
                  if (!o) { return }
                  o.set({fill: mode > 0 ? OR : (mode < 0 ? "#b0b0b0" : "#111111"),
                         fontWeight: mode > 0 ? "bold" : "normal", dirty: true})
                  if (o.group) { o.group.set({dirty: true}) }
               })
            }
            // Overlay polylines (control wires, extra segment)
            const ov = (key, on) => {
               if (this._ov[key]) { this._ov[key].set({visible: on, dirty: true}) }
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
            ov("ex1", ST || C)
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
            // Control signal names + control wires light up when asserted
            tx("c_reg2loc", S.reg2loc ? 1 : 0); tx("c_branch", S.branch ? 1 : 0)
            tx("c_memread", S.memread ? 1 : 0); tx("c_memtoreg", S.memtoreg ? 1 : 0)
            tx("c_aluop", 1); tx("c_memwrite", S.memwrite ? 1 : 0)
            tx("c_alusrc", S.alusrc ? 1 : 0); tx("c_regwrite", S.regwrite ? 1 : 0)
            ov("reg2loc", S.reg2loc); ov("branch", S.branch); ov("memread", S.memread)
            ov("memtoreg", S.memtoreg); ov("memwrite", S.memwrite); ov("alusrc", S.alusrc)
            ov("regwrite", S.regwrite)

            this._fig.set({dirty: true})
            this._ovl.set({dirty: true})
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

            // Control lines become dashed so they read differently from data wires.
            DASHED.forEach((k) => {
               [].concat(this._el[k]).forEach((o) => {
                  if (o) { o.set({strokeDashArray: [3, 2], dirty: true}) }
               })
            })
            // Remember original look and position of every named primitive.
            Object.keys(PRIMS).forEach((k) => {
               [].concat(this._el[k]).forEach((o) => {
                  if (o) { o.__base = {stroke: o.stroke, sw: o.strokeWidth, fill: o.fill, left: o.left, top: o.top} }
               })
            })

            try {
               // Extra segment: Instruction[4-0] bus from x=111 to the Reg2Loc mux branch point.
               this._ov.ex1 = mkGlow(res, [[111, 200.8], [152.3, 200.8]], false)

               // Find the 8 control wires: cyan subpaths that touch the Control ellipse.
               const CYAN = "#00b9f2"
               const near = (pt) => pt[0] >= 186 && pt[0] <= 197 && pt[1] >= 70 && pt[1] <= 150
               const r1 = (v) => Math.round(v * 10) / 10
               const found = []
               const all = []
               res.ext.primitives.forEach((p, pi) => {
                  if (p.stroke !== CYAN || !p.d || pi === 0 || pi === 54) { return }
                  parseSubpaths(p.d).forEach((sp) => {
                     if (sp.pts.length < 2) { return }
                     const a = sp.pts[0]
                     const z = sp.pts[sp.pts.length - 1]
                     all.push([pi, sp.curve ? "curve" : "line", sp.pts.length, r1(a[0]), r1(a[1]), r1(z[0]), r1(z[1])])
                     if (sp.curve) { return }
                     if (near(a)) { found.push({prim: pi, pts: sp.pts, y: a[1]}) }
                     else if (near(z)) { found.push({prim: pi, pts: sp.pts.slice().reverse(), y: z[1]}) }
                  })
               })
               found.sort((m, n) => m.y - n.y)

               if (found.length === 8 && found[4].prim === 55) {
                  CTRL_NAMES.forEach((nm, k) => {
                     if (nm !== "aluop") { this._ov[nm] = mkGlow(res, found[k].pts, true) }
                  })
                  credit.set({text: "control-wire overlay: OK (8/8 found). Diagram fetched at runtime from the PDF URL (not copied here)."})
               } else {
                  console.log("CTRL_MAP_FAILED found=" + found.length + " all_cyan_subpaths=" + JSON.stringify(all))
                  credit.set({text: "control-wire overlay: FAILED (found " + found.length + "/8), see console for CTRL_MAP_FAILED"})
               }
            } catch (e) {
               console.error("overlay setup error:", e)
               credit.set({text: "overlay setup error: " + e.message})
            }

            this._ready = true
            this._paint()
         }).catch((e) => {
            console.error("PDF extraction failed:", e)
         })

         return {figure: figure, ovl: ovl, status: status, status2: status2, credit: credit}
      },

      render() {
         const NAMES = ["ADD X3,X1,X2  (R-type)", "SUB X4,X2,X1  (R-type)", "LDUR X5,[X0,#0]  (load)",
                        "STUR X3,[X0,#0]  (store)", "CBZ X1,#2  (branch TAKEN)", "CBZ X4,#2  (branch not taken)"]
         let idx = '$idx'.asInt(0)
         let S = {
            r: '$is_r'.asInt(0) == 1,
            ld: '$is_ldur'.asInt(0) == 1,
            st: '$is_stur'.asInt(0) == 1,
            cb: '$is_cbz'.asInt(0) == 1,
            reg2loc: '$reg2loc'.asInt(0) == 1,
            alusrc: '$alusrc'.asInt(0) == 1,
            memtoreg: '$memtoreg'.asInt(0) == 1,
            regwrite: '$regwrite'.asInt(0) == 1,
            memread: '$memread'.asInt(0) == 1,
            memwrite: '$memwrite'.asInt(0) == 1,
            branch: '$branch'.asInt(0) == 1,
            pcsrc: '$pcsrc'.asInt(0) == 1
         }
         let aluop = '$aluop'.asInt(0)
         let zero = '$zero'.asInt(0)
         this._state = S

         const b = (v) => v ? 1 : 0
         this.getObjects().status.set({text: NAMES[Math.min(idx, 5)]})
         this.getObjects().status2.set({text:
            "Reg2Loc=" + b(S.reg2loc) + " ALUSrc=" + b(S.alusrc) + " MemtoReg=" + b(S.memtoreg) +
            " RegWrite=" + b(S.regwrite) + " MemRead=" + b(S.memread) + " MemWrite=" + b(S.memwrite) +
            " Branch=" + b(S.branch) + " ALUOp=" + aluop.toString(2).padStart(2, "0") +
            " Zero=" + zero + " PCSrc=" + b(S.pcsrc)})
         this._paint()
         return []
      }
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
