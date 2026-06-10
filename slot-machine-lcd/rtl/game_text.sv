// ============================================================
//  game_text.sv  –  turn slot-machine state into two LCD lines
//
//  16x2 layout:
//    Line1:  "REELS: X X X    "
//    Line2:  "COINS:DDD SSSSSS"
//      DDD    = score, 3 digits
//      SSSSSS = status (SPIN? / SPIN.. / WIN!  / WIN20 / JACKPT / LOSE)
//
//  This layout also works as the top two rows of a 20x4 panel.
// ============================================================
module game_text (
    input  logic [2:0]  sym0,   // left reel symbol  (0..6)
    input  logic [2:0]  sym1,   // middle
    input  logic [2:0]  sym2,   // right
    input  logic [7:0]  score,  // 0..255
    input  logic [2:0]  state,  // FSM state
    output logic [7:0]  line1 [0:15],
    output logic [7:0]  line2 [0:15]
);

    // FSM state codes (must match top)
    localparam S_IDLE=3'd0, S_SPIN=3'd1, S_RESULT=3'd2, S_WIN=3'd3, S_LOSE=3'd4;

    // symbol -> ASCII character
    function automatic logic [7:0] sym_chr (input logic [2:0] s);
        case (s)
        3'd0: return "=";   // BAR
        3'd1: return "7";   // Seven
        3'd2: return "3";   // Three
        3'd3: return "C";   // Cherry
        3'd4: return "B";   // Bell
        3'd5: return "H";   // Horse
        3'd6: return "L";   // Lemon
        default: return "?";
        endcase
    endfunction

    // score digits
    logic [7:0] d_h, d_t, d_u;
    always_comb begin
        d_h = "0" + (score / 100);
        d_t = "0" + ((score / 10) % 10);
        d_u = "0" + (score % 10);
    end

    // 6-char status field
    logic [7:0] st [0:5];
    always_comb begin
        // default blanks
        st[0]=" "; st[1]=" "; st[2]=" "; st[3]=" "; st[4]=" "; st[5]=" ";
        unique case (state)
        S_IDLE: begin st[0]="S"; st[1]="P"; st[2]="I"; st[3]="N"; st[4]="?"; st[5]=" "; end
        S_SPIN: begin st[0]="S"; st[1]="P"; st[2]="I"; st[3]="N"; st[4]="."; st[5]="."; end
        S_WIN: begin
            if (sym0==sym1 && sym1==sym2 && sym0==3'd1) begin       // 7-7-7
                st[0]="J"; st[1]="A"; st[2]="C"; st[3]="K"; st[4]="P"; st[5]="T";
            end else if (sym0==sym1 && sym1==sym2) begin            // x-x-x
                st[0]="W"; st[1]="I"; st[2]="N"; st[3]="2"; st[4]="0"; st[5]=" ";
            end else begin                                          // pair
                st[0]="W"; st[1]="I"; st[2]="N"; st[3]="!"; st[4]=" "; st[5]=" ";
            end
        end
        S_LOSE: begin st[0]="L"; st[1]="O"; st[2]="S"; st[3]="E"; st[4]=" "; st[5]=" "; end
        default: ;
        endcase
    end

    // ---- compose line 1: "REELS: X X X    " ----
    always_comb begin
        line1[0]="R"; line1[1]="E"; line1[2]="E"; line1[3]="L"; line1[4]="S";
        line1[5]=":"; line1[6]=" ";
        line1[7]  = sym_chr(sym0);
        line1[8]  = " ";
        line1[9]  = sym_chr(sym1);
        line1[10] = " ";
        line1[11] = sym_chr(sym2);
        line1[12]=" "; line1[13]=" "; line1[14]=" "; line1[15]=" ";
    end

    // ---- compose line 2: "COINS:DDD SSSSSS" ----
    always_comb begin
        line2[0]="C"; line2[1]="O"; line2[2]="I"; line2[3]="N"; line2[4]="S";
        line2[5]=":";
        line2[6]=d_h; line2[7]=d_t; line2[8]=d_u;
        line2[9]=" ";
        line2[10]=st[0]; line2[11]=st[1]; line2[12]=st[2];
        line2[13]=st[3]; line2[14]=st[4]; line2[15]=st[5];
    end

endmodule