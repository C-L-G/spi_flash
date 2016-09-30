/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/8 下午2:43:41
madified:
***********************************************/
`timescale 1ns/1ps
module spi_sck_verb #(
    parameter PHASE     = 0,
    parameter ACTIVE    = 0
)(
    input       sck_en,
    input       clock,      //spi data rate
    input       pause,
    output      spi_sck,
    output reg  trs_ctrl_data_en,
    output reg  rev_ctrl_data_en,
    output reg  vld_data_flag
);

reg     pause_lat;

always@(posedge clock)begin
    vld_data_flag       <= trs_ctrl_data_en && !pause;
    rev_ctrl_data_en    <= trs_ctrl_data_en;
    pause_lat           <= pause;
    if(sck_en)begin
        if(!pause)
                trs_ctrl_data_en    <= 1'b1;
        else    trs_ctrl_data_en    <= 1'b0;
    end else    trs_ctrl_data_en    <= 1'b0;

    // if(sck_en)begin
    //     if(!pause_lat)
    //             rev_ctrl_data_en    <= 1'b1;
    //     else    rev_ctrl_data_en    <= 1'b0;
    // end else    rev_ctrl_data_en    <= 1'b0;

end

// assign rev_ctrl_data_en = trs_ctrl_data_en;

wire    origin_sck_a;
wire    origin_sck_p;
wire    origin_pause;

assign  origin_sck_a    =  (ACTIVE==0)? 1'b1 : 1'b0;
assign  origin_sck_p    =  (PHASE ==0)? rev_ctrl_data_en : rev_ctrl_data_en;
assign  origin_pause    =  (PHASE ==0)? pause_lat : pause;

wire    ddio_cp,ddio_cn;
wire    ddio_dp,ddio_dn;

assign ddio_cp  = (ACTIVE==0 && PHASE ==0)? clock : !clock;
assign ddio_cn  = !ddio_cp;

assign ddio_dp  = (ACTIVE==0 && PHASE ==0)? sck_en && !pause_lat : !(sck_en && !pause_lat);
assign ddio_dn  = (ACTIVE==0 && PHASE ==0)? 1'b0 : sck_en;

custom_ddio custom_ddio_inst(
/*  input       */  .rst_n      (1'b1       ),
/*  input       */  .clk_p      (ddio_cn    ),
/*  input       */  .clk_n      (ddio_cp    ),
/*  input       */  .en         (rev_ctrl_data_en),
/*  input       */  .d_p        (ddio_dp    ),
/*  input       */  .d_n        (ddio_dn    ),
/*  output reg  */  .d          (spi_sck    )
);
// assign  spi_sck = (ACTIVE==0)? (rev_ctrl_data_en && clock) : !(rev_ctrl_data_en && clock);
endmodule
