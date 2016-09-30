/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/14 下午4:22:10
madified:
***********************************************/
`timescale 1ns/1ps
module slaver_sck_parse #(
    parameter PHASE     = 0,
    parameter ACTIVE    = 0
)(
    input       ex_clock    ,
    input       spi_sck     ,
    input       spi_csn     ,
    output      tx_driver_clock,
    output      rx_driver_clock,
    output      dirver_rst_n
);

wire        pose_sck;
assign      pose_sck = ACTIVE? ~spi_sck : spi_sck;

wire    clock;
reg		tx_trigger_clock;
always@(*)
	case({ACTIVE==1,PHASE==1})
	2'b00:	tx_trigger_clock	= !spi_csn && !spi_sck;
	2'b01:	tx_trigger_clock	= !spi_csn && spi_sck;
	2'b10:	tx_trigger_clock	=  spi_sck;
	2'b11:	tx_trigger_clock	= !spi_sck;
	default:;
	endcase

assign clock = tx_trigger_clock;

reg		rx_trigger_clock;
always@(*)
	case({ACTIVE==1,PHASE==1})
	2'b00:	rx_trigger_clock	=  spi_sck;
	2'b01:	rx_trigger_clock	= !spi_sck;
	2'b10:	rx_trigger_clock	= !spi_sck;
	2'b11:	rx_trigger_clock	=  spi_sck;
	default:;
	endcase


wire    spi_csn_raising;
wire    spi_csn_falling;

edge_generator #(
	.MODE		("NORMAL" 	)  // FAST NORMAL BEST
)gen_edge(
	.clk		(ex_clock           ),
	.rst_n      (1'b1               ),
	.in         (spi_csn            ),
	.raising    (spi_csn_raising    ),
	.falling    (spi_csn_falling    )
);


assign tx_driver_clock = clock;
assign dirver_rst_n = !spi_csn_raising;
assign rx_driver_clock =rx_trigger_clock;

endmodule
