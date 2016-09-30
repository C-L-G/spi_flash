/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/19 下午1:45:00
Version: VERB : 2016/9/28 上午10:38:41
    use spi_master verb
madified:
***********************************************/
`timescale 1ns/1ps
module spi_flash_verb #(
    parameter PHASE     = 0,
    parameter ACTIVE    = 0,
    parameter SSIZE = 4,
    parameter DSIZE = 8
)(
    //-- spi interface
    output                  spi_csn         ,
    output                  spi_sck         ,
    inout [4-1:0]           spi_dq          ,
    //---
    input                   dr_spi_clk      ,   //double spi data rate
    input                   dr_spi_rst_n    ,
    input                   clock           ,
    input                   rst_n           ,
    input                   clk_en          ,
    //---
    cmd_inf.slaver          cmd_inf,
    //--
    data_inf.slaver         wr_data_inf     ,
    data_inf.master         rd_data_inf     ,
    data_inf.master         rd_data_inf_1   ,
    input                   rd_frame_flag   ,
    input                   wr_frame_flag   ,
    data_inf.slaver         wr_data_inf_1
);

wire[DSIZE-1:0]       spi_id          ;
wire                  spi_id_vld      ;
spi_req_inf #(
    .DSIZE      (DSIZE  )
)inc_2_master(
/*  input bit */ .clock      (clock        ),
/*  input bit */ .rst_n      (rst_n        ),
/*  input bit */ .clk_en     (clk_en       )
);

spi_req_inf #(
    .DSIZE      (DSIZE  )
)s0(
/*  input bit */ .clock      (clock         ),
/*  input bit */ .rst_n      (rst_n         ),
/*  input bit */ .clk_en     (clk_en        )
);

spi_req_inf #(
    .DSIZE      (DSIZE  )
)s1(
/*  input bit */ .clock      (clock         ),
/*  input bit */ .rst_n      (rst_n         ),
/*  input bit */ .clk_en     (clk_en        )
);

spi_req_inf #(
    .DSIZE      (DSIZE  )
)s2(
/*  input bit */ .clock      (clock         ),
/*  input bit */ .rst_n      (rst_n         ),
/*  input bit */ .clk_en     (clk_en        )
);

spi_req_inf #(
    .DSIZE      (DSIZE  )
)s3(
/*  input bit */ .clock      (clock         ),
/*  input bit */ .rst_n      (rst_n         ),
/*  input bit */ .clk_en     (clk_en        )
);

spi_req_inf #(
    .DSIZE      (DSIZE  )
)s4(
/*  input bit */ .clock      (clock         ),
/*  input bit */ .rst_n      (rst_n         ),
/*  input bit */ .clk_en     (clk_en        )
);

spi_req_inf #(
    .DSIZE      (DSIZE  )
)s5(
/*  input bit */ .clock      (clock         ),
/*  input bit */ .rst_n      (rst_n         ),
/*  input bit */ .clk_en     (clk_en        )
);

spi_req_inf #(
    .DSIZE      (DSIZE  )
)s6(
/*  input bit */ .clock      (clock         ),
/*  input bit */ .rst_n      (rst_n         ),
/*  input bit */ .clk_en     (clk_en        )
);

spi_req_inf #(
    .DSIZE      (DSIZE  )
)s7(
/*  input bit */ .clock      (clock         ),
/*  input bit */ .rst_n      (rst_n         ),
/*  input bit */ .clk_en     (clk_en        )
);

spi_master_verb #(
    .PHASE     (PHASE     ),
    .ACTIVE    (ACTIVE    ),
    .SSIZE     (SSIZE     ),
    .CSNUM     (DSIZE/SSIZE     )
)spi_master_inst(
    //-- spi interface
/*  output             */   .spi_csn         (spi_csn         ),
/*  output             */   .spi_sck         (spi_sck         ),
/*  inout [4-1:0]      */   .spi_dq          (spi_dq          ),
    //---
/*  input              */   .spi_dr_clock    (dr_spi_clk      ),    //spi data rate
/*  input              */   .spi_dr_rst_n    (dr_spi_rst_n    ),
    //--- ctrl signals
/*  input              */   .request         (inc_2_master.request     ),
/*  input [23:0]       */   .req_len         (inc_2_master.req_len     ),
/*  input [23:0]       */   .req_wr_len      (inc_2_master.req_wr_len  ),
/*  input [2:0]        */   .req_cmd         (inc_2_master.req_cmd     ),
/*  output             */   .busy            (inc_2_master.busy        ),
/*  output             */   .finish          (inc_2_master.finish      ),
    //--- write port
/*  input                  */ .wr_clk        (inc_2_master.clock       ),
/*  input                  */ .wr_rst_n      (inc_2_master.rst_n       ),
/*  input                  */ .wr_en         (inc_2_master.clk_en      ),
/*  input                  */ .wr_vld        (inc_2_master.wr_vld      ),
/*  input [SSIZE*CSNUM-1:0]*/ .wr_data       (inc_2_master.wr_data     ),
/*  output                 */ .wr_ready      (inc_2_master.wr_ready    ),
/*  output                 */ .wr_last       (inc_2_master.wr_last     ),
    //--- read port
/*  input                  */ .rd_clk        (inc_2_master.clock       ),
/*  input                  */ .rd_rst_n      (inc_2_master.rst_n       ),
/*  input                  */ .rd_en         (inc_2_master.clk_en      ),
/*  input                  */ .rd_ready      (inc_2_master.rd_ready    ),
/*  output                 */ .rd_vld        (inc_2_master.rd_vld      ),
/*  output[SSIZE*CSNUM-1:0]*/ .rd_data       (inc_2_master.rd_data     )
);

spi_req_interconnect #(
    .DSIZE      (DSIZE      )
)spi_req_interconnect_inst(
/*  spi_req_inf.slaver */ .s0           (s0           ),
/*  spi_req_inf.slaver */ .s1           (s1           ),
/*  spi_req_inf.slaver */ .s2           (s2           ),
/*  spi_req_inf.slaver */ .s3           (s3           ),
/*  spi_req_inf.slaver */ .s4           (s4           ),
/*  spi_req_inf.slaver */ .s5           (s5           ),
/*  spi_req_inf.slaver */ .s6           (s6           ),
/*  spi_req_inf.slaver */ .s7           (s7           ),
/*  spi_req_inf.master */ .m0           (inc_2_master)
);

spi_read_ID #(
    .DSIZE      (DSIZE  ),
    .CMD        (1      ),
    .MODULE_ID  (0      ),
    .SSIZE      (SSIZE  )
)spi_read_ID_inst0(
/*  cmd_inf.slaver    */  .cmd_inf      (cmd_inf  ),
/*  output[DSIZE-1:0] */  .spi_id       (         ),
/*  output            */  .id_vld       (         ),
/*  spi_req_inf.master*/  .inf          (s0             )
);


spi_write_enable #(
    .MODULE_ID  (1      ),
    .CMD_WR_EN  (2      ),
    .CMD_WR_DS  (3      ),
    .SSIZE      (SSIZE  )
)spi_write_enable_inst(
/*  cmd_inf.slaver    */  .cmd_inf          (cmd_inf  ),
/*  spi_req_inf.master */ .inf              (s1         )
);

spi_page_write #(
    .MODULE_ID      (2          ),
    .CMD            (4          ),
    .DSIZE          (DSIZE      ),
    .BURST_LEN      (256        ),
    .SSIZE          (SSIZE      )
)spi_page_write_inst(
/*  cmd_inf.slaver      */ .cmd_inf         (cmd_inf    ),
/*  spi_req_inf.master  */ .inf             (s2         ),
/*  input [3*DSIZE-1:0] */ .wr_addr         ({8'd000,8'd100,8'd000}      ),
/*  data_interface      */ .data_inf        (wr_data_inf   )
);


set_dq_x4 #(
    .MODULE_ID  (3  ),
    .CMD        (5  )
)set_dq_x4_inst(
/*  input [1:0]        */ .outside_flash_xx  (0         ),        //X1 X2 X4
/*  cmd_inf.slaver     */ .cmd_inf           (cmd_inf   ),
/*  spi_req_inf.master */ .inf               (s3        )
);


spi_read_mem #(
    .MODULE_ID      (4      ),
    .CMD            (6      ),
    .SSIZE          (SSIZE  ),
    .DSIZE          (DSIZE  )
)spi_read_mem_inst(
/*  cmd_inf.slaver      */  .cmd_inf        (cmd_inf    ),
/*  spi_req_inf.master  */  .inf            (s4         ),
/*  input [3*DSIZE-1:0] */  .rd_addr        ({8'd000,8'd100,8'd000} ),
/*  data_inf.master     */  .data_inf       (rd_data_inf)
);

read_flash_burst #(
    .SSIZE      (SSIZE  ),
    .DSIZE      (DSIZE  )
)read_flash_burst_inst(
/*  spi_req_inf.master*/  .inf              (s5             ),
/*  data_inf.master   */  .data_inf         (rd_data_inf_1  ),
/*  input             */  .frame_flag       (rd_frame_flag  )
);

write_flash_burst #(
    .DSIZE      (DSIZE  ),
    .SSIZE      (SSIZE  )
)write_flash_burst_inst(
/*  input              */ .frame_flag       (wr_frame_flag  ),
/*  spi_req_inf.master */ .inf              (s6             ),
/*  data_inf.slaver    */ .data_inf         (wr_data_inf_1  )
);

endmodule
