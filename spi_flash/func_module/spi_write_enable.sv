/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/19 上午11:12:48
madified:
***********************************************/
`timescale 1ns/1ps
module spi_write_enable #(
    parameter   MODULE_ID  = 0,
    parameter   CMD_WR_EN  = 0,
    parameter   CMD_WR_DS  = 1,
    parameter   SSIZE      = 1
)(
    cmd_inf.slaver      cmd_inf,
    spi_req_inf.master  inf
);

wire    clock;
wire    rst_n;
assign  clock = inf.clock;
assign  rst_n = inf.rst_n;
//--->> STATE CORE <<--------------
typedef enum {IDLE,REQ_EN,REQ_DIS,REQ_EXEC,REQ_FSH} REQ_STATE;
REQ_STATE nstate,cstate;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cstate  <= IDLE;
    else        cstate  <= nstate;

always@(*)
    case(cstate)
    IDLE:
        if(cmd_inf.request && cmd_inf.cmd == CMD_WR_EN)
                nstate  = REQ_EN;
        else if(cmd_inf.request && cmd_inf.cmd == CMD_WR_DS)
                nstate  = REQ_DIS;
        else    nstate  = IDLE;
    REQ_EN:
        if(inf.busy)
                nstate  = REQ_EXEC;
        else    nstate  = REQ_EN;
    REQ_DIS:
        if(inf.busy)
                nstate  = REQ_EXEC;
        else    nstate  = REQ_DIS;
    REQ_EXEC:
        if(~inf.busy)
                nstate  = REQ_FSH;
        else    nstate  = REQ_EXEC;
    REQ_FSH:    nstate  = IDLE;
    default:    nstate  = IDLE;
    endcase

reg busy;
reg finish;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  busy    <= 1'b1;
    else
        case(nstate)
        REQ_EN,REQ_DIS,REQ_EXEC:
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
        REQ_EN,REQ_DIS:
                inf.request <= 1'b1;
        default:inf.request <= 1'b0;
        endcase

// always@(posedge clock,negedge rst_n)
//     if(~rst_n)  inf.req_len <= 24'd0;
//     else
//         case(nstate)
//         REQ_EN,REQ_DIS:
//                 inf.req_len <= 24'd1*8/SSIZE;
//         default:inf.req_len <= 24'd0;
//         endcase
assign inf.req_len      = 24'd1*8/SSIZE;
assign inf.req_wr_len   = 24'd1*8/SSIZE;

always@(posedge clock,negedge rst_n)begin:VALID_BLOCK
reg     tmp;
    if(~rst_n)begin
        inf.wr_vld    <= 1'b0;
        tmp           <= 1'b0;
    end else begin
        case(nstate)
        REQ_EXEC:begin
            if(inf.wr_ready && inf.clk_en && inf.wr_vld)
                    tmp     <= 1'b1;
            else    tmp     <= tmp;
            if(inf.wr_ready && inf.clk_en && inf.wr_vld)
                    inf.wr_vld   <= 1'b0;
            else    inf.wr_vld   <= ~tmp;
        end
        default:begin
            tmp           <= 1'b0;
            inf.wr_vld    <= 1'b0;
        end
        endcase
    end
end

always@(posedge clock,negedge rst_n)begin:DATA_GEN_BLOCK
    if(~rst_n)begin
        inf.wr_data    <= 1'b0;
    end else begin
        case(nstate)
        REQ_EN: inf.wr_data <= 8'b0000_0110;
        REQ_DIS:inf.wr_data <= 8'b0000_0100;
        default:;
        endcase
end end

assign inf.req_cmd = 0;

endmodule
