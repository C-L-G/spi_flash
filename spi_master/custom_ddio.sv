/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/28 上午11:13:42
madified:
***********************************************/
`timescale 1ns/1ps
module custom_ddio #(
    parameter MODE = "LATTICE"
)(
    input           rst_n,
    input           clk_p,
    input           clk_n,
    input           en,
    input           d_p,
    input           d_n,
    output reg      d
);

wire    d_alt;
wire    lattice_dp,lattice_dn;
wire    lattice_p;
generate
if(MODE == "TEST")begin
always@(posedge clk_p)begin
    if(en)
        d   <= d_p;
    else
        d   <= 1'b0;
end
always@(posedge clk_n)begin
    if(en)
        d   <= d_n;
    else
        d   <= 1'b0;
end
end else if(MODE == "ALTERA")begin

alt_ddio alt_ddio_inst(
/*	input	[0:0]  */      .datain_h       (d_p            ),
/*	input	[0:0]  */      .datain_l       (d_n            ),
/*	input	       */      .outclock       (clk_p          ),
/*	input	       */      .outclocken     (en             ),
/*	output	[0:0]  */      .dataout        (d_alt          )
);

end else if(MODE == "LATTICE")begin

// ddio_lattice ddio_lattice_inst_pre (
// /*  input wire        */  .clk          (clk_p      ),
// /*  input wire        */  .reset        (!rst_n     ),
// /*  input wire [1:0]  */  .dataout      ({(d_p & en),(d_n & en)}    ),
// /*  output wire       */  .clkout       (           ),
// /*  output wire       */  .sclk         (           ),
// /*  output wire [0:0] */  .dout         (lattice_p  )
// );

ddio_lattice ddio_lattice_inst (
/*  input wire        */  .clk          (clk_p      ),
/*  input wire        */  .reset        (!rst_n     ),
/*  input wire [1:0]  */  .dataout      ({(d_n & en),(d_p & en)}    ),
/*  output wire       */  .clkout       (           ),
/*  output wire       */  .sclk         (           ),
/*  output wire [0:0] */  .dout         (d_alt      )
);
end else if(MODE == "LATTICE_SIM")begin

ddio_lattice_sim ddio_lattice_sim_inst (
/*  input wire        */  .clk          (clk_p      ),
/*  input wire        */  .reset        (!rst_n     ),
/*  input wire [1:0]  */  .dataout      ({(d_n & en),(d_p & en)}    ),
/*  output wire       */  .clkout       (           ),
/*  output wire       */  .sclk         (           ),
/*  output wire [0:0] */  .dout         (d_alt      )
);
end
endgenerate

always@(*)
    d = d_alt;

endmodule
