\m5_TLV_version 1d: tl-x.org
\m5
   //use(m5-1.0)   /// uncomment to use M5 macro library.
\SV
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV


   // Connect SV inputs to TLV pipesignals.
   $reset = *reset;
   //Ripple carry adder!
   |calc //this is like a conveyor belt...
      @1 //workstations? 
         $a0[0:0] = $rand[0:0];
         $b0[0:0] = $rand[1:1];
         $a1[0:0] = $rand[2:2];
         $b1[0:0] = $rand[3:3];
         $a2[0:0] = $rand[4:4];
         $b2[0:0] = $rand[5:5];
         $a3[0:0] = $rand[6:6];
         $b3[0:0] = $rand[7:7];
         $c_in[0:0] = 1'b0;
      @2 //FA0
         $s_0 = $a0 ^ $b0 ^ $c_in;
         $c_0 = ($a0 & $b0) | ($c_in & ($a0 ^ $b0));
      @3 //FA1
         $s_1 = $a1 ^ $b1 ^ $c_0;
         $c_1 = ($a1 & $b1) | ($c_0 & ($a1 ^ $b1));
      @4 //FA2
         $s_2 = $a2 ^ $b2 ^ $c_1;
         $c_2 = ($a2 & $b2) | ($c_1 & ($a2 ^ $b2));
      @5 //FA3
         $s_3 = $a3 ^ $b3 ^ $c_2;
         $c_out = ($a3 & $b3) | ($c_2 & ($a3 ^ $b3));
         
         \viz_js //its inside the @5 i see
            box: {width: 400, height: 200, fill: "#222222"},
            init() {
               let objs = {};
               
               // The title
               objs.title = new fabric.Text("Pipelined Ripple Carry Adder", {
                  left: 40, top: 10, fontSize: 20, fill: "#ffffff", fontFamily: "monospace"
               });
               
               // the 4 FA blocksss (Looping right to left)
               for (let i = 0; i < 4; i++) {
                  let x = 300 - (i * 80); // LSB on the right (300), MSB on the left (60)
                  
                  // Silicon Block, wait..whats this again?
                  objs["box_" + i] = new fabric.Rect({
                     left: x, top: 70, width: 50, height: 60, 
                     fill: "#333333", stroke: "#00FF00", strokeWidth: 2, rx: 5, ry: 5
                  });
                  objs["lbl_" + i] = new fabric.Text("FA" + i, {
                     left: x + 10, top: 90, fontSize: 14, fill: "#aaaaaa", fontFamily: "monospace"
                  });
                  
                  // I/O Text (Pink for A, Cyan for B, Yellow for Sum)
                  objs["val_a_" + i] = new fabric.Text("A", {left: x + 10, top: 40, fontSize: 16, fill: "#ff66cc", fontWeight: "bold"});
                  objs["val_b_" + i] = new fabric.Text("B", {left: x + 30, top: 40, fontSize: 16, fill: "#66ccff", fontWeight: "bold"});
                  objs["val_s_" + i] = new fabric.Text("S", {left: x + 20, top: 140, fontSize: 18, fill: "#ffff00", fontWeight: "bold"});
                  
                  // Carry Wires
                  if (i < 3) {
                     // Internal rippling wires
                     objs["wire_" + i] = new fabric.Line([x, 100, x - 30, 100], {stroke: "#555555", strokeWidth: 4});
                  } else if (i === 3) {
                     // THE CARRY OUTTT
                     objs["wire_out"] = new fabric.Line([x, 100, x - 30, 100], {stroke: "#555555", strokeWidth: 4});
                     objs["val_cout"] = new fabric.Text("C", {left: x - 45, top: 90, fontSize: 18, fill: "#ff9900", fontWeight: "bold"});
                  }
               }
               return objs;
            },
            
            render() {
               let objs = this.getObjects();
               
               // Pulling exact scalar variables!
               let a = [ '<<4$a0'.asInt(), '<<4$a1'.asInt(), '<<4$a2'.asInt(), '<<4$a3'.asInt() ];
               let b = [ '<<4$b0'.asInt(), '<<4$b1'.asInt(), '<<4$b2'.asInt(), '<<4$b3'.asInt() ];
               let s = [ '<<3$s_0'.asInt(), '<<2$s_1'.asInt(), '<<1$s_2'.asInt(), '$s_3'.asInt() ];
               let c = [ '<<3$c_0'.asInt(), '<<2$c_1'.asInt(), '<<1$c_2'.asInt() ];
               
               // Fetching the final overflow bit
               let final_c = '$c_out'.asInt(); 
               
               // Update the Canvas
               for (let i = 0; i < 4; i++) {
                  objs["val_a_" + i].set({text: Number.isNaN(a[i]) ? "X" : a[i].toString()});
                  objs["val_b_" + i].set({text: Number.isNaN(b[i]) ? "X" : b[i].toString()});
                  objs["val_s_" + i].set({text: Number.isNaN(s[i]) ? "X" : s[i].toString()});
                  
                  if (i < 3) {
                     // Light up internal wires
                     objs["wire_" + i].set({stroke: c[i] === 1 ? "#00FF00" : "#555555"});
                  } else if (i === 3) {
                     // Light up the final overflow wire and update its text!
                     objs["wire_out"].set({stroke: final_c === 1 ? "#00FF00" : "#555555"});
                     objs["val_cout"].set({text: Number.isNaN(final_c) ? "X" : final_c.toString()});
                  }
               }
            }

   // Assert these to end simulation
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
