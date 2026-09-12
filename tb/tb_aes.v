// FIPS-197 C.1 vector + decrypt round-trip
`timescale 1ns/1ps

module tb_aes;
    reg clk = 0;
    reg rst_n = 0;
    always #5 clk = ~clk;

    reg         wr = 0, rd = 0;
    reg  [5:0]  waddr = 0, raddr = 0;
    reg  [31:0] wdata = 0;
    wire [31:0] rdata;

    cryptocore_top dut (
        .clk(clk), .rst_n(rst_n),
        .wr(wr), .waddr(waddr), .wdata(wdata),
        .rd(rd), .raddr(raddr), .rdata(rdata)
    );

    task mmio_wr;
        input [5:0] a;
        input [31:0] d;
        begin
            @(posedge clk);
            wr <= 1; waddr <= a; wdata <= d;
            @(posedge clk);
            wr <= 0;
        end
    endtask

    task mmio_rd;
        input [5:0] a;
        output [31:0] d;
        begin
            @(posedge clk);
            rd <= 1; raddr <= a;
            @(posedge clk);
            d = rdata;
            rd <= 0;
        end
    endtask

    task wait_done;
        integer guard;
        reg [31:0] st;
        begin
            guard = 0;
            st = 0;
            while (!st[1] && guard < 1000) begin
                mmio_rd(6'h04, st);
                guard = guard + 1;
            end
            if (!st[1]) begin
                $display("TIMEOUT waiting done, status=%h", st);
                $display("FAIL");
                $finish;
            end
        end
    endtask

    task load_key_enc;
        // KEY 000102...0f, PT 001122...ff, decrypt=0
        begin
            mmio_wr(6'h08, 32'h00010203);
            mmio_wr(6'h0C, 32'h04050607);
            mmio_wr(6'h10, 32'h08090a0b);
            mmio_wr(6'h14, 32'h0c0d0e0f);
            mmio_wr(6'h18, 32'h00112233);
            mmio_wr(6'h1C, 32'h44556677);
            mmio_wr(6'h20, 32'h8899aabb);
            mmio_wr(6'h24, 32'hccddeeff);
            mmio_wr(6'h00, 32'h1); // start encrypt
        end
    endtask

    reg [31:0] d0,d1,d2,d3;
    reg [31:0] st;

    initial begin
        $dumpfile("tb_aes.vcd");
        $dumpvars(0, tb_aes);
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        // ---- Encrypt FIPS-197 C.1 ----
        load_key_enc();
        wait_done();
        mmio_rd(6'h28, d0);
        mmio_rd(6'h2C, d1);
        mmio_rd(6'h30, d2);
        mmio_rd(6'h34, d3);
        $display("ENC got  %h %h %h %h", d0,d1,d2,d3);
        $display("ENC want 69c4e0d8 6a7b0430 d8cdb780 70b4c55a");
        if (d0 !== 32'h69c4e0d8 || d1 !== 32'h6a7b0430 ||
            d2 !== 32'hd8cdb780 || d3 !== 32'h70b4c55a) begin
            $display("FAIL encrypt");
            $finish;
        end
        $display("ENCRYPT PASS");

        // clear done
        mmio_wr(6'h04, 32'h2);

        // ---- Decrypt the same CT back to PT ----
        mmio_wr(6'h18, 32'h69c4e0d8);
        mmio_wr(6'h1C, 32'h6a7b0430);
        mmio_wr(6'h20, 32'hd8cdb780);
        mmio_wr(6'h24, 32'h70b4c55a);
        mmio_wr(6'h00, 32'h3); // decrypt + start
        wait_done();
        mmio_rd(6'h28, d0);
        mmio_rd(6'h2C, d1);
        mmio_rd(6'h30, d2);
        mmio_rd(6'h34, d3);
        $display("DEC got  %h %h %h %h", d0,d1,d2,d3);
        if (d0 !== 32'h00112233 || d1 !== 32'h44556677 ||
            d2 !== 32'h8899aabb || d3 !== 32'hccddeeff) begin
            $display("FAIL decrypt");
            $finish;
        end
        $display("DECRYPT PASS");
        $display("PASS");
        $finish;
    end
endmodule
