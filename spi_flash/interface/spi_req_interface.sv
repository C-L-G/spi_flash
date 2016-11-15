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
interface spi_req_inf #(
    parameter DSIZE = 8,
    parameter CSIZE = 3
)(
    input bit  clock,
    input bit  clk_en,
    input bit  rst_n
);

logic                  request         ;
logic[CSIZE-1:0]       req_cmd         ;
logic[23:0]            req_len         ;
logic[23:0]            req_wr_len      ;
logic                  busy            ;
logic                  finish          ;
//--- write port
logic                  wr_vld          ;
logic[DSIZE-1:0]       wr_data         ;
logic                  wr_ready        ;
logic                  wr_last         ;
//--- read port
logic                  rd_ready        ;
logic                  rd_vld          ;
logic[DSIZE-1:0]       rd_data         ;
logic                  rd_last         ;

modport master(
    input                   clock           ,
    input                   clk_en          ,
    input                   rst_n           ,
    output                  request         ,
    output                  req_cmd         ,
    output                  req_len         ,
    output                  req_wr_len      ,
    input                   busy            ,
    input                   finish          ,
    //--- write port
    output                  wr_vld          ,
    output                  wr_data         ,
    input                   wr_ready        ,
    output                  wr_last         ,
    //--- read port
    input                   rd_vld          ,
    output                  rd_ready        ,
    input                   rd_last         ,
    input                   rd_data
);

modport slaver(
    input                   clock           ,
    input                   clk_en          ,
    input                   rst_n           ,
    //---
    input                   request         ,
    input                   req_cmd         ,
    input                   req_len         ,
    input                   req_wr_len      ,
    output                  busy            ,
    output                  finish          ,
    //--- write port
    input                   wr_vld          ,
    input                   wr_data         ,
    output                  wr_ready        ,
    input                   wr_last         ,
    //--- read port
    input                   rd_ready        ,
    output                  rd_vld          ,
    output                  rd_last         ,
    output                  rd_data
);

endinterface
