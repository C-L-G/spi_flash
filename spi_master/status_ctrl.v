/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/12 下午4:47:17
madified:
***********************************************/
`timescale 1ns/1ps
module status_ctrl #(
    parameter SSIZE = 1
)(
    input           wr_clk,
    input           wr_rst_n,
    input           wr_clk_en,
    input           rd_clk,
    input           rd_rst_n,
    input           rd_clk_en,
    input           spi_dr_clock,
    input           spi_dr_rst_n,
    output reg      spi_csn,
    input           request,
    input [2:0]     req_cmd,
    input [23:0]    req_len,
    input [23:0]    req_wr_len,
    output          busy,
    output          finish,
    output reg[SSIZE-1:0]      dq_wr_rd,
    output          wr_finish,
    input           data_flag,
    output reg      sck_en,
    output reg      rst_fifo,
    output          wr_rd_pause,
    input           deserial_empty,
    input           deserial_rd_vld,
    output reg      mark_deserial
);

reg [3:0]       cstate,nstate;

localparam      IDLE    = 4'd0,
                REQ_S   = 4'd1,
                WAIT_E  = 4'd2,
                FSH     = 4'd3,
                TAIL    = 4'd4,
                WAIT_EMT= 4'd5;

reg             cnt_fsh;
reg             tail_fsh;

always@(posedge wr_clk,negedge wr_rst_n)
    if(~wr_rst_n)  cstate  <= IDLE;
    else        cstate  <= nstate;

wire        burst_ready_state;

always@(*)
    case(cstate)
    IDLE:
        if(request)
                nstate = REQ_S;
        else    nstate = IDLE;
    REQ_S:      nstate = WAIT_E;
    WAIT_E:
        if(cnt_fsh)
                nstate = WAIT_EMT;
        else    nstate = WAIT_E;
    TAIL:
        if(tail_fsh)
                nstate = FSH;
        else    nstate = TAIL;
    WAIT_EMT:
        if(burst_ready_state)begin
            if(deserial_empty && wr_clk_en)
                    nstate = FSH;
            else    nstate = WAIT_EMT;
        end else    nstate = FSH;
    FSH:        nstate = IDLE;
    default:    nstate = IDLE;
    endcase


reg     busy_reg;
reg     fsh_reg;

always@(posedge wr_clk,negedge wr_rst_n)
    if(~wr_rst_n)  busy_reg    <= 1'b0;
    else
    case(nstate)
    REQ_S,WAIT_E,TAIL,WAIT_EMT:
                    busy_reg    <= 1'b1;
    default:        busy_reg    <= 1'b0;
    endcase

always@(posedge wr_clk,negedge wr_rst_n)
    if(~wr_rst_n)  fsh_reg <= 1'b0;
    else
    case(nstate)
    FSH:        fsh_reg <= 1'b1;
    default:    fsh_reg <= 1'b0;
    endcase

reg [23:0]      count;
//
// always@(posedge wr_clk,negedge wr_rst_n)
//     if(~wr_rst_n)  count   <= 24'd0;
//     else
//         case(nstate)
//         WAIT_E:
//             if(data_flag)
//                     count <= count + 1'b1;
//             else    count <= count;
//         default:count <= 24'd0;
//         endcase

always@(posedge spi_dr_clock,negedge spi_dr_rst_n)
    if(~spi_dr_rst_n)   count   <= 24'd0;
    else begin
        if(spi_csn)begin
            count <= 24'd0;
        end else begin
            count <= count + data_flag;
        end
    end

reg [23:0]      cnt_point;

always@(posedge wr_clk,negedge wr_rst_n)
    if(~wr_rst_n)  cnt_point   <= 24'd0;
    else
        case(nstate)
        IDLE,FSH:
                cnt_point   <= 24'd0;
        REQ_S:  cnt_point   <= req_len;
        default:cnt_point   <= cnt_point;
        endcase

reg [23:0]      wr_cnt_point;

always@(posedge wr_clk,negedge wr_rst_n)
    if(~wr_rst_n)  wr_cnt_point   <= 24'd0;
    else
        case(nstate)
        REQ_S:  wr_cnt_point   <= req_wr_len;
        default:wr_cnt_point   <= wr_cnt_point;
        endcase

// always@(posedge wr_clk,negedge wr_rst_n)
//     if(~wr_rst_n)  cnt_fsh <= 1'b0;
//     else
//         case(nstate)
//         WAIT_E: cnt_fsh <= count == cnt_point;
//         default:cnt_fsh <= 1'b0;
//         endcase

always@(posedge spi_dr_clock,negedge spi_dr_rst_n)begin:GEN_CNT_FSH
reg [4:0]   tail_cnt;
    if(~spi_dr_rst_n)begin
        cnt_fsh     <= 1'd0;
        tail_cnt    <= 4'd0;
        tail_fsh    <= 1'b1;
    end else begin
        if(~spi_csn)begin
            cnt_fsh <= count >= cnt_point;
        end else begin
            cnt_fsh <= 1'b0;
        end

        if(cnt_fsh)begin
            if(tail_cnt<4'd15)
                    tail_cnt    <= tail_cnt + 1'b1;
            else    tail_cnt    <= tail_cnt;
        end else    tail_cnt    <= 4'd0;

        tail_fsh <= tail_cnt > 4'd14;
    end
end
//----->> DQ CTRL <<-----------------
reg [2:0]   cmd;
always@(posedge wr_clk,negedge wr_rst_n)
    if(~wr_rst_n)  cmd   <= 3'd0;
    else
        case(nstate)
        REQ_S:  cmd   <= req_cmd;
        default:cmd   <= cmd;
        endcase
/*
cmd:
000-> default burst write ,only write
001-> DQ[0] force write
      DQ[3:1] rd_wr_ctrl
010-> burst read
*/
assign burst_ready_state = cmd == 3'b010;

reg  wr_fsh;

always@(posedge spi_dr_clock,negedge spi_dr_rst_n)
    if(~spi_dr_rst_n)   wr_fsh  <= 1'b0;
    else begin
        if(~spi_csn)    wr_fsh  <= count >= wr_cnt_point;
        else            wr_fsh  <= 1'b0;
    end

always@(posedge spi_dr_clock,negedge spi_dr_rst_n)begin:GEN_DQ_WR_RD_BLOCK
integer KK;
    if(~spi_dr_rst_n)   dq_wr_rd    <= {SSIZE{1'b1}};
    else begin
        if(~spi_csn)begin
            if(cmd == 3'b001)begin
                for(KK=0;KK<SSIZE;KK=KK+1)
                    dq_wr_rd[KK]    <= 1'b1;
                dq_wr_rd[0] <= count >= (wr_cnt_point-1);
            end else begin
                for(KK=0;KK<SSIZE;KK=KK+1)
                    dq_wr_rd[KK]    <= count >= (wr_cnt_point-1);
            end
        end else    dq_wr_rd    <= {SSIZE{1'b1}};
    end
end
//-----<< DQ CTRL >>-----------------
//----->> PAUSE CTRL <<--------------
reg        wr_rd_pause_reg;
always@(posedge spi_dr_clock,negedge spi_dr_rst_n)begin
    if(~spi_dr_rst_n)   wr_rd_pause_reg    <= 1'b0;     //ENABLE WR PAUSE
    else begin
        if(~spi_csn)
                wr_rd_pause_reg <= count >= wr_cnt_point;   //ENABLE RD PAUSE
        else    wr_rd_pause_reg <= 1'b0;
    end
end

assign wr_rd_pause = wr_rd_pause_reg;
//-----<< PAUSE CTRL >>--------------
//---->> SPI CSN <<---------
always@(posedge spi_dr_clock,negedge spi_dr_rst_n)begin:GEN_SPI_CSN
reg [1:0]   tmp;
    if(~spi_dr_rst_n)begin
       spi_csn  <= 1'b1;
       tmp      <= 2'b11;
       rst_fifo <= 1'b0;
    end else begin
        rst_fifo<= tmp == 2'b10;
        tmp     <= {tmp[0],~busy_reg};
        spi_csn <= tmp[1];
    end
end
//----<< SPI CSN >>---------
assign wr_finish= wr_fsh;
assign busy     = busy_reg;
assign finish   = fsh_reg;

//----->> SCK ENABLE <<-----
// always@(posedge wr_clk,negedge wr_rst_n)
//     if(~wr_rst_n)  sck_en    <= 1'b0;
//     else
//     case(nstate)
//     REQ_S,WAIT_E:
//                 sck_en    <= 1'b1;
//     default:    sck_en    <= 1'b0;
//     endcase
always@(count,cnt_point,spi_csn)
    sck_en  = !(count >= cnt_point) && !spi_csn;
//-----<< SCK ENABLE >>-----
//----->> MARK DESERIAL <<--
always@(posedge rd_clk,negedge rd_rst_n)begin:MARK_BLOCK
reg [23:0]      cnt;
    if(~rd_rst_n)begin
        cnt             <= 24'd0;
        mark_deserial   <= 1'b1;
    end else begin
        if(!busy)begin
            cnt     <= 24'd0;
        end else begin
            if(deserial_rd_vld)
                    cnt     <= cnt + 1'b1;
            else    cnt     <= cnt;

            mark_deserial   <= cnt < (wr_cnt_point*SSIZE/8+4);
        end
    end
end
//-----<< MARK DESERIAL >>--
endmodule
