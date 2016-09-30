/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/19 下午1:45:00
madified:
***********************************************/
`timescale 1ns/1ps
module spi_req_interconnect #(
    parameter DSIZE = 8
)(
    spi_req_inf.slaver  s0,
    spi_req_inf.slaver  s1,
    spi_req_inf.slaver  s2,
    spi_req_inf.slaver  s3,
    spi_req_inf.slaver  s4,
    spi_req_inf.slaver  s5,
    spi_req_inf.slaver  s6,
    spi_req_inf.slaver  s7,
    spi_req_inf.master  m0
);

typedef enum {IDLE,SL0,SL1,SL2,SL3,SL4,SL5,SL6,SL7,EX_REQ,REQ_EXEC,REQ_FSH} ROLL_ARBIT;

ROLL_ARBIT rnstate,rcstate;

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   rcstate <= IDLE;
    else            rcstate <= rnstate;

logic[2:0]      curr_port;

always@(*)
    case(rcstate)
    IDLE:   rnstate = SL0;
    SL0:if(s0.request)
                rnstate = EX_REQ;
        else    rnstate = SL1;
    SL1:if(s1.request)
                rnstate = EX_REQ;
        else    rnstate = SL2;
    SL2:if(s2.request)
                rnstate = EX_REQ;
        else    rnstate = SL3;
    SL3:if(s3.request)
                rnstate = EX_REQ;
        else    rnstate = SL4;
    SL4:if(s4.request)
                rnstate = EX_REQ;
        else    rnstate = SL5;
    SL5:if(s5.request)
                rnstate = EX_REQ;
        else    rnstate = SL6;
    SL6:if(s6.request)
                rnstate = EX_REQ;
        else    rnstate = SL7;
    SL7:if(s7.request)
                rnstate = EX_REQ;
        else    rnstate = SL0;
    EX_REQ:
        if(m0.busy)
                rnstate = REQ_EXEC;
        else    rnstate = EX_REQ;
    REQ_EXEC:
        if(~m0.busy)
                rnstate = REQ_FSH;
        else    rnstate = REQ_EXEC;
    REQ_FSH:
        case(curr_port)
        0:  rnstate = SL1;
        1:  rnstate = SL2;
        2:  rnstate = SL3;
        3:  rnstate = SL4;
        4:  rnstate = SL5;
        5:  rnstate = SL6;
        6:  rnstate = SL7;
        7:  rnstate = SL0;
        default:
            rnstate = IDLE;
        endcase
    default:rnstate = IDLE;
    endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   curr_port   <= 3'd0;
    else
        case(rnstate)
        SL0:    curr_port   <= 3'd0;
        SL1:    curr_port   <= 3'd1;
        SL2:    curr_port   <= 3'd2;
        SL3:    curr_port   <= 3'd3;
        SL4:    curr_port   <= 3'd4;
        SL5:    curr_port   <= 3'd5;
        SL6:    curr_port   <= 3'd6;
        SL7:    curr_port   <= 3'd7;
        default:curr_port   <= curr_port;
        endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.request  <= 1'b0;
    else
        case(rnstate)
        EX_REQ:     m0.request  <= 1'b1;
        default:    m0.request  <= 1'b0;
        endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.req_len  <= 24'd0;
    else
        case(rnstate)
        EX_REQ:begin
            case(curr_port)
            0:  m0.req_len  <= s0.req_len;
            1:  m0.req_len  <= s1.req_len;
            2:  m0.req_len  <= s2.req_len;
            3:  m0.req_len  <= s3.req_len;
            4:  m0.req_len  <= s4.req_len;
            5:  m0.req_len  <= s5.req_len;
            6:  m0.req_len  <= s6.req_len;
            7:  m0.req_len  <= s7.req_len;
            default:;
            endcase
        end
        default:m0.req_len  <= 24'd0;
        endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.req_wr_len  <= 24'd0;
    else
        case(rnstate)
        EX_REQ:begin
            case(curr_port)
            0:  m0.req_wr_len  <= s0.req_wr_len;
            1:  m0.req_wr_len  <= s1.req_wr_len;
            2:  m0.req_wr_len  <= s2.req_wr_len;
            3:  m0.req_wr_len  <= s3.req_wr_len;
            4:  m0.req_wr_len  <= s4.req_wr_len;
            5:  m0.req_wr_len  <= s5.req_wr_len;
            6:  m0.req_wr_len  <= s6.req_wr_len;
            7:  m0.req_wr_len  <= s7.req_wr_len;
            default:;
            endcase
        end
        default:m0.req_wr_len  <= 24'd0;
        endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.req_cmd  <= 0;
    else
        case(rnstate)
        EX_REQ:begin
            case(curr_port)
            0:  m0.req_cmd  <= s0.req_cmd;
            1:  m0.req_cmd  <= s1.req_cmd;
            2:  m0.req_cmd  <= s2.req_cmd;
            3:  m0.req_cmd  <= s3.req_cmd;
            4:  m0.req_cmd  <= s4.req_cmd;
            5:  m0.req_cmd  <= s5.req_cmd;
            6:  m0.req_cmd  <= s6.req_cmd;
            7:  m0.req_cmd  <= s7.req_cmd;
            default:;
            endcase
        end
        default:m0.req_cmd  <= 24'd0;
        endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)begin
        s0.finish  <= 1'b0;
        s1.finish  <= 1'b0;
        s2.finish  <= 1'b0;
        s3.finish  <= 1'b0;
        s4.finish  <= 1'b0;
        s5.finish  <= 1'b0;
        s6.finish  <= 1'b0;
        s7.finish  <= 1'b0;
    end else begin
        s0.finish  <= 1'b0;
        s1.finish  <= 1'b0;
        s2.finish  <= 1'b0;
        s3.finish  <= 1'b0;
        s4.finish  <= 1'b0;
        s5.finish  <= 1'b0;
        s6.finish  <= 1'b0;
        s7.finish  <= 1'b0;
        case(rnstate)
        REQ_FSH:begin
            case(curr_port)
            0:  s0.finish  <= 1'b1;
            1:  s1.finish  <= 1'b1;
            2:  s2.finish  <= 1'b1;
            3:  s3.finish  <= 1'b1;
            4:  s4.finish  <= 1'b1;
            5:  s5.finish  <= 1'b1;
            6:  s6.finish  <= 1'b1;
            7:  s7.finish  <= 1'b1;
            default:;
            endcase
        end
        default:;
        endcase
    end

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)begin
        s0.busy  <= 1'b0;
        s1.busy  <= 1'b0;
        s2.busy  <= 1'b0;
        s3.busy  <= 1'b0;
        s4.busy  <= 1'b0;
        s5.busy  <= 1'b0;
        s6.busy  <= 1'b0;
        s7.busy  <= 1'b0;
    end else begin
        s0.busy  <= 1'b0;
        s1.busy  <= 1'b0;
        s2.busy  <= 1'b0;
        s3.busy  <= 1'b0;
        s4.busy  <= 1'b0;
        s5.busy  <= 1'b0;
        s6.busy  <= 1'b0;
        s7.busy  <= 1'b0;
        case(curr_port)
        0:  s0.busy  <= m0.busy;
        1:  s1.busy  <= m0.busy;
        2:  s2.busy  <= m0.busy;
        3:  s3.busy  <= m0.busy;
        4:  s4.busy  <= m0.busy;
        5:  s5.busy  <= m0.busy;
        6:  s6.busy  <= m0.busy;
        7:  s7.busy  <= m0.busy;
        default:;
        endcase
    end

logic   write_flag;
always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   write_flag  <= 1'b0;
    else
        case(rnstate)
        REQ_EXEC:   write_flag  <= 1'b1;
        default:    write_flag  <= 1'b0;
        endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.wr_data  <= 0;
    else begin
        if(write_flag && m0.clk_en)begin
            case(curr_port)
            0:      m0.wr_data  <= (s0.wr_vld && m0.wr_ready)? s0.wr_data : m0.wr_data;
            1:      m0.wr_data  <= (s1.wr_vld && m0.wr_ready)? s1.wr_data : m0.wr_data;
            2:      m0.wr_data  <= (s2.wr_vld && m0.wr_ready)? s2.wr_data : m0.wr_data;
            3:      m0.wr_data  <= (s3.wr_vld && m0.wr_ready)? s3.wr_data : m0.wr_data;
            4:      m0.wr_data  <= (s4.wr_vld && m0.wr_ready)? s4.wr_data : m0.wr_data;
            5:      m0.wr_data  <= (s5.wr_vld && m0.wr_ready)? s5.wr_data : m0.wr_data;
            6:      m0.wr_data  <= (s6.wr_vld && m0.wr_ready)? s6.wr_data : m0.wr_data;
            7:      m0.wr_data  <= (s7.wr_vld && m0.wr_ready)? s7.wr_data : m0.wr_data;
            default:;
            endcase
        end else    m0.wr_data  <= m0.wr_data;
    end

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.wr_vld  <= 1'b0;
    else begin
        if(write_flag)begin
            if(m0.clk_en)begin
                case(curr_port)
                0:      m0.wr_vld  <= (s0.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s0.wr_vld && m0.wr_vld && m0.wr_ready);
                1:      m0.wr_vld  <= (s1.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s1.wr_vld && m0.wr_vld && m0.wr_ready);
                2:      m0.wr_vld  <= (s2.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s2.wr_vld && m0.wr_vld && m0.wr_ready);
                3:      m0.wr_vld  <= (s3.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s3.wr_vld && m0.wr_vld && m0.wr_ready);
                4:      m0.wr_vld  <= (s4.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s4.wr_vld && m0.wr_vld && m0.wr_ready);
                5:      m0.wr_vld  <= (s5.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s5.wr_vld && m0.wr_vld && m0.wr_ready);
                6:      m0.wr_vld  <= (s6.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s6.wr_vld && m0.wr_vld && m0.wr_ready);
                7:      m0.wr_vld  <= (s7.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s7.wr_vld && m0.wr_vld && m0.wr_ready);
                default:;
                endcase
            end else begin
                m0.wr_vld   <= m0.wr_vld;
            end
        end else    m0.wr_vld  <= 1'b0;
    end

assign s0.wr_last   = m0.wr_last;
assign s1.wr_last   = m0.wr_last;
assign s2.wr_last   = m0.wr_last;
assign s3.wr_last   = m0.wr_last;
assign s4.wr_last   = m0.wr_last;
assign s5.wr_last   = m0.wr_last;
assign s6.wr_last   = m0.wr_last;
assign s7.wr_last   = m0.wr_last;

assign s0.wr_ready   = m0.wr_ready;
assign s1.wr_ready   = m0.wr_ready;
assign s2.wr_ready   = m0.wr_ready;
assign s3.wr_ready   = m0.wr_ready;
assign s4.wr_ready   = m0.wr_ready;
assign s5.wr_ready   = m0.wr_ready;
assign s6.wr_ready   = m0.wr_ready;
assign s7.wr_ready   = m0.wr_ready;

// assign s0.busy   = m0.busy;
// assign s1.busy   = m0.busy;
// assign s2.busy   = m0.busy;
// assign s3.busy   = m0.busy;
// assign s4.busy   = m0.busy;
// assign s5.busy   = m0.busy;
// assign s6.busy   = m0.busy;
// assign s7.busy   = m0.busy;

/*
wire            up_wr_en;
wire[7:0]       down_ready;
reg [7:0]       curr_vld;
reg [DSIZE-1:0] curr_data   [7:0];
reg             curr_ready;

assign  up_wr_en    = m0.rd_vld;
assign  down_ready  = {s7.rd_ready,s6.rd_ready,s5.rd_ready,s4.rd_ready,s3.rd_ready,s2.rd_ready,s1.rd_ready,s0.rd_ready};

assign  {s7.rd_vld,s6.rd_vld,s5.rd_vld,s4.rd_vld,s3.rd_vld,s2.rd_vld,s1.rd_vld,s0.rd_vld} = curr_vld;

assign  s0.rd_data  = curr_data[0];
assign  s1.rd_data  = curr_data[1];
assign  s2.rd_data  = curr_data[2];
assign  s3.rd_data  = curr_data[3];
assign  s4.rd_data  = curr_data[4];
assign  s5.rd_data  = curr_data[5];
assign  s6.rd_data  = curr_data[6];
assign  s7.rd_data  = curr_data[7];

genvar KK;
generate
//==================================================
for(KK=0;KK<8;KK=KK+1)begin:GEN_READ_DATA_BLOCK
always@(posedge m0.clock,negedge m0.rst_n)begin
    if(~m0.rst_n)  curr_vld[KK]    <= 1'b0;
    else begin
        if(m0.clk_en)begin
            if(KK == curr_port)begin
                case({up_wr_en,curr_vld[KK],down_ready[KK]})
                3'b000: curr_vld[KK]    <= 1'b0;
                3'b001: curr_vld[KK]    <= 1'b0;
                3'b010: curr_vld[KK]    <= 1'b1;
                3'b011: curr_vld[KK]    <= 1'b0;
                3'b100: curr_vld[KK]    <= 1'b1;
                3'b101: curr_vld[KK]    <= 1'b1;
                3'b110: curr_vld[KK]    <= 1'b1;
                3'b111: curr_vld[KK]    <= 1'b1;
                default:curr_vld[KK]    <= 1'b0;
                endcase
            end else    curr_vld[KK]    <= 1'b0;
        end else    curr_vld[KK]    <= curr_vld[KK];
end end
//=================================================
always@(posedge m0.clock,negedge m0.rst_n)begin
    if(~m0.rst_n) curr_data[KK]    <= {DSIZE{1'b0}};
    else begin
        if(m0.clk_en)begin
            if(KK == curr_port)begin
                case({up_wr_en,curr_vld[KK],down_ready[KK]})
                3'b000: curr_data[KK]    <= curr_data[KK];
                3'b001: curr_data[KK]    <= curr_data[KK];
                3'b010: curr_data[KK]    <= curr_data[KK];
                3'b011: curr_data[KK]    <= curr_data[KK];
                3'b100: curr_data[KK]    <= m0.rd_data;
                3'b101: curr_data[KK]    <= m0.rd_data;
                3'b110: curr_data[KK]    <= curr_data[KK];
                3'b111: curr_data[KK]    <= m0.rd_data;
                default:curr_data[KK]    <= curr_data[KK];
                endcase
            end else    curr_data[KK]    <= {DSIZE{1'b0}};
        end else    curr_data[KK]    <= curr_data[KK];
end end
//==================================================
end
endgenerate


always@(posedge m0.clock,negedge m0.rst_n)begin
    if(~m0.rst_n) curr_ready    <= 1'b0;
    else begin
        if(m0.clk_en)begin
            case(curr_port)
            3'd0: curr_ready    <= s0.rd_ready;
            3'd1: curr_ready    <= s1.rd_ready;
            3'd2: curr_ready    <= s2.rd_ready;
            3'd3: curr_ready    <= s3.rd_ready;
            3'd4: curr_ready    <= s4.rd_ready;
            3'd5: curr_ready    <= s5.rd_ready;
            3'd6: curr_ready    <= s6.rd_ready;
            3'd7: curr_ready    <= s7.rd_ready;
            default:curr_ready  <= 1'b0;
            endcase
        end else    curr_ready    <= curr_ready;
end end

assign m0.rd_ready = curr_ready;
*/
// data_connect_pipe #(
//     .DSIZE      (DSIZE  )
// )data_connect_pipe_inst4(
// /*  input             */  .clock            (m0.clock           ),
// /*  input             */  .rst_n            (m0.rst_n           ),
// /*  input             */  .clk_en           (m0.clk_en          ),
// /*  input             */  .from_up_vld      (m0.rd_vld   && (curr_port==4)       ),
// /*  input [DSIZE-1:0] */  .from_up_data     (m0.rd_data         ),
// /*  output            */  .to_up_ready      (m0.rd_ready        ),
//
// /*  input             */  .from_down_ready  (s4.rd_ready && (curr_port==4)       ),
// /*  output            */  .to_down_vld      (s4.rd_vld          ),
// /*  output[DSIZE-1:0] */  .to_down_data     (s4.rd_data         )
// );

data_connect_pipe #(
    .DSIZE      (DSIZE  )
)data_connect_pipe_inst5(
/*  input             */  .clock            (m0.clock           ),
/*  input             */  .rst_n            (m0.rst_n           ),
/*  input             */  .clk_en           (m0.clk_en          ),
/*  input             */  .from_up_vld      (m0.rd_vld   && (curr_port==5)       ),
/*  input [DSIZE-1:0] */  .from_up_data     (m0.rd_data         ),
/*  output            */  .to_up_ready      (m0.rd_ready        ),

/*  input             */  .from_down_ready  (s5.rd_ready && (curr_port==5)       ),
/*  output            */  .to_down_vld      (s5.rd_vld          ),
/*  output[DSIZE-1:0] */  .to_down_data     (s5.rd_data         )
);


endmodule


module slaver_data_tap #(
    parameter DSIZE = 8,
    parameter ID    = 0
)(
    input                   clock,
    input                   rst_n,
    input [2:0]             curr_port,
    input                   rd_en,
    input                   rd_vld,
    input [DSIZE-1:0]       rd_data,
    output                  rd_ready,
    output                  tap_vld,
    output[DSIZE-1:0]       tap_data,
    input                   tap_ready
);

// always@(posedge clock,negedge rst_n)begin
//     if(~rst_n)begin
//         tap_vld     <= 1'b0;
//         tap_data    <= {DSIZE{1'b0}};
//     end else begin
//         if(rd_en)begin
//             if(ID == curr_port)begin
//                 tap_vld     <= rd_vld;
//                 tap_data    <= rd_data;
//             end else begin
//                 tap_vld     <= 1'b0;
//                 tap_data    <= {DSIZE{1'b0}};
//             end
//         end else begin
//             tap_vld     <= tap_vld;
//             tap_data    <= tap_data;
// end end end

reg                 curr_vld;
reg                 curr_ready;
reg [DSIZE-1:0]     curr_data;
wire        up_wr_en,down_ready;
assign      up_wr_en    = rd_vld;
assign      down_ready  = tap_ready;

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  curr_vld    <= 1'b0;
    else begin
        if(rd_en)begin
            if(ID == curr_port)begin
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
            end else    curr_vld    <= 1'b0;
        end else    curr_vld    <= curr_vld;
end end

assign tap_vld  = curr_vld;

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  curr_ready    <= 1'b0;
    else begin
        if(rd_en)begin
            if(ID == curr_port)begin
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
            end else    curr_ready    <= 1'b0;
        end else    curr_ready    <= curr_ready;
end end

assign rd_ready = curr_ready;


always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  curr_data    <= {DSIZE{1'b0}};
    else begin
        if(rd_en)begin
            if(ID == curr_port)begin
                case({up_wr_en,curr_vld,down_ready})
                3'b000: curr_data    <= curr_data;
                3'b001: curr_data    <= curr_data;
                3'b010: curr_data    <= curr_data;
                3'b011: curr_data    <= curr_data;
                3'b100: curr_data    <= rd_data;
                3'b101: curr_data    <= rd_data;
                3'b110: curr_data    <= curr_data;
                3'b111: curr_data    <= rd_data;
                default:curr_data    <= curr_data;
                endcase
            end else    curr_data    <= {DSIZE{1'b0}};
        end else    curr_data    <= curr_data;
end end

assign tap_data = curr_data;

endmodule
