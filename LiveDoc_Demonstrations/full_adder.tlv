\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;

   /* ---- Logic ----
   Change the inputs from here */
   $aa = 1'b0;
   $bb = 1'b1;
   $cin = 1'b1;
   $gg = $aa & $bb;
   $un1_cout = $cin & ($aa ^ $bb);
   $ss = $cin ^ ($aa ^ $bb);
   $cout = $gg | $un1_cout;

   \viz_js
      box: {left: 0, top: 0, width: 350, height: 200, fill: "#f8f8f8"},

      init() {
         let widgets = {}

         let figure = new fabric.Group([], {
            originX: "left", originY: "top", selectable: false, evented: false
         })
         widgets.figure = figure

         widgets.caption = new fabric.Text(
            "Harris & Harris Figure 4.8 — fulladder synthesized circuit",
            {left: 18, top: 8, fontSize: 10, fontFamily: "Roboto", fill: "#555"}
         )
         widgets.loading = new fabric.Text(
            "extracting figure...",
            {left: 18, top: 26, fontSize: 9, fontFamily: "Roboto", fill: "#666"}
         )
         widgets.status = new fabric.Text("", {
            left: 18, top: 286, fontSize: 8, fontFamily: "Roboto", fill: "#1565c0",
            selectable: false, evented: false
         })
         
          //change the URL here!!
         const PDF_URL = "https://pumps-sec-chorus-boxes.trycloudflare.com/page179.pdf"
         const OFFX = 20
         const OFFY = 36

         // ── DEBUG GRID (set to false once bubbles are positioned correctly) ──
         const SHOW_DEBUG_GRID = false
         let debugDots = []
         if (SHOW_DEBUG_GRID) {
            for (let gx = 0; gx <= 400; gx += 40) {
               for (let gy = 0; gy <= 150; gy += 40) {
                  debugDots.push(new fabric.Circle({
                     left: gx, top: gy, radius: 1.5, fill: "#00aaff",
                     originX: "center", originY: "center", visible: false
                  }))
                  debugDots.push(new fabric.Text(gx + "," + gy, {
                     left: gx + 3, top: gy + 3, fontSize: 6, fill: "#00aaff", visible: false
                  }))
               }
            }
         }
         //widgets.debugDots = debugDots

         // ── Bubble factory: dot + value label ──
         const mkBubble = (name) => ({
            dot: new fabric.Circle({
               left: 0, top: 0, radius: 6, fill: "#999",
               stroke: "#333", strokeWidth: 1, originX: "center", originY: "center", visible: false
            }),
            txt: new fabric.Text(name + "=?", {
               left: 0, top: 0, fontSize: 8, fontFamily: "monospace", fill: "#222", visible: false
            })
         })

         let bub = {
            aa:  mkBubble("a"),
            bb:  mkBubble("b"),
            cin: mkBubble("cin"),
            gg:  mkBubble("g"),
            ss:  mkBubble("s"),
            unc: mkBubble("uc"),
            co:  mkBubble("cout")
         }
         this._bub = bub

         // ── POSITIONS (placeholder — calibrate against the debug grid dots) ──
         const POS = {
            aa:  {x: 30,  y: 110},
            bb:  {x: 30,  y: 150},
            cin: {x: 21,  y: 70},
            gg:  {x: 155, y: 32},
            ss:  {x: 310, y: 45},
            unc: {x: 155, y: 155},
            co:  {x: 310, y: 120}
         }

         const place = (b, pos) => {
            b.dot.set({left: pos.x, top: pos.y, visible: true})
            b.txt.set({left: pos.x + 9, top: pos.y - 5, visible: true})
         }
         Object.keys(bub).forEach((k) => place(bub[k], POS[k]))

         this._ready = false
         this._state = null   // explicit — nothing to paint until render() runs once

         this._paint = () => {
            // Guard BOTH conditions: extraction must be done AND at least one
            // render() cycle must have populated _state. Without the second
            // check, the .then() callback below can call _paint() before any
            // cycle has run, reading undefined.aa and throwing mid-render —
            // which corrupts the Fabric group and cascades into
            // "this._objects[e].render is not a function" on every later frame.
            if (!this._ready || !this._state) { return }
            const S = this._state
            const ON = "#e8590c"
            const set1 = (b, v) => {
               b.dot.set({fill: v ? ON : "#999"})
               let name = b.txt.text.split("=")[0]
               b.txt.set({text: name + "=" + v, fill: v ? ON : "#222"})
            }
            set1(bub.aa,  S.aa)
            set1(bub.bb,  S.bb)
            set1(bub.cin, S.cin)
            set1(bub.gg,  S.gg)
            set1(bub.ss,  S.ss)
            set1(bub.unc, S.unc)
            set1(bub.co,  S.co)
            this.getCanvas().requestRenderAll()
         }

         this.global.pdf.buildFigure(fabric, {url: PDF_URL}, {
            page: 1,
            select: {mode: "region", rect: [90, 300, 500, 420], space: "device"},
            clip: true,
            left: OFFX,
            top: OFFY,
            into: figure
         }).then(() => {
            widgets.loading.set({visible: false})
            widgets.caption.set({fill: "#333"})
            if (SHOW_DEBUG_GRID) {
               debugDots.forEach((d) => d.set({visible: true}))
            }
            this._ready = true
            this._paint()   // safe no-op now if render() hasn't fired yet
            this.getCanvas().requestRenderAll()
         }).catch((e) => {
            console.error("PDF figure extraction failed:", e)
            widgets.loading.set({
               text: "PDF extraction failed (see console)",
               fill: "#c00"
            })
            widgets.status.set({text: "Check the PDF URL / CORS / tunnel"})
            this.getCanvas().requestRenderAll()
         })

         return Object.assign(
            widgets,
            {aa_dot: bub.aa.dot, aa_txt: bub.aa.txt},
            {bb_dot: bub.bb.dot, bb_txt: bub.bb.txt},
            {cin_dot: bub.cin.dot, cin_txt: bub.cin.txt},
            {gg_dot: bub.gg.dot, gg_txt: bub.gg.txt},
            {ss_dot: bub.ss.dot, ss_txt: bub.ss.txt},
            {unc_dot: bub.unc.dot, unc_txt: bub.unc.txt},
            {co_dot: bub.co.dot, co_txt: bub.co.txt},
            debugDots.reduce((acc, d, i) => { acc["dbg" + i] = d; return acc }, {})
         )
      },

      render() {
         this._state = {
            aa:  '$aa'.asInt(0),
            bb:  '$bb'.asInt(0),
            cin: '$cin'.asInt(0),
            gg:  '$gg'.asInt(0),
            ss:  '$ss'.asInt(0),
            unc: '$un1_cout'.asInt(0),
            co:  '$cout'.asInt(0)
         }
         this._paint()
         return []
      }

   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
