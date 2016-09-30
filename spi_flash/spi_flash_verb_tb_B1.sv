/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/20 下午2:19:13
madified:
***********************************************/
`timescale 1ns/1ns
module spi_flash_verb_tb_B1;
localparam SSIZE = 1;
localparam real
                SPI_DR_CLK_RATE_MIN = 50,
                SPI_DR_CLK_RATE_MAX = 40*2,
                SPI_DATA_RATE       = SPI_DR_CLK_RATE_MIN, //SPI_DR_CLK_RATE_MAX;
                DATA_RATE           = SPI_DATA_RATE/(8/SSIZE);

bit		spi_dr_clock;
bit		spi_dr_rst_n;

clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(SPI_DR_CLK_RATE_MIN  	    )//144-160Mhz
)clock_rst_spi(
	.clock			(spi_dr_clock	    ),
	.rst_x			(spi_dr_rst_n		)
);

bit		clock;
bit		rst_n;
bit     clk_en = 1;

clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(DATA_RATE     ) //36MBps    Byte = 8bit
)clock_rst_wr(
	.clock			(clock	    ),
	.rst_x			(rst_n      )
);

wire      spi_csn         ;
wire      spi_sck         ;
wire      spi_mosi        ;
wire      spi_miso        ;
wire [3:0] DQ;


N25Qxxx DUT (
    .S          (spi_csn    ),
    .C_         (spi_sck    ),
    .HOLD_DQ3   (DQ[3]      ),
    .DQ0        (DQ[0]      ),
    .DQ1        (DQ[1]      ),
    .Vcc        (32'd3000   ),
    .Vpp_W_DQ2  (DQ[2]      )
);

cmd_inf #(
    .CSIZE      (4      ),
    .LSIZE      (24     ),
    .SLIZE      (16     )
)cmd_inf ();

data_inf #(
    .DSIZE      (8      )
)wr_data_inf();

data_inf #(
    .DSIZE      (8      )
)rd_data_inf();

data_inf #(
    .DSIZE      (8      )
)rd_data_inf_1();

data_inf #(
    .DSIZE      (8      )
)wr_data_inf_1();

bit rd_frame_flag ;
bit wr_frame_flag ;

spi_flash_verb #(
    .PHASE          (0      ),
    .ACTIVE         (0      ),
    .SSIZE          (SSIZE  ),
    .DSIZE          (8      )
)spi_flash_inst(
    //-- spi interface
/*  output            */    .spi_csn         (spi_csn       ),
/*  output            */    .spi_sck         (spi_sck       ),
/*  inout [SSIZE-1:0] */    .spi_dq          (DQ            ),
    //---
/*  input             */    .dr_spi_clk      (spi_dr_clock  ),   //spi data rate
/*  input             */    .dr_spi_rst_n    (spi_dr_rst_n  ),
/*  input             */    .clock           (clock         ),
/*  input             */    .rst_n           (rst_n         ),
/*  input             */    .clk_en          (clk_en        ),
    //---
/*  cmd_inf.slaver    */    .cmd_inf         (cmd_inf       ),
/*  data_inf.slaver   */    .wr_data_inf     (wr_data_inf   ),
/*  data_inf.master   */    .rd_data_inf     (rd_data_inf   ),
/*  data_inf.master   */    .rd_data_inf_1   (rd_data_inf_1 ),
/*  input             */    .rd_frame_flag   (rd_frame_flag ),
/*  data_inf.slaver   */    .wr_data_inf_1   (wr_data_inf_1 ),
/*  input             */    .wr_frame_flag   (wr_frame_flag )
);
defparam spi_flash_inst.spi_master_inst.spi_sck_inst.custom_ddio_inst.MODE = "TEST";


bit     trigger_0   = 0;
bit     trigger_1   = 0;
bit     trigger_2   = 0;

bit     led_0       ;
bit     led_1       ;
bit     led_2       ;

rd_wr_burst_rtl_test #(
    .DELAY      (24000)
)rd_wr_burst_rtl_test_inst(
/*    input  */     .clock          (clock      ),
/*    input  */     .rst_n          (rst_n      ),
/*    input  */     .clk_en         (clk_en     ),
/*    input  */     .trigger_0      (trigger_0  ),
/*    input  */     .trigger_1      (trigger_1  ),
/*    input  */     .trigger_2      (trigger_2  ),

/*    output reg */ .led_0          (led_0      ),
/*    output reg */ .led_1          (led_1      ),
/*    output reg */ .led_2          (led_2      ),

/*    output reg */ .rd_frame_flag  (rd_frame_flag  ),
/*    output reg */ .wr_frame_flag  (wr_frame_flag  ),

/*    cmd_inf.master */ .cmd_inf    (cmd_inf    ),
/*    data_inf.master*/ .wr_data_inf(wr_data_inf_1),
/*    data_inf.slaver*/ .rd_data_inf(rd_data_inf_1)
);
//-----<< task test >>-------
task trigger_0_task;
    trigger_0   = 0;
    trigger_0   = 1;
    repeat(3)
        @(posedge clock);
    trigger_0   = 0;
    wait(led_0==0);
endtask:trigger_0_task;

task trigger_1_task;
    trigger_1   = 0;
    trigger_1   = 1;
    repeat(3)
        @(posedge clock);
    trigger_1   = 0;
    wait(led_1==0);
endtask:trigger_1_task;

task trigger_2_task;
    trigger_2   = 0;
    trigger_2   = 1;
    repeat(3)
        @(posedge clock);
    trigger_2   = 0;
    wait(led_2==0);
    #(2e6);
endtask:trigger_2_task;

initial begin
    wait(rst_n);
    #(30e3);
    // ID_task;
    trigger_0_task;
    #(30e3);
    trigger_2_task;
    trigger_1_task;
end

endmodule
