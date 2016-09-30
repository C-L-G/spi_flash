/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/28 下午5:20:16
madified:
***********************************************/
`timescale 1ns/1ns
module read_flash_burst #(
    parameter SSIZE     = 1,
    parameter DSIZE     = 8,
    parameter READ_MEM_CMD_X4 = 8'h6B,
    parameter READ_MEM_CMD_X1 = 8'h03
)(
    spi_req_inf.master  inf,
    data_inf.master     data_inf,
    input               frame_flag
);
localparam  WR_NUM  = 9;

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
        SEND_ADDR0: curr_data   <= 8'd0;
        SEND_ADDR1: curr_data   <= 8'd0;
        SEND_ADDR2: curr_data   <= 8'd0;
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
/*
reg     mark;
always@(posedge clock,negedge rst_n)begin:MARK_BLOCK
reg [3:0]   cnt;
    if(~rst_n)begin
        mark    <= 1'b0;
        cnt     <= 4'd0;
    end else begin
        case(dnstate)
        SEND_CMD:begin
            mark    <= 1'b1;
            cnt     <= 4'd0;
        end
        GET_DATA:begin
            if(cnt == WR_NUM)
                    cnt     <= cnt;
            else    cnt     <= cnt + (inf.clk_en&&inf.rd_vld);

            if(cnt == WR_NUM)
                    mark    <= 1'b0;
            else if(cnt == (WR_NUM-1) && inf.clk_en)
                    mark    <= 1'b0;
            else    mark    <= mark;
        end
        default:begin
            cnt     <= 4'd0;
            mark    <= mark;
        end
        endcase
end end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  data_inf.valid  <= 1'b0;
    else begin
        if(inf.clk_en)begin
            if(!mark)begin
                case({inf.rd_vld,data_inf.valid,data_inf.ready})
                3'b000: data_inf.valid    = 1'b0;
                3'b001: data_inf.valid    = 1'b0;
                3'b010: data_inf.valid    = 1'b1;
                3'b011: data_inf.valid    = 1'b0;
                3'b100: data_inf.valid    = 1'b1;
                3'b101: data_inf.valid    = 1'b1;
                3'b110: data_inf.valid    = 1'b1;
                3'b111: data_inf.valid    = 1'b1;
                default:data_inf.valid    = 1'b0;
                endcase
            end else    data_inf.valid  <= 1'b0;
        end else    data_inf.valid  <= data_inf.valid;
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  data_inf.data  <= 1'b0;
    else begin
        if(inf.clk_en)begin
            if(!mark)begin
                case({inf.rd_vld,data_inf.valid,data_inf.ready})
                3'b000: data_inf.data    = data_inf.data;
                3'b001: data_inf.data    = data_inf.data;
                3'b010: data_inf.data    = data_inf.data;
                3'b011: data_inf.data    = data_inf.data;
                3'b100: data_inf.data    = inf.rd_data;
                3'b101: data_inf.data    = inf.rd_data;
                3'b110: data_inf.data    = data_inf.data;
                3'b111: data_inf.data    = inf.rd_data;
                default:data_inf.data    = data_inf.data;
                endcase
            end else    data_inf.data  <= {DSIZE{1'b0}};
        end else    data_inf.data  <= data_inf.data;
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  inf.rd_ready  <= 1'b0;
    else begin
        if(inf.clk_en)begin
            if(!mark)
                    inf.rd_ready    <= data_inf.ready;
            else    inf.rd_ready    <= 1'b1;
        end else    inf.rd_ready    <= inf.rd_ready;
    end
*/
//---<< DATA OUT >>---------------------
endmodule
