/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/29 上午10:47:27
madified:
***********************************************/
`timescale 1ns/1ps
module rd_wr_burst_rtl_test #(
    parameter DELAY     = 24'hFF0_000
)(
    input       clock,
    input       rst_n,
    input       clk_en,
    input       trigger_0,
    input       trigger_1,
    input       trigger_2,
    input       trigger_3,

    output reg  led_0,
    output reg  led_1,
    output reg  led_2,
    output reg  led_3,

    output reg  rd_frame_flag,
    output reg  wr_frame_flag,

    cmd_inf.master  cmd_inf,
    data_inf.master wr_data_inf,
    data_inf.slaver rd_data_inf
);

wire	trigger_0_raising;
wire    trigger_0_falling;
edge_generator #(
	.MODE		("BEST" 	)  // FAST NORMAL BEST
)gen_sync_0(
	.clk		(clock				),
	.rst_n      (rst_n              ),
	.in         (trigger_0          ),
	.raising    (trigger_0_raising  ),
	.falling    (trigger_0_falling  )
);

wire	trigger_1_raising;
wire    trigger_1_falling;
edge_generator #(
	.MODE		("BEST" 	)  // FAST NORMAL BEST
)gen_sync_1(
	.clk		(clock				),
	.rst_n      (rst_n              ),
	.in         (trigger_1          ),
	.raising    (trigger_1_raising  ),
	.falling    (trigger_1_falling  )
);

wire	trigger_2_raising;
wire    trigger_2_falling;
edge_generator #(
	.MODE		("BEST" 	)  // FAST NORMAL BEST
)gen_sync_2(
	.clk		(clock				),
	.rst_n      (rst_n              ),
	.in         (trigger_2          ),
	.raising    (trigger_2_raising  ),
	.falling    (trigger_2_falling  )
);

wire	trigger_3_raising;
wire    trigger_3_falling;
edge_generator #(
	.MODE		("BEST" 	)  // FAST NORMAL BEST
)gen_sync_3(
	.clk		(clock				),
	.rst_n      (rst_n              ),
	.in         (trigger_3          ),
	.raising    (trigger_3_raising  ),
	.falling    (trigger_3_falling  )
);
//---->> TRIGGER 0 <<-------------
typedef enum {CIDLE,SET_CMD,SET_CMD_LAT,CMD_FSH,SET_WR_EN,SET_WR_EN_1,SET_WR_EN_FSH} CMD_STATE;

CMD_STATE   mnstate,mcstate;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  mcstate     <= CIDLE;
    else        mcstate     <= mnstate;

logic lat_done;

always@(*)
    case(mcstate)
    CIDLE:
        if(trigger_0_falling)
                mnstate = SET_CMD;
        else if(trigger_3_falling)
                mnstate = SET_WR_EN;
        else    mnstate = CIDLE;
    SET_CMD:
        if(clk_en)
                mnstate = SET_CMD_LAT;
        else    mnstate = SET_CMD;
    SET_CMD_LAT:
        if(clk_en)
                mnstate = CMD_FSH;
        else    mnstate = SET_CMD_LAT;
    CMD_FSH:    mnstate = CIDLE;
    SET_WR_EN:
        if(clk_en && lat_done)
                mnstate = SET_WR_EN_FSH;
        else    mnstate = SET_WR_EN;
    default:    mnstate = CIDLE;
    endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cmd_inf.request <= 1'b0;
    else
        case(mnstate)
        SET_CMD,SET_CMD_LAT,SET_WR_EN:
                cmd_inf.request <= 1'b1;
        default:cmd_inf.request <= 1'b0;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cmd_inf.cmd <= 0;
    else begin
        case(mnstate)
        SET_CMD:
            cmd_inf.cmd <= 5;
        SET_WR_EN:
            cmd_inf.cmd <= 2;
        default:;
        endcase
    end

always@(posedge clock,negedge rst_n)begin:LAT_DONE_BLOCK
reg [2:0]   cnt;
    if(~rst_n)begin
        cnt         <= 3'd0;
        lat_done    <= 1'b0;
    end else begin
        case(mnstate)
        SET_WR_EN:begin
            cnt         <= cnt + 1'b1;
            lat_done    <= cnt > 4;
        end
        default:begin
            cnt         <= 3'd0;
            lat_done    <= 1'b0;
        end
        endcase
    end
end
//----<< TRIGGER 0 >>-------------
//---->> TRIGGER 1 2 <<-----------
typedef enum {IDLE,RD_REQ,RD_REQ_1,RD_REQ_2,KEEP_RD,READY,RD_FSH,WR_REQ,WR_REQ_1,WR_REQ_2,WAIT_WR_READY,BURST_WR,WR_FSH,WR_WAIT_1MS} DATA_STATE;
DATA_STATE  nstate,cstate;

logic   rd_done,wr_done,delay_done;
logic[23:0] cnt;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cstate  <= IDLE;
    else        cstate  <= nstate;

always@(*)
    case(cstate)
    IDLE:
        if(trigger_1_falling)
                nstate  = RD_REQ;
        else if(trigger_2_falling)
                nstate  = WR_REQ;
        else    nstate  = IDLE;
    RD_REQ:
        if(clk_en)
                nstate  = RD_REQ_1;
        else    nstate  = RD_REQ;
    RD_REQ_1:
        if(clk_en)
                nstate  = RD_REQ_2;
        else    nstate  = RD_REQ_1;
    RD_REQ_2:
        if(clk_en)
                nstate  = KEEP_RD;
        else    nstate  = RD_REQ_2;
    KEEP_RD:
        if(rd_done && clk_en)
                nstate  = RD_FSH;
        else    nstate  = KEEP_RD;
    RD_FSH:     nstate  = IDLE;
    WR_REQ:
        if(clk_en)
                nstate  = WR_REQ_1;
        else    nstate  = WR_REQ;
    WR_REQ_1:
        if(clk_en)
                nstate  = WR_REQ_2;
        else    nstate  = WR_REQ_1;
    WR_REQ_2:
        if(clk_en)
                nstate  = WAIT_WR_READY;
        else    nstate  = WR_REQ_2;
    WAIT_WR_READY:
        if(wr_data_inf.ready && clk_en)
                nstate  = BURST_WR;
        else    nstate  = WAIT_WR_READY;
    BURST_WR:
        if(wr_done && clk_en)
                nstate  = WR_FSH;
        else    nstate  = BURST_WR;
    WR_FSH:     nstate  = WR_WAIT_1MS;
    WR_WAIT_1MS:
        if(delay_done)
                nstate  = IDLE;
        else    nstate  = WR_WAIT_1MS;
    default:    nstate  = IDLE;
    endcase

//---->> READ <<-------------
always@(posedge clock,negedge rst_n)
    if(~rst_n)  rd_frame_flag   <= 1'b0;
    else
        case(nstate)
        RD_REQ,RD_REQ_1,RD_REQ_2:
                rd_frame_flag   <= 1'b1;
        default:rd_frame_flag   <= 1'b0;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cnt <= 24'd0;
    else
        case(nstate)
        IDLE:   cnt <= 24'd0;
        KEEP_RD:begin
            if(rd_data_inf.ready && clk_en && rd_data_inf.valid)
                    cnt     <= cnt + 1'b1;
            else    cnt     <= cnt;
        end
        RD_FSH:     cnt     <= 24'd0;
        BURST_WR:begin
            if(wr_data_inf.ready && clk_en && wr_data_inf.valid)
                    cnt     <= cnt + 1'b1;
            else    cnt     <= cnt;
        end
        WR_FSH:     cnt     <= 24'd0;
        WR_WAIT_1MS:begin
                    cnt     <= cnt + 1'b1;
        end
        default:    cnt     <= cnt;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  rd_data_inf.ready   <= 1'b0;
    else
        case(nstate)
        KEEP_RD:    rd_data_inf.ready <= 1'b1;
        default:    rd_data_inf.ready <= 1'b0;
        endcase
//----<< READ >>-------------
//---->> WRITE <<-------------
always@(posedge clock,negedge rst_n)
    if(~rst_n)  wr_frame_flag   <= 1'b0;
    else
        case(nstate)
        WR_REQ,WR_REQ_1,WR_REQ_2:
                wr_frame_flag   <= 1'b1;
        default:wr_frame_flag   <= 1'b0;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  wr_data_inf.valid   <= 1'b0;
    else
        case(nstate)
        BURST_WR:
                wr_data_inf.valid   <= 1'b1;
        default:wr_data_inf.valid   <= 1'b0;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  wr_data_inf.data    <= 8'd0;
    else
        case(nstate)
        BURST_WR:begin
            if(wr_data_inf.valid && clk_en && wr_data_inf.ready)
                    wr_data_inf.data    <= wr_data_inf.data + 1'b1;
            else    wr_data_inf.data    <= wr_data_inf.data;
        end
        default:    wr_data_inf.data    <= 8'd0;
        endcase
//----<< WRITE >>-------------
always@(posedge clock,negedge rst_n)
    if(~rst_n)begin
        rd_done     <= 1'b0;
        wr_done     <= 1'b0;
        delay_done  <= 1'b0;
    end else begin
        rd_done     <= 1'b0;
        wr_done     <= 1'b0;
        delay_done  <= 1'b0;
        case(nstate)
        KEEP_RD:    rd_done <= cnt >= 256;
        BURST_WR:   wr_done <= cnt >= 256;
        WR_WAIT_1MS:
                    delay_done  <= cnt == DELAY;
        default:begin
            rd_done     <= 1'b0;
            wr_done     <= 1'b0;
            delay_done  <= 1'b0;
        end
        endcase
    end


always@(posedge clock,negedge rst_n)
    if(~rst_n)  led_0   <= 1'b1;
    else
        case(mnstate)
        CMD_FSH:led_0   <= 1'b0;
        default:;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  led_1   <= 1'b1;
    else
        case(nstate)
        KEEP_RD:begin
            led_1   <= rd_data_inf.data > 64;
        end
        RD_FSH: led_1   <= 1'b0;
        default:;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  led_2   <= 1'b1;
    else
        case(nstate)
        WR_FSH: led_2   <= 1'b0;
        default:;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  led_3   <= 1'b1;
    else
        case(mnstate)
        SET_WR_EN_FSH: led_3   <= 1'b0;
        default:;
        endcase

endmodule
