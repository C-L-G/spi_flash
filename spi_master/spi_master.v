/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/12 下午3:40:08
madified:
***********************************************/
`timescale 1ns/1ps
module spi_master #(
    parameter PHASE     = 0,
    parameter ACTIVE    = 0,
    parameter SSIZE     = 1,
    parameter CSNUM     = 8
)(
    //-- spi interface
    output                  spi_csn         ,
    output                  spi_sck         ,
    output[SSIZE-1:0]       spi_mosi        ,
    input [SSIZE-1:0]       spi_miso        ,
    inout [SSIZE-1:0]       spi_dq          ,
    //---
    input                   spi_dr_clock    ,    //double spi data rate
    input                   spi_dr_rst_n    ,
    //--- ctrl signals
    input                   request         ,
    input [2:0]             req_cmd         ,
    input [23:0]            req_len         ,
    input [23:0]            req_wr_len      ,
    output                  busy            ,
    output                  finish          ,
    //--- write port
    input                   wr_clk          ,
    input                   wr_rst_n        ,
    input                   wr_en           ,
    input                   wr_vld          ,
    input [SSIZE*CSNUM-1:0] wr_data         ,
    output                  wr_ready        ,
    output                  wr_last         ,
    //--- read port
    input                   rd_clk          ,
    input                   rd_rst_n        ,
    input                   rd_en           ,
    input                   rd_ready        ,
    output reg              rd_vld          ,
    output reg [SSIZE*CSNUM-1:0] rd_data
);

wire                   trs_data_flag;
wire                   rev_data_flag;
wire                   sck_en;
wire                   rst_fifo;
wire[SSIZE-1:0]        dq_wr_rd;
wire                   wr_rd_pause;
wire                   deserial_empty;
wire                   mark_deserial;
wire                   deserial_rd_vld;

status_ctrl #(
    .SSIZE  (SSIZE      )
)status_ctrl_inst(
/*  input        */  .spi_dr_clock (spi_dr_clock        ),
/*  input        */  .spi_dr_rst_n (spi_dr_rst_n        ),
/*  output       */  .spi_csn      (spi_csn             ),
/*  input        */  .wr_clk       (wr_clk              ),
/*  input        */  .wr_clk_en    (wr_en               ),
/*  input        */  .wr_rst_n     (wr_rst_n            ),
/*  input        */  .rd_clk       (rd_clk              ),
/*  input        */  .rd_rst_n     (rd_rst_n            ),
/*  input        */  .rd_clk_en    (rd_en               ),
/*  input        */  .request      (request             ),
/*  input [2:0]  */  .req_cmd      (req_cmd             ),
/*  input [23:0] */  .req_len      (req_len             ),
/*  input [23:0] */  .req_wr_len   (req_wr_len          ),
/*  output       */  .busy         (busy                ),
/*  output       */  .finish       (finish              ),
/*  output       */  .wr_finish    (                    ),
/*  output SSIZE */  .dq_wr_rd     (dq_wr_rd            ),
/*  input        */  .data_flag    (trs_data_flag       ),
/*  output       */  .sck_en       (sck_en              ),
/*  output       */  .rst_fifo     (rst_fifo            ),
/*  output       */  .wr_rd_pause  (wr_rd_pause         ),
/*  input        */  .deserial_empty    (deserial_empty ),
/*  input        */  .deserial_rd_vld   (deserial_rd_vld    ),
/*  output reg   */  .mark_deserial     (mark_deserial      )
);

genvar KK;
generate
for(KK=0;KK<SSIZE;KK=KK+1)begin
    assign  #3 spi_dq[KK]  = (dq_wr_rd[KK]==1'b0)? spi_mosi[KK] : {1{1'bz}};
end
endgenerate
assign  spi_miso= spi_dq;

wire    serial_last,deserial_last;
wire    wr_pause,rd_pause;
wire    serial_empty,deserial_full;

assign  wr_pause = (wr_rd_pause==1'b0) && (serial_last || serial_empty);
assign  rd_pause = (wr_rd_pause==1'b1) && (deserial_last || deserial_full);

spi_sck #(
    .PHASE     (PHASE   ),
    .ACTIVE    (ACTIVE  )
)spi_sck_inst(
/*  input   */    .sck_en           (sck_en             ),
/*  input   */    .clock            (spi_dr_clock       ),//double spi data rate
/*  input   */    .pause            (wr_pause || rd_pause        ),
/*  output  */    .spi_sck          (spi_sck            ),
/*  output  */    .trs_ctrl_data_en (trs_data_flag      ),
/*  output  */    .rev_ctrl_data_en (rev_data_flag      )
);

serial #(
    .SSIZE      (SSIZE          ),
    .CSNUM      (CSNUM          )
)serial_inst(
/*  input                 */  .wr_clk           (wr_clk             ),
/*  input                 */  .wr_rst_n         (wr_rst_n           ),
/*  input                 */  .wr_vld           (wr_en  && wr_vld   ),
/*  input[SSIZE*CSNUM-1:0]*/  .wr_data          (wr_data            ),
/*  output                */  .wr_ready         (wr_ready           ),
/*  output                */  .wr_last          (wr_last            ),
/*  input                 */  .rd_clk           (spi_dr_clock       ),
/*  input                 */  .rd_en            (trs_data_flag      ),
/*  input                 */  .rd_rst_n         (spi_dr_rst_n && !rst_fifo       ),
/*  output                */  .rd_vld           (                   ),
/*  output[SSIZE-1:0]     */  .rd_data          (spi_mosi           ),
/*  output                */  .empty            (serial_empty       ),
/*  output                */  .rd_last          (serial_last        )
);

wire                    rd_vld_de;
wire[SSIZE*CSNUM-1:0]   rd_data_de;

deserial #(
    .SSIZE      (SSIZE          ),
    .CSNUM      (CSNUM          )
)deserial_inst(
/*  input                   */  .wr_clk          (spi_dr_clock      ),
/*  input                   */  .wr_rst_n        (spi_dr_rst_n      ),
/*  input                   */  .wr_vld          (rev_data_flag     ),
/*  output                  */  .wr_full         (deserial_full     ),
/*  output                  */  .wr_last         (deserial_last     ),
/*  input[SSIZE-1:0]        */  .wr_data         (spi_miso          ),
/*  input                   */  .rd_clk          (rd_clk            ),
/*  input                   */  .rd_rst_n        (rd_rst_n && !rst_fifo         ),
/*  input                   */  .rd_en           (rd_en && rd_ready ),
/*  output                  */  .rd_vld          (rd_vld_de         ),
/*  output[SSIZE*CSNUM-1:0] */  .rd_data         (rd_data_de        ),
/*  output                  */  .rd_empty        (deserial_empty    )
);
assign  deserial_rd_vld = rd_vld_de;
//------------------------------------
always@(posedge rd_clk,negedge rd_rst_n)begin
    if(~rd_rst_n)   rd_vld  <=1'b0;
    else begin
        if(!mark_deserial)begin
            if(rd_vld_de)
                        rd_vld  <= 1'b1;
            else if(rd_en)
                        rd_vld  <= !rd_ready;
            else        rd_vld  <= rd_vld;
        end else        rd_vld  <= 1'b0;
end end

always@(posedge rd_clk,negedge rd_rst_n)begin
    if(~rd_rst_n)   rd_data  <={(SSIZE*CSNUM){1'b0}};
    else begin
        if(rd_vld_de && !mark_deserial)
                    rd_data  <= rd_data_de;
        else        rd_data  <= rd_data;
end end

// wire                    up_wr_en;
// wire                    down_ready;
// reg                     curr_vld;
// reg [SSIZE*CSNUM-1:0]   curr_data;
// reg                     curr_ready;
//
// assign up_wr_en     = rd_vld_de;
// assign down_ready   = rd_en && rd_ready;
//
// always@(posedge rd_clk,negedge rd_rst_n)begin
//     if(~rd_rst_n)   curr_vld    <= 1'b0;
//     else
//         case({up_wr_en,curr_vld,down_ready})
//         3'b000: curr_vld    <= 1'b0;
//         3'b001: curr_vld    <= 1'b0;
//         3'b010: curr_vld    <= 1'b1;
//         3'b011: curr_vld    <= 1'b0;
//         3'b100: curr_vld    <= 1'b1;
//         3'b101: curr_vld    <= 1'b1;
//         3'b110: curr_vld    <= 1'b1;
//         3'b111: curr_vld    <= 1'b1;
//         default:curr_vld    <= 1'b0;
//         endcase
// end
//
// always@(posedge rd_clk,negedge rd_rst_n)begin
//     if(~rd_rst_n)   curr_ready  <= 1'b0;
//     else
//         case({up_wr_en,curr_vld,down_ready})
//         3'b000: curr_ready    <= 1'b1;
//         3'b001: curr_ready    <= 1'b1;
//         3'b010: curr_ready    <= 1'b0;
//         3'b011: curr_ready    <= 1'b1;
//         3'b100: curr_ready    <= 1'b0;
//         3'b101: curr_ready    <= 1'b0;
//         3'b110: curr_ready    <= 1'b0;
//         3'b111: curr_ready    <= 1'b1;
//         default:curr_ready    <= 1'b0;
//         endcase
// end

endmodule
