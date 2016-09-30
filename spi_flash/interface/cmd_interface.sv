/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/9/21 下午4:22:53
madified:
***********************************************/
interface cmd_inf #(
    parameter   CSIZE = 4,
    parameter   LSIZE = 24,
    parameter   SLIZE = 16
);

logic               request;
logic[LSIZE-1:0]    req_len;
wire [SLIZE-1:0]    busy;
wire [SLIZE-1:0]    finish;
logic[CSIZE-1:0]    cmd;

modport master (
    output      request,
    output      req_len,
    input       busy,
    input       finish,
    output      cmd
);

modport slaver (
    input       request,
    input       req_len,
    inout       busy,
    inout       finish,
    input       cmd
);

endinterface
