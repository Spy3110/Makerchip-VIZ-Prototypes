\m5_TLV_version 1d: tl-x.org
\m5
   /*
   1-BIT ALU...
   */
\SV
   m5_makerchip_module  
\TLV
   $reset = *reset;
   `BOGUS_USE($reset)
   
   // Inputs
   $aa       = $rand[0];
   $bb       = $rand[1];
   $ainvert  = $rand[2];
   $binvert  = $rand[3];
   $carry_in = $rand[3]; // intentionally same as $binvert (two's complement subtraction)
   $operation[1:0] = $rand[5:4];
   
   // Input muxes (invert if needed)
   $a_mux = $ainvert ? !$aa : $aa;
   $b_mux = $binvert ? !$bb : $bb;
   
   // Operations
   $and      = $a_mux & $b_mux;
   $or       = $a_mux | $b_mux;  // a OR b
   $sum      = $a_mux ^ $b_mux ^ $carry_in;
   $carry_out = ($a_mux & $b_mux) | ($carry_in & ($a_mux ^ $b_mux));
   `BOGUS_USE($carry_out)
   
   // Output mux
   $result = ($operation == 2'b00) ? $and :
             ($operation == 2'b01) ? $or  :
             ($operation == 2'b10) ? $sum :
             1'b0;
   `BOGUS_USE($result)
   
   //------------THE VIZ SECTION------------
   \viz_js
      box: {width: 600, height: 340, fill: "#fff4ec", stroke: "#e8b89a", strokeWidth: 2, rx: 8, ry: 8},
      
      init() {
         let o = {};
         
         // ── Title ──
         o.title = new fabric.Text("1-Bit ALU", {
            left: 250, top: 10,
            fontSize: 15, fill: "#b05020",
            fontFamily: "monospace", fontWeight: "bold"
         });

         // ── Helper: draw an AND gate (D-shape) via SVG path ──
         // origin = top-left of bounding box, w x h
         const andGatePath = (x, y, w, h) => {
            let hw = h / 2;
            return new fabric.Path(
               `M ${x} ${y} L ${x + w * 0.5} ${y} Q ${x + w} ${y} ${x + w} ${y + hw} Q ${x + w} ${y + h} ${x + w * 0.5} ${y + h} L ${x} ${y + h} Z`,
               {fill: "#fde8d8", stroke: "#c0603a", strokeWidth: 2}
            );
         };

         // ── Helper: draw an OR gate via SVG path ──
         const orGatePath = (x, y, w, h) => {
            let hw = h / 2;
            return new fabric.Path(
               `M ${x} ${y} Q ${x + w * 0.4} ${y} ${x + w} ${y + hw} Q ${x + w * 0.4} ${y + h} ${x} ${y + h} Q ${x + w * 0.3} ${y + hw} ${x} ${y} Z`,
               {fill: "#fde8d8", stroke: "#c0603a", strokeWidth: 2}
            );
         };

         // ── Helper: MUX box ──
         const muxBox = (x, y, w, h, label) => {
            let grp = {};
            grp.rect = new fabric.Rect({left: x, top: y, width: w, height: h,
               fill: "#fce4cf", stroke: "#c0603a", strokeWidth: 2, rx: 4});
            grp.lbl  = new fabric.Text(label, {left: x + 4, top: y + h/2 - 7,
               fontSize: 11, fill: "#7a2e00", fontFamily: "monospace"});
            return grp;
         };

         // ── Helper: full adder box ──
         const faBox = (x, y, w, h) => {
            let grp = {};
            grp.rect = new fabric.Rect({left: x, top: y, width: w, height: h,
               fill: "#fce4cf", stroke: "#5050c0", strokeWidth: 2, rx: 4});
            grp.lbl  = new fabric.Text("+", {left: x + w/2 - 5, top: y + h/2 - 9,
               fontSize: 18, fill: "#3030a0", fontFamily: "monospace", fontWeight: "bold"});
            return grp;
         };

         // ══════════════════════════════════════
         //   LAYOUT (all X/Y coords)
         // ══════════════════════════════════════
         
         // A mux  — left side top
         let amux = muxBox(50, 50, 44, 60, "MUX\n A");
         o.amux_rect = amux.rect;
         o.amux_lbl  = amux.lbl;

         // B mux  — left side bottom
         let bmux = muxBox(50, 220, 44, 60, "MUX\n B");
         o.bmux_rect = bmux.rect;
         o.bmux_lbl  = bmux.lbl;

         // AND gate
         o.and_gate = andGatePath(180, 80, 60, 44);

         // OR gate
         o.or_gate  = orGatePath(180, 155, 60, 44);

         // Full adder box
         let fa = faBox(180, 225, 60, 44);
         o.fa_rect = fa.rect;
         o.fa_lbl  = fa.lbl;

         // Output MUX
         let omux = muxBox(330, 100, 44, 140, "");
         o.omux_rect = omux.rect;
         // "0 / 1 / 2" labels inside output mux
         o.omux_0 = new fabric.Text("00", {left: 340, top: 115, fontSize: 11, fill: "#7a2e00", fontFamily: "monospace"});
         o.omux_1 = new fabric.Text("01", {left: 340, top: 162, fontSize: 11, fill: "#7a2e00", fontFamily: "monospace"});
         o.omux_2 = new fabric.Text("10", {left: 340, top: 208, fontSize: 11, fill: "#7a2e00", fontFamily: "monospace"});

         // ── Wire helper: Manhattan polyline (horizontal then vertical then horizontal) ──
         const mwire = (pts) => new fabric.Polyline(
            pts.map(([x,y]) => ({x, y})),
            {stroke: "#cccccc", strokeWidth: 2, fill: "transparent"}
         );

         // ── Wires: A and B inputs to their muxes ──
         // A → A_mux (straight horizontal)
         o.w_a_to_amux = mwire([[20,80],[50,80]]);
         // B → B_mux (straight horizontal)
         o.w_b_to_bmux = mwire([[20,250],[50,250]]);

         // ── Bus lines coming out of A_mux (right edge at x=74) ──
         // A_mux output splits into 3: use a vertical bus at x=100,
         // then branch right to each gate
         //   A_mux exits at (74, 80) — mid of mux
         //   AND top input  at (160, 92)
         //   OR  top input  at (160, 168)
         //   FA  top input  at (160, 232)
         o.w_amux_bus  = mwire([[94,80],[120,80],[120,232]]);        // vertical bus
         o.w_amux_and  = mwire([[120,92],[180,92]]);                 // branch → AND
         o.w_amux_or   = mwire([[120,168],[186,168]]);               // branch → OR
         o.w_amux_fa   = mwire([[120,232],[180,232]]);               // branch → FA

         // ── Bus lines coming out of B_mux (right edge at x=74) ──
         // B_mux exits at (74, 230)
         //   AND bottom input at (160, 112)
         //   OR  bottom input at (160, 188)
         //   FA  bottom input at (160, 252)
         o.w_bmux_bus  = mwire([[94,252],[130,252],[130,112]]);      // vertical bus
         o.w_bmux_and  = mwire([[130,112],[180,112]]);               // branch → AND
         o.w_bmux_or   = mwire([[130,188],[185,188]]);               // branch → OR
         o.w_bmux_fa   = mwire([[130,252],[180,252]]);               // branch → FA

         // ── Gate outputs → output MUX (right side) ──
         // AND output at (220,102) → omux slot 0 at (310,125)
         o.w_and_omux  = mwire([[240,102],[265,102],[265,125],[330,125]]);
         // OR  output at (220,177) → omux slot 1 at (310,170)
         o.w_or_omux   = mwire([[240,177],[265,177],[265,170],[330,170]]);
         // FA  output at (220,247) → omux slot 2 at (310,215)
         o.w_fa_omux   = mwire([[240,247],[265,247],[265,215],[330,215]]);
         
         //the stupid carry_in wire manually added damnnit
         o.w_cin_bus  = mwire([[230,227],[230,200],[300,200],[300,70]]); //changed

         // CarryOut downward from FA bottom
         o.w_carry_out = mwire([[230,269],[230,310]]);
         // Result out from omux right edge
         o.w_result    = mwire([[374,170],[450,170]]);

         // ── Input/Output Labels ──
         o.lbl_a        = new fabric.Text("A",        {left: 10,   top: 72,  fontSize: 12, fill: "#333", fontFamily: "monospace", fontWeight: "bold"});
         o.lbl_b        = new fabric.Text("B",        {left: 10,   top: 242, fontSize: 12, fill: "#333", fontFamily: "monospace", fontWeight: "bold"});
         o.lbl_ainv     = new fabric.Text("Ainvert",  {left: 60,  top: 15,  fontSize: 10, fill: "#5050c0", fontFamily: "monospace"});
         o.lbl_binv     = new fabric.Text("Binvert", {left: 60, top: 310, fontSize: 10, fill: "#5050c0", fontFamily: "monospace"});
         o.lbl_cin      = new fabric.Text("CarryIn", {left: 280, top: 55, fontSize: 10, fill: "#5050c0", fontFamily: "monospace"}); //changed
         o.lbl_result   = new fabric.Text("\u2192 Result", {left: 460, top: 163, fontSize: 12, fill: "#333", fontFamily: "monospace", fontWeight: "bold"});
         o.lbl_cout     = new fabric.Text("CarryOut", {left: 210, top: 315, fontSize: 10, fill: "#333", fontFamily: "monospace"});
         o.lbl_and_gate = new fabric.Text("AND",      {left: 190, top: 130, fontSize: 9,  fill: "#c0603a", fontFamily: "monospace"});
         o.lbl_or_gate  = new fabric.Text("OR",       {left: 190, top: 204, fontSize: 9,  fill: "#c0603a", fontFamily: "monospace"});

         //Ainvert, Binvert INPUTS─
         o.w_ainvert_ctrl = mwire([[80, 30],[80, 50]]);
         o.w_binvert_ctrl = mwire([[80, 280],[80, 310]]);

         // ── Value bubbles (show live signal values) ──
         const bubble = (x, y) => new fabric.Circle({left: x, top: y, radius: 9,
            fill: "#ffffff", stroke: "#aaaaaa", strokeWidth: 1});
         const bubbleTxt = (x, y) => new fabric.Text("?", {left: x, top: y,
            fontSize: 10, fill: "#333333", fontFamily: "monospace"});

         // main signal bubbles
         o.val_a    = bubble(25,   85);   o.vt_a    = bubbleTxt(31,   88);
         o.val_b    = bubble(25,   225);  o.vt_b    = bubbleTxt(31,   229);
         o.val_amux = bubble(100,  55);   o.vt_amux = bubbleTxt(106,  58);
         o.val_bmux = bubble(100,  255);  o.vt_bmux = bubbleTxt(106,  258);
         o.val_and  = bubble(240, 80);   o.vt_and  = bubbleTxt(246, 83);
         o.val_or   = bubble(240, 155);  o.vt_or   = bubbleTxt(246, 158);
         o.val_sum  = bubble(243, 225);  o.vt_sum  = bubbleTxt(249, 228);
         o.val_res  = bubble(440, 160);  o.vt_res  = bubbleTxt(446, 163);
         o.val_cout = bubble(200, 272);  o.vt_cout = bubbleTxt(206, 275);

         // ── Ainvert bubble (above A_mux) ──
         o.val_ainv = bubble(55, 30);
         o.vt_ainv  = bubbleTxt(61, 33);

         // ── Binvert bubble (below B_mux) ──
         o.val_binv = bubble(55, 285);
         o.vt_binv  = bubbleTxt(61, 288);

         // ── Operation display box — prominent, top right ──
         o.op_box = new fabric.Rect({
            left: 390, top: 50, width: 160, height: 60,
            fill: "#fce4cf", stroke: "#c0603a", strokeWidth: 2, rx: 6
         });
         o.lbl_op = new fabric.Text("Operation:", {
            left: 398, top: 56, fontSize: 11, fill: "#7a2e00", fontFamily: "monospace"
         });
         o.op_bits = new fabric.Text("op = --", {
            left: 398, top: 72, fontSize: 13, fill: "#b05020", fontFamily: "monospace", fontWeight: "bold"
         });
         o.op_name = new fabric.Text("( -- )", {
            left: 398, top: 90, fontSize: 13, fill: "#5050c0", fontFamily: "monospace", fontWeight: "bold"
         });

         return o;
      },

      render() {
         let o = this.getObjects();

         // Read signals
         let aa        = '$aa'.asInt();
         let bb        = '$bb'.asInt();
         let ainvert   = '$ainvert'.asInt();
         let binvert   = '$binvert'.asInt();
         let carry_in  = '$carry_in'.asInt(); //changed
         let a_mux     = '$a_mux'.asInt();
         let b_mux     = '$b_mux'.asInt();
         let and_val   = '$and'.asInt();
         let or_val    = '$or'.asInt();
         let sum_val   = '$sum'.asInt();
         let carry_out = '$carry_out'.asInt();
         let result    = '$result'.asInt();
         let operation = '$operation'.asInt();

         // Wire color helper: hot = signal is 1
         const hot  = "#e05010";
         const cold = "#cccccc";
         const wire = (v) => isNaN(v) ? "#aaaaaa" : (v ? hot : cold);

         // Update wires
         o.w_a_to_amux.set({stroke: wire(aa)});
         o.w_b_to_bmux.set({stroke: wire(bb)});
         // A_mux bus + branches
         o.w_amux_bus.set({stroke: wire(a_mux)});
         o.w_amux_and.set({stroke: wire(a_mux)});
         o.w_amux_or.set({stroke: wire(a_mux)});
         o.w_amux_fa.set({stroke: wire(a_mux)});
         // B_mux bus + branches
         o.w_bmux_bus.set({stroke: wire(b_mux)});
         o.w_bmux_and.set({stroke: wire(b_mux)});
         o.w_bmux_or.set({stroke: wire(b_mux)});
         o.w_bmux_fa.set({stroke: wire(b_mux)});
         // Gate → output mux
         o.w_and_omux.set({stroke: wire(and_val)});
         o.w_or_omux.set({stroke: wire(or_val)});
         o.w_fa_omux.set({stroke: wire(sum_val)});
         o.w_result.set({stroke: wire(result)});
         o.w_carry_out.set({stroke: wire(carry_out)});
         o.w_cin_bus.set({stroke: wire(carry_in)}); //changed

         // Gate highlight: glow orange if output is 1
         const gateColor = (v) => isNaN(v) ? "#fde8d8" : (v ? "#ffc09a" : "#fde8d8");
         o.and_gate.set({fill: gateColor(and_val)});
         o.or_gate.set({fill:  gateColor(or_val)});
         o.fa_rect.set({fill:  gateColor(sum_val)});

         // MUX highlight: glow if inverting
         o.amux_rect.set({fill: ainvert ? "#ffc09a" : "#fce4cf"});
         o.bmux_rect.set({fill: binvert ? "#ffc09a" : "#fce4cf"});

         // Output MUX highlight selected slot
         o.omux_0.set({fill: operation === 0 ? hot : "#7a2e00"});
         o.omux_1.set({fill: operation === 1 ? hot : "#7a2e00"});
         o.omux_2.set({fill: operation === 2 ? hot : "#7a2e00"});

         // Value bubbles helper
         const setVal = (bubble, txt, v) => {
            let s = isNaN(v) ? "X" : v.toString();
            bubble.set({fill: v === 1 ? "#ffc09a" : "#ffffff"});
            txt.set({text: s});
         };

         setVal(o.val_a,    o.vt_a,    aa);
         setVal(o.val_b,    o.vt_b,    bb);
         setVal(o.val_amux, o.vt_amux, a_mux);
         setVal(o.val_bmux, o.vt_bmux, b_mux);
         setVal(o.val_and,  o.vt_and,  and_val);
         setVal(o.val_or,   o.vt_or,   or_val);
         setVal(o.val_sum,  o.vt_sum,  sum_val);
         setVal(o.val_res,  o.vt_res,  result);
         setVal(o.val_cout, o.vt_cout, carry_out);

         // ── Ainvert and Binvert control bubbles ──
         setVal(o.val_ainv, o.vt_ainv, ainvert);
         setVal(o.val_binv, o.vt_binv, binvert);
         // color the control wires too
         o.w_ainvert_ctrl.set({stroke: wire(ainvert)});
         o.w_binvert_ctrl.set({stroke: wire(binvert)});

         // ── Operation display box (prominent, top right) ──
         const opBits  = ["00", "01", "10", "11"];
         const opNames = ["AND", "OR", "ADD/SUB", "???"];
         if (isNaN(operation)) {
            o.op_bits.set({text: "op = ??"});
            o.op_name.set({text: "( ? )"});
         } else {
            o.op_bits.set({text: "op = " + opBits[operation]});
            o.op_name.set({text: "( " + opNames[operation] + " )"});
         }
      }

   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
