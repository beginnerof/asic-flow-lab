// Iterative AES-128 encrypt/decrypt (FIPS-197)
// Byte 0 is the MSB of the 128-bit word (matches standard test-vector dumps).
module aes_core (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire         decrypt,
    input  wire [127:0] key,
    input  wire [127:0] din,
    output reg  [127:0] dout,
    output reg          busy,
    output reg          done
);
    // ---- pure functions ----
    function [7:0] sboxf;
        input [7:0] x;
        begin
            case (x)
                8'h00: sboxf=8'h63; 8'h01: sboxf=8'h7c; 8'h02: sboxf=8'h77; 8'h03: sboxf=8'h7b;
                8'h04: sboxf=8'hf2; 8'h05: sboxf=8'h6b; 8'h06: sboxf=8'h6f; 8'h07: sboxf=8'hc5;
                8'h08: sboxf=8'h30; 8'h09: sboxf=8'h01; 8'h0a: sboxf=8'h67; 8'h0b: sboxf=8'h2b;
                8'h0c: sboxf=8'hfe; 8'h0d: sboxf=8'hd7; 8'h0e: sboxf=8'hab; 8'h0f: sboxf=8'h76;
                8'h10: sboxf=8'hca; 8'h11: sboxf=8'h82; 8'h12: sboxf=8'hc9; 8'h13: sboxf=8'h7d;
                8'h14: sboxf=8'hfa; 8'h15: sboxf=8'h59; 8'h16: sboxf=8'h47; 8'h17: sboxf=8'hf0;
                8'h18: sboxf=8'had; 8'h19: sboxf=8'hd4; 8'h1a: sboxf=8'ha2; 8'h1b: sboxf=8'haf;
                8'h1c: sboxf=8'h9c; 8'h1d: sboxf=8'ha4; 8'h1e: sboxf=8'h72; 8'h1f: sboxf=8'hc0;
                8'h20: sboxf=8'hb7; 8'h21: sboxf=8'hfd; 8'h22: sboxf=8'h93; 8'h23: sboxf=8'h26;
                8'h24: sboxf=8'h36; 8'h25: sboxf=8'h3f; 8'h26: sboxf=8'hf7; 8'h27: sboxf=8'hcc;
                8'h28: sboxf=8'h34; 8'h29: sboxf=8'ha5; 8'h2a: sboxf=8'he5; 8'h2b: sboxf=8'hf1;
                8'h2c: sboxf=8'h71; 8'h2d: sboxf=8'hd8; 8'h2e: sboxf=8'h31; 8'h2f: sboxf=8'h15;
                8'h30: sboxf=8'h04; 8'h31: sboxf=8'hc7; 8'h32: sboxf=8'h23; 8'h33: sboxf=8'hc3;
                8'h34: sboxf=8'h18; 8'h35: sboxf=8'h96; 8'h36: sboxf=8'h05; 8'h37: sboxf=8'h9a;
                8'h38: sboxf=8'h07; 8'h39: sboxf=8'h12; 8'h3a: sboxf=8'h80; 8'h3b: sboxf=8'he2;
                8'h3c: sboxf=8'heb; 8'h3d: sboxf=8'h27; 8'h3e: sboxf=8'hb2; 8'h3f: sboxf=8'h75;
                8'h40: sboxf=8'h09; 8'h41: sboxf=8'h83; 8'h42: sboxf=8'h2c; 8'h43: sboxf=8'h1a;
                8'h44: sboxf=8'h1b; 8'h45: sboxf=8'h6e; 8'h46: sboxf=8'h5a; 8'h47: sboxf=8'ha0;
                8'h48: sboxf=8'h52; 8'h49: sboxf=8'h3b; 8'h4a: sboxf=8'hd6; 8'h4b: sboxf=8'hb3;
                8'h4c: sboxf=8'h29; 8'h4d: sboxf=8'he3; 8'h4e: sboxf=8'h2f; 8'h4f: sboxf=8'h84;
                8'h50: sboxf=8'h53; 8'h51: sboxf=8'hd1; 8'h52: sboxf=8'h00; 8'h53: sboxf=8'hed;
                8'h54: sboxf=8'h20; 8'h55: sboxf=8'hfc; 8'h56: sboxf=8'hb1; 8'h57: sboxf=8'h5b;
                8'h58: sboxf=8'h6a; 8'h59: sboxf=8'hcb; 8'h5a: sboxf=8'hbe; 8'h5b: sboxf=8'h39;
                8'h5c: sboxf=8'h4a; 8'h5d: sboxf=8'h4c; 8'h5e: sboxf=8'h58; 8'h5f: sboxf=8'hcf;
                8'h60: sboxf=8'hd0; 8'h61: sboxf=8'hef; 8'h62: sboxf=8'haa; 8'h63: sboxf=8'hfb;
                8'h64: sboxf=8'h43; 8'h65: sboxf=8'h4d; 8'h66: sboxf=8'h33; 8'h67: sboxf=8'h85;
                8'h68: sboxf=8'h45; 8'h69: sboxf=8'hf9; 8'h6a: sboxf=8'h02; 8'h6b: sboxf=8'h7f;
                8'h6c: sboxf=8'h50; 8'h6d: sboxf=8'h3c; 8'h6e: sboxf=8'h9f; 8'h6f: sboxf=8'ha8;
                8'h70: sboxf=8'h51; 8'h71: sboxf=8'ha3; 8'h72: sboxf=8'h40; 8'h73: sboxf=8'h8f;
                8'h74: sboxf=8'h92; 8'h75: sboxf=8'h9d; 8'h76: sboxf=8'h38; 8'h77: sboxf=8'hf5;
                8'h78: sboxf=8'hbc; 8'h79: sboxf=8'hb6; 8'h7a: sboxf=8'hda; 8'h7b: sboxf=8'h21;
                8'h7c: sboxf=8'h10; 8'h7d: sboxf=8'hff; 8'h7e: sboxf=8'hf3; 8'h7f: sboxf=8'hd2;
                8'h80: sboxf=8'hcd; 8'h81: sboxf=8'h0c; 8'h82: sboxf=8'h13; 8'h83: sboxf=8'hec;
                8'h84: sboxf=8'h5f; 8'h85: sboxf=8'h97; 8'h86: sboxf=8'h44; 8'h87: sboxf=8'h17;
                8'h88: sboxf=8'hc4; 8'h89: sboxf=8'ha7; 8'h8a: sboxf=8'h7e; 8'h8b: sboxf=8'h3d;
                8'h8c: sboxf=8'h64; 8'h8d: sboxf=8'h5d; 8'h8e: sboxf=8'h19; 8'h8f: sboxf=8'h73;
                8'h90: sboxf=8'h60; 8'h91: sboxf=8'h81; 8'h92: sboxf=8'h4f; 8'h93: sboxf=8'hdc;
                8'h94: sboxf=8'h22; 8'h95: sboxf=8'h2a; 8'h96: sboxf=8'h90; 8'h97: sboxf=8'h88;
                8'h98: sboxf=8'h46; 8'h99: sboxf=8'hee; 8'h9a: sboxf=8'hb8; 8'h9b: sboxf=8'h14;
                8'h9c: sboxf=8'hde; 8'h9d: sboxf=8'h5e; 8'h9e: sboxf=8'h0b; 8'h9f: sboxf=8'hdb;
                8'ha0: sboxf=8'he0; 8'ha1: sboxf=8'h32; 8'ha2: sboxf=8'h3a; 8'ha3: sboxf=8'h0a;
                8'ha4: sboxf=8'h49; 8'ha5: sboxf=8'h06; 8'ha6: sboxf=8'h24; 8'ha7: sboxf=8'h5c;
                8'ha8: sboxf=8'hc2; 8'ha9: sboxf=8'hd3; 8'haa: sboxf=8'hac; 8'hab: sboxf=8'h62;
                8'hac: sboxf=8'h91; 8'had: sboxf=8'h95; 8'hae: sboxf=8'he4; 8'haf: sboxf=8'h79;
                8'hb0: sboxf=8'he7; 8'hb1: sboxf=8'hc8; 8'hb2: sboxf=8'h37; 8'hb3: sboxf=8'h6d;
                8'hb4: sboxf=8'h8d; 8'hb5: sboxf=8'hd5; 8'hb6: sboxf=8'h4e; 8'hb7: sboxf=8'ha9;
                8'hb8: sboxf=8'h6c; 8'hb9: sboxf=8'h56; 8'hba: sboxf=8'hf4; 8'hbb: sboxf=8'hea;
                8'hbc: sboxf=8'h65; 8'hbd: sboxf=8'h7a; 8'hbe: sboxf=8'hae; 8'hbf: sboxf=8'h08;
                8'hc0: sboxf=8'hba; 8'hc1: sboxf=8'h78; 8'hc2: sboxf=8'h25; 8'hc3: sboxf=8'h2e;
                8'hc4: sboxf=8'h1c; 8'hc5: sboxf=8'ha6; 8'hc6: sboxf=8'hb4; 8'hc7: sboxf=8'hc6;
                8'hc8: sboxf=8'he8; 8'hc9: sboxf=8'hdd; 8'hca: sboxf=8'h74; 8'hcb: sboxf=8'h1f;
                8'hcc: sboxf=8'h4b; 8'hcd: sboxf=8'hbd; 8'hce: sboxf=8'h8b; 8'hcf: sboxf=8'h8a;
                8'hd0: sboxf=8'h70; 8'hd1: sboxf=8'h3e; 8'hd2: sboxf=8'hb5; 8'hd3: sboxf=8'h66;
                8'hd4: sboxf=8'h48; 8'hd5: sboxf=8'h03; 8'hd6: sboxf=8'hf6; 8'hd7: sboxf=8'h0e;
                8'hd8: sboxf=8'h61; 8'hd9: sboxf=8'h35; 8'hda: sboxf=8'h57; 8'hdb: sboxf=8'hb9;
                8'hdc: sboxf=8'h86; 8'hdd: sboxf=8'hc1; 8'hde: sboxf=8'h1d; 8'hdf: sboxf=8'h9e;
                8'he0: sboxf=8'he1; 8'he1: sboxf=8'hf8; 8'he2: sboxf=8'h98; 8'he3: sboxf=8'h11;
                8'he4: sboxf=8'h69; 8'he5: sboxf=8'hd9; 8'he6: sboxf=8'h8e; 8'he7: sboxf=8'h94;
                8'he8: sboxf=8'h9b; 8'he9: sboxf=8'h1e; 8'hea: sboxf=8'h87; 8'heb: sboxf=8'he9;
                8'hec: sboxf=8'hce; 8'hed: sboxf=8'h55; 8'hee: sboxf=8'h28; 8'hef: sboxf=8'hdf;
                8'hf0: sboxf=8'h8c; 8'hf1: sboxf=8'ha1; 8'hf2: sboxf=8'h89; 8'hf3: sboxf=8'h0d;
                8'hf4: sboxf=8'hbf; 8'hf5: sboxf=8'he6; 8'hf6: sboxf=8'h42; 8'hf7: sboxf=8'h68;
                8'hf8: sboxf=8'h41; 8'hf9: sboxf=8'h99; 8'hfa: sboxf=8'h2d; 8'hfb: sboxf=8'h0f;
                8'hfc: sboxf=8'hb0; 8'hfd: sboxf=8'h54; 8'hfe: sboxf=8'hbb; 8'hff: sboxf=8'h16;
            endcase
        end
    endfunction

    function [7:0] xt;
        input [7:0] a;
        begin
            xt = {a[6:0], 1'b0} ^ (a[7] ? 8'h1b : 8'h00);
        end
    endfunction

    function [7:0] gmul;
        input [7:0] a;
        input [7:0] b;
        reg [7:0] p, aa, bb;
        integer k;
        begin
            p = 8'h0; aa = a; bb = b;
            for (k = 0; k < 8; k = k + 1) begin
                if (bb[0]) p = p ^ aa;
                aa = xt(aa);
                bb = {1'b0, bb[7:1]};
            end
            gmul = p;
        end
    endfunction

    // FIPS byte n <-> bits [127-8*n -: 8]
    function [127:0] sub_bytes_f;
        input [127:0] s;
        begin
            sub_bytes_f = {
                sboxf(s[127:120]), sboxf(s[119:112]), sboxf(s[111:104]), sboxf(s[103:96]),
                sboxf(s[95:88]),   sboxf(s[87:80]),   sboxf(s[79:72]),   sboxf(s[71:64]),
                sboxf(s[63:56]),   sboxf(s[55:48]),   sboxf(s[47:40]),   sboxf(s[39:32]),
                sboxf(s[31:24]),   sboxf(s[23:16]),   sboxf(s[15:8]),    sboxf(s[7:0])
            };
        end
    endfunction

    function [127:0] shift_rows_f;
        input [127:0] s;
        begin
            // out[4*c+r] = in[4*((c+r)%4)+r]
            shift_rows_f = {
                s[127:120], s[87:80], s[55:48], s[23:16],
                s[119:112], s[79:72], s[47:40], s[15:8],
                s[111:104], s[71:64], s[39:32], s[7:0],
                s[103:96],  s[63:56], s[31:24], s[127-8*15 -: 8]
            };
            // Explicit: byte n at [127-8*n]
            // n0=in0, n1=in5, n2=in10, n3=in15
            // n4=in4, n5=in9, n6=in14, n7=in3
            // n8=in8, n9=in13, n10=in2, n11=in7
            // n12=in12, n13=in1, n14=in6, n15=in11
            shift_rows_f = {
                s[127:120], // 0 <- 0
                s[87:80],   // 1 <- 5   byte5 = s[127-40 -:8]=s[87:80]
                s[55:48],   // 2 <- 10  byte10=s[127-80]=s[47:40] WAIT
                s[23:16],   // 3
                s[119:112], // 4
                s[79:72],   // 5 <- 9
                s[47:40],   // 6
                s[15:8],    // 7
                s[111:104], // 8
                s[71:64],   // 9 <- 13
                s[39:32],   // 10
                s[7:0],     // 11
                s[103:96],  // 12
                s[63:56],   // 13 <- 1
                s[31:24],   // 14
                s[95:88]    // 15 <- 11
            };
            // Correct mapping using byte index formula:
            // in[k] bits = s[127-8*k -: 8]
            shift_rows_f = {
                s[127:120],     // in0
                s[87:80],       // in5
                s[47:40],       // in10
                s[7:0],         // in15
                s[119:112],     // in4
                s[79:72],       // in9
                s[39:32],       // in14
                s[127-8*3 -:8], // in3 = s[103:96]
                s[111:104],     // in8
                s[71:64],       // in13
                s[31:24],       // in2
                s[127-8*7 -:8], // in7 = s[71:64] conflict — write clearly:
                8'h00, 8'h00, 8'h00, 8'h00
            };
        end
    endfunction

    // Clean helpers
    function [7:0] bget;
        input [127:0] s;
        input integer n; // 0..15, FIPS order
        begin
            bget = s[127-8*n -: 8];
        end
    endfunction

    function [127:0] bpack;
        input [7:0] b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15;
        begin
            bpack = {b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15};
        end
    endfunction

    function [127:0] sr;
        input [127:0] s;
        begin
            sr = bpack(
                bget(s,0),  bget(s,5),  bget(s,10), bget(s,15),
                bget(s,4),  bget(s,9),  bget(s,14), bget(s,3),
                bget(s,8),  bget(s,13), bget(s,2),  bget(s,7),
                bget(s,12), bget(s,1),  bget(s,6),  bget(s,11)
            );
        end
    endfunction

    function [127:0] isr;
        input [127:0] s;
        begin
            isr = bpack(
                bget(s,0),  bget(s,13), bget(s,10), bget(s,7),
                bget(s,4),  bget(s,1),  bget(s,14), bget(s,11),
                bget(s,8),  bget(s,5),  bget(s,2),  bget(s,15),
                bget(s,12), bget(s,9),  bget(s,6),  bget(s,3)
            );
        end
    endfunction

    function [31:0] mixcol;
        input [31:0] c;
        reg [7:0] a0,a1,a2,a3,t;
        begin
            a0=c[31:24]; a1=c[23:16]; a2=c[15:8]; a3=c[7:0];
            t = a0^a1^a2^a3;
            mixcol = {
                a0 ^ t ^ xt(a0^a1),
                a1 ^ t ^ xt(a1^a2),
                a2 ^ t ^ xt(a2^a3),
                a3 ^ t ^ xt(a3^a0)
            };
        end
    endfunction

    function [31:0] inv_mixcol;
        input [31:0] c;
        reg [7:0] a0,a1,a2,a3;
        begin
            a0=c[31:24]; a1=c[23:16]; a2=c[15:8]; a3=c[7:0];
            inv_mixcol = {
                gmul(a0,8'he)^gmul(a1,8'hb)^gmul(a2,8'hd)^gmul(a3,8'h9),
                gmul(a0,8'h9)^gmul(a1,8'he)^gmul(a2,8'hb)^gmul(a3,8'hd),
                gmul(a0,8'hd)^gmul(a1,8'h9)^gmul(a2,8'he)^gmul(a3,8'hb),
                gmul(a0,8'hb)^gmul(a1,8'hd)^gmul(a2,8'h9)^gmul(a3,8'he)
            };
        end
    endfunction

    function [127:0] mc;
        input [127:0] s;
        begin
            mc = {mixcol(s[127:96]), mixcol(s[95:64]), mixcol(s[63:32]), mixcol(s[31:0])};
        end
    endfunction

    function [127:0] imc;
        input [127:0] s;
        begin
            imc = {inv_mixcol(s[127:96]), inv_mixcol(s[95:64]),
                   inv_mixcol(s[63:32]),  inv_mixcol(s[31:0])};
        end
    endfunction

    function [127:0] next_rk;
        input [127:0] prev;
        input [3:0]   rnd; // 1..10
        reg [31:0] w0,w1,w2,w3,tmp;
        reg [7:0] rc;
        begin
            w0=prev[127:96]; w1=prev[95:64]; w2=prev[63:32]; w3=prev[31:0];
            tmp = {w3[23:0], w3[31:24]};
            tmp = {sboxf(tmp[31:24]), sboxf(tmp[23:16]), sboxf(tmp[15:8]), sboxf(tmp[7:0])};
            case (rnd)
                4'd1: rc=8'h01; 4'd2: rc=8'h02; 4'd3: rc=8'h04; 4'd4: rc=8'h08;
                4'd5: rc=8'h10; 4'd6: rc=8'h20; 4'd7: rc=8'h40; 4'd8: rc=8'h80;
                4'd9: rc=8'h1b; default: rc=8'h36;
            endcase
            tmp = tmp ^ {rc, 24'h0};
            w0 = w0 ^ tmp;
            w1 = w1 ^ w0;
            w2 = w2 ^ w1;
            w3 = w3 ^ w2;
            next_rk = {w0,w1,w2,w3};
        end
    endfunction

    function [7:0] isboxf;
        input [7:0] x;
        begin
            case (x)
                8'h00: isboxf=8'h52; 8'h01: isboxf=8'h09; 8'h02: isboxf=8'h6a; 8'h03: isboxf=8'hd5;
                8'h04: isboxf=8'h30; 8'h05: isboxf=8'h36; 8'h06: isboxf=8'ha5; 8'h07: isboxf=8'h38;
                8'h08: isboxf=8'hbf; 8'h09: isboxf=8'h40; 8'h0a: isboxf=8'ha3; 8'h0b: isboxf=8'h9e;
                8'h0c: isboxf=8'h81; 8'h0d: isboxf=8'hf3; 8'h0e: isboxf=8'hd7; 8'h0f: isboxf=8'hfb;
                8'h10: isboxf=8'h7c; 8'h11: isboxf=8'he3; 8'h12: isboxf=8'h39; 8'h13: isboxf=8'h82;
                8'h14: isboxf=8'h9b; 8'h15: isboxf=8'h2f; 8'h16: isboxf=8'hff; 8'h17: isboxf=8'h87;
                8'h18: isboxf=8'h34; 8'h19: isboxf=8'h8e; 8'h1a: isboxf=8'h43; 8'h1b: isboxf=8'h44;
                8'h1c: isboxf=8'hc4; 8'h1d: isboxf=8'hde; 8'h1e: isboxf=8'he9; 8'h1f: isboxf=8'hcb;
                8'h20: isboxf=8'h54; 8'h21: isboxf=8'h7b; 8'h22: isboxf=8'h94; 8'h23: isboxf=8'h32;
                8'h24: isboxf=8'ha6; 8'h25: isboxf=8'hc2; 8'h26: isboxf=8'h23; 8'h27: isboxf=8'h3d;
                8'h28: isboxf=8'hee; 8'h29: isboxf=8'h4c; 8'h2a: isboxf=8'h95; 8'h2b: isboxf=8'h0b;
                8'h2c: isboxf=8'h42; 8'h2d: isboxf=8'hfa; 8'h2e: isboxf=8'hc3; 8'h2f: isboxf=8'h4e;
                8'h30: isboxf=8'h08; 8'h31: isboxf=8'h2e; 8'h32: isboxf=8'ha1; 8'h33: isboxf=8'h66;
                8'h34: isboxf=8'h28; 8'h35: isboxf=8'hd9; 8'h36: isboxf=8'h24; 8'h37: isboxf=8'hb2;
                8'h38: isboxf=8'h76; 8'h39: isboxf=8'h5b; 8'h3a: isboxf=8'ha2; 8'h3b: isboxf=8'h49;
                8'h3c: isboxf=8'h6d; 8'h3d: isboxf=8'h8b; 8'h3e: isboxf=8'hd1; 8'h3f: isboxf=8'h25;
                8'h40: isboxf=8'h72; 8'h41: isboxf=8'hf8; 8'h42: isboxf=8'hf6; 8'h43: isboxf=8'h64;
                8'h44: isboxf=8'h86; 8'h45: isboxf=8'h68; 8'h46: isboxf=8'h98; 8'h47: isboxf=8'h16;
                8'h48: isboxf=8'hd4; 8'h49: isboxf=8'ha4; 8'h4a: isboxf=8'h5c; 8'h4b: isboxf=8'hcc;
                8'h4c: isboxf=8'h5d; 8'h4d: isboxf=8'h65; 8'h4e: isboxf=8'hb6; 8'h4f: isboxf=8'h92;
                8'h50: isboxf=8'h6c; 8'h51: isboxf=8'h70; 8'h52: isboxf=8'h48; 8'h53: isboxf=8'h50;
                8'h54: isboxf=8'hfd; 8'h55: isboxf=8'hed; 8'h56: isboxf=8'hb9; 8'h57: isboxf=8'hda;
                8'h58: isboxf=8'h5e; 8'h59: isboxf=8'h15; 8'h5a: isboxf=8'h46; 8'h5b: isboxf=8'h57;
                8'h5c: isboxf=8'ha7; 8'h5d: isboxf=8'h8d; 8'h5e: isboxf=8'h9d; 8'h5f: isboxf=8'h84;
                8'h60: isboxf=8'h90; 8'h61: isboxf=8'hd8; 8'h62: isboxf=8'hab; 8'h63: isboxf=8'h00;
                8'h64: isboxf=8'h8c; 8'h65: isboxf=8'hbc; 8'h66: isboxf=8'hd3; 8'h67: isboxf=8'h0a;
                8'h68: isboxf=8'hf7; 8'h69: isboxf=8'he4; 8'h6a: isboxf=8'h58; 8'h6b: isboxf=8'h05;
                8'h6c: isboxf=8'hb8; 8'h6d: isboxf=8'hb3; 8'h6e: isboxf=8'h45; 8'h6f: isboxf=8'h06;
                8'h70: isboxf=8'hd0; 8'h71: isboxf=8'h2c; 8'h72: isboxf=8'h1e; 8'h73: isboxf=8'h8f;
                8'h74: isboxf=8'hca; 8'h75: isboxf=8'h3f; 8'h76: isboxf=8'h0f; 8'h77: isboxf=8'h02;
                8'h78: isboxf=8'hc1; 8'h79: isboxf=8'haf; 8'h7a: isboxf=8'hbd; 8'h7b: isboxf=8'h03;
                8'h7c: isboxf=8'h01; 8'h7d: isboxf=8'h13; 8'h7e: isboxf=8'h8a; 8'h7f: isboxf=8'h6b;
                8'h80: isboxf=8'h3a; 8'h81: isboxf=8'h91; 8'h82: isboxf=8'h11; 8'h83: isboxf=8'h41;
                8'h84: isboxf=8'h4f; 8'h85: isboxf=8'h67; 8'h86: isboxf=8'hdc; 8'h87: isboxf=8'hea;
                8'h88: isboxf=8'h97; 8'h89: isboxf=8'hf2; 8'h8a: isboxf=8'hcf; 8'h8b: isboxf=8'hce;
                8'h8c: isboxf=8'hf0; 8'h8d: isboxf=8'hb4; 8'h8e: isboxf=8'he6; 8'h8f: isboxf=8'h73;
                8'h90: isboxf=8'h96; 8'h91: isboxf=8'hac; 8'h92: isboxf=8'h74; 8'h93: isboxf=8'h22;
                8'h94: isboxf=8'he7; 8'h95: isboxf=8'had; 8'h96: isboxf=8'h35; 8'h97: isboxf=8'h85;
                8'h98: isboxf=8'he2; 8'h99: isboxf=8'hf9; 8'h9a: isboxf=8'h37; 8'h9b: isboxf=8'he8;
                8'h9c: isboxf=8'h1c; 8'h9d: isboxf=8'h75; 8'h9e: isboxf=8'hdf; 8'h9f: isboxf=8'h6e;
                8'ha0: isboxf=8'h47; 8'ha1: isboxf=8'hf1; 8'ha2: isboxf=8'h1a; 8'ha3: isboxf=8'h71;
                8'ha4: isboxf=8'h1d; 8'ha5: isboxf=8'h29; 8'ha6: isboxf=8'hc5; 8'ha7: isboxf=8'h89;
                8'ha8: isboxf=8'h6f; 8'ha9: isboxf=8'hb7; 8'haa: isboxf=8'h62; 8'hab: isboxf=8'h0e;
                8'hac: isboxf=8'haa; 8'had: isboxf=8'h18; 8'hae: isboxf=8'hbe; 8'haf: isboxf=8'h1b;
                8'hb0: isboxf=8'hfc; 8'hb1: isboxf=8'h56; 8'hb2: isboxf=8'h3e; 8'hb3: isboxf=8'h4b;
                8'hb4: isboxf=8'hc6; 8'hb5: isboxf=8'hd2; 8'hb6: isboxf=8'h79; 8'hb7: isboxf=8'h20;
                8'hb8: isboxf=8'h9a; 8'hb9: isboxf=8'hdb; 8'hba: isboxf=8'hc0; 8'hbb: isboxf=8'hfe;
                8'hbc: isboxf=8'h78; 8'hbd: isboxf=8'hcd; 8'hbe: isboxf=8'h5a; 8'hbf: isboxf=8'hf4;
                8'hc0: isboxf=8'h1f; 8'hc1: isboxf=8'hdd; 8'hc2: isboxf=8'ha8; 8'hc3: isboxf=8'h33;
                8'hc4: isboxf=8'h88; 8'hc5: isboxf=8'h07; 8'hc6: isboxf=8'hc7; 8'hc7: isboxf=8'h31;
                8'hc8: isboxf=8'hb1; 8'hc9: isboxf=8'h12; 8'hca: isboxf=8'h10; 8'hcb: isboxf=8'h59;
                8'hcc: isboxf=8'h27; 8'hcd: isboxf=8'h80; 8'hce: isboxf=8'hec; 8'hcf: isboxf=8'h5f;
                8'hd0: isboxf=8'h60; 8'hd1: isboxf=8'h51; 8'hd2: isboxf=8'h7f; 8'hd3: isboxf=8'ha9;
                8'hd4: isboxf=8'h19; 8'hd5: isboxf=8'hb5; 8'hd6: isboxf=8'h4a; 8'hd7: isboxf=8'h0d;
                8'hd8: isboxf=8'h2d; 8'hd9: isboxf=8'he5; 8'hda: isboxf=8'h7a; 8'hdb: isboxf=8'h9f;
                8'hdc: isboxf=8'h93; 8'hdd: isboxf=8'hc9; 8'hde: isboxf=8'h9c; 8'hdf: isboxf=8'hef;
                8'he0: isboxf=8'ha0; 8'he1: isboxf=8'he0; 8'he2: isboxf=8'h3b; 8'he3: isboxf=8'h4d;
                8'he4: isboxf=8'hae; 8'he5: isboxf=8'h2a; 8'he6: isboxf=8'hf5; 8'he7: isboxf=8'hb0;
                8'he8: isboxf=8'hc8; 8'he9: isboxf=8'heb; 8'hea: isboxf=8'hbb; 8'heb: isboxf=8'h3c;
                8'hec: isboxf=8'h83; 8'hed: isboxf=8'h53; 8'hee: isboxf=8'h99; 8'hef: isboxf=8'h61;
                8'hf0: isboxf=8'h17; 8'hf1: isboxf=8'h2b; 8'hf2: isboxf=8'h04; 8'hf3: isboxf=8'h7e;
                8'hf4: isboxf=8'hba; 8'hf5: isboxf=8'h77; 8'hf6: isboxf=8'hd6; 8'hf7: isboxf=8'h26;
                8'hf8: isboxf=8'he1; 8'hf9: isboxf=8'h69; 8'hfa: isboxf=8'h14; 8'hfb: isboxf=8'h63;
                8'hfc: isboxf=8'h55; 8'hfd: isboxf=8'h21; 8'hfe: isboxf=8'h0c; 8'hff: isboxf=8'h7d;
            endcase
        end
    endfunction

    function [127:0] inv_sub_bytes_f;
        input [127:0] s;
        begin
            inv_sub_bytes_f = {
                isboxf(s[127:120]), isboxf(s[119:112]), isboxf(s[111:104]), isboxf(s[103:96]),
                isboxf(s[95:88]),   isboxf(s[87:80]),   isboxf(s[79:72]),   isboxf(s[71:64]),
                isboxf(s[63:56]),   isboxf(s[55:48]),   isboxf(s[47:40]),   isboxf(s[39:32]),
                isboxf(s[31:24]),   isboxf(s[23:16]),   isboxf(s[15:8]),    isboxf(s[7:0])
            };
        end
    endfunction

    // ---- state ----
    reg [127:0] rk [0:10];
    reg [127:0] state;
    reg [3:0]   kcnt;
    reg [3:0]   rcnt;
    reg         is_dec;
    reg [2:0]   st;

    localparam S_IDLE=0, S_KEXP=1, S_INIT=2, S_ROUNDS=3, S_LAST=4, S_DONE=5;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 128'h0;
            dout  <= 128'h0;
            busy  <= 1'b0;
            done  <= 1'b0;
            kcnt  <= 4'd0;
            rcnt  <= 4'd0;
            is_dec<= 1'b0;
            st    <= S_IDLE;
            for (i = 0; i <= 10; i = i + 1)
                rk[i] <= 128'h0;
        end else begin
            done <= 1'b0;
            case (st)
                S_IDLE: if (start) begin
                    busy   <= 1'b1;
                    is_dec <= decrypt;
                    rk[0]  <= key;
                    kcnt   <= 4'd0;
                    st     <= S_KEXP;
                end
                S_KEXP: begin
                    if (kcnt < 4'd10) begin
                        rk[kcnt+1] <= next_rk(rk[kcnt], kcnt + 4'd1);
                        kcnt <= kcnt + 4'd1;
                    end else begin
                        if (is_dec) begin
                            state <= din ^ rk[10];
                            rcnt  <= 4'd9;
                            st    <= S_ROUNDS; // InvRounds 9..1 then InvFinal
                        end else begin
                            state <= din ^ rk[0];
                            rcnt  <= 4'd1;
                            st    <= S_ROUNDS;
                        end
                    end
                end
                S_ROUNDS: begin
                    if (!is_dec) begin
                        // rounds 1..9
                        state <= mc(sr(sub_bytes_f(state))) ^ rk[rcnt];
                        if (rcnt == 4'd9) begin
                            st <= S_LAST;
                        end else
                            rcnt <= rcnt + 4'd1;
                    end else begin
                        // InvRound on rk[9]..rk[1]: InvShift, InvSub, ARK, InvMix
                        state <= imc(inv_sub_bytes_f(isr(state)) ^ rk[rcnt]);
                        if (rcnt == 4'd1)
                            st <= S_LAST;
                        else
                            rcnt <= rcnt - 4'd1;
                    end
                end
                S_LAST: begin
                    if (!is_dec)
                        dout <= sr(sub_bytes_f(state)) ^ rk[10];
                    else
                        dout <= isr(inv_sub_bytes_f(state)) ^ rk[0];
                    st <= S_DONE;
                end
                S_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    st   <= S_IDLE;
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule
