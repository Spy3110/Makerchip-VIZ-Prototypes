\m5_TLV_version 1d: tl-x.org
\m5
   //THE REGISTER FILE 2-bit input, 4 registers 
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;
   //the inputs
   $wr_reg[1:0] = $rand[1:0];
   $wr_enable[0:0] = $rand[2:2];
   $read_one[1:0] = $rand[5:4];
   $read_two[1:0] = $rand[7:6];
   $data[3:0] = $rand[11:8];

   //I want a decoder first
   $dec_out[3:0] = ($wr_reg == 2'd0) ? 4'b0001 :
              ($wr_reg == 2'd1) ? 4'b0010 :
              ($wr_reg == 2'd2) ? 4'b0100 :
              4'b1000;

   //the decoder o/p goes to AND gates with write_enable
   $and_0 = $dec_out[0] & $wr_enable;
   $and_1 = $dec_out[1] & $wr_enable;
   $and_2 = $dec_out[2] & $wr_enable;
   $and_3 = $dec_out[3] & $wr_enable;

   //now comes the sequencial part
   //the actual registers
   $reg_0[3:0] = $and_0 ? $data : >>1$reg_0;
   $reg_1[3:0] = $and_1 ? $data : >>1$reg_1;
   $reg_2[3:0] = $and_2 ? $data : >>1$reg_2;
   $reg_3[3:0] = $and_3 ? $data : >>1$reg_3;

   //now I'll make two read ports, using MUXes
   $mux_one[3:0] = ($read_one == 2'b00) ? $reg_0 :
                   ($read_one == 2'b01) ? $reg_1 :
                   ($read_one == 2'b10) ? $reg_2 :
                   $reg_3;
   $mux_two[3:0] = ($read_two == 2'b00) ? $reg_0 :
                   ($read_two == 2'b01) ? $reg_1 :
                   ($read_two == 2'b10) ? $reg_2 :
                   $reg_3;

   //------------THE VIZ SECTION------------
   \viz_js
      box: {width: 790, height: 500, fill: "#eef5fb", stroke: "#9fc4e0", strokeWidth: 2, rx: 8, ry: 8},

      init() {
         let o = {};

         // ── Title ──
         o.title = new fabric.Text("4-Register File  (2-bit Address, 4-bit Data)", {
            left: 190, top: 8, fontSize: 15, fill: "#1a4a70",
            fontFamily: "monospace", fontWeight: "bold"
         });

         // ── Row centers for the 4 registers ──
         const rowY = [100, 180, 260, 340];

         // ── Helper: AND gate (D-shape), same style as the ALU ──
         const andGatePath = (x, y, w, h) => {
            let hw = h / 2;
            return new fabric.Path(
               `M ${x} ${y} L ${x + w * 0.5} ${y} Q ${x + w} ${y} ${x + w} ${y + hw} Q ${x + w} ${y + h} ${x + w * 0.5} ${y + h} L ${x} ${y + h} Z`,
               {fill: "#eaf2fa", stroke: "#3a6ea5", strokeWidth: 2}
            );
         };

         // ── Helper: small clock-edge triangle marker (for C pins) ──
         const clockTri = (x, y) => new fabric.Path(
            `M ${x} ${y - 5} L ${x + 7} ${y} L ${x} ${y + 5} Z`,
            {fill: "#555555", strokeWidth: 0}
         );

         // ── Helper: Manhattan wire ──
         const mwire = (pts) => new fabric.Polyline(
            pts.map(([x, y]) => ({x, y})),
            {stroke: "#cccccc", strokeWidth: 2, fill: "transparent"}
         );

         // ── Helper: value bubble ──
         const bubble = (x, y) => new fabric.Circle({left: x, top: y, radius: 9,
            fill: "#ffffff", stroke: "#aaaaaa", strokeWidth: 1});
         const bubbleTxt = (x, y) => new fabric.Text("?", {left: x, top: y,
            fontSize: 10, fill: "#333333", fontFamily: "monospace"});

         // ══════════════════════════════════════
         //   DECODER
         // ══════════════════════════════════════
         o.decoder_rect = new fabric.Rect({
            left: 80, top: 70, width: 90, height: 300,
            fill: "#dcecf9", stroke: "#3a6ea5", strokeWidth: 2, rx: 6, ry: 6
         });
         o.decoder_lbl1 = new fabric.Text("2-to-4", {
            left: 100, top: 195, fontSize: 12, fill: "#1a4a70", fontFamily: "monospace", fontWeight: "bold"
         });
         o.decoder_lbl2 = new fabric.Text("Decoder", {
            left: 92, top: 210, fontSize: 12, fill: "#1a4a70", fontFamily: "monospace", fontWeight: "bold"
         });

         // Write Register input into decoder
         o.w_wrreg_in = mwire([[10, 200], [80, 200]]);
         o.lbl_wrreg = new fabric.Text("Write Register", {
            left: 10, top: 210, fontSize: 10, fill: "#333", fontFamily: "monospace"
         });
         o.val_wrreg = bubble(10, 178); o.vt_wrreg = bubbleTxt(15, 181);

         // Decoder output pins + AND gates + registers, per row
         for (let i = 0; i < 4; i++) {
            let ry = rowY[i];

            // decoder pin -> AND gate top input
            o["w_dec_gate_" + i] = mwire([[170, ry], [210, ry], [210, ry - 8]]);
            o["dec_pin_" + i] = new fabric.Circle({left: 165, top: ry - 4, radius: 4,
               fill: "#888888", strokeWidth: 0});
            o["dec_pin_lbl_" + i] = new fabric.Text(i.toString(), {
               left: 148, top: ry - 6, fontSize: 9, fill: "#555", fontFamily: "monospace"
            });

            // AND gate
            o["gate_" + i] = andGatePath(210, ry - 15, 44, 30);
            o["gate_lbl_" + i] = new fabric.Text("&", {
               left: 226, top: ry - 8, fontSize: 12, fill: "#3a6ea5", fontFamily: "monospace", fontWeight: "bold"
            });

            // gate output -> register C pin
            o["w_gate_c_" + i] = mwire([[254, ry], [266, ry], [266, ry - 10], [280, ry - 10]]);
            o["clk_tri_" + i] = clockTri(280, ry - 10);

            // Register (flip-flop) box
            o["reg_rect_" + i] = new fabric.Rect({
               left: 280, top: ry - 24, width: 160, height: 48,
               fill: "#fbfdff", stroke: "#3a6ea5", strokeWidth: 2, rx: 4, ry: 4
            });
            o["reg_lbl_" + i] = new fabric.Text("Register " + i, {
               left: 300, top: ry - 20, fontSize: 11, fill: "#1a4a70", fontFamily: "monospace", fontWeight: "bold"
            });
            o["reg_c_lbl_" + i] = new fabric.Text("C", {
               left: 284, top: ry - 17, fontSize: 9, fill: "#555", fontFamily: "monospace"
            });
            o["reg_d_lbl_" + i] = new fabric.Text("D", {
               left: 284, top: ry + 4, fontSize: 9, fill: "#555", fontFamily: "monospace"
            });
            o["reg_val_bub_" + i] = bubble(400, ry - 9);
            o["reg_val_txt_" + i] = bubbleTxt(404, ry - 6);

            // Register Data bus -> D pin
            o["w_data_d_" + i] = mwire([[265, ry + 10], [280, ry + 10]]);
         }

         // Write-enable vertical bus feeding all AND gate bottom inputs
         o.w_write_top = mwire([[20, 40], [195, 40]]);
         o.w_write_bus = mwire([[195, 40], [195, 348]]);
         o.lbl_write = new fabric.Text("Write", {
            left: 20, top: 20, fontSize: 11, fill: "#333", fontFamily: "monospace"
         });
         o.val_write = bubble(90, 18); o.vt_write = bubbleTxt(95, 21);
         for (let i = 0; i < 4; i++) {
            let ry = rowY[i];
            o["w_write_stub_" + i] = mwire([[195, ry + 8], [210, ry + 8]]);
         }

         // Register Data vertical bus (from left input, up through all D pins)
         o.w_data_in = mwire([[10, 400], [265, 400]]);
         o.w_data_bus = mwire([[265, 110], [265, 400]]);
         o.lbl_data = new fabric.Text("Register Data", {
            left: 10, top: 410, fontSize: 10, fill: "#333", fontFamily: "monospace"
         });
         o.val_data = bubble(10, 378); o.vt_data = bubbleTxt(15, 381);

         // ══════════════════════════════════════
         //   MUX 1 (top) and MUX 2 (bottom)
         // ══════════════════════════════════════
         const muxPill = (x, y, w, h) => new fabric.Rect({
            left: x, top: y, width: w, height: h,
            fill: "#eaf2fa", stroke: "#3a6ea5", strokeWidth: 2, rx: w / 2.2, ry: w / 2.2
         });

         o.mux1_rect = muxPill(560, 60, 100, 180);
         o.mux1_lbl = new fabric.Text("M\nU\nX", {
            left: 600, top: 120, fontSize: 13, fill: "#1a4a70",
            fontFamily: "monospace", fontWeight: "bold", textAlign: "center"
         });
         o.mux2_rect = muxPill(560, 280, 100, 180);
         o.mux2_lbl = new fabric.Text("M\nU\nX", {
            left: 600, top: 340, fontSize: 13, fill: "#1a4a70",
            fontFamily: "monospace", fontWeight: "bold", textAlign: "center"
         });

         const mux1PinY = [90, 130, 170, 210];
         const mux2PinY = [310, 350, 390, 430];

         for (let i = 0; i < 4; i++) {
            let ry = rowY[i];
            let col1 = 460 + i * 8;
            let col2 = 500 + i * 8;

            // register out -> mux1 lane i
            o["w_reg_mux1_" + i] = mwire([[440, ry], [col1, ry], [col1, mux1PinY[i]], [560, mux1PinY[i]]]);
            // register out -> mux2 lane i
            o["w_reg_mux2_" + i] = mwire([[440, ry], [col2, ry], [col2, mux2PinY[i]], [560, mux2PinY[i]]]);
         }

         // Read Register selects
         o.w_read1_sel = mwire([[610, 20], [610, 60]]);
         o.lbl_read1 = new fabric.Text("Read Register 1", {
            left: 545, top: 4, fontSize: 10, fill: "#333", fontFamily: "monospace"
         });
         o.val_read1 = bubble(610, 2); o.vt_read1 = bubbleTxt(615, 5);

         o.w_read2_sel = mwire([[610, 475], [610, 460]]);
         o.lbl_read2 = new fabric.Text("Read Register 2", {
            left: 545, top: 480, fontSize: 10, fill: "#333", fontFamily: "monospace"
         });
         o.val_read2 = bubble(610, 478); o.vt_read2 = bubbleTxt(615, 481);

         // Outputs
         o.w_out1 = mwire([[660, 150], [700, 150]]);
         o.lbl_out1 = new fabric.Text("Read Data 1", {
            left: 700, top: 160, fontSize: 11, fill: "#333", fontFamily: "monospace", fontWeight: "bold"
         });
         o.val_out1 = bubble(700, 128); o.vt_out1 = bubbleTxt(705, 131);

         o.w_out2 = mwire([[660, 370], [700, 370]]);
         o.lbl_out2 = new fabric.Text("Read Data 2", {
            left: 700, top: 380, fontSize: 11, fill: "#333", fontFamily: "monospace", fontWeight: "bold"
         });
         o.val_out2 = bubble(700, 348); o.vt_out2 = bubbleTxt(705, 351);

         return o;
      },

      render() {
         let o = this.getObjects();

         let wr_reg = '$wr_reg'.asInt();
         let wr_enable = '$wr_enable'.asInt();
         let read_one = '$read_one'.asInt();
         let read_two = '$read_two'.asInt();
         let data = '$data'.asInt();
         let dec_out = '$dec_out'.asInt();
         let and_sig = [ '$and_0'.asInt(), '$and_1'.asInt(), '$and_2'.asInt(), '$and_3'.asInt() ];
         let reg_val = [ '$reg_0'.asInt(), '$reg_1'.asInt(), '$reg_2'.asInt(), '$reg_3'.asInt() ];
         let mux_one = '$mux_one'.asInt();
         let mux_two = '$mux_two'.asInt();

         const hot = "#e8890f";
         const cold = "#c9c9c9";
         const bit = (v) => isNaN(v) ? "#aaaaaa" : (v ? hot : cold);
         const nz  = (v) => isNaN(v) ? "#aaaaaa" : (v ? hot : cold); // nonzero bus glow

         const setVal = (bub, txt, v, colorFn) => {
            let s = isNaN(v) ? "X" : v.toString();
            txt.set({text: s});
            bub.set({fill: colorFn && colorFn(v) === hot ? "#ffd9a8" : "#ffffff"});
         };

         // Write Register / Write Enable / Data inputs
         setVal(o.val_wrreg, o.vt_wrreg, wr_reg, nz);
         o.w_wrreg_in.set({stroke: nz(wr_reg)});

         setVal(o.val_write, o.vt_write, wr_enable, bit);
         o.w_write_top.set({stroke: bit(wr_enable)});
         o.w_write_bus.set({stroke: bit(wr_enable)});

         setVal(o.val_data, o.vt_data, data, nz);
         o.w_data_in.set({stroke: nz(data)});
         o.w_data_bus.set({stroke: nz(data)});

         // Per-row: decoder pin, gate, register
         for (let i = 0; i < 4; i++) {
            let decBit = (dec_out >> i) & 1;
            o["dec_pin_" + i].set({fill: isNaN(decBit) ? "#888888" : (decBit ? hot : "#888888")});
            o["w_dec_gate_" + i].set({stroke: bit(decBit)});
            o["w_write_stub_" + i].set({stroke: bit(wr_enable)});

            let gateOut = and_sig[i];
            o["gate_" + i].set({fill: isNaN(gateOut) ? "#eaf2fa" : (gateOut ? "#ffd9a8" : "#eaf2fa")});
            o["w_gate_c_" + i].set({stroke: bit(gateOut)});

            o["w_data_d_" + i].set({stroke: nz(data)});

            let rv = reg_val[i];
            o["reg_val_txt_" + i].set({text: isNaN(rv) ? "X" : rv.toString()});
            o["reg_val_bub_" + i].set({fill: (!isNaN(rv) && rv !== 0) ? "#ffd9a8" : "#ffffff"});
            o["reg_rect_" + i].set({stroke: gateOut ? hot : "#3a6ea5"});

            // Mux lanes: glow only if this register is the one currently being read
            let sel1 = (read_one === i);
            let sel2 = (read_two === i);
            o["w_reg_mux1_" + i].set({stroke: sel1 ? hot : cold, strokeWidth: sel1 ? 3 : 2});
            o["w_reg_mux2_" + i].set({stroke: sel2 ? hot : cold, strokeWidth: sel2 ? 3 : 2});
         }

         // Read selects + outputs
         setVal(o.val_read1, o.vt_read1, read_one, nz);
         setVal(o.val_read2, o.vt_read2, read_two, nz);
         o.w_read1_sel.set({stroke: nz(read_one)});
         o.w_read2_sel.set({stroke: nz(read_two)});

         setVal(o.val_out1, o.vt_out1, mux_one, nz);
         setVal(o.val_out2, o.vt_out2, mux_two, nz);
         o.w_out1.set({stroke: nz(mux_one)});
         o.w_out2.set({stroke: nz(mux_two)});
      }

   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
