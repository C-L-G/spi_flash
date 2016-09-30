/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/30 下午4:35:29
madified:
***********************************************/
`timescale 1ns/1ps
module ddio_lattice_sim (
  input wire        clk       ,
  input wire        reset     ,
  input wire [1:0]  dataout   ,
  output wire       clkout    ,
  output wire       sclk      ,
  output reg  [0:0] dout
);


always@(posedge clk)
    if(reset)
        dout    <= 1'b0;
    else
        dout    <= dataout[0];

always@(negedge clk)
    if(reset)
        dout    <= 1'b0;
    else
        dout    <= dataout[1];

endmodule
