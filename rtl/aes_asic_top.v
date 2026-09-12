// ASIC top: flat MMIO ports for OpenLane pin placement.
// Same register map as aes_mmio / cryptocore_top.
module aes_asic_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        wr,
    input  wire [5:0]  waddr,
    input  wire [31:0] wdata,
    input  wire        rd,
    input  wire [5:0]  raddr,
    output wire [31:0] rdata
);
    cryptocore_top u_core (
        .clk   (clk),
        .rst_n (rst_n),
        .wr    (wr),
        .waddr (waddr),
        .wdata (wdata),
        .rd    (rd),
        .raddr (raddr),
        .rdata (rdata)
    );
endmodule
