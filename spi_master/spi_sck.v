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
module spi_sck #(
    parameter PHASE     = 0,
    parameter ACTIVE    = 0
)(
    input       sck_en,
    input       clock,      //double spi data rate
    input       pause,
    output      spi_sck,
    output      trs_ctrl_data_en,
    output      rev_ctrl_data_en
);

reg     point;

always@(posedge clock)begin
    if(sck_en)begin
        if(~pause)
                point <= ~point;
        else    point <= point;
    end else begin
        point <= 1'b0 ;
end end

reg     en_reg;
reg     en_reg_lat;

always@(posedge clock)begin
    // en_reg_lat  <= en_reg;
    en_reg_lat  <= trs_ctrl_data_en;
    if(sck_en)begin
        if(~pause)
                en_reg <= ~en_reg;
        else    en_reg <= 1'b0;
    end else begin
        en_reg <= 1'b0 ;
end end

assign trs_ctrl_data_en = en_reg && !pause;
assign rev_ctrl_data_en = en_reg_lat;

reg     clk_reg;

always@(posedge clock)begin:GEM_SCK_BLOCK
reg     tmp;
    tmp     <= trs_ctrl_data_en;

    if(PHASE)
            clk_reg <= trs_ctrl_data_en ;
    else    clk_reg <= tmp;

end

assign  spi_sck = (ACTIVE==0)? clk_reg : !clk_reg;

endmodule
