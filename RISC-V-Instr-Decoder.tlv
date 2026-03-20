\m5_TLV_version 1d: tl-x.org
\m5
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;
   
   //RISC-V opcode decoder: it will take a 32-bit instruction, find its opcode, and then tell which type of instruction it is!
   //Its also known as "Bit-slicer" kinda childish name I agree （￣^￣）
   $instr[31:0] = $rand[31:0]; //it will generate a code, a random one
   $opcode[6:0] = $instr[6:0]; //it will find out its opcode
   
   //now we will check whats the type
   $is_r = $opcode == 7'b0110011;
   $is_i = $opcode == 7'b0010011;
   $is_s = $opcode == 7'b0100011;
   $is_b = $opcode == 7'b1100011;
   $is_u = ($opcode == 7'b0110111) || ($opcode == 7'b0010111);
   $is_j = $opcode == 7'b1101111;
   
   //the VIZ
   \viz_js
      box: {width: 500, height: 250, fill: "#1a1a1a"},
      init() {
         let objs = {};
         let types = [
            {lbl: "R", col: "#ff4d4d", x: 50}, 
            {lbl: "I", col: "#ffff4d", x: 125},
            {lbl: "S", col: "#4dff4d", x: 200},
            {lbl: "B", col: "#4d4dff", x: 275},
            {lbl: "U", col: "#b34dff", x: 350},
            {lbl: "J", col: "#ff944d", x: 425}
         ];

         objs.instr_text = new fabric.Text("00000000000000000000000000000000", {
            left: 50, top: 60, fontSize: 20, fill: "#888888", fontFamily: "monospace"
         });

         objs.spotlight = new fabric.Rect({
            left: 323, top: 55, width: 85, height: 30, 
            fill: "transparent", stroke: "#555555", strokeWidth: 2, rx: 3, ry: 3
         });

         types.forEach((t, i) => {
            objs["box_" + i] = new fabric.Rect({
               left: t.x, top: 150, width: 60, height: 60, fill: t.col, opacity: 0.1, rx: 8
            });
            objs["lbl_" + i] = new fabric.Text(t.lbl, {
               left: t.x + 20, top: 165, fontSize: 28, fill: "#ffffff", fontWeight: "bold", fontFamily: "monospace"
            });
         });
         return objs;
      },
      //the boss fight
      render() {
         let objs = this.getObjects();
         let instr = '$instr'.asInt().toString(2).padStart(32, '0');
         objs.instr_text.set({text: instr});

         // Logic Check
         let activeIdx = -1;
         if ('$is_r'.asInt() == 1)      activeIdx = 0;
         else if ('$is_i'.asInt() == 1) activeIdx = 1;
         else if ('$is_s'.asInt() == 1) activeIdx = 2;
         else if ('$is_b'.asInt() == 1) activeIdx = 3;
         else if ('$is_u'.asInt() == 1) activeIdx = 4;
         else if ('$is_j'.asInt() == 1) activeIdx = 5;

         let colors = ["#ff4d4d", "#ffff4d", "#4dff4d", "#4d4dff", "#b34dff", "#ff944d"];

         if (activeIdx !== -1) {
            objs.spotlight.set({stroke: colors[activeIdx], strokeWidth: 3});
            for (let i = 0; i < 6; i++) {
               objs["box_" + i].set({opacity: (i === activeIdx) ? 1 : 0.1});
            }
         } else {
            objs.spotlight.set({stroke: "#555555", strokeWidth: 1});
            for (let i = 0; i < 6; i++) {
               objs["box_" + i].set({opacity: 0.1});
            }
         }
      }

   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
