/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/13 上午11:17:39
madified:
***********************************************/
`timescale 1ns/1ps
module spi_master_phy_tb;

//--->> SYSYTEM VAR <<--------
localparam	Freq	= 100;
parameter	PHASE	= 0;
parameter	ACTIVE	= 0;
localparam  SSIZE   = 1,
            CSNUM   = 8;

bit		spi_dr_clock;
bit		spi_dr_rst_n;

clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(200	    )
)clock_rst_spi(
	.clock			(spi_dr_clock	    ),
	.rst_x			(spi_dr_rst_n		)
);

bit		wr_clk;
bit		wr_rst_n;

clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(10  	    )
)clock_rst_wr(
	.clock			(wr_clk	    ),
	.rst_x			(wr_rst_n	)
);

bit		rd_clk;
bit		rd_rst_n;

clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(10  	    )
)clock_rst_rd(
	.clock			(rd_clk	    ),
	.rst_x			(rd_rst_n	)
);

bit		spi_slaver_clock;
bit		spi_slaver_rst_n;

clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(1000	    )
)clock_rst_spi_slaver(
	.clock			(spi_slaver_clock	    ),
	.rst_x			(spi_slaver_rst_n		)
);

//---<< SYSTEM VAR >>-----------
//--->> TASK <<-----------------
bit             request;
bit [23:0]      req_len;
bit             busy;
bit             finish;
bit [7:0]       wr_data;
bit [7:0]       rd_data;
bit             wr_ready;
bit             wr_en;

task spi_burst(int len);
    request = 1'b0;
    repeat(10)
        @(posedge spi_dr_clock);
    request = 1'b1;
    req_len = len*8;
    wait(busy);
    request = 1'b0;
    req_len = 0;
endtask:spi_burst

task automatic burst_data;
int cnt;
int data = 128;
    @(posedge request);
    cnt = req_len;
    @(posedge busy);
    repeat(cnt)begin
        @(posedge wr_clk)
        wait(wr_ready);
        wr_en = 1;
        wr_data = data;
        data = data + 1;
    end
endtask:burst_data

wire            spi_csn ;
wire            spi_sck ;
wire[SSIZE-1:0] spi_mosi;
wire[SSIZE-1:0] spi_miso;

spi_master #(
    .PHASE          (PHASE  ),
    .ACTIVE         (ACTIVE ),
    .SSIZE          (1      ),
    .CSNUM          (8      )
)spi_master_phy_inst(
    //-- spi interface
/*  output            */    .spi_csn         (spi_csn      ),
/*  output            */    .spi_sck         (spi_sck      ),
/*  output[SSIZE-1:0] */    .spi_mosi        (spi_mosi     ),
/*  input [SSIZE-1:0] */    .spi_miso        (spi_miso     ),
    //---
/*  input             */    .spi_dr_clock    (spi_dr_clock      ),    //double spi data rate
/*  input             */    .spi_dr_rst_n    (spi_dr_rst_n      ),
    //--- ctrl signals
/*  input             */    .request         (request           ),
/*  input             */    .req_len         (req_len           ),
/*  output            */    .busy            (busy              ),
/*  output            */    .finish          (finish            ),
    //--- write port
/*  input                  */ .wr_clk        (wr_clk            ),
/*  input                  */ .wr_rst_n      (wr_rst_n          ),
/*  input                  */ .wr_en         (wr_en             ),
/*  input [SSIZE*CSNUM-1:0]*/ .wr_data       (wr_data           ),
/*  output                 */ .wr_ready      (wr_ready          ),
    //--- read port
/*  input                   */.rd_clk        (rd_clk            ),
/*  input                   */.rd_rst_n      (rd_rst_n          ),
/*  output                  */.rd_vld        (rd_vld            ),
/*  output[SSIZE*CSNUM0-1:0]*/.rd_data       (rd_data           )
);

initial begin
    wait(wr_rst_n);
    wait(spi_dr_rst_n);
    fork
        spi_burst(100);
        burst_data;
    join
end

logic		rx_stream_sof	;
logic[7:0]	rx_stream_data	;
logic		rx_stream_vld	;
logic		rx_stream_eof	;
logic		tx_send_flag	;
logic[23:0]	tx_send_momment =0;
logic[7:0]	tx_send_data	=0;
logic		tx_send_valid	=0;
logic		tx_empty		;

spi_phy #(
	.PHASE			(PHASE					),
	.ACTIVE			(ACTIVE					)
)spi_slave_phy_inst(
	//-->> SPI INTERFACE <<---
/*    input		*/	.sck			(spi_sck      			),
/*    input		*/	.cs_n   		(spi_csn           		),
/*    output	*/	.miso   		(spi_miso          		),
/*	input		*/	.mosi			(spi_mosi     			),
	//-->> system <<---------
/*	input		*/	.clock			(spi_slaver_clock       ),
/*	input		*/	.rst_n			(spi_slaver_rst_n       ),
	//-->> RX INTERFACE <<---
/*	output		*/	.rx_stream_sof	(rx_stream_sof		),
/*	output[7:0]	*/	.rx_stream_data	(rx_stream_data		),
/*	output		*/	.rx_stream_vld	(rx_stream_vld		),
/*	output		*/	.rx_stream_eof	(rx_stream_eof		),
	//-->> TX INTERFACE <<---
/*	output		*/	.tx_send_flag	(tx_send_flag		),
/*	input [23:0]*/	.tx_send_momment(tx_send_momment	),
/*	input [7:0]	*/	.tx_send_data	(tx_send_data		),
/*	input		*/	.tx_send_valid	(tx_send_valid		),
/*	output		*/	.tx_empty		(tx_empty			)
);

logic[7:0]	write_data [$] = {8'hF1,8'h01,8'h02,8'h03,8'h04,8'h01,8'h02,8'h03,8'h04};
logic[7:0]	rx_data_seq[$];


task slaver_tx_data_task(int cnt = 8);
	@(posedge tx_send_flag);
	tx_send_momment	= 0;
	tx_send_valid	= 0;
	tx_send_data	= 0;
	wait(tx_send_flag);
	repeat(cnt)begin
		if(!tx_send_flag)	break;
		wait(tx_empty);
		@(posedge spi_slaver_clock);
		tx_send_valid	= 1;
		tx_send_data	+=1;
		@(posedge spi_slaver_clock);
		tx_send_valid	= 0;
		// wait(!tx_empty);
	end
endtask: slaver_tx_data_task

initial begin
    wait(spi_slaver_rst_n);
	repeat(10) @(posedge spi_slaver_clock);
    fork
    	slaver_tx_data_task(8);
    	get_rx_stream;
    join
end

task get_rx_stream;
	wait(rx_stream_sof);
	rx_data_seq	= {};
	while(!rx_stream_eof && !spi_slave_phy_inst.cs_n)begin
		@(posedge spi_slaver_clock);
		if(rx_stream_vld)
				rx_data_seq.push_back(rx_stream_data);
		else	rx_data_seq = rx_data_seq;
	end
endtask: get_rx_stream


endmodule
