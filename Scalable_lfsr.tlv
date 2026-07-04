\m5_TLV_version 1d: tl-x.org
\m5
   
   // ============================================
   // Linear Feedback Shift Register: Code B (UPDATED!)
   // ============================================
   //OKAY NO! ITS FIBONACCI ONE! NOT GALOIS!
   //I tried to make everything dynamic! 
   //so that we can even change the number of flip-flop we want..
   //EVERYTHING IS DYNAMIC NOW!(almost) PLS GIVE IT A TRY/ᐠ｡ꞈ｡ᐟ\
   
   
   use(m5-1.0)
   var(NUM_FF,8) //you can change how many flip-flops you want! (Try changing it to 5)
   var(MAX_FF,7) //but here you've to enter (total num of Flipflops - 1, try changing it to 4)
   //the values of which FF to XOR comes here
   var(TAP_1, 7)
   var(TAP_2, 2)
   
\SV
   m5_makerchip_module
\TLV
   |register
      @1
         $reset = *reset; //I moved it here cuz I thought it was causing time lag, but smt else is causing it.
         \viz_js
            box: {left: 0, top: 0, width: m5_NUM_FF * 110, height: 200, strokeWidth: 2, fill : "gray" , stroke: "black"},
            where: {left: 0, top: 0, width: 10, height: 10}, //I made this dynamic, so that it can keep up with total flip-flops

            template: { 
               connecting_line: ["Line", [80, 70,(m5_NUM_FF * 97), 70], {stroke: "cyan", strokeWidth: 2}], //OMGGG ITS WORKING FOR ALL!
               //debug_line: ["Line",[40,100,(m5_TAP_1 * 115),100] , {stroke : "yellow", strokeWidth: 2}],

               xor_input1: ["Line", [0,0,0,0], {stroke: "cyan", strokeWidth: 1.5}],
               xor_input2: ["Line", [0,0,0,0], {stroke: "cyan", strokeWidth: 1.5}],
               
               xor_gate: ["Circle", {left: 303, top: 110, radius: 30, fill: "black", stroke: "cyan", strokeWidth: 2}],    
               gate_text: ["Text", "XOR", {left: 317, top: 130, fill: "white", fontSize: 20, fontFamily: "monospace"}],
               
               line: ["Line", [25, 145, 305, 145],{stroke: "cyan"}],
               baseline_vert_up: ["Line", [25, 145, 25, 74], {stroke: "cyan"}],
               baseline_final_input: ["Line", [25, 73, 40, 73], {stroke: "cyan"}],
               feedback_state_dot: ["Circle", {left: 175, top: 140, radius: 5, fill: "#444444", strokeWidth: 0}],
            },
         
            render() {
               let canvas = this.global.canvas;
               let dot = this.getObjects().feedback_state_dot;
               dot.set({ left: 295,top: 140, fill: "#00FF00" });
               
               // Animate LEFT
               dot.animate({ left: 20 }, {
                   duration: 200,
                   onChange: canvas.renderAll.bind(canvas),
                   onComplete: () => {
                       // Animate up
                       dot.animate({ top: 69 }, {
                           duration: 100,
                           onChange: canvas.renderAll.bind(canvas),
                           onComplete: () => {
                               // animate right
                               dot.animate({ left: 35 }, {
                                   duration: 100,
                                   onChange: canvas.renderAll.bind(canvas)
                               });
                           }
                       });
                   }
               });
               //here comes the dynamic XOR!
               let tap1X = (m5_TAP_1 * 115); // Middle of Tap 1 box
               let tap2X = (m5_TAP_2 * 115) + 20; // Middle of Tap 2 box
               let xorX = (tap1X + tap2X) / 2;        // Place XOR gate between them
               
               this.getObjects().xor_gate.set({ left: xorX - 30 });
               this.getObjects().gate_text.set({ left: xorX - 15 });
               
               this.getObjects().line.set({x1: 25, y1: 145, x2: (xorX-30), y2: 145});
               
               this.getObjects().xor_input1.set({ x1: tap1X, y1: 90, x2: xorX, y2: 120 });
               this.getObjects().xor_input2.set({ x1: tap2X, y1: 90, x2: xorX, y2: 120 });
            }
         
         /ff[m5_MAX_FF:0]
            $Signal <= |register$reset ? (#ff == 0 ? 1'b1 : 1'b0) :
                      (#ff == 0) ? (/ff[m5_TAP_1]>>1$Signal ^ /ff[m5_TAP_2]>>1$Signal) :
                                   /ff[#ff - 1]>>1$Signal;
                                   // IT'S WORKING NOW, MR HOOVER!/ᐠ｡ꞈ｡ᐟ\✿
            \viz_js
               template: {
                  box_shape: ["Rect", {left: 40, top: 50, width: 40, height: 40, fill: "black", stroke: "cyan", strokeWidth: 2}],
                  box_text: ["Text", "0", {left: 55, top: 60, fill: "white", fontSize: 20, fontFamily: "monospace"}],
                  box_name: ["Text", "FF#", {left: 38, top: 20, fill: "black", fontSize: 20, fontFamily: "monospace"}],
               },

               render() {

                  let index = this.getIndex();
                  let offset = 60 * index;
                  let val1 = '$Signal'.asInt();
                  //everything else is good I guess
                  this.getObjects().box_shape.set({left: 40 + offset});
                  this.getObjects().box_text.set({left: 55 + offset, text: val1.toString()});
                  this.getObjects().box_name.set({left: 38 + offset, text: "FF#" + index});

                  if (val1 === 1) {
                      this.getObjects().box_shape.set({fill: "#00FF00"}); // Neon Green
                  } else {
                      this.getObjects().box_shape.set({fill: "#222222"}); // Dark Gray
                  }
               }


   *passed = *cyc_cnt > 50;
   *failed = 1'b0;
\SV
   endmodule
