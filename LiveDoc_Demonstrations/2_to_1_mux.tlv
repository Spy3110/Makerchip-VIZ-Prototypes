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
         const REGION = [150, 238, 500, 358]   // page 3 crop; figure (0,0) = this rect's top-left
         const OR = "#ff7a00"
         const GATE_ON = "#ffd9b8"
         const ACTIVE_WIRE_WIDTH = 1.5

         // Pool positions (page 3, region above).
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
         // Label positions: D0, S, O/P, D1.
         const LABS = {
            l_d0: [0, 1], l_s: [2], l_y: [3], l_d1: [4, 5]
         }

         // Value bubbles live in box space; onReady moves them onto the figure via fig().
         const mk = (t) => new fabric.Text(t, {left: -100, top: -100, fontSize: 9, fontFamily: "monospace", fontWeight: "bold", fill: "#888888", backgroundColor: "#ffffff"})
         const b_d0 = mk("d0"), b_d1 = mk("d1"), b_s = mk("s"), b_sbar = mk("sbar"), b_a0 = mk("a0"), b_a1 = mk("a1"), b_y = mk("y")
         const status = new fabric.Text("loading diagram...", {left: 15, top: 8, fontSize: 11, fill: "#222222", fontFamily: "monospace"})

         // Group returned synchronously; named elements arrive in this.liveDocElements.
         // Live Doc draws the PDF's own copyright notice below the figure by default.
         const figure = this.global.pdf.extractToFabric(this, {url: PDF_URL}, {
            extract: {page: 3, select: {mode: "region", rect: REGION}, clip: true},
            build: {
               notice: "Figure from Multiplexer and Demultiplexer, Department of Physics, IIT Roorkee. Referenced at runtime, not copied.",
               primitives: PRIMS,
               labels: LABS,
               onReady: ({elements, fig, ext, notice}) => {
                 console.log("rights:", ext.rights, "notice drawn:", !!notice)
                  // Remember original styles so lit(false) can restore them.
                  Object.keys(PRIMS).forEach((k) => {
                     [].concat(elements[k]).forEach((o) => {
                        if (o) { o.__base = {stroke: o.stroke, sw: o.strokeWidth, fill: o.fill} }
                     })
                  })
                  // Anchors are page points measured from primitive bboxes; subtract the
                  // region corner to get figure coordinates, then fig() maps to box space.
                  const put = (obj, x, y) => {
                     const P = fig(x - REGION[0], y - REGION[1])
                     obj.set({left: P.x, top: P.y})
                     obj.setCoords()
                  }
                  put(b_d0, 190, 243)
                  put(b_d1, 190, 329)
                  put(b_s, 190, 288)
                  put(b_sbar, 288, 280)
                  put(b_a0, 364, 262)
                  put(b_a1, 364, 318)
                  put(b_y, 428, 282)
                  // Live Doc calls this.rerender() right after onReady.
               },
               onError: (e) => {
                  console.error("PDF extraction failed:", e)
                  this._err = "ERR: " + (e && e.message ? e.message : e) + "  "
               }
            }
         })
         figure.set({left: OFFX, top: OFFY})

         return {figure, status, b_d0, b_d1, b_s, b_sbar, b_a0, b_a1, b_y}
      },

      render() {
       try {
         const S = {
            d0:   '$d0'.asInt(0) == 1,
            d1:   '$d1'.asInt(0) == 1,
            s:    '$s'.asInt(0) == 1,
            sbar: '$sbar'.asInt(0) == 1,
            a0:   '$a0'.asInt(0) == 1,
            a1:   '$a1'.asInt(0) == 1,
            y:    '$y'.asInt(0) == 1
         }
         const OR = "#ff7a00"
         const GATE_ON = "#ffd9b8"
         const ACTIVE_WIRE_WIDTH = 1.5

         // ---- Box-space overlays (independent of the PDF) ----
         const O = this.getObjects()
         const upd = (obj, name, on) => obj.set({text: name + "=" + (on ? 1 : 0), fill: on ? OR : "#888888"})
         upd(O.b_d0, "D0", S.d0); upd(O.b_d1, "D1", S.d1); upd(O.b_s, "S", S.s)
         upd(O.b_sbar, "Sbar", S.sbar); upd(O.b_a0, "D0.Sbar", S.a0); upd(O.b_a1, "D1.S", S.a1); upd(O.b_y, "Y", S.y)
         O.status.set({text: (this._err || "") + "S=" + (S.s ? 1 : 0) + " selects " + (S.s ? "D1" : "D0") + "  ->  Y=" + (S.y ? 1 : 0)})

         // ---- PDF elements: render() also runs before the PDF arrives ----
         const E = this.liveDocElements
         if (!E) { return [] }

         const lit = (name, on) => {
            [].concat(E[name]).forEach((o) => {
               if (!o) { return }
               const b = o.__base
               if (b.sw > 0) { o.set({stroke: on ? OR : b.stroke, strokeWidth: on ? ACTIVE_WIRE_WIDTH : b.sw}) }
               else { o.set({fill: on ? GATE_ON : b.fill}) }
            })
         }
         const tx = (name, on) => {
            [].concat(E[name]).forEach((o) => {
               if (!o) { return }
               o.set({fill: on ? OR : "#111111", fontWeight: on ? "bold" : "normal"})
            })
         }

         lit("w_d0", S.d0); lit("w_d1", S.d1)
         lit("w_s", S.s); lit("w_s_g2", S.s)
         lit("w_sbar", S.sbar)
         lit("w_a0", S.a0); lit("w_a1", S.a1)
         lit("w_y", S.y)
         lit("g_and0", S.a0); lit("g_and1", S.a1); lit("g_or", S.y)
         tx("l_d0", S.d0); tx("l_d1", S.d1); tx("l_s", S.s); tx("l_y", S.y)
       } catch (e) {
         this.getObjects().status.set({text: "RENDER ERR: " + (e && e.message ? e.message : e)})
       }
         return []
      }
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
