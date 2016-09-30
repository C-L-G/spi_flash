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
module spi_flash_verb_tb;
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

bit rd_frame_flag = 0;
bit wr_frame_flag = 0;

spi_flash_verb #(
    .PHASE          (0      ),
    .ACTIVE         (0      ),
    .SSIZE          (SSIZE  ),
    .DSIZE          (8      )
)spi_flash_inst(
    //-- spi interface
/*  output            */    .spi_csn         (spi_csn       ),
/*  output            */    .spi_sck         (spi_sck       ),
/*  inout [4-1:0]     */    .spi_dq          (DQ            ),
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
/*  data_inf.slaver   */    .wr_data_inf_1   (wr_data_inf_1 )
);
defparam spi_flash_inst.spi_master_inst.spi_sck_inst.custom_ddio_inst.MODE = "TEST";
//----->> task test <<-------
task automatic REQ_TASK(int MODULE_ID,int cmd);
    repeat(5)
        @(posedge clock);
    cmd_inf.request  = 1;
    cmd_inf.cmd      = cmd;
    repeat(2)
        @(posedge clock);
    cmd_inf.request = 0;
    wait(cmd_inf.finish[MODULE_ID]);
endtask:REQ_TASK

task ID_task;
    REQ_TASK(0,1);
endtask:ID_task

task flash_write_enable;
    REQ_TASK(1,2);
    $display("<<TASK>> WRITE ENABLE");
endtask:flash_write_enable

task flash_write_disable;
    REQ_TASK(1,3);
    $display("<<TASK>> WRITE DISABLE");
endtask:flash_write_disable

task page_write_task;
    wr_data_inf.valid     = 0;
    wr_data_inf.data    = 255;
    fork
        REQ_TASK(2,4);
        repeat(256)begin
            wr_data_inf.valid = 1;
            forever begin
                @(negedge clock);
                if(wr_data_inf.ready && clk_en)begin
                    @(posedge clock);
                    break;
                end
            end
            wr_data_inf.data -= 1;
        end
    join
    wr_data_inf.valid     = 0;
    wr_data_inf.data    = 0;
endtask:page_write_task

task set_x4_task;
    REQ_TASK(3,5);
    $display("<<TASK>>SET X4 DONE");
endtask:set_x4_task

task read_mem_task;
    fork
        REQ_TASK(3,6);
        rd_data_ready_random_task(256);
    join
    $display("<<TASK>>READ MEM DONE");
endtask:read_mem_task

int  tmp_cnt;
task automatic rd_data_ready_random_task(int num);
int     cnt;
    rd_data_inf.ready = 0;
    forever begin
        if(cnt == num-1)
            break;

        @(negedge clock);
        if(rd_data_inf.ready && rd_data_inf.valid && clk_en)
                cnt += 1;
        else    cnt = cnt;
        tmp_cnt = cnt;
        @(posedge clock);

        if($urandom_range(100) > 180)
                rd_data_inf.ready   = 0;
        else    rd_data_inf.ready   = 1;
    end
    rd_data_inf.ready = 0;
endtask:rd_data_ready_random_task

task frame_stream_read_task;
    rd_frame_flag  = 1;
    rd_data_inf_1.ready = 0;
    repeat(3)
        @(posedge   clock);
    rd_frame_flag  = 0;
    rd_data_inf_1.ready = 1;
    wait(spi_flash_inst.read_flash_burst_inst.finish);
endtask:frame_stream_read_task
//-----<< task test >>-------

initial begin
    wait(rst_n);
    #(30e3);
    // ID_task;
    // set_x4_task;
    flash_write_enable;
    page_write_task;
    #(1e6);
    flash_write_disable;
    read_mem_task;
    // frame_stream_read_task;
end

endmodule
