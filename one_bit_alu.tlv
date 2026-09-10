\m5_TLV_version 1d: tl-x.org
\m5
   /*
   1-BIT ALU WITH TOP-DOWN CONTROL ROUTING
   */
\SV
   m5_makerchip_module  
\TLV
   $reset = *reset;
   `BOGUS_USE($reset)
   
   // Try changing these inputs!
   $aa       = 1'b0;
   $bb       = 1'b1;
   $ainvert  = $rand[2];
   $binvert  = $rand[3];
   $carry_in = $rand[3]; // intentionally same as $binvert (two's complement subtraction)
   $operation[1:0] = $rand[5:4];
   
   // Input muxes (invert if needed)
   $a_mux = $ainvert ? !$aa : $aa;
   $b_mux = $binvert ? !$bb : $bb;
   
   // Operations
   $and      = $a_mux & $b_mux;
   $or       = $a_mux | $b_mux;  
   $sum      = $a_mux ^ $b_mux ^ $carry_in;
   $carry_out = ($a_mux & $b_mux) | ($carry_in & ($a_mux ^ $b_mux));
   `BOGUS_USE($carry_out)
   
   // Output mux (Supports 4th operation: Pass-B)
   $result = ($operation == 2'b00) ? $and :
             ($operation == 2'b01) ? $or  :
             ($operation == 2'b10) ? $sum :
                                     $bb; // 2'b11: Pass-B
   `BOGUS_USE($result)
   
   //------------THE VIZ SECTION------------
   \viz_js
      box: {width: 620, height: 380, fill: "#fff4ec", stroke: "#e8b89a", strokeWidth: 2, rx: 8, ry: 8},
      
      init() {
         let o = {};
         
         // ── Title ──
         o.title = new fabric.Text("1-Bit ALU", {
            left: 250, top: 10,
            fontSize: 15, fill: "#b05020",
            fontFamily: "monospace", fontWeight: "bold"
         });

         // ── Helper: Draw an AND gate (D-shape) ──
         const andGatePath = (x, y, w, h) => {
            let hw = h / 2;
            return new fabric.Path(
               `M ${x} ${y} L ${x + w * 0.5} ${y} Q ${x + w} ${y} ${x + w} ${y + hw} Q ${x + w} ${y + h} ${x + w * 0.5} ${y + h} L ${x} ${y + h} Z`,
               {fill: "#fde8d8", stroke: "#c0603a", strokeWidth: 2}
            );
         };

         // ── Helper: Draw an OR gate ──
         const orGatePath = (x, y, w, h) => {
            let hw = h / 2;
            return new fabric.Path(
               `M ${x} ${y} Q ${x + w * 0.4} ${y} ${x + w} ${y + hw} Q ${x + w * 0.4} ${y + h} ${x} ${y + h} Q ${x + w * 0.3} ${y + hw} ${x} ${y} Z`,
               {fill: "#fde8d8", stroke: "#c0603a", strokeWidth: 2}
            );
         };

         // ── Helper: Draw a NOT gate (Triangle + Bubble) ──
         const notGatePath = (x, y) => {
            return new fabric.Path(
               `M ${x} ${y} L ${x} ${y+14} L ${x+12} ${y+7} Z M ${x+12} ${y+7} a 2.5 2.5 0 1 0 5 0 a 2.5 2.5 0 1 0 -5 0`,
               {fill: "#fde8d8", stroke: "#c0603a", strokeWidth: 2}
            );
         };

         // ── Helper: Trapezoidal MUX Shape ──
         const muxBox = (x, y, w, h) => {
            let inset = h * 0.12;
            return new fabric.Path(
               `M ${x} ${y} L ${x} ${y + h} L ${x + w} ${y + h - inset} L ${x + w} ${y + inset} Z`,
               {fill: "#fce4cf", stroke: "#c0603a", strokeWidth: 2}
            );
         };

         // ── Helper: Full Adder Box ──
         const faBox = (x, y, w, h) => {
            let grp = {};
            grp.rect = new fabric.Rect({left: x, top: y, width: w, height: h,
               fill: "#fce4cf", stroke: "#5050c0", strokeWidth: 2, rx: 4});
            grp.lbl  = new fabric.Text("+", {left: x + w/2 - 5, top: y + h/2 - 9,
               fontSize: 18, fill: "#3030a0", fontFamily: "monospace", fontWeight: "bold"});
            return grp;
         };

         // ══════════════════════════════════════
         //    LAYOUT 
         // ══════════════════════════════════════
         
         // A MUX & Inverter
         o.amux_rect = muxBox(90, 50, 44, 60);
         o.not_a     = notGatePath(45, 93); //changed
         o.amux_0    = new fabric.Text("0", {left: 94, top: 54, fontSize: 10, fill: "#7a2e00", fontFamily: "monospace"});
         o.amux_1    = new fabric.Text("1", {left: 94, top: 92, fontSize: 10, fill: "#7a2e00", fontFamily: "monospace"});

         // B MUX & Inverter
         o.bmux_rect = muxBox(90, 250, 44, 60);
         o.not_b     = notGatePath(45, 293); //changed
         o.bmux_0    = new fabric.Text("0", {left: 94, top: 254, fontSize: 10, fill: "#7a2e00", fontFamily: "monospace"});
         o.bmux_1    = new fabric.Text("1", {left: 94, top: 292, fontSize: 10, fill: "#7a2e00", fontFamily: "monospace"});

         // Processing Gates
         o.and_gate = andGatePath(220, 80, 60, 44);
         o.or_gate  = orGatePath(220, 155, 60, 44);
         let fa     = faBox(220, 225, 60, 44);
         o.fa_rect  = fa.rect;
         o.fa_lbl   = fa.lbl;

         // Expanded Output MUX
         o.omux_rect = muxBox(370, 100, 44, 160);
         o.omux_0 = new fabric.Text("00", {left: 374, top: 114, fontSize: 10, fill: "#7a2e00", fontFamily: "monospace"});
         o.omux_1 = new fabric.Text("01", {left: 374, top: 149, fontSize: 10, fill: "#7a2e00", fontFamily: "monospace"});
         o.omux_2 = new fabric.Text("10", {left: 374, top: 184, fontSize: 10, fill: "#7a2e00", fontFamily: "monospace"});
         o.omux_3 = new fabric.Text("11", {left: 374, top: 219, fontSize: 10, fill: "#7a2e00", fontFamily: "monospace"});

         // ── Wire Helper ──
         const mwire = (pts) => new fabric.Polyline(
            pts.map(([x,y]) => ({x, y})),
            {stroke: "#cccccc", strokeWidth: 2, fill: "transparent"}
         );

         // ── Input Split & NOT Interconnects ──
         o.w_a_straight = mwire([[20,80], [40,80], [40,62], [90,62]]);
         o.w_a_to_not   = mwire([[40,80], [40,100], [45,100]]); //changed
         o.w_a_from_not = mwire([[60,100], [90,100]]);

         o.w_b_straight = mwire([[20,280], [40,280], [40,262], [90,262]]);
         o.w_b_to_not   = mwire([[40,280], [40,300], [45,300]]); //changed
         o.w_b_from_not = mwire([[60,300], [90,300]]);

         // ── Processing Buses ──
         o.w_amux_bus  = mwire([[134,80],[160,80],[160,232]]);        
         o.w_amux_and  = mwire([[160,92],[220,92]]);                  
         o.w_amux_or   = mwire([[160,168],[225,168]]);               
         o.w_amux_fa   = mwire([[160,232],[220,232]]);               

         o.w_bmux_bus  = mwire([[134,280],[170,280],[170,112]]);      
         o.w_bmux_and  = mwire([[170,112],[220,112]]);               
         o.w_bmux_or   = mwire([[170,188],[225,188]]);               
         o.w_bmux_fa   = mwire([[170,252],[220,252]]);               

         // ── Gate outputs → Output MUX slots ──
         o.w_and_omux  = mwire([[280,102],[305,102],[305,120],[370,120]]);
         o.w_or_omux   = mwire([[280,177],[305,177],[305,155],[370,155]]);
         o.w_fa_omux   = mwire([[280,247],[305,247],[305,190],[370,190]]);
         o.w_passb_omux = mwire([[28,280],[28,365],[320,365],[320,225],[370,225]]); 
         
         o.w_cin_bus   = mwire([[270,227],[270,200],[340,200],[340,70]]); 
         o.w_carry_out = mwire([[270,269],[270,340]]);
         o.w_result    = mwire([[414,180],[480,180]]);

         // ── Selection Line for Main MUX (Moved UP) ──
         o.w_omux_sel  = mwire([[392, 70], [392, 110]]);

         // ── Control Lines for Input MUXes (Moved UP) ──
         o.w_ainvert_ctrl = mwire([[112, 25],[112, 53]]);
         o.w_binvert_ctrl = mwire([[112, 215],[112, 253]]); 

         // Labels
         o.lbl_a        = new fabric.Text("A",        {left: 8,   top: 72,  fontSize: 12, fill: "#333", fontFamily: "monospace", fontWeight: "bold"});
         o.lbl_b        = new fabric.Text("B",        {left: 8,   top: 272, fontSize: 12, fill: "#333", fontFamily: "monospace", fontWeight: "bold"});
         
         o.lbl_ainv     = new fabric.Text("Ainvert",  {left: 90,  top: 10,  fontSize: 10, fill: "#5050c0", fontFamily: "monospace"});
         o.lbl_binv     = new fabric.Text("Binvert", {left: 90, top: 195, fontSize: 10, fill: "#5050c0", fontFamily: "monospace"});
         o.lbl_cin      = new fabric.Text("CarryIn", {left: 310, top: 55,  fontSize: 10, fill: "#5050c0", fontFamily: "monospace"}); 
         o.lbl_omux_sel = new fabric.Text("operation[1:0]", {left: 360, top: 50, fontSize: 10, fill: "#5050c0", fontFamily: "monospace"});
         o.lbl_cout     = new fabric.Text("CarryOut", {left: 250, top: 345, fontSize: 10, fill: "#333", fontFamily: "monospace"});
         
         o.lbl_result   = new fabric.Text("\u2192 Result", {left: 490, top: 173, fontSize: 12, fill: "#333", fontFamily: "monospace", fontWeight: "bold"});
         o.lbl_and_gate = new fabric.Text("AND",      {left: 230, top: 130, fontSize: 9,  fill: "#c0603a", fontFamily: "monospace"});
         o.lbl_or_gate  = new fabric.Text("OR",       {left: 230, top: 204, fontSize: 9,  fill: "#c0603a", fontFamily: "monospace"});

         // Live Value Bubbles
         const bubble = (x, y) => new fabric.Circle({left: x, top: y, radius: 9, fill: "#ffffff", stroke: "#aaaaaa", strokeWidth: 1});
         const bubbleTxt = (x, y) => new fabric.Text("?", {left: x, top: y, fontSize: 10, fill: "#333333", fontFamily: "monospace"});

         o.val_a    = bubble(18,   60);   o.vt_a    = bubbleTxt(24,   63);
         o.val_b    = bubble(18,   260);  o.vt_b    = bubbleTxt(24,   263);
         o.val_amux = bubble(140,  55);   o.vt_amux = bubbleTxt(146,  58);
         o.val_bmux = bubble(140,  285);  o.vt_bmux = bubbleTxt(146,  288);
         o.val_and  = bubble(285,  80);   o.vt_and  = bubbleTxt(291,  83);
         o.val_or   = bubble(285,  155);  o.vt_or   = bubbleTxt(291,  158);
         o.val_sum  = bubble(285,  225);  o.vt_sum  = bubbleTxt(291,  228);
         o.val_res  = bubble(465,  170);  o.vt_res  = bubbleTxt(471,  173);
         o.val_cout = bubble(240,  302);  o.vt_cout = bubbleTxt(246,  305);
         
         o.val_ainv = bubble(92,   22);   o.vt_ainv = bubbleTxt(98,   25);
         o.val_binv = bubble(92,   210);  o.vt_binv = bubbleTxt(98,   213);

         // Global State Panel
         o.op_box = new fabric.Rect({left: 450, top: 40, width: 140, height: 60, fill: "#fce4cf", stroke: "#c0603a", strokeWidth: 2, rx: 6});
         o.lbl_op = new fabric.Text("Operation:", {left: 458, top: 46, fontSize: 11, fill: "#7a2e00", fontFamily: "monospace"});
         o.op_bits = new fabric.Text("op = --", {left: 458, top: 62, fontSize: 13, fill: "#b05020", fontFamily: "monospace", fontWeight: "bold"});
         o.op_name = new fabric.Text("( -- )", {left: 458, top: 80, fontSize: 13, fill: "#5050c0", fontFamily: "monospace", fontWeight: "bold"});

         return o;
      },

      render() {
         let o = this.getObjects();

         // Fetch hardware simulation signals
         let aa        = '$aa'.asInt();
         let bb        = '$bb'.asInt();
         let ainvert   = '$ainvert'.asInt();
         let binvert   = '$binvert'.asInt();
         let carry_in  = '$carry_in'.asInt(); 
         let a_mux     = '$a_mux'.asInt();
         let b_mux     = '$b_mux'.asInt();
         let and_val   = '$and'.asInt();
         let or_val    = '$or'.asInt();
         let sum_val   = '$sum'.asInt();
         let carry_out = '$carry_out'.asInt();
         let result    = '$result'.asInt();
         let operation = '$operation'.asInt();

         const hot  = "#e05010";
         const cold = "#cccccc";
         const wire = (v) => isNaN(v) ? "#aaaaaa" : (v ? hot : cold);

         // Dynamic Wire Updates
         o.w_a_straight.set({stroke: wire(aa)});
         o.w_a_to_not.set({stroke: wire(aa)});
         o.w_a_from_not.set({stroke: wire(isNaN(aa) ? NaN : !aa)});
         
         o.w_b_straight.set({stroke: wire(bb)});
         o.w_b_to_not.set({stroke: wire(bb)});
         o.w_b_from_not.set({stroke: wire(isNaN(bb) ? NaN : !bb)});

         o.w_amux_bus.set({stroke: wire(a_mux)});
         o.w_amux_and.set({stroke: wire(a_mux)});
         o.w_amux_or.set({stroke: wire(a_mux)});
         o.w_amux_fa.set({stroke: wire(a_mux)});

         o.w_bmux_bus.set({stroke: wire(b_mux)});
         o.w_bmux_and.set({stroke: wire(b_mux)});
         o.w_bmux_or.set({stroke: wire(b_mux)});
         o.w_bmux_fa.set({stroke: wire(b_mux)});

         o.w_and_omux.set({stroke: wire(and_val)});
         o.w_or_omux.set({stroke: wire(or_val)});
         o.w_fa_omux.set({stroke: wire(sum_val)});
         o.w_passb_omux.set({stroke: wire(bb)});
         
         o.w_result.set({stroke: wire(result)});
         o.w_carry_out.set({stroke: wire(carry_out)});
         o.w_cin_bus.set({stroke: wire(carry_in)});
         o.w_omux_sel.set({stroke: isNaN(operation) ? "#aaaaaa" : hot});

         // Gate Highlight Glows
         const gateColor = (v) => isNaN(v) ? "#fde8d8" : (v ? "#ffc09a" : "#fde8d8");
         o.and_gate.set({fill: gateColor(and_val)});
         o.or_gate.set({fill:  gateColor(or_val)});
         o.fa_rect.set({fill:  gateColor(sum_val)});
         o.not_a.set({fill: gateColor(isNaN(aa) ? NaN : !aa)});
         o.not_b.set({fill: gateColor(isNaN(bb) ? NaN : !bb)});

         o.amux_rect.set({fill: ainvert ? "#ffc09a" : "#fce4cf"});
         o.bmux_rect.set({fill: binvert ? "#ffc09a" : "#fce4cf"});

         // Output MUX Dynamic Text Highlighting
         o.omux_0.set({fill: operation === 0 ? hot : "#7a2e00"});
         o.omux_1.set({fill: operation === 1 ? hot : "#7a2e00"});
         o.omux_2.set({fill: operation === 2 ? hot : "#7a2e00"});
         o.omux_3.set({fill: operation === 3 ? hot : "#7a2e00"});

         // Bubbles rendering
         const setVal = (bbl, txt, v) => {
            bbl.set({fill: v === 1 ? "#ffc09a" : "#ffffff"});
            txt.set({text: isNaN(v) ? "X" : v.toString()});
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
         setVal(o.val_ainv, o.vt_ainv, ainvert);
         setVal(o.val_binv, o.vt_binv, binvert);
         
         o.w_ainvert_ctrl.set({stroke: wire(ainvert)});
         o.w_binvert_ctrl.set({stroke: wire(binvert)});

         // State display mapping
         const opBits  = ["00", "01", "10", "11"];
         const opNames = ["AND", "OR", "ADD/SUB", "PASS-B"];
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
