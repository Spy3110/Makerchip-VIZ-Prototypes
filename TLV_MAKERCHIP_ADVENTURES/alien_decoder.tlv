\m5_TLV_version 1d: tl-x.org
\m5
\SV
   m5_makerchip_module
   /* WELCOME, TL-Verilog ADVENTURERS!
   
   👽 INCOMING TRANSMISSION FROM ALIEN OVERLORD...
   
   "Human. I have sent you a binary code.
   Find the correct lever. Pull it.
   Save your planet.
   - Zorp"
   
   Something is wrong with this decoder.
   Watch the VIZ carefully.
   When Zorp sends 101, which lever lights up?
   Should it be that one...?
   
   Find the bug. Fix it.
   Earth is counting on you. 🌍
   */
\TLV
   $reset = *reset;
   `BOGUS_USE($reset)
   
   $in_a[2:0] = $rand[2:0];
   
   // *GASPS* SOMETHING IS WRONG HERE...
   $out_y[7:0] = ($in_a == 3'd0) ? 8'b00000001 :
                 ($in_a == 3'd1) ? 8'b00000010 :
                 ($in_a == 3'd2) ? 8'b00000100 :
                 ($in_a == 3'd3) ? 8'b00100000 :  // hmm...
                 ($in_a == 3'd4) ? 8'b00010000 :
                 ($in_a == 3'd5) ? 8'b00001000 :
                 ($in_a == 3'd6) ? 8'b01000000 :
                 8'b10000000;
   
   \viz_js //DO NOT TOUCH THIS,GREMLIN!
      box: {width: 380, height: 300, fill: "#0a0a1a"},
      
      init() {
         let o = {};
         
         // Alien transmission header
         o.alien = new fabric.Text("👽 ALIEN TRANSMISSION", {
            left: 80, top: 8,
            fontSize: 13, fill: "#00ff88",
            fontFamily: "monospace", fontWeight: "bold"
         });
         
         // Input display
         o.input_label = new fabric.Text("Zorp says:", {
            left: 20, top: 35,
            fontSize: 12, fill: "#888888",
            fontFamily: "monospace"
         });
         o.input_val = new fabric.Text("000", {
            left: 100, top: 35,
            fontSize: 12, fill: "#00ff88",
            fontFamily: "monospace"
         });
         
         // Earth status
         o.earth = new fabric.Text("🌍 EARTH STATUS: WAITING...", {
            left: 60, top: 55,
            fontSize: 12, fill: "#ffffff",
            fontFamily: "monospace"
         });
         
         // 8 levers
         let leverColors = ["#333333"];
         for (let i = 0; i < 8; i++) {
            let x = 20 + i * 44;
            
            // Lever base
            o["lever_base_" + i] = new fabric.Rect({
               left: x, top: 180,
               width: 30, height: 80,
               fill: "#222222",
               stroke: "#444444",
               strokeWidth: 1,
               rx: 3, ry: 3
            });
            
            // Lever handle (circle on top)
            o["lever_handle_" + i] = new fabric.Circle({
               left: x, top: 160,
               radius: 15,
               fill: "#333333",
               stroke: "#555555",
               strokeWidth: 2
            });
            
            // Lever number
            o["lever_num_" + i] = new fabric.Text(i.toString(), {
               left: x + 11, top: 225,
               fontSize: 12, fill: "#888888",
               fontFamily: "monospace"
            });
            
            // Lever emoji label
            o["lever_emoji_" + i] = new fabric.Text("🔧", {
               left: x + 6, top: 183,
               fontSize: 16,
               fontFamily: "monospace"
            });
         }
         
         // Decoder box
         o.decoder_box = new fabric.Rect({
            left: 20, top: 120,
            width: 340, height: 30,
            fill: "#111133",
            stroke: "#4444ff",
            strokeWidth: 2,
            rx: 5, ry: 5
         });
         o.decoder_label = new fabric.Text("3:8 DECODER", {
            left: 130, top: 127,
            fontSize: 12, fill: "#4444ff",
            fontFamily: "monospace"
         });
         
         // Warning text
         o.warning = new fabric.Text("", {
            left: 60, top: 270,
            fontSize: 11, fill: "#ff3333",
            fontFamily: "monospace"
         });
         
         return o;
      },
      
      render() {
         let o = this.getObjects();
         
         let in_a = '$in_a'.asInt();
         let out_y = '$out_y'.asInt();
         
         // Show binary input
         let toBin = (v) => isNaN(v) ? "XXX" :
                            v.toString(2).padStart(3, "0");
         o.input_val.set({text: toBin(in_a)});
         
         // Find which lever is active
         let activeLevel = -1;
         for (let i = 0; i < 8; i++) {
            if ((out_y >> i) & 1) {
               activeLevel = i;
               break;
            }
         }
         
         // Expected lever (what SHOULD be active)
         let expectedLever = isNaN(in_a) ? -1 : in_a;
         
         // Update all levers
         for (let i = 0; i < 8; i++) {
            let isActive = (i === activeLevel);
            let isCorrect = (activeLevel === expectedLever);
            
            // Color logic
            let handleColor = isActive ? 
               (isCorrect ? "#00ff00" : "#ff3333") : 
               "#333333";
            let strokeColor = isActive ?
               (isCorrect ? "#00ff88" : "#ff6666") :
               "#555555";
            
            o["lever_handle_" + i].set({
               fill: handleColor,
               stroke: strokeColor
            });
            o["lever_base_" + i].set({
               fill: isActive ? "#1a1a1a" : "#222222",
               stroke: strokeColor
            });
         }
         
         // Earth status
         if (isNaN(in_a)) {
            o.earth.set({text: "🌍 EARTH STATUS: WAITING...", fill: "#ffffff"});
            o.warning.set({text: ""});
         } else if (activeLevel === expectedLever) {
            o.earth.set({text: "🌍 EARTH STATUS: ✅ SAVED!", fill: "#00ff88"});
            o.warning.set({text: ""});
         } else {
            o.earth.set({
               text: "🌍 EARTH STATUS: 💥 DOOMED!",
               fill: "#ff3333"
            });
            o.warning.set({
               text: "⚠️ Lever " + activeLevel + " pulled! Zorp wanted " + expectedLever + "!",
            });
         }
      }
   
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
