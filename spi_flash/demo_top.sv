/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/20 下午2:19:13
madified:
***********************************************/
`timescale 1ns/1ns
module demo_top #(
    parameter   SSIZE = 1
)(
    input                   clock           ,
    input                   rst_n           ,
    input                   spi_dr_clock    ,
    input                   spi_dr_rst_n    ,
    //-- spi interface
    output                  spi_csn         ,
    output                  spi_sck         ,
    inout [4-1:0]           spi_dq          ,
    input                   trigger_0       ,
    input                   trigger_1       ,
    input                   trigger_2       ,
    input                   trigger_3       ,

    output                  led_0           ,
    output                  led_1           ,
    output                  led_2           ,
    output                  led_3
);

wire    clk_en;
assign  clk_en  = 1'b1;

//---->> interface defaine <<-----------------------
cmd_inf #(
    .CSIZE      (4      ),
    .LSIZE      (24     ),
    .SLIZE      (16     )
)cmd_inf ();

data_inf #(
    .DSIZE      (8      )
)wr_data_inf();

data_inf #(
    .DSIZE      (8      )
)rd_data_inf();

data_inf #(
    .DSIZE      (8      )
)rd_data_inf_1();

data_inf #(
    .DSIZE      (8      )
)wr_data_inf_1();
//----<< interface defaine >>-----------------------
bit rd_frame_flag ;
bit wr_frame_flag ;

spi_flash_verb #(
    .PHASE          (0      ),
    .ACTIVE         (0      ),
    .SSIZE          (SSIZE  ),
    .DSIZE          (8      )
)spi_flash_inst(
    //-- spi interface
/*  output            */    .spi_csn         (spi_csn       ),
/*  output            */    .spi_sck         (spi_sck       ),
/*  inout [SSIZE-1:0] */    .spi_dq          (spi_dq        ),
    //---
/*  input             */    .dr_spi_clk      (spi_dr_clock  ),   //spi data rate
/*  input             */    .dr_spi_rst_n    (spi_dr_rst_n  ),
/*  input             */    .clock           (clock         ),
/*  input             */    .rst_n           (rst_n         ),
/*  input             */    .clk_en          (clk_en        ),
    //---
/*  cmd_inf.slaver    */    .cmd_inf         (cmd_inf       ),
/*  data_inf.slaver   */    .wr_data_inf     (wr_data_inf   ),
/*  data_inf.master   */    .rd_data_inf     (rd_data_inf   ),
/*  data_inf.master   */    .rd_data_inf_1   (rd_data_inf_1 ),
/*  input             */    .rd_frame_flag   (rd_frame_flag ),
/*  data_inf.slaver   */    .wr_data_inf_1   (wr_data_inf_1 ),
/*  input             */    .wr_frame_flag   (wr_frame_flag )
);

// defparam spi_flash_inst.spi_master_inst.spi_sck_inst.custom_ddio_inst.MODE = "ALTERA";

rd_wr_burst_rtl_test #(
    .DELAY      (24000)
)rd_wr_burst_rtl_test_inst(
/*    input  */     .clock          (clock      ),
/*    input  */     .rst_n          (rst_n      ),
/*    input  */     .clk_en         (clk_en     ),
/*    input  */     .trigger_0      (trigger_0  ),
/*    input  */     .trigger_1      (trigger_1  ),
/*    input  */     .trigger_2      (trigger_2  ),
/*    input  */     .trigger_3      (trigger_3  ),
/*    output reg */ .led_0          (led_0      ),
/*    output reg */ .led_1          (led_1      ),
/*    output reg */ .led_2          (led_2      ),
/*    output reg */ .led_3          (led_3      ),
/*    output reg */ .rd_frame_flag  (rd_frame_flag  ),
/*    output reg */ .wr_frame_flag  (wr_frame_flag  ),

/*    cmd_inf.master */ .cmd_inf    (cmd_inf    ),
/*    data_inf.master*/ .wr_data_inf(wr_data_inf_1),
/*    data_inf.slaver*/ .rd_data_inf(rd_data_inf_1)
);

endmodule
