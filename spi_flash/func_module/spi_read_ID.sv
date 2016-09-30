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
module spi_read_ID #(
    parameter MODULE_ID= 0,
    parameter DSIZE = 8,
    parameter CMD   = 0,
    parameter SSIZE = 1
)(
    cmd_inf.slaver      cmd_inf,
    output[DSIZE-1:0]   spi_id,
    output              id_vld,
    spi_req_inf.master  inf
);
localparam ID_REQ_LEN = 4;

wire    clock;
wire    rst_n;
assign  clock = inf.clock;
assign  rst_n = inf.rst_n;

//--->> STATE CORE <<--------------
typedef enum {IDLE,EX_REQ,REQ_EXEC,REQ_FSH} REQ_STATE;
REQ_STATE nstate,cstate;
// localparam  IDLE        = 4'd0,
//             EX_REQ      = 4'd1,
//             REQ_EXEC    = 4'd2,
//             REQ_FSH     = 4'd3;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cstate <= IDLE;
    else        cstate <= nstate;

always@(*)
    case(cstate)
    IDLE:
        if(cmd_inf.request && cmd_inf.cmd == CMD)
                nstate = EX_REQ;
        else    nstate = IDLE;
    EX_REQ:
        if(inf.busy)
                nstate = REQ_EXEC;
        else    nstate = EX_REQ;
    REQ_EXEC:
        if(~inf.busy)
                nstate = REQ_FSH;
        else    nstate = REQ_EXEC;
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
//         EX_REQ: inf.req_len <= ID_REQ_LEN*8/SSIZE;
//         default:inf.req_len <= 24'd0;
//         endcase
assign inf.req_len     = ID_REQ_LEN*8/SSIZE;
assign inf.req_wr_len  = ID_REQ_LEN*8/SSIZE;
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

reg [4:0]   cnt;

always@(posedge clock,negedge rst_n)begin:DATA_GEN_BLOCK
    if(~rst_n)begin
        inf.wr_vld    <= 1'b0;
        inf.wr_data <= {DSIZE{1'b0}};
        cnt         <= 5'd0;
    end else begin
        if(wr_data_flag)begin
            //---------------------------
            if(inf.wr_ready && inf.clk_en && inf.wr_vld)
                    cnt     <= cnt + 1'd1;
            else    cnt     <= cnt;
            //----------------------------
            if(cnt == (ID_REQ_LEN-1) && inf.wr_ready && inf.clk_en)
                    inf.wr_vld    <= 1'b0;
            else if(cnt == 0)
                    inf.wr_vld    <= 1'b1;
            else    inf.wr_vld   <= inf.wr_vld;
            //---------------------------
            case(cnt)
            0: inf.wr_data  <= 8'b1001_1111;
            1: inf.wr_data  <= 1;
            default: inf.wr_data  <= inf.wr_data;
            endcase
        end else begin
            inf.wr_vld    <= 1'b0;
            inf.wr_data <= {DSIZE{1'b0}};
            cnt         <= 5'd0;
        end
end end

reg [DSIZE-1:0]     id_reg;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  id_reg      <= {DSIZE{1'b0}};
    else
        case(cnt)
        ID_REQ_LEN: id_reg <= inf.rd_data;
        default:;
        endcase

assign spi_id = id_reg;

reg     id_vld_reg;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  id_vld_reg <= 1'b0;
    else
        case(nstate)
        REQ_FSH:id_vld_reg <= inf.clk_en;
        default:id_vld_reg <= 1'b0;
        endcase

assign id_vld = id_vld_reg;

assign inf.req_cmd = 0;

endmodule
