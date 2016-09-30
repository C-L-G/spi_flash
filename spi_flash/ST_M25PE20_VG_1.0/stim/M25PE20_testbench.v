/*=========================================================

Testbench for M25PE20 SPI Bus Flash Memory

=========================================================*/

`include "E:/work/other_module/spi_flash/ST_M25PE20_VG_1.0/code/M25PE20_macro.v"

//=========================================================
module M25PE20_TB;

//---------------------------------------------------------
wire c,d,q,s,tsl,reset,vcc,vss;

//---------------------------------------------------------
//Memory Array Initial
//---------------------------------------------------------
initial begin
  $display("%t: NOTE: Load Memory with Initial Content.",$realtime);
  $readmemh("E:/work/other_module/spi_flash/ST_M25PE20_VG_1.0/sim/M25PE20_initial.txt",U_M25PE20.memory);
  $display("%t: NOTE: Load Memory Successfully.\n",$realtime);
end

//---------------------------------------------------------
//Memory Model Instance
//---------------------------------------------------------
M25PE20_MEMORY U_M25PE20(.C(c),.D(d),.Q(q),.S(s),.TSL(tsl),.RESET(reset),.VCC(vcc),.VSS(vss));

//---------------------------------------------------------
//Memory Stimuli Instance
//---------------------------------------------------------
M25PE20_DRIVER D_M25PE20(.C(c),.D(d),.Q(q),.S(s),.TSL(tsl),.RESET(reset),.VCC(vcc),.VSS(vss));

endmodule
