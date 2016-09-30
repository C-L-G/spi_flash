/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/29 上午10:32:55
madified:
***********************************************/
`timescale 1ns/1ps
module write_flash_burst #(
    parameter PAGE_PRG_CMD = 8'h02,
    parameter DSIZE     = 8,
    parameter SSIZE     = 1
)(
    input               frame_flag,
    spi_req_inf.master  inf,
    data_inf.slaver     data_inf
);

localparam BURST_LEN  = 256;

wire    clock;
wire    rst_n;
assign  clock = inf.clock;
assign  rst_n = inf.rst_n;
//--->> STATE CORE <<--------------
typedef enum {IDLE,EX_REQ,REQ_EXEC,REQ_FSH} REQ_STATE;
REQ_STATE nstate,cstate;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cstate  <= IDLE;
    else        cstate  <= nstate;


always@(*)
    case(cstate)
    IDLE:
        if(frame_flag)
                nstate  = EX_REQ;
        else    nstate  = IDLE;
    EX_REQ:
        if(inf.busy)
                nstate  = REQ_EXEC;
        else    nstate  = EX_REQ;
    REQ_EXEC:
        if(~inf.busy)
                nstate  = REQ_FSH;
        else    nstate  = REQ_EXEC;
    REQ_FSH:    nstate  = IDLE;
    default:    nstate  = IDLE;
    endcase

reg     busy,finish;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  busy    <= 1'b1;
    else
        case(nstate)
        EX_REQ,REQ_EXEC:
                busy    <= 1'b1;
        default:busy    <= 1'b0;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  finish    <= 1'b1;
    else
        case(nstate)
        REQ_FSH:
                finish    <= 1'b1;
        default:finish    <= 1'b0;
        endcase

// assign cmd_inf.busy[MODULE_ID]     = busy;
// assign cmd_inf.finish[MODULE_ID]   = finish;
//---<< STATE CORE >>--------------
always@(posedge clock,negedge rst_n)
    if(~rst_n)  inf.request <= 1'b0;
    else
        case(nstate)
        EX_REQ: inf.request <= 1'b1;
        default:inf.request <= 1'b0;
        endcase

// always@(posedge clock,negedge rst_n)
//     if(~rst_n)  inf.req_len <= 24'd0;
//     else
//         case(nstate)
//         EX_REQ: inf.req_len <= (BURST_LEN+1+3)*8;
//         default:inf.req_len <= 24'd0;
//         endcase
assign inf.req_len      = (BURST_LEN+1+3)*8/SSIZE;
assign inf.req_wr_len   = (BURST_LEN+1+3)*8/SSIZE;
reg             wr_data_flag;

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  wr_data_flag    <= 1'b0;
    else
        case(nstate)
        REQ_EXEC:
                wr_data_flag    <= 1'b1;
        default:wr_data_flag    <= 1'b0;
        endcase
end

typedef enum {DIDLE,SEND_CMD,SEND_ADDR0,SEND_ADDR1,SEND_ADDR2,SEND_DATA,SEND_FSH} DATA_STATE;

DATA_STATE  dcstate,dnstate;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  dcstate <= DIDLE;
    else        dcstate <= dnstate;

always@(*)
    case(dcstate)
    DIDLE:
        if(wr_data_flag)
                dnstate = SEND_CMD;
        else    dnstate = DIDLE;
    SEND_CMD:
        if(inf.wr_ready && inf.clk_en)
                dnstate = SEND_ADDR0;
        else    dnstate = SEND_CMD;
    SEND_ADDR0:
        if(inf.wr_ready && inf.clk_en)
                dnstate = SEND_ADDR1;
        else    dnstate = SEND_ADDR0;
    SEND_ADDR1:
        if(inf.wr_ready && inf.clk_en)
                dnstate = SEND_ADDR2;
        else    dnstate = SEND_ADDR1;
    SEND_ADDR2:
        if(inf.wr_ready && inf.clk_en)
                dnstate = SEND_DATA;
        else    dnstate = SEND_ADDR2;
    SEND_DATA:
        if(~wr_data_flag)
                dnstate = SEND_FSH;
        else    dnstate = SEND_DATA;
    SEND_FSH:   dnstate = DIDLE;
    default:    dnstate = DIDLE;
    endcase

reg                 curr_vld;
reg                 curr_ready;
reg [DSIZE-1:0]     curr_data;
wire        up_wr_en,down_ready;
assign      up_wr_en    = data_inf.valid;
assign      down_ready  = inf.wr_ready;


always@(posedge clock,negedge rst_n)
    if(~rst_n)  curr_vld  <= 1'b0;
    else
        case(dnstate)
        SEND_CMD,SEND_ADDR0,SEND_ADDR1:
            curr_vld    <= 1'b1;
        SEND_ADDR2:
            curr_vld    <= 1'b1;
        SEND_DATA:begin
            if(inf.clk_en)begin
                case({up_wr_en,curr_vld,down_ready})
                3'b000: curr_vld    <= 1'b0;
                3'b001: curr_vld    <= 1'b0;
                3'b010: curr_vld    <= 1'b1;
                3'b011: curr_vld    <= 1'b0;
                3'b100: curr_vld    <= 1'b1;
                3'b101: curr_vld    <= 1'b1;
                3'b110: curr_vld    <= 1'b1;
                3'b111: curr_vld    <= 1'b1;
                default:curr_vld    <= 1'b0;
                endcase
            end else    curr_vld    <= curr_vld;
        end
        default: curr_vld   <= 1'b0;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  curr_ready  <= 1'b0;
    else
        case(dnstate)
        SEND_CMD,SEND_ADDR0,SEND_ADDR1:
            curr_ready    <= 1'b0;
        SEND_ADDR2:
            curr_ready    <= 1'b0;
        SEND_DATA:begin
            if(inf.clk_en)begin
                case({up_wr_en,curr_vld,down_ready})
                3'b000: curr_ready    <= 1'b1;
                3'b001: curr_ready    <= 1'b1;
                3'b010: curr_ready    <= 1'b0;
                3'b011: curr_ready    <= 1'b1;
                3'b100: curr_ready    <= 1'b0;
                3'b101: curr_ready    <= 1'b0;
                3'b110: curr_ready    <= 1'b0;
                3'b111: curr_ready    <= 1'b1;
                default:curr_ready    <= 1'b0;
                endcase
            end else    curr_ready    <= curr_ready;
        end
        default: curr_ready   <= 1'b0;
        endcase

logic   enable_data_ready;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  enable_data_ready  <= 1'b0;
    else
        case(dnstate)
        SEND_DATA:begin
            if(inf.clk_en)
                    enable_data_ready   <= 1'b1;
            else    enable_data_ready   <= enable_data_ready;
        end
        default: enable_data_ready   <= 1'b0;
        endcase

assign data_inf.ready  = inf.wr_ready && enable_data_ready;
assign inf.wr_vld      = curr_vld;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  curr_data  <= {DSIZE{1'b0}};
    else
        case(dnstate)
        SEND_CMD:   curr_data   <= PAGE_PRG_CMD;
        SEND_ADDR0: curr_data   <= 8'd0;
        SEND_ADDR1: curr_data   <= 8'd0;
        SEND_ADDR2: curr_data   <= 8'd0;
        SEND_DATA:begin
            if(inf.clk_en)begin
                case({up_wr_en,curr_vld,down_ready})
                3'b000: curr_data    <= curr_data;
                3'b001: curr_data    <= curr_data;
                3'b010: curr_data    <= curr_data;
                3'b011: curr_data    <= curr_data;
                3'b100: curr_data    <= data_inf.data;
                3'b101: curr_data    <= data_inf.data;
                3'b110: curr_data    <= curr_data;
                3'b111: curr_data    <= data_inf.data;
                default:curr_data    <= curr_data;
                endcase
            end else    curr_data    <= curr_data;
        end
        default: curr_data   <= {DSIZE{1'b0}};
        endcase

assign inf.wr_data = curr_data;

assign inf.req_cmd = 0;

endmodule
