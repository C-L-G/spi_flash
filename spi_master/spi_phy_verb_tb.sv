/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/28 上午10:23:42
madified:
***********************************************/
`timescale 1ns/1ps
module spi_phy_verb_tb;

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
	.FreqM			(72	        )
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
	.FreqM			(36  	    )
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
	.FreqM			(36  	    )
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

spi_master_verb #(
    .PHASE          (PHASE  ),
    .ACTIVE         (ACTIVE ),
    .SSIZE          (SSIZE  ),
    .CSNUM          (CSNUM  )
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
    wait(rd_rst_n);
    #1000;
    fork
        spi_burst(100);
        burst_data;
    join
end

logic                           slaver_wr_en         = 0;
logic[SSIZE*CSNUM-1:0]          slaver_wr_data      ;
logic                           slaver_wr_ready     ;
logic                           slaver_wr_last      ;
logic                           slaver_wr_stream_sof;
logic                           slaver_wr_stream_eof;

logic                           slaver_rd_en          = 0;
logic                           slaver_rd_vld         ;
logic[SSIZE*CSNUM-1:0]          slaver_rd_data        ;
logic                           slaver_rd_stream_sof  ;
logic                           slaver_rd_stream_eof  ;

spi_slaver #(
    .PHASE          (PHASE     ),
    .ACTIVE         (ACTIVE    ),
    .SSIZE          (SSIZE     ),
    .CSNUM          (CSNUM     )
)spi_slaver_phy_inst(
    //-- spi interface
/*  input              */   .spi_csn         (spi_csn         ),
/*  input              */   .spi_sck         (spi_sck         ),
/*  input [SSIZE-1:0]  */   .spi_mosi        (spi_mosi        ),
/*  output[SSIZE-1:0]  */   .spi_miso        (spi_miso        ),
    //--- write port
/*  input                  */ .wr_clk        (wr_clk                ),
/*  input                  */ .wr_rst_n      (wr_rst_n              ),
/*  input                  */ .wr_en         (slaver_wr_en          ),
/*  input [SSIZE*CSNUM-1:0]*/ .wr_data       (slaver_wr_data        ),
/*  output                 */ .wr_ready      (slaver_wr_ready       ),
/*  output                 */ .wr_last       (slaver_wr_last        ),
/*  output                 */ .wr_stream_sof (slaver_wr_stream_sof  ),
/*  output                 */ .wr_stream_eof (slaver_wr_stream_eof  ),
    //--- read port
/*  input                  */ .rd_clk        (rd_clk                ),
/*  input                  */ .rd_rst_n      (rd_rst_n              ),
/*  input                  */ .rd_en         (slaver_rd_en          ),
/*  output                 */ .rd_vld        (slaver_rd_vld         ),
/*  output[SSIZE*CSNUM-1:0]*/ .rd_data       (slaver_rd_data        ),
/*  output                 */ .rd_stream_sof (slaver_rd_stream_sof  ),
/*  output                 */ .rd_stream_eof (slaver_rd_stream_eof  )
);

logic[SSIZE*CSNUM-1:0]	write_data [$] = {8'hF1,8'h01,8'h02,8'h03,8'h04,8'h01,8'h02,8'h03,8'h04};
logic[SSIZE*CSNUM-1:0]	rx_data_seq[$];

event  filter_feof;

task automatic slaver_tx_data_task;
int     data = 0;
	// wait(slaver_wr_stream_sof);
    wait(filter_feof.triggered());
    data = 128;
	forever begin
        @(posedge   wr_clk);
        if(slaver_wr_ready)begin
            slaver_wr_en    = 1;
            slaver_wr_data  = data;
            data += 1;
        end else begin
            slaver_wr_en    = 0;
        end
        if(slaver_wr_stream_eof)
            break;
	end
    slaver_wr_en    = 0;
endtask: slaver_tx_data_task

initial begin
    wait(wr_rst_n);
    @(negedge slaver_wr_stream_eof);
    -> filter_feof;
    fork
    	slaver_tx_data_task;
    	slaver_rx_data_task;
    join
end

task automatic slaver_rx_data_task;
	wait(slaver_rd_stream_sof);
	rx_data_seq	= {};
    slaver_rd_en = 1;
	while(!slaver_rd_stream_eof)begin
		@(posedge spi_slaver_clock);
		if(slaver_rd_vld)
				rx_data_seq.push_back(slaver_rd_data);
		else	rx_data_seq = rx_data_seq;
	end
endtask: slaver_rx_data_task


endmodule
