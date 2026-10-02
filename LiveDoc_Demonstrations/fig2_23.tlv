\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   //figure 2.23 from page 67 from Harris & Harris
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;

   $aa = $rand[0];
   $bb = $rand[1];
   $cc = $rand[2];

   $a_bar = ~$aa;
   $b_bar = ~$bb;
   $c_bar = ~$cc;

   $m1 = $a_bar & $b_bar & $c_bar;
   $m2 = $aa & $b_bar & $c_bar;
   $m3 = $aa & $b_bar & $cc;
   $yy = $m1 | $m2 | $m3;
   `BOGUS_USE($reset)
   `BOGUS_USE($yy)

   \viz_js
      box: {left: 0, top: 0, width: 250, height: 180, fill: "#ffffff"},

      init() {
         const PDF_URL = "https://vacations-luggage-keeps-rate.trycloudflare.com/page67.pdf"
         const ON = "#ff6600"
         const DX = -1.5, DY = -0.5        // shift ALL lines (figure units)
         const WIDTH = 1             // line thickness
         const ALIGN = false          // true = show every line, so you can align without waiting for signals
         
         // Segments in FIGURE space: [x1, y1, x2, y2]. Nudge these to align.
         const SEGS = {
            aa:    [[149,24,149,105], [149,72,263,72], [149,94,263,94]],
            bb:    [[185,24,185,105]],
            cc:    [[221,24,221,105], [221,103,263,103]],
            a_bar: [[168,38,168,105], [168,49,263,49]],
            b_bar: [[204,38,204,105], [204,54,263,54], [204,76,263,76], [204,99,263,99]],
            c_bar: [[240,38,240,105], [240,59,263,59], [240,80,263,80]],
            m1:    [[285,53.5,317,53.5]],
            m2:    [[285,76,317,76]],
            m3:    [[285,98.5,317,98.5]],
            yy:    [[303,130,303,135]]
         }

         let figure = new fabric.Group([], {
            originX: "left", originY: "top", selectable: false, evented: false
         })

         // Create ALL overlay lines now, hidden, parked off-screen.
         let out = {figure: figure}
         this._lines = {}
         Object.keys(SEGS).forEach((k) => {
            this._lines[k] = SEGS[k].map((s, i) => {
               let ln = new fabric.Line([0, 0, 1, 1], {
                  stroke: ON, strokeWidth: 1, visible: false,
                  selectable: false, evented: false
               })
               out[k + "_" + i] = ln
               return ln
            })
         })

         this._ready = false
         this._state = null

         this._paint = () => {
            if (!this._ready || !this._state) { return }
            Object.keys(this._lines).forEach((k) => {
               this._lines[k].forEach((ln) => { ln.set({visible: ALIGN || this._state[k], dirty: true}) })
            })
            this.getCanvas().requestRenderAll()
         }

         this.global.pdf.buildFigure(fabric, {url: PDF_URL}, {
            page: 1,
            select: {mode: "region", rect: [0, 80, 400, 220], space: "device"},
            clip: true, left: 10, top: 12, into: figure
         }).then((res) => {
            Object.keys(SEGS).forEach((k) => {
               SEGS[k].forEach((s, i) => {
                  const P1 = res.fig(s[0], s[1])
                  const P2 = res.fig(s[2], s[3])
                  this._lines[k][i].set({x1: P1.x + DX, y1: P1.y + DY, x2: P2.x + DX, y2: P2.y + DY})
                  this._lines[k][i].setCoords()
               })
            })
            this._ready = true
            this._paint()
         }).catch((e) => { console.error("PDF figure extraction failed:", e) })

         return out
      },

      render() {
         this._state = {
            aa: '$aa'.asInt(0) == 1, bb: '$bb'.asInt(0) == 1, cc: '$cc'.asInt(0) == 1,
            a_bar: '$a_bar'.asInt(0) == 1, b_bar: '$b_bar'.asInt(0) == 1, c_bar: '$c_bar'.asInt(0) == 1,
            m1: '$m1'.asInt(0) == 1, m2: '$m2'.asInt(0) == 1, m3: '$m3'.asInt(0) == 1,
            yy: '$yy'.asInt(0) == 1
         }
         this._paint()
         return []
      }
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
