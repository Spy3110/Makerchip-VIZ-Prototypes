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
         //change the URL here!!
         const PDF_URL = "https://asks-handle-blacks-reno.trycloudflare.com/page179.pdf"
         const OFFX = 0
         const OFFY = 36

         // extractToFabric returns the (initially empty) group synchronously and fills it
         // when the PDF arrives. Live Doc shows its own "Loading PDF..." text meanwhile,
         // and draws the document's copyright notice below the figure by default.
         const figure = this.global.pdf.extractToFabric(this, {url: PDF_URL}, {
            extract: {
               page: 1,
               select: {mode: "region", rect: [90, 300, 500, 420]},
               clip: true
            },
            build: {
               onError: (e) => {
                  this.obj.status.set({text: "PDF extraction failed - check the PDF URL / CORS / tunnel"})
               }
            }
         })
         figure.set({left: OFFX, top: OFFY})   // figure (0,0) lands at box (OFFX, OFFY)

         const widgets = {figure}

         widgets.caption = new fabric.Text(
            "Harris & Harris Figure 4.8 — fulladder synthesized circuit",
            {left: 18, top: 8, fontSize: 10, fontFamily: "Roboto", fill: "#333"}
         )
         widgets.status = new fabric.Text("", {
            left: 18, top: 286, fontSize: 8, fontFamily: "Roboto", fill: "#1565c0",
            selectable: false, evented: false
         })

         // ── DEBUG GRID (set to false once bubbles are positioned correctly) ──
         const SHOW_DEBUG_GRID = false
         if (SHOW_DEBUG_GRID) {
            let n = 0
            for (let gx = 0; gx <= 400; gx += 40) {
               for (let gy = 0; gy <= 150; gy += 40) {
                  widgets["dbg_dot" + n] = new fabric.Circle({
                     left: gx, top: gy, radius: 1.5, fill: "#00aaff",
                     originX: "center", originY: "center"
                  })
                  widgets["dbg_txt" + n] = new fabric.Text(gx + "," + gy, {
                     left: gx + 3, top: gy + 3, fontSize: 6, fill: "#00aaff"
                  })
                  n++
               }
            }
         }

         // ── Value bubbles (box space): dot + label per signal ──
         // POS is in box coordinates — calibrate against the debug grid.
         const POS = {
            aa:  {x: 30,  y: 110, name: "a"},
            bb:  {x: 30,  y: 150, name: "b"},
            cin: {x: 21,  y: 70,  name: "cin"},
            gg:  {x: 155, y: 32,  name: "g"},
            ss:  {x: 310, y: 45,  name: "s"},
            unc: {x: 155, y: 155, name: "uc"},
            co:  {x: 310, y: 120, name: "cout"}
         }
         Object.keys(POS).forEach((k) => {
            const p = POS[k]
            widgets[k + "_dot"] = new fabric.Circle({
               left: p.x, top: p.y, radius: 6, fill: "#999",
               stroke: "#333", strokeWidth: 1, originX: "center", originY: "center"
            })
            widgets[k + "_txt"] = new fabric.Text(p.name + "=?", {
               left: p.x + 9, top: p.y - 5, fontSize: 8, fontFamily: "monospace", fill: "#222"
            })
         })

         return widgets
      },

      render() {
         // The bubbles don't depend on the PDF, so no readiness check is needed here.
         const o = this.getObjects()
         const ON = "#e8590c"
         const NAMES = {aa: "a", bb: "b", cin: "cin", gg: "g", ss: "s", unc: "uc", co: "cout"}
         const V = {
            aa:  '$aa'.asInt(0),
            bb:  '$bb'.asInt(0),
            cin: '$cin'.asInt(0),
            gg:  '$gg'.asInt(0),
            ss:  '$ss'.asInt(0),
            unc: '$un1_cout'.asInt(0),
            co:  '$cout'.asInt(0)
         }
         Object.keys(NAMES).forEach((k) => {
            const v = V[k]
            o[k + "_dot"].set({fill: v ? ON : "#999"})
            o[k + "_txt"].set({text: NAMES[k] + "=" + v, fill: v ? ON : "#222"})
         })
         return []
      }

   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
