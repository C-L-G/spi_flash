/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/8 下午2:07:08
madified:
***********************************************/
`timescale 1ns/1ps
module deserial #(
    parameter   SSIZE = 1,
    parameter   CSNUM = 8
)(
        input                   wr_clk,
        input                   wr_rst_n,
        input                   wr_vld,
        input[SSIZE-1:0]        wr_data,
        output                  wr_last,
        output                  wr_full,

        input                   rd_clk,
        input                   rd_rst_n,
        input                   rd_en,
        output                  rd_vld,
        output[SSIZE*CSNUM-1:0] rd_data,
        output                  rd_empty
);


fifo_1ton #(
	.DSIZE		(SSIZE  ),
	.NSIZE		(CSNUM	),
	.DEPTH		(4      ),
	.ALMOST		(1      ),
	.DEF_VALUE	(0      )
)fifo_1ton_inst(
	//--->> WRITE PORT <<-----
/*	input				    */	.wr_clk			(wr_clk		),
/*	input				    */	.wr_rst_n       (wr_rst_n   ),
/*	input				    */	.wr_en          (wr_vld     ),
/*	input [DSIZE-1:0]	    */	.wr_data        (wr_data    ),
/*	output[5*NSIZE-1:0]	    */	.wr_count       (           ),
/*	output				    */	.wr_full        (wr_full    ),
/*  output                  */  .wr_last        (wr_last    ),
/*	output				    */	.wr_almost_full (           ),
	//--->> READ PORT <<------
/*	input				    */	.rd_clk			(rd_clk		),
/*	input				    */	.rd_rst_n       (rd_rst_n   ),
/*	input				    */	.rd_en          (rd_en      ),
/*	output[DSIZE*NSIZE-1:0]	*/	.rd_data        (rd_data    ),
/*	output[4:0]			    */	.rd_count       (           ),
/*	output				    */	.rd_empty       (rd_empty   ),
/*	output				    */	.rd_almost_empty(           ),
/*	output				    */	.rd_vld			(rd_vld   	)
);

endmodule
