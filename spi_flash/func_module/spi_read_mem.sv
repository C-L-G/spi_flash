/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/23 下午3:08:31
madified:
***********************************************/
`timescale 1ns/1ps
module spi_read_mem #(
    parameter MODULE_ID = 0,
    parameter CMD       = 0,
    parameter SSIZE     = 1,
    parameter DSIZE     = 8,
    parameter READ_MEM_CMD_X4 = 8'h6B,
    parameter READ_MEM_CMD_X1 = 8'h03
)(
    cmd_inf.slaver      cmd_inf,
    spi_req_inf.master  inf,
    input [3*DSIZE-1:0] rd_addr,
    data_inf.master     data_inf
);
localparam  WR_NUM  = 4;

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
        if(cmd_inf.request && cmd_inf.cmd == CMD)
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

assign cmd_inf.busy[MODULE_ID]     = busy;
assign cmd_inf.finish[MODULE_ID]   = finish;
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
assign inf.req_len      = (256+WR_NUM)*8/SSIZE;
assign inf.req_wr_len   =  4*8/SSIZE;

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

typedef enum {DIDLE,SEND_CMD,SEND_ADDR0,SEND_ADDR1,SEND_ADDR2,GET_DATA,SEND_FSH} DATA_STATE;

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
                dnstate = GET_DATA;
        else    dnstate = SEND_ADDR2;
    GET_DATA:
        if(~wr_data_flag)
                dnstate = SEND_FSH;
        else    dnstate = GET_DATA;
    SEND_FSH:   dnstate = DIDLE;
    default:    dnstate = DIDLE;
    endcase

reg                 curr_vld;
reg [DSIZE-1:0]     curr_data;


always@(posedge clock,negedge rst_n)
    if(~rst_n)  curr_vld  <= 1'b0;
    else
        case(dnstate)
        SEND_CMD,SEND_ADDR0,SEND_ADDR1,SEND_ADDR2:
            curr_vld    <= 1'b1;
        GET_DATA:begin
            curr_vld   <= 1'b0;
        end
        default: curr_vld   <= 1'b0;
        endcase

assign inf.wr_vld         = curr_vld;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  curr_data  <= {DSIZE{1'b0}};
    else
        case(dnstate)
        SEND_CMD:   curr_data   <= (SSIZE==1)? READ_MEM_CMD_X1 : READ_MEM_CMD_X4;
        SEND_ADDR0: curr_data   <= rd_addr[3*DSIZE-1-:DSIZE];
        SEND_ADDR1: curr_data   <= rd_addr[2*DSIZE-1-:DSIZE];
        SEND_ADDR2: curr_data   <= rd_addr[1*DSIZE-1-:DSIZE];
        GET_DATA:begin
                    curr_data   <= {DSIZE{1'b0}};
        end
        default: curr_data   <= {DSIZE{1'b0}};
        endcase

assign inf.wr_data = curr_data;

assign data_inf.valid   = inf.rd_vld;
assign data_inf.data    = inf.rd_data;
assign inf.rd_ready     = data_inf.ready;
assign inf.req_cmd      = 3'b010;

//--->> DATA OUT <<---------------------
//---<< DATA OUT >>---------------------
endmodule
