/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/23 上午10:56:54
madified:
***********************************************/
`timescale 1ns/1ps
module set_dq_x4 #(
    parameter MODULE_ID = 0,
    parameter CMD       = 0,
    parameter [7:0] X4_CMD = 8'h61,
    parameter [7:0] X4_REG = 8'b0100_0111
)(
    input [1:0]         outside_flash_xx,        //X1 X2 X4
    cmd_inf.slaver      cmd_inf,
    spi_req_inf.master  inf
);

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
//         EX_REQ:begin
//             case(outside_flash_xx)
//             0:  inf.req_len <= 2*8;     //X1
//             1:  inf.req_len <= 2*4;     //X2
//             2:  inf.req_len <= 2*2;     //X4
//             default:
//                 inf.req_len <= 2*8;
//             endcase
//         end
//         default:inf.req_len <= 24'd0;
//         endcase

always@(outside_flash_xx)begin
    case(outside_flash_xx)
    0:  inf.req_len = 2*8;     //X1
    1:  inf.req_len = 2*4;     //X2
    2:  inf.req_len = 2*2;     //X4
    default:
        inf.req_len = 2*8;
    endcase
end

assign inf.req_wr_len   = inf.req_len;


always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  inf.wr_vld    <= 1'b0;
    else
        case(nstate)
        REQ_EXEC:
                inf.wr_vld    <= 1'b1;
        default:inf.wr_vld    <= 1'b0;
        endcase
end

wire[0:15]      SET_X4_CMD = {X4_CMD,X4_REG};

typedef enum {DIDLE,SET_DATA0,SET_DATA1,SET_DATA2,SET_DATA3,SET_DATA4,SET_DATA5,SET_DATA6,SET_DATA7} DATA_STATE;
DATA_STATE dnstate,dcstate;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  dcstate <= DIDLE;
    else if(!inf.wr_vld)
                dcstate <= DIDLE;
    else        dcstate <= dnstate;

always@(*)
    case(dcstate)
    DIDLE:
        if(inf.wr_vld && inf.clk_en && inf.wr_ready)
                dnstate = SET_DATA0;
        else    dnstate = DIDLE;
    SET_DATA0:
        if(inf.wr_vld && inf.clk_en && inf.wr_ready)
                dnstate = SET_DATA1;
        else    dnstate = DIDLE;
    SET_DATA1:
        if(inf.wr_vld && inf.clk_en && inf.wr_ready)
                dnstate = SET_DATA2;
        else    dnstate = SET_DATA1;
    SET_DATA2:
        if(inf.wr_vld && inf.clk_en && inf.wr_ready)
                dnstate = SET_DATA3;
        else    dnstate = SET_DATA2;
    SET_DATA3:
        if(inf.wr_vld && inf.clk_en && inf.wr_ready)
                dnstate = SET_DATA4;
        else    dnstate = SET_DATA3;
    SET_DATA4:
        if(inf.wr_vld && inf.clk_en && inf.wr_ready)
                dnstate = SET_DATA5;
        else    dnstate = SET_DATA4;
    SET_DATA5:
        if(inf.wr_vld && inf.clk_en && inf.wr_ready)
                dnstate = SET_DATA6;
        else    dnstate = SET_DATA5;
    SET_DATA6:
        if(inf.wr_vld && inf.clk_en && inf.wr_ready)
                dnstate = SET_DATA7;
        else    dnstate = SET_DATA6;
    SET_DATA7:
        if(inf.wr_vld && inf.clk_en && inf.wr_ready)
                dnstate = DIDLE;
        else    dnstate = SET_DATA7;
    default:    dnstate = DIDLE;
    endcase

always@(posedge clock,negedge rst_n)begin:GEN_DATA
    if(~rst_n)  inf.wr_data <= 8'd0;
    else begin
        case(dnstate)
        DIDLE:
            case(outside_flash_xx)
            0:  inf.wr_data <= {3'b000,SET_X4_CMD[0],3'b000,SET_X4_CMD[1]};
            1:  inf.wr_data <= {2'b00,SET_X4_CMD[0],SET_X4_CMD[1],2'b00,SET_X4_CMD[2],SET_X4_CMD[3]};
            2:  inf.wr_data <= X4_CMD;
            default:;
            endcase
        SET_DATA0:
            case(outside_flash_xx)
            0:  inf.wr_data <= {3'b000,SET_X4_CMD[2],3'b000,SET_X4_CMD[3]};
            1:  inf.wr_data <= {2'b00,SET_X4_CMD[4],SET_X4_CMD[5],2'b00,SET_X4_CMD[6],SET_X4_CMD[7]};
            2:  inf.wr_data <= X4_REG;
            default:;
            endcase
        SET_DATA1:
            case(outside_flash_xx)
            0:  inf.wr_data <= {3'b000,SET_X4_CMD[4],3'b000,SET_X4_CMD[5]};
            1:  inf.wr_data <= {2'b00,SET_X4_CMD[8],SET_X4_CMD[9],2'b00,SET_X4_CMD[10],SET_X4_CMD[11]};
            default:;
            endcase
        SET_DATA2:
            case(outside_flash_xx)
            0:  inf.wr_data <= {3'b000,SET_X4_CMD[6],3'b000,SET_X4_CMD[7]};
            1:  inf.wr_data <= {2'b00,SET_X4_CMD[12],SET_X4_CMD[13],2'b00,SET_X4_CMD[14],SET_X4_CMD[15]};
            default:;
            endcase
        SET_DATA3:
            case(outside_flash_xx)
            0:  inf.wr_data <= {3'b000,SET_X4_CMD[8],3'b000,SET_X4_CMD[9]};
            default:;
            endcase
        SET_DATA4:
            case(outside_flash_xx)
            0:  inf.wr_data <= {3'b000,SET_X4_CMD[10],3'b000,SET_X4_CMD[11]};
            default:;
            endcase
        SET_DATA5:
            case(outside_flash_xx)
            0:  inf.wr_data <= {3'b000,SET_X4_CMD[12],3'b000,SET_X4_CMD[13]};
            default:;
            endcase
        SET_DATA6,SET_DATA7:
            case(outside_flash_xx)
            0:  inf.wr_data <= {3'b000,SET_X4_CMD[14],3'b000,SET_X4_CMD[15]};
            default:;
            endcase
        default:;
        endcase
end end




assign inf.req_cmd = (outside_flash_xx==0)? 3'b001: 3'b000;

endmodule
