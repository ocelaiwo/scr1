`include "scr1_arch_description.svh"
`include "scr1_ahb.svh"
`ifdef SCR1_IPIC_EN
`include "scr1_ipic.svh"
`endif // SCR1_IPIC_EN

module top_exp_ahb (
    input logic                clk,

// Instruction Memory Interface
    inout logic [3:0]                imem_hprot,
    inout logic [2:0]                imem_hburst,
    inout logic [2:0]                imem_hsize,
    inout logic [1:0]                imem_htrans,
    inout logic [SCR1_AHB_WIDTH-1:0] imem_haddr,
    output logic                      imem_hready,
    output logic [SCR1_AHB_WIDTH-1:0] imem_hrdata,
    output logic                      imem_hresp,

// Memory Interface
    inout logic [3:0]                dmem_hprot,
    inout logic [2:0]                dmem_hburst,
    inout logic [2:0]                dmem_hsize,
    inout logic [1:0]                dmem_htrans,
    inout logic [SCR1_AHB_WIDTH-1:0] dmem_haddr,
    inout logic                      dmem_hwrite,
    inout logic [SCR1_AHB_WIDTH-1:0] dmem_hwdata,
    output logic                      dmem_hready,
    output logic [SCR1_AHB_WIDTH-1:0] dmem_hrdata,
    output logic                      dmem_hresp

);

//-------------------------------------------------------------------------------
// Local parameters
//-------------------------------------------------------------------------------
localparam                          SCR1_MEM_SIZE       = 1024*1024;
localparam                          TIMEOUT             = 'd2000_000;//20ms;
localparam                          ARCH                = 'h1;
localparam                          COMPLIANCE          = 'h2;
localparam                          ADDR_START          = 'h200;
localparam                          ADDR_TRAP_VECTOR    = 'h240;
localparam                          ADDR_TRAP_DEFAULT   = 'h1C0;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
logic                                   rst_n;
logic                                   rtc_clk     = 1'b0;
`ifdef SCR1_IPIC_EN
logic [SCR1_IRQ_LINES_NUM-1:0]          irq_lines;
`else // SCR1_IPIC_EN
logic                                   ext_irq;
`endif // SCR1_IPIC_EN
logic                                   soft_irq;
logic [31:0]                            fuse_mhartid;
integer                                 imem_req_ack_stall;
integer                                 dmem_req_ack_stall;

logic                                   test_mode   = 1'b0;
`ifdef SCR1_DBG_EN
logic                                   trst_n;
logic                                   tck;
logic                                   tms;
logic                                   tdi;
logic                                   tdo;
logic                                   tdo_en;
`endif // SCR1_DBG_EN

bit [1:0]                               rst_cnt;
bit                                     rst_init;

// Reset logic
assign rst_n = &rst_cnt;

always_ff @(posedge clk) begin
    if (rst_init)       rst_cnt <= '0;
    else if (~&rst_cnt) rst_cnt <= rst_cnt + 1'b1;
end


`ifdef SCR1_DBG_EN
initial begin
    trst_n  = 1'b0;
    tck     = 1'b0;
    tdi     = 1'b0;
    #900ns trst_n   = 1'b1;
    #500ns tms      = 1'b1;
    #800ns tms      = 1'b0;
    #500ns trst_n   = 1'b0;
    #100ns tms      = 1'b1;
end
`endif // SCR1_DBG_EN

//-------------------------------------------------------------------------------
// Core instance
//-------------------------------------------------------------------------------
scr1_top_ahb i_top (
    // Reset
    .pwrup_rst_n            (rst_n                  ),
    .rst_n                  (rst_n                  ),
    .cpu_rst_n              (rst_n                  ),
`ifdef SCR1_DBG_EN
    .sys_rst_n_o            (                       ),
    .sys_rdc_qlfy_o         (                       ),
`endif // SCR1_DBG_EN

    // Clock
    .clk                    (clk                    ),
    .rtc_clk                (rtc_clk                ),

    // Fuses
    .fuse_mhartid           (fuse_mhartid           ),
`ifdef SCR1_DBG_EN
    .fuse_idcode            (`SCR1_TAP_IDCODE       ),
`endif // SCR1_DBG_EN

    // IRQ
`ifdef SCR1_IPIC_EN
    .irq_lines              (irq_lines              ),
`else // SCR1_IPIC_EN
    .ext_irq                (ext_irq                ),
`endif // SCR1_IPIC_EN
    .soft_irq               (soft_irq               ),

    // DFT
    .test_mode              (1'b0                   ),
    .test_rst_n             (1'b1                   ),

`ifdef SCR1_DBG_EN
    // JTAG
    .trst_n                 (trst_n                 ),
    .tck                    (tck                    ),
    .tms                    (tms                    ),
    .tdi                    (tdi                    ),
    .tdo                    (tdo                    ),
    .tdo_en                 (tdo_en                 ),
`endif // SCR1_DBG_EN

    // Instruction Memory Interface
    .imem_hprot         (imem_hprot     ),
    .imem_hburst        (imem_hburst    ),
    .imem_hsize         (imem_hsize     ),
    .imem_htrans        (imem_htrans    ),
    .imem_hmastlock     (),
    .imem_haddr         (imem_haddr     ),
    .imem_hready        (imem_hready    ),
    .imem_hrdata        (imem_hrdata    ),
    .imem_hresp         (imem_hresp     ),

    // Data Memory Interface
    .dmem_hprot         (dmem_hprot     ),
    .dmem_hburst        (dmem_hburst    ),
    .dmem_hsize         (dmem_hsize     ),
    .dmem_htrans        (dmem_htrans    ),
    .dmem_hmastlock     (),
    .dmem_haddr         (dmem_haddr     ),
    .dmem_hwrite        (dmem_hwrite    ),
    .dmem_hwdata        (dmem_hwdata    ),
    .dmem_hready        (dmem_hready    ),
    .dmem_hrdata        (dmem_hrdata    ),
    .dmem_hresp         (dmem_hresp     )
);

endmodule : top_exp_ahb

