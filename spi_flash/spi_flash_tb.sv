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
module spi_flash_tb;
`define M25Q032A13E
localparam SSIZE = 4;

bit		spi_dr_clock;
bit		spi_dr_rst_n;

clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(32  	    )
)clock_rst_spi(
	.clock			(spi_dr_clock	    ),
	.rst_x			(spi_dr_rst_n		)
);

bit		wr_clk;
bit		wr_rst_n;
bit     wr_en;

clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(20 	    )
)clock_rst_wr(
	.clock			(wr_clk	    ),
	.rst_x			(wr_rst_n		)
);

always@(posedge wr_clk,negedge wr_rst_n)begin:GEN_WR_EN
int  cnt;
    if(~wr_rst_n)begin
        cnt     <= 0;
        wr_en   <= 0;
    end else begin
        if(cnt == 9)
                cnt <= 0;
        else    cnt <= cnt + 1;

        wr_en <= cnt == 2;
end end

bit		rd_clk;
bit		rd_rst_n;
bit     rd_en;

clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(20 	    )
)clock_rst_rd(
	.clock			(rd_clk	    ),
	.rst_x			(rd_rst_n		)
);

always@(posedge rd_clk,negedge rd_rst_n)begin:GEN_RD_EN
int cnt;
    if(~rd_rst_n)begin
        cnt     <= 0;
        rd_en   <= 0;
    end else begin
        if(cnt == 9)
                cnt <= 0;
        else    cnt <= cnt + 1;

        rd_en <= cnt == 6;
end end

wire      spi_csn         ;
wire      spi_sck         ;
wire      spi_mosi        ;
wire      spi_miso        ;
wire [3:0] DQ;

int  Vcc = 32'hbb8;


// M25Pxxx M25Pxxx_inst(
// /*  input                 */  .S           (spi_csn      ),
// /*  input                 */  .C           (spi_sck      ),
// /*  input [`VoltageRange] */  .Vcc         (Vcc          ),
// /*  input                 */  .D           (spi_mosi     ),
// /*  output                */  .Q           (spi_miso     ),
// /*  input                 */  .W           (1'b1         ),
// /*  input                 */  .RESET       (!spi_dr_rst_n      )
// );
//----->> FLASH MODEL <<-------------------
`ifdef M25PE20
logic   VCC;
logic   VSS;
logic   TSL = 0;
logic   RESET = 0;
event   read_id_event,read_id_finish_event;
initial begin
    VCC = 1;
    VSS = 1;
    #(30e3);        $display("time delay for Vcc to /S low 30us");
    #(2e6);        $display("time delay before first write, program and erase instruction");
    #(10); TSL = 1'b1;     $display("top sector is not protected");
    #(10); RESET = 1'b0;   $display("enter reset mode");
    #(200);           $display("chip select deselect time");
    -> read_id_event;
    wait(read_id_finish_event.triggered());
    #(10e3);            $display("reset pulse width");
    RESET = 1'b1;
end

M25PE20_MEMORY M25PE20_MEMORY_inst(
/*  input */    .C              (spi_sck    ),
/*  input */    .D              (spi_mosi   ),
/*  output*/    .Q              (spi_miso   ),
/*  input */    .S              (spi_csn    ),
/*  input */    .TSL            (TSL        ),
/*  input */    .RESET          (RESET      ),
/*  input */    .VCC            (VCC        ),
/*  input */    .VSS            (VSS        )
);
`elsif M25Q032A13E

N25Qxxx DUT (
    .S          (spi_csn    ),
    .C_         (spi_sck    ),
    .HOLD_DQ3   (DQ[3]      ),
    .DQ0        (DQ[0]      ),
    .DQ1        (DQ[1]      ),
    .Vcc        (32'd3000   ),
    .Vpp_W_DQ2  (DQ[2]      )
);
`endif

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

logic   req_id = 0;
logic   req_wr_enable = 0;
logic   req_wr_disable= 0;

spi_flash #(
    .PHASE          (0      ),
    .ACTIVE         (0      ),
    .SSIZE          (SSIZE  ),
    .DSIZE          (8      )
)spi_flash_inst(
    //-- spi interface
/*  output            */    .spi_csn         (spi_csn       ),
/*  output            */    .spi_sck         (spi_sck       ),
/*  output[SSIZE-1:0] */    .spi_mosi        (spi_mosi      ),
/*  input [SSIZE-1:0] */    .spi_miso        (spi_miso      ),
/*  inout [SSIZE-1:0] */    .spi_dq          (DQ            ),
    //---
/*  input             */    .dr_spi_clk      (spi_dr_clock  ),   //double spi data rate
/*  input             */    .dr_spi_rst_n    (spi_dr_rst_n  ),
/*  input             */    .clock           (wr_clk        ),
/*  input             */    .rst_n           (wr_rst_n      ),
/*  input             */    .clk_en          (wr_en         ),
    //---
/*  cmd_inf.slaver    */    .cmd_inf         (cmd_inf       ),
/*  data_inf.slaver   */    .wr_data_inf     (wr_data_inf      ),
/*  data_inf.master   */    .rd_data_inf     (rd_data_inf      )
);

//----->> task test <<-------
task automatic REQ_TASK(int MODULE_ID,int cmd);
    repeat(5)
        @(posedge wr_clk);
    cmd_inf.request  = 1;
    cmd_inf.cmd      = cmd;
    repeat(2)
        @(posedge wr_clk);
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
                @(negedge wr_clk);
                if(wr_en && wr_data_inf.ready)begin
                    @(posedge wr_clk);
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
    forever begin
        if(cnt == num)
            break;

        @(negedge wr_clk);
        if(rd_data_inf.ready && rd_data_inf.valid && wr_en)
                cnt += 1;
        else    cnt = cnt;
        tmp_cnt = cnt;
        @(posedge wr_clk);

        if($urandom_range(100) > 180)
                rd_data_inf.ready   = 0;
        else    rd_data_inf.ready   = 1;
    end
    rd_data_inf.ready = 0;
endtask:rd_data_ready_random_task
//-----<< task test >>-------
// program P0;
// initial begin
//     wait(read_id_event.triggered());
//     wait(wr_rst_n);
//     wait(rd_rst_n);
//     ID_task;
//     -> read_id_finish_event;
//     wait(RESET);
//     #(30e3);
//     ID_task;
//     #(1000);
//     #(10e6);
//     flash_write_enable;
//     page_write_task;
//     // flash_write_disable;
// end
// endprogram

initial begin
    wait(wr_rst_n);
    wait(rd_rst_n);
    #(30e3);
    set_x4_task;
    flash_write_enable;
    page_write_task;
    #(1e6);
    flash_write_disable;
    read_mem_task;
end
//--->> SPI SPLIT <<-------
int spi_cnt = 0;

always@(posedge spi_sck)begin
    repeat(7) @(posedge spi_sck);
    spi_cnt += 1;
end

always@(negedge spi_csn)
    spi_cnt = 0;

endmodule
