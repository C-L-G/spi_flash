/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/14 下午4:35:22
madified:
***********************************************/
`timescale 1ns/1ps
module spi_slaver #(
    parameter PHASE     = 0,
    parameter ACTIVE    = 0,
    parameter SSIZE     = 1,
    parameter CSNUM     = 8
)(
    //-- spi interface
    input                   spi_csn         ,
    input                   spi_sck         ,
    input [SSIZE-1:0]       spi_mosi        ,
    output[SSIZE-1:0]       spi_miso        ,
    //--- write port
    input                   wr_clk          ,
    input                   wr_rst_n        ,
    input                   wr_en           ,
    input [SSIZE*CSNUM-1:0] wr_data         ,
    output                  wr_ready        ,
    output                  wr_last         ,
    output                  wr_stream_sof   ,
    output                  wr_stream_eof   ,
    //--- read port
    input                   rd_clk          ,
    input                   rd_rst_n        ,
    input                   rd_en           ,
    output                  rd_vld          ,
    output[SSIZE*CSNUM-1:0] rd_data         ,
    output                  rd_stream_sof   ,
    output                  rd_stream_eof
);


wire    spi_tx_clock;
wire    spi_rx_clock;
wire    spi_dr_rst_n;

slaver_sck_parse #(
    .PHASE        (PHASE    ),
    .ACTIVE       (ACTIVE   )
)slaver_sck_parse_inst(
/*  input  */   .ex_clock       (wr_clk         ),
/*  input  */   .spi_sck        (spi_sck        ),
/*  input  */   .spi_csn        (spi_csn        ),
/*  output */   .tx_driver_clock(spi_tx_clock   ),
/*  output */   .rx_driver_clock(spi_rx_clock   ),
/*  output */   .dirver_rst_n   (spi_dr_rst_n   )
);

serial #(
    .SSIZE      (SSIZE          ),
    .CSNUM      (CSNUM          )
)serial_inst(
/*  input                 */  .wr_clk           (wr_clk             ),
/*  input                 */  .wr_rst_n         (wr_rst_n           ),
/*  input                 */  .wr_vld           (wr_en              ),
/*  input[SSIZE*CSNUM-1:0]*/  .wr_data          (wr_data            ),
/*  output                */  .wr_ready         (wr_ready           ),
/*  output                */  .wr_last          (wr_last            ),
/*  input                 */  .rd_clk           (spi_tx_clock       ),
/*  input                 */  .rd_en            (!spi_csn           ),
/*  input                 */  .rd_rst_n         (spi_dr_rst_n       ),
/*  output                */  .rd_vld           (                   ),
/*  output[SSIZE-1:0]     */  .rd_data          (spi_miso           ),
/*  output                */  .empty            (                   ),
/*  output                */  .rd_last          (                   )
);

deserial #(
    .SSIZE      (SSIZE          ),
    .CSNUM      (CSNUM          )
)deserial_inst(
/*  input                   */  .wr_clk          (spi_rx_clock      ),
/*  input                   */  .wr_rst_n        (spi_dr_rst_n      ),
/*  input                   */  .wr_vld          (!spi_csn          ),
/*  input[SSIZE-1:0]        */  .wr_data         (spi_mosi          ),
/*  input                   */  .rd_clk          (rd_clk            ),
/*  input                   */  .rd_rst_n        (rd_rst_n          ),
/*  input                   */  .rd_en           (rd_en             ),
/*  output                  */  .rd_vld          (rd_vld            ),
/*  output[SSIZE*CSNUM-1:0] */  .rd_data         (rd_data           )
);

stream_seof stream_seof_wr(
/*  input  */     .spi_csn  (spi_csn        ),
/*  input  */     .clock    (wr_clk         ),
/*  input  */     .rst_n    (wr_rst_n       ),
/*  output */     .sof      (wr_stream_sof  ),
/*  output */     .eof      (wr_stream_eof  )
);

stream_seof stream_seof_rd(
/*  input  */     .spi_csn  (spi_csn        ),
/*  input  */     .clock    (rd_clk         ),
/*  input  */     .rst_n    (rd_rst_n       ),
/*  output */     .sof      (rd_stream_sof  ),
/*  output */     .eof      (rd_stream_eof  )
);

endmodule
