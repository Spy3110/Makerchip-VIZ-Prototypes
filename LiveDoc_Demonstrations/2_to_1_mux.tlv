\m5_TLV_version 1d: tl-x.org
\m5
   //experimenting with livedoc
   use(m5-1.0)
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;

   // Sweep all 8 input combinations; S changes every 4 cycles.
   $cnt[2:0] = $reset ? 3'd0 : >>1$cnt + 3'd1;
   $d0 = $cnt[0];
   $d1 = $cnt[1];
   $s  = $cnt[2];

   // 2-to-1 mux: Y = D0.S' + D1.S
   $sbar = ! $s;
   $a0 = $d0 && $sbar;
   $a1 = $d1 && $s;
   $y  = $a0 || $a1;

   // ---------- VIZ: figure fetched by reference from the PDF, recolored by index ----------
   \viz_js
      box: {left: 0, top: 0, width: 380, height: 190, fill: "#ffffff", stroke: "#cccccc", strokeWidth: 1},

      init() {
         const PDF_URL = "https://www.iitr.ac.in/Academics/static/Department/Physics/Electronics%20Laboratory/multiplexer_and_demultiplexer.pdf"
         const OFFX = 15, OFFY = 25
         const OR = "#ff7a00"
         const GATE_ON = "#ffd9b8"
         const ACTIVE_WIRE_WIDTH = 1.5

         // Primitive indices (page 3, region [150,238,500,358] device space).
         const PRIMS = {
            w_d0: [5, 12],
            w_d1: [21, 30],
            w_s: [18, 19],
            w_s_g2: [28, 29, 20, 27],
            w_sbar: [14, 17, 16, 6, 13],
            w_a0: [7, 31, 32, 35, 0],
            w_a1: [22, 33, 34, 36, 37, 1],
            w_y: [2, 38],
            g_and0: [8, 10],
            g_and1: [23, 25],
            g_or: [3]
         }
         // Label indices within the figure region: D0, S, O/P, D1.
         const LABS = {
            l_d0: [0, 1], l_s: [2], l_y: [3], l_d1: [4, 5]
         }

         let figure = new fabric.Group([], {originX: "left", originY: "top", selectable: false, evented: false})
         const mk = (t) => new fabric.Text(t, {left: -100, top: -100, fontSize: 9, fontFamily: "monospace", fontWeight: "bold", fill: "#888888", backgroundColor: "#ffffff"})
         let b_d0 = mk("d0"), b_d1 = mk("d1"), b_s = mk("s"), b_sbar = mk("sbar"), b_a0 = mk("a0"), b_a1 = mk("a1"), b_y = mk("y")
         let status = new fabric.Text("loading diagram...", {left: 15, top: 8, fontSize: 11, fill: "#222222", fontFamily: "monospace"})
         let credit = new fabric.Text("Diagram fetched at runtime from the PDF URL in the code (not copied into this file).", {left: 15, top: 178, fontSize: 6, fill: "#999999", fontFamily: "monospace"})

         this._ready = false
         this._state = null
         this._fig = figure
         this._bubbles = {}

         this._paint = () => {
            if (!this._ready || !this._state) { return }
            const S = this._state
            const E = this._el

            const lit = (name, on) => {
               [].concat(E[name]).forEach((o) => {
                  if (!o) { return }
                  const b = o.__base
                  if (b.sw > 0) { o.set({stroke: on ? OR : b.stroke, strokeWidth: on ? ACTIVE_WIRE_WIDTH : b.sw}) }
                  else { o.set({fill: on ? GATE_ON : b.fill}) }
                  o.set({dirty: true})
                  if (o.group) { o.group.set({dirty: true}) }
               })
            }
            const tx = (name, on) => {
               [].concat(E[name]).forEach((o) => {
                  if (!o) { return }
                  o.set({fill: on ? OR : "#111111", fontWeight: on ? "bold" : "normal", dirty: true})
                  if (o.group) { o.group.set({dirty: true}) }
               })
            }

            lit("w_d0", S.d0); lit("w_d1", S.d1)
            lit("w_s", S.s); lit("w_s_g2", S.s)
            lit("w_sbar", S.sbar)
            lit("w_a0", S.a0); lit("w_a1", S.a1)
            lit("w_y", S.y)
            lit("g_and0", S.a0); lit("g_and1", S.a1); lit("g_or", S.y)
            tx("l_d0", S.d0); tx("l_d1", S.d1); tx("l_s", S.s); tx("l_y", S.y)

            this._fig.set({dirty: true})
            this.getCanvas().requestRenderAll()
         }

         this.global.pdf.buildFigure(fabric, {url: PDF_URL}, {
            page: 3,
            select: {mode: "region", rect: [150, 238, 500, 358], space: "device"},
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
            // Bubble anchors, in device-space coordinates measured from primitive bboxes.
            const O = this.getObjects()
            // Anchors are device-space points measured from primitive bboxes; fig() takes figure space (origin at region top-left).
            const put = (obj, x, y) => { const P = res.fig(x - 150, y - 238); obj.set({left: P.x, top: P.y}); obj.setCoords() }
            put(O.b_d0, 190, 243)
            put(O.b_d1, 190, 329)
            put(O.b_s, 190, 288)
            put(O.b_sbar, 288, 280)
            put(O.b_a0, 364, 262)
            put(O.b_a1, 364, 318)
            put(O.b_y, 428, 282)
            this._ready = true
            this._paint()
         }).catch((e) => {
            console.error("PDF extraction failed:", e)
            this._err = "ERR: " + (e && e.message ? e.message : e)
         })

         return {figure: figure, status: status, credit: credit,
                 b_d0: b_d0, b_d1: b_d1, b_s: b_s, b_sbar: b_sbar, b_a0: b_a0, b_a1: b_a1, b_y: b_y}
      },

      render() {
       try {
         let S = {
            d0:   '$d0'.asInt(0) == 1,
            d1:   '$d1'.asInt(0) == 1,
            s:    '$s'.asInt(0) == 1,
            sbar: '$sbar'.asInt(0) == 1,
            a0:   '$a0'.asInt(0) == 1,
            a1:   '$a1'.asInt(0) == 1,
            y:    '$y'.asInt(0) == 1
         }
         this._state = S

         const O = this.getObjects()
         const upd = (obj, name, on) => obj.set({text: name + "=" + (on ? 1 : 0), fill: on ? "#ff7a00" : "#888888"})
         upd(O.b_d0, "D0", S.d0); upd(O.b_d1, "D1", S.d1); upd(O.b_s, "S", S.s)
         upd(O.b_sbar, "Sbar", S.sbar); upd(O.b_a0, "D0.Sbar", S.a0); upd(O.b_a1, "D1.S", S.a1); upd(O.b_y, "Y", S.y)
         O.status.set({text: (this._err || "") + "S=" + (S.s ? 1 : 0) + " selects " + (S.s ? "D1" : "D0") + "  ->  Y=" + (S.y ? 1 : 0)})

         this._paint()
       } catch (e) {
         this.getObjects().status.set({text: "RENDER ERR: " + (e && e.message ? e.message : e)})
       }
         return []
      }
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
