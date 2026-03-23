\m5_TLV_version 1d: tl-x.org
\m5
   
   // ============================================
   // Linear Feedback Shift Register: Used for encryption and cryptography irl
   // ============================================
\SV
   m5_makerchip_module 
\TLV
!   $reset = *reset;
   
   |register
      @1
         $Box1 = $reset ? 1'b1 : (>>1$Box3 ^ >>1$Box4);
         $Box2 = $reset ? 1'b0 : >>1$Box1 ;
         $Box3 = $reset ? 1'b0 : >>1$Box2 ;
         $Box4 = $reset ? 1'b0 : >>1$Box3 ;
         
         \viz_js
             box: {left: 0, top: 0, width: 300, height: 200, strokeWidth: 2, fill : "gray" , stroke: "black"},
             where: {left: 0, top: 0, width: 10, height: 10},
             
             template: {

               box1_shape: ["Rect", {left: 40, top: 50, width: 40, height: 40, fill: "black", stroke: "cyan", strokeWidth: 2}],
               box1_text: ["Text", "0", {left: 55 , top: 60, fill: "white", fontSize: 20, fontFamily: "monospace"}],
               box_name: ["Text", "FF#0", {left: 38 , top: 20, fill: "black", fontSize: 20, fontFamily: "monospace"}],

               box2_shape: ["Rect", {left: 100, top: 50, width: 40, height: 40, fill: "black", stroke: "cyan", strokeWidth: 2}],
               box2_text: ["Text", "0", {left: 115, top: 60, fill: "white", fontSize: 20, fontFamily: "monospace"}],
               box2_name: ["Text", "FF#1", {left: 98 , top: 20, fill: "black", fontSize: 20, fontFamily: "monospace"}],
               
               box3_shape: ["Rect", {left: 160, top: 50, width: 40, height: 40, fill: "black", stroke: "cyan", strokeWidth: 2}],
               box3_text: ["Text", "0", {left: 175, top: 60, fill: "white", fontSize: 20, fontFamily: "monospace"}],
               box3_name: ["Text", "FF#2", {left: 158 , top: 20, fill: "black", fontSize: 20, fontFamily: "monospace"}],
               
               box4_shape: ["Rect", {left: 220, top: 50, width: 40, height: 40, fill: "black", stroke: "cyan", strokeWidth: 2}],
               box4_text: ["Text", "0", {left: 235, top: 60, fill: "white", fontSize: 20, fontFamily: "monospace"}],
               box4_name: ["Text", "FF#3", {left: 218 , top: 20, fill: "black", fontSize: 20, fontFamily: "monospace"}],
               
               line_0to1: ["Line", [80, 70, 100, 70], {stroke: "cyan", strokeWidth: 2}],
               line_1to2: ["Line", [140, 70, 160, 70], {stroke: "cyan", strokeWidth: 2}],
               line_2to3: ["Line", [200, 70, 220, 70], {stroke: "cyan", strokeWidth: 2}],
               
               xor_input1: ["Line", [180, 90, 205, 115], {stroke: "cyan", strokeWidth: 1.5}], 
               xor_input2: ["Line", [245, 90, 220, 115], {stroke: "cyan", strokeWidth: 1.5}], 
               
               xor_gate: ["Circle", {left: 182, top: 110, radius: 30, fill: "black", stroke: "cyan", strokeWidth: 2}],    
               gate_text: ["Text", "XOR", {left: 196, top: 129, fill: "white", fontSize: 20, fontFamily: "monospace"}],
                            //ohhhh now i got is that [left point,left, right, right point size]
               line: ["Line", [25, 145, 182, 145],{stroke: "cyan"}],
               baseline_vert_up: ["Line", [25, 145, 25, 74], {stroke: "cyan"}],
               baseline_final_input: ["Line", [25, 73, 40, 73], {stroke: "cyan"}],
               feedback_state_dot: ["Circle", {left: 175, top: 140, radius: 5, fill: "#444444", strokeWidth: 0}],
              
               dot0_1: ["Circle", {left: 80, top: 68, radius: 3, fill: "#444444", strokeWidth: 0}],
              
               dot1_2: ["Circle", {left: 140, top: 68, radius: 3, fill: "#444444", strokeWidth: 0}],
               
               dot2_3: ["Circle", {left: 200, top: 68, radius: 3, fill: "#444444", strokeWidth: 0}],
               },
            
            //ANIMATION!
            render() {
              
               let canvas = this.global.canvas;
               let dot = this.getObjects().feedback_state_dot;

               dot.set({ left: 175, top: 140, fill: "#00FF00" });

               // Animate LEFT 
                 dot.animate({ left: 20 }, {
                     duration: 100, 
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
                 }); //the hell! so long
                 
                 this.getObjects().dot0_1.set({ left: 80, top: 68, fill: "#00FF00"});
                 this.getObjects().dot0_1.animate({ left: 100 }, {
                                     duration: 200,
                                     onChange: this.global.canvas.renderAll.bind(canvas)

                                 });
                 this.getObjects().dot1_2.set({ left: 140, top: 68, fill: "#00FF00"});
                 this.getObjects().dot1_2.animate({ left: 160 }, {
                                     duration: 200,
                                     onChange: this.global.canvas.renderAll.bind(canvas)

                                 });
                 this.getObjects().dot2_3.set({ left: 200, top: 68, fill: "#00FF00"});
                 this.getObjects().dot2_3.animate({ left: 220 }, {
                                     duration: 200,
                                     onChange: this.global.canvas.renderAll.bind(canvas)

                                 });
                 
               let val1 = '$Box1'.asInt();

               this.getObjects().box1_text.set({text: val1.toString()});

               if (val1 === 1) {
                   this.getObjects().box1_shape.set({fill: "#00FF00"}); // Neon Green
               } else {
                   this.getObjects().box1_shape.set({fill: "#222222"}); // Dark Gray
               } //mwahahahaha!
               //box-2
               let val2 = '$Box2'.asInt();
               this.getObjects().box2_text.set({text: val2.toString()});
               if (val2 === 1) {
                   this.getObjects().box2_shape.set({fill: "#00FF00"}); // Neon Green
               } else {
                   this.getObjects().box2_shape.set({fill: "#222222"}); // Dark Gray
               }
               
               
               //box-3
               let val3 = '$Box3'.asInt();
               this.getObjects().box3_text.set({text: val3.toString()});
               if (val3 === 1) {
                   this.getObjects().box3_shape.set({fill: "#00FF00"}); // Neon Green
               } else {
                   this.getObjects().box3_shape.set({fill: "#222222"}); // Dark Gray
               }
               
               //box-4
               let val4 = '$Box4'.asInt();
               this.getObjects().box4_text.set({text: val4.toString()});
               if (val4 === 1) {
                   this.getObjects().box4_shape.set({fill: "#00FF00"}); // Neon Green
               } else {
                   this.getObjects().box4_shape.set({fill: "#222222"}); // Dark Gray
               }
              }

   *passed = *cyc_cnt > 50;
   *failed = 1'b0;
\SV
   endmodule
