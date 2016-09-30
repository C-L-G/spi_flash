/*===============================================

M25PE20 SPI Bus Flash Memory Driver

===============================================*/

`include "E:/work/other_module/spi_flash/ST_M25PE20_VG_1.0/code/M25PE20_macro.v"

//Max. No of bytes for PAGE WRITE and PAGE PROGRAM by different data
`define  PGBUF_MAX   256

//===============================================
module M25PE20_DRIVER(C,D,Q,S,TSL,RESET,VCC,VSS);

//-----------------------------------------------
output C,D,S,TSL,RESET,VCC,VSS;
input Q;

//-----------------------------------------------
reg C,D,S,TSL,RESET,VCC;

//-----------------------------------------------
integer i,j;

reg[7:0] sr,lk_reg,read_dat,id1,id2,id3;
//data buf for PAGE WRITE with different data
reg[7:0] page_wr_buf[`PGBUF_MAX-1:0];
//data buf for PAGE PROGRAM with different data
reg[7:0] page_pg_buf[`PGBUF_MAX-1:0];

//-----------------------------------------------
// Test the M25PE20
//-----------------------------------------------
initial begin
  for(i=0;i<=`PGBUF_MAX-1;i=i+1)
  begin
    page_wr_buf[i] = 8'hff; //page write buffer initial
    page_pg_buf[i] = 8'hff; //page program buffer initial
  end
  VCC = 1'b1;
  #(`tVSL);            //time delay for Vcc to /S low
  #(`tPUW_MAX);        //time delay before first write, program and erase instruction
  #10; TSL = 1'b1;     //top sector is not protected
  #10; RESET = 1'b0;   //enter reset mode
  #10; S = 1'b1;
  #(`tSHSL);           //chip select deselect time
  READ_IDENTIFICATION; //instruction is sent during reset mode
  #(`tRLRH);           //reset pulse width
  RESET = 1'b1;

  S = 1'b1; #(`tCHSL); #(`tRHSL1);
  S = 1'b0; #(`tSLCH-`tDVCH);
  for(i=0;i<=7;i=i+1)
  begin
    //WREN instruction
    if((i==5)||(i==6)) D = 1'b1; else D = 1'b0;
    //data setup time, and /S active setup time with #(`tSLCH-`tDVCH)
    #(`tDVCH); C = 1'b1;
    //reset is driven low during instruction byte latched in
    RESET = 1'b0;
    #(`tCH+2); C = 1'b0;
    #(`tCL+2-`tDVCH);
  end
  #(`tDVCH); #(`tCHSH); //chip select active hold time
   S = 1'b1; #(`tSHSL); //chip select deselect time
  #(`tRLRH);
  RESET = 1'b1; #(`tRHSL1);

  READ_IDENTIFICATION;

  ///////////////////////////////////////////////////////
  //Program address 000000~00000c and read for verification
  /*
  WRITE_ENABLE;
  //page_pg_buf = {8'h55,8'haa,8'h00,8'hff,8'haa,8'h55,8'hff,8'h00,8'h12,8'h34,8'h56,8'h78};
  page_pg_buf[0] = 8'h55;  page_pg_buf[1] = 8'haa;   page_pg_buf[2] = 8'h00;
  page_pg_buf[3] = 8'hff;  page_pg_buf[4] = 8'haa;   page_pg_buf[5] = 8'h55;
  page_pg_buf[6] = 8'hff;  page_pg_buf[7] = 8'h00;   page_pg_buf[8] = 8'h12;
  page_pg_buf[9] = 8'h34;  page_pg_buf[10] = 8'h56;  page_pg_buf[11] = 8'h78;
  PAGE_PROGRAM_DIFF_DATA(12,24'h000000);
  #200;
  RESET = 1'b0;
  #(`tRLRH);
  //RESET = 1'b1;
  //#(`tRHSL1);
  #200;
  //S = 1'b0;
  #(`tPW_MAX);
  //while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  RESET = 1'b1;
  READ_DATA_BYTES(4,24'h000000);
  READ_DATA_BYTES(4,24'h000004);
  READ_DATA_BYTES(4,24'h000008);
  READ_DATA_BYTES(4,24'h00000c);
  $stop;

  //Write address 000000~00000c and read for verification
  WRITE_ENABLE;
  //page_wr_buf = {8'haa,8'h55,8'hff,8'h00,8'h55,8'haa,8'h00,8'hff,8'hab,8'hcd,8'hef,8'h01};
  page_wr_buf[0] = 8'haa;  page_wr_buf[1] = 8'h55;   page_wr_buf[2] = 8'hff;
  page_wr_buf[3] = 8'h00;  page_wr_buf[4] = 8'h55;   page_wr_buf[5] = 8'haa;
  page_wr_buf[6] = 8'h00;  page_wr_buf[7] = 8'hff;   page_wr_buf[8] = 8'hab;
  page_wr_buf[9] = 8'hcd;  page_wr_buf[10] = 8'hef;  page_wr_buf[11] = 8'h01;
  PAGE_WRITE_DIFF_DATA(12,24'h000000);
  //#(`tPW_MAX);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  READ_DATA_BYTES(4,24'h000000);
  READ_DATA_BYTES(4,24'h000004);
  READ_DATA_BYTES(4,24'h000008);
  READ_DATA_BYTES(4,24'h00000c);

  //Bulk Erase and read for verification
  WRITE_ENABLE;
  BULK_ERASE; #(`tBE_MAX);
  READ_DATA_BYTES(4,24'h000000);
  READ_DATA_BYTES(4,24'h000004);
  READ_DATA_BYTES(4,24'h000008);
  READ_DATA_BYTES(4,24'h00000c);

  //Program address 000000 continuously, verify "only change bit from 1 to 0"
  WRITE_ENABLE;
  PAGE_ERASE(24'h000000);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(1,8'hff,24'h000000);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  READ_DATA_BYTES(1,24'h000000);
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(1,8'hfe,24'h000000);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  READ_DATA_BYTES(1,24'h000000);
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(1,8'hfd,24'h000000);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  READ_DATA_BYTES(1,24'h000000);
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(1,8'hfb,24'h000000);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  READ_DATA_BYTES(1,24'h000000);
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(1,8'hf7,24'h000000);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  READ_DATA_BYTES(1,24'h000000);
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(1,8'hef,24'h000000);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  READ_DATA_BYTES(1,24'h000000);
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(1,8'hdf,24'h000000);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  READ_DATA_BYTES(1,24'h000000);
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(1,8'hbf,24'h000000);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  READ_DATA_BYTES(1,24'h000000);
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(1,8'h7f,24'h000000);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  READ_DATA_BYTES(1,24'h000000);
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(1,8'hff,24'h000000);
  while(U_M25PE20.status_reg[0] == 1)   READ_STATUS_REGISTER;
  READ_DATA_BYTES(1,24'h000000);
  WRITE_ENABLE;
  PAGE_ERASE(24'h000000);
  #(`tPE_MAX);
  */

//=============================================================================
//check all instructions druing an erase,write or program cycle is in progress.
//=============================================================================
  $display("=================================================================================================");
  $display("%t: TESTING1: All instructions are executed while an erase,program,write cycle is in progress.",$realtime);
  $display("=================================================================================================");
  WRITE_ENABLE;
  SECTOR_ERASE(24'h000000); //Sector Erase begin,WIP=1.
  //PAGE_ERASE(24'h010000);
  //PAGE_WRITE_SAME_DATA(2,8'h68,24'h000000);
  WRITE_ENABLE;
  WRITE_DISABLE;
  READ_IDENTIFICATION;
  READ_STATUS_REGISTER;
  READ_DATA_BYTES(2,24'h000100);
  READ_DATA_BYTES_FAST(2,24'h000100);
  PAGE_PROGRAM_SAME_DATA(2,8'haa,24'h000000);
  //#(`tPP_MAX+100);
  PAGE_WRITE_SAME_DATA(2,8'h00,24'h01ff00);
  //#(`tPW_MAX+100);
  PAGE_ERASE(24'h010000);
  //#(`tPE_MAX);
  SECTOR_ERASE(24'h000000);
  //#(`tSE_MAX);
  DEEP_POWER_DOWN;
  //#(`tDP);
  RELEASE_FROM_DEEP_POWER_DOWN;
  //#(`tRDP);
  #(`tSE_MAX); //Sector Erase Cycle finish

//=============================================================================
//check hardware write protect
//=============================================================================
  $display("=================================================================");
  $display("%t: TESTING2: Memory hardware write protect by TSL input.",$realtime);
  $display("=================================================================");
  TSL = 1'b0;  //wr_protect,Top 256 pages become read only
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(2,8'haa,24'h030000); //program "aa" to page 768, top 256 pages
  #(`tPP_MAX+100);
  READ_DATA_BYTES(2,24'h030000);

  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(256,8'haa,24'h02ff00); //program "aa" to page 767, not protected
  #(`tPP_MAX+100);
  //RESET = 1'b0;
  //#(`tRLRH);
  //RESET = 1'b1;
  //#(`tRHSL1);
  READ_DATA_BYTES_FAST(2,24'h02ff00);
  TSL = 1'b1;

  //---------------------------------------------
  TSL = 1'b0;  //wr_protect
  //WRITE_ENABLE;
  //PAGE_WRITE_SAME_DATA(2,8'haa,24'h00ff00); //write "aa" to page255
  //#(`tPW_MAX+100);
  //READ_DATA_BYTES(2,24'h00ff00);
  WRITE_ENABLE;
  PAGE_WRITE_SAME_DATA(2,8'haa,24'h03ff00);   //write "aa" to page 1023
  #(`tPW_MAX+100);
  READ_DATA_BYTES_FAST(2,24'h03ff00);
  TSL = 1'b1;
  //---------------------------------------------
  TSL = 1'b1;  //not wr_protect
  #(`tTHSL);
  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(2,8'h55,24'h03ff00); //program "55" to page 1023
  #(`tPP_MAX+100);
  READ_DATA_BYTES(2,24'h03ff00);

  WRITE_ENABLE;
  PAGE_WRITE_SAME_DATA(2,8'h55,24'h030000);   //write "55" to page 768
  #(`tPW_MAX+100);
  READ_DATA_BYTES_FAST(2,24'h030000);
  //---------------------------------------------
  TSL = 1'b0;  //wr protect
  WRITE_ENABLE;
  PAGE_ERASE(24'h000000);                     //erase page 0
  #(`tPE_MAX);
  READ_DATA_BYTES(2,24'h000000);

  WRITE_ENABLE;
  PAGE_ERASE(24'h03ff00);                     //erase page 1023
  #(`tPE_MAX);
  READ_DATA_BYTES(2,24'h03ff00);

  WRITE_ENABLE;
  SECTOR_ERASE(24'h000000);                   //erase sector 0
  #(`tSE_MAX);
  READ_DATA_BYTES(2,24'h000000);

  WRITE_ENABLE;
  SECTOR_ERASE(24'h010000);                   //erase sector 1
  #(`tSE_MAX);
  READ_DATA_BYTES(2,24'h010000);

  WRITE_ENABLE;
  SECTOR_ERASE(24'h020000);                   //erase sector 2
  #(`tSE_MAX);
  READ_DATA_BYTES(2,24'h020000);

  WRITE_ENABLE;
  SECTOR_ERASE(24'h030000);                   //erase sector 3
  #(`tSE_MAX);
  READ_DATA_BYTES(2,24'h030000);

  TSL = 1'b1;

//=============================================================================
//check the address increases or rolls over during read and write operation
//=============================================================================
  $display("==========================================================================================");
  $display("%t: TESTING3: Memory Write,Program,Erase,Read operation and address roll over.",$realtime);
  $display("==========================================================================================");
  TSL = 1'b1;
  #(`tTHSL);
  WRITE_ENABLE;
  PAGE_ERASE(24'h000000);         //erase page 0
  #(`tPE_MAX);

  WRITE_ENABLE;
  SECTOR_ERASE(24'h000000);       //erase sector 0
  #(`tSE_MAX);

  WRITE_ENABLE;
  SECTOR_ERASE(24'h010000);       //erase sector 1
  #(`tSE_MAX);

  WRITE_ENABLE;
  SECTOR_ERASE(24'h020000);       //erase sector 2
  #(`tSE_MAX);

  WRITE_ENABLE;
  SECTOR_ERASE(24'h030000);       //erase sector 3
  #(`tSE_MAX);

  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(2,8'h66,24'h0000ff);
  #(`tPP_MAX+100);                //page program from byte 255 in page 0, address roll over in write operation.

  READ_DATA_BYTES(2,24'h000000);  //read data addressed "00h" and "01h"
  READ_DATA_BYTES(2,24'h0000ff);  //read data addressed "ffh" and "100h"

  WRITE_ENABLE;
  PAGE_WRITE_SAME_DATA(2,8'h88,24'h03ffff);
  #(`tPW_MAX+100);                //page write from byte 255 in page 1023(last page), address roll over in write operation.

  READ_DATA_BYTES(2,24'h03ff00);  //read data addressed "3ff00h" and "3ff01h"
  READ_DATA_BYTES(2,24'h03ffff);  //read data addressed "3ffffh" and "00000h", address roll over in read

//=================================================================
//check the behavior of memory regarding deep power down mode
//=================================================================
  $display("===============================================================================");
  $display("%t: TESTING4: Memory Deep Power Down and Release Deep Power Down instruction.",$realtime);
  $display("===============================================================================");
  DEEP_POWER_DOWN;
  #(`tDP);
  RELEASE_FROM_DEEP_POWER_DOWN;
  //#100;
  //S = 1'b0;
  //#(`tRDP-100);
  //RELEASE_FROM_DEEP_POWER_DOWN;
  #(`tRDP);
  //--------------------
  DEEP_POWER_DOWN;
  //#100;
  //S = 1'b0;
  //#(`tDP-100);
  //DEEP_POWER_DOWN; //all instructions are execute during Deep Power Down mode
  #(`tDP);
  WRITE_ENABLE;
  WRITE_DISABLE;
  READ_IDENTIFICATION;
  READ_STATUS_REGISTER;
  READ_DATA_BYTES(2,24'h000000);
  READ_DATA_BYTES_FAST(2,24'h000000);
  PAGE_PROGRAM_SAME_DATA(2,8'haa,24'h000000);
  #(`tPP_MAX+100);
  PAGE_WRITE_SAME_DATA(2,8'h00,24'h01ff00);
  #(`tPW_MAX+100);
  PAGE_ERASE(24'h010000);
  #(`tPE_MAX);
  SECTOR_ERASE(24'h000000);
  #(`tSE_MAX);
  DEEP_POWER_DOWN;
  #(`tDP);
  RELEASE_FROM_DEEP_POWER_DOWN;
  #(`tRDP);
  DEEP_POWER_DOWN;
  #(`tDP);
  VCC = 1'b0;        //Deep Power Down is stoped by Power off
  #100;
  /////////////////////////////////////////////////////////////
  VCC = 1'b1;        //power on
  #1;
  #(`tVSL);
  #(`tPUW_MAX);
  S = 1'b0;
  //#10;
  //S = 1'b1;
  //RESET = 1'b1;
  //#10;
  //RESET = 1'b0;    //hardware reset
  //#(`tRLRH);
  //RESET = 1'b1;
  //-----------------------------
  READ_STATUS_REGISTER;

  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(2,8'h68,24'h03ff00);
  #(`tPP_MAX+100);
  READ_DATA_BYTES(2,24'h03ff00);

  $display("===============================================================================");
  $display("%t: TESTING5: Check the timing that violated the specification.",$realtime);
  $display("===============================================================================");
  VIOLATE_TIMING;

  $finish;
end

//#####################################
// Check the violated timings
//#####################################
task VIOLATE_TIMING;
begin
  C = 1'b0; S = 1'b1; #2;
  C = 1'b1; S = 1'b1; #(`tCHSL - 5);
  C = 1'b1; S = 1'b0; #2; //violated tCH,tCL,tCHSL,tSLCH and fc
  C = 1'b0; S = 1'b0; #(`tSLCH - 5);
  C = 1'b1; S = 1'b0; #2;

  C = 1'b0;
  #`tCL;  //violated data in setup and hold time
  D = ~D; #(`tDVCH - 1); C = 1'b1; #(`tCHDX - 1);
  D = 1'hz; #`tCH;

  C = 1'b0; #`tCL;
  C = 1'b1; S = 1'b0; #(`tCHSH - 5);
  C = 1'b1; S = 1'b1; #2; //violated tCH,tCL,tCHSH,tSHCH,tSHSL,fc
  C = 1'b0; S = 1'b1; #(`tSHCH - 5);
  C = 1'b1; S = 1'b1; #2;
  #(`tSHSL-50);
  C = 1'b1; S = 1'b0; #10; C = 1'b0;

  S = 1'b1; TSL = 1'b0; #`tSHSL;
  S = 1'b1; TSL = 1'b1; #(`tTHSL - 1);
  S = 1'b0; TSL = 1'b1; #30; //violated tTHSL,tSHTL
  S = 1'b1; TSL = 1'b1; #(`tSHTL - 1);
  S = 1'b1; TSL = 1'b0; #30;
  S = 1'b1; TSL = 1'b1; #30;

  S = 1'b1; RESET = 1'b1; #`tSHSL;
  S = 1'b0; RESET = 1'b1; #10;
  S = 1'b0; RESET = 1'b0;
  #(`tRLRH - 20);
  S = 1'b1; RESET = 1'b0;
  #(`tSHRH - 1);            //violated tRLRH,tSHRH
  S = 1'b1; RESET = 1'b1;
  #(`tRHSL1 - 1);
  S = 1'b0; RESET = 1'b1;
  #1000;
  S = 1'b1; #`tSHSL;

  WRITE_ENABLE;
  SECTOR_ERASE(24'h000000);
  #10;
  RESET = 1'b0;
  #(`tRLRH);
  RESET = 1'b1;
  #(`tRHSL3 - 1);
  S = 1'b0;
  //#(`tSE_MAX);
  #1000;
  S = 1'b1;
  #200;

  WRITE_ENABLE;
  PAGE_PROGRAM_SAME_DATA(4,8'haa,24'h01fffc);
  #10;
  RESET = 1'b0;
  #(`tRLRH);
  RESET = 1'b1;
  #(`tRHSL2 - 1);
  S = 1'b0;
  #(`tPP_MAX);
  S = 1'b1;
  #200;
end
endtask

//###############################################
// Stimuli task definition
//###############################################
task WRITE_ENABLE;
begin
  S = 1'b1; #(`tCHSL);  //chip select not active hold time
  S = 1'b0; #(`tSLCH - `tDVCH);
  for(i=0;i<=7;i=i+1)
  begin
    if((i==5)||(i==6)) D = 1'b1; else D = 1'b0;
    //data setup time, and chip select active setup time with #(`tSLCH-`tDVCH)
    #(`tDVCH); C = 1'b1;
    //clock high time
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  #(`tDVCH); #(`tCHSH); //chip select active hold time
   S = 1'b1; #(`tSHSL); //chip select deselect time
end
endtask
//===============================================
task WRITE_DISABLE;
begin
   S = 1'b1; #(`tCHSL); //chip select not active hold time
   S = 1'b0; #(`tSLCH - `tDVCH);
  for(i=0;i<=7;i=i+1)
  begin
    if(i==5) D = 1'b1; else D = 1'b0;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  #(`tDVCH); #(`tCHSH); //chip select active hold time
   S = 1'b1; #(`tSHSL); //chip select deselect time
end
endtask
//===============================================
task READ_IDENTIFICATION;
begin
   S = 1'b1; #(`tCHSL); //chip select not active hold time
   S = 1'b0; #(`tSLCH - `tDVCH);
  for(i=0;i<=7;i=i+1)
  begin
    if((i==1)||(i==2)) D = 1'b0; else D = 1'b1;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  #(`tDVCH);
  //read 24-bit id
  for(i=0;i<=7;i=i+1)
  begin
    C = 1'b1; id1 = {id1[7:0],Q}; #(`tCH + 2);
    C = 1'b0; #(`tCL + 2);
  end
  for(i=0;i<=7;i=i+1)
  begin
     C = 1'b1; id2 = {id2[7:0],Q}; #(`tCH+2);
     C = 1'b0; #(`tCL+2);
  end
  for(i=0;i<=7;i=i+1)
  begin
    C = 1'b1; id3 = {id3[7:0],Q}; #(`tCH+2);
    C = 1'b0; #(`tCL+2);
  end
  $display("%t: Manufacturer = [%h]",$realtime,id1);
  $display("%t: Memory_type = [%h]",$realtime,id2);
  $display("%t: Memory_capacity = [%h]\n",$realtime,id3);
  #(`tCHSH);  //chip select active hold time
  S = 1'b1;
  #(`tSHSL);  //chip select deselect time
end
endtask
//===============================================
task READ_STATUS_REGISTER;
reg dis;
begin
  S = 1'b1; #(`tCHSL); //chip select not active hold time
  S = 1'b0; #(`tSLCH - `tDVCH);
  for(i=0;i<=7;i=i+1)
  begin
    if((i==5)||(i==7)) D = 1'b1; else D = 1'b0;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  #(`tDVCH);
  //read status register
  for(i=0;i<=7;i=i+1)
  begin
    C = 1'b1; sr = {sr[6:0],Q}; #(`tCH+2);
    C = 1'b0; #(`tCL+2);
  end
   if(sr[0] == 1'b0) dis = 1'b1;
   if(sr[0] == 1'b1) dis = 1'b0;
   if(dis == 1'b1) $display("%t: STATUS_REGISTER = [%b]",$realtime,sr);
  #(`tCHSH);  //chip select active hold time
  S = 1'b1;
  #(`tSHSL);  //chip select deselect time
end
endtask
//===============================================
// task READ_LOCK_REGISTER;
// input[23:0] address;
// begin
//   S = 1'b1; #(`tCHSL); //chip select not active hold time
//   S = 1'b0; #(`tSLCH - `tDVCH);
//   for(i=0;i<=7;i=i+1)
//   begin
//     if((i==0)||(i==1)||(i==2)||(i==4)) D = 1'b1; else D = 1'b0;
//     #(`tDVCH); C = 1'b1;
//     #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
//   end
//   //address input
//   for(i=0;i<=23;i=i+1)
//   begin
//     D = address[23-i];
//     #(`tDVCH); C = 1'b1;
//     #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
//   end
//   #(`tDVCH);
//   //read lock register
//   for(i=0;i<=7;i=i+1)
//   begin
//     C = 1'b1; lk_reg = {lk_reg[6:0],Q}; #(`tCH+2);
//     C = 1'b0; #(`tCL+2);
//   end
//   $display("%t: LOCK REGISTER = [%b]\n",$realtime,lk_reg);
//   #(`tCHSH);  //chip select active hold time
//   S = 1'b1;
//   #(`tSHSL);  //chip select deselect time
// end
// endtask
//===============================================
task READ_DATA_BYTES;
input n;
input[23:0] address;
integer n;
begin
  S = 1'b1; #(`tCHSL); ///S not active hold time
  S = 1'b0; #(`tSLCH-`tDVCH); ///S active setup time
  for(i=0;i<=7;i=i+1)
  begin
    if((i==6)||(i==7)) D = 1'b1; else D = 1'b0;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  //address input
  for(i=0;i<=23;i=i+1)
  begin
    D = address[23-i];
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  #(`tDVCH);
  //read data bytes
  for(i=1;i<=n;i=i+1)
  begin
    address = U_M25PE20.memory_address[`MEM_ADDR_BITS-1:0];
    for(j=0;j<=7;j=j+1)
    begin
      C = 1'b1; read_dat = {read_dat[6:0],Q}; #(`tRH);
      C = 1'b0; #(`tRL);
    end
    $display("%t: READ RESULT: ADDRESS = [%h], DATA = [%h]",$realtime,address,read_dat);
  end
  #(`tCHSH);  ///S active hold time
  S = 1'b1;
  #(`tSHSL);  ///S Deselect time
end
endtask
//===============================================
task READ_DATA_BYTES_FAST;
input n;
input[23:0] address;
integer n;
begin
  S = 1'b1; #(`tCHSL);  ///S not active hold time
  S = 1'b0; #(`tSLCH-`tDVCH); ///S active setup time
  for(i=0;i<=7;i=i+1)
  begin
    if((i==4)||(i==6)||(i==7)) D = 1'b1;
    else D = 1'b0;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  //address input
  for(i=0;i<=23;i=i+1)
  begin
    D = address[23-i];
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  //dummy byte input
  for(i=0;i<=7;i=i+1)
  begin
    D = address[7-i];
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  #(`tDVCH);
  //read data bytes
  for(i=1;i<=n;i=i+1)
  begin
    address = U_M25PE20.memory_address[`MEM_ADDR_BITS-1:0];
    for(j=0;j<=7;j=j+1)
    begin
      C = 1'b1; read_dat = {read_dat[6:0],Q}; #(`tCH+2);
      C = 1'b0; #(`tCL+2);
    end
    $display("%t: FAST READ RESULT: ADDRESS = [%h], DATA = [%h]",$realtime,address,read_dat);
  end
  #(`tCHSH);  ///S active hold time
  S = 1'b1;
  #(`tSHSL);  ///S Deselect time
end
endtask
//===============================================
// task WRITE_TO_LOCK_REGISTER;
// input[23:0] address;
// input[7:0] data;
// begin
//   S = 1'b1; #(`tCHSL); ///S not active hold time
//   S = 1'b0; #(`tSLCH-`tDVCH); ///S active setup time
//   for(i=0;i<=7;i=i+1)
//   begin
//     if((i==3)||(i==4)||(i==6)) D = 1'b0; else D = 1'b1;
//     #(`tDVCH); C = 1'b1;
//     #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
//   end
//   //address input
//   for(i=0;i<=23;i=i+1)
//   begin
//     D = address[23-i];
//     #(`tDVCH); C = 1'b1;
//     #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
//   end
//   //data bytes input
//   for(j=0;j<=7;j=j+1)
//   begin
//     D = data[7-j];
//     #(`tDVCH); C = 1'b1;
//     #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
//   end
//   //------------------
//   #(`tDVCH); #(`tCHSH); ///S active hold time
//    S = 1'b1; #(`tSHSL); ///S Deselect time
// end
// endtask
//===============================================
task PAGE_WRITE_DIFF_DATA;
input n;
input[23:0] address;    //the accessed location's address
reg[7:0] data;
integer n;
begin
  S = 1'b1; #(`tCHSL);  ///S not active hold time
  S = 1'b0; #(`tSLCH-`tDVCH); ///S active setup time
  for(i=0;i<=7;i=i+1)
  begin
    if((i==4)||(i==6)) D = 1'b1; else D = 1'b0;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  //address input
  for(i=0;i<=23;i=i+1)
  begin
    D = address[23-i];
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  //data bytes input
  for(i=0;i<=n-1;i=i+1)
  begin
    data = page_wr_buf[i];
    for(j=0;j<=7;j=j+1)
    begin
      D = data[7-j];
      #(`tDVCH); C = 1'b1;
      #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
    end
  end
  //------------------
  #(`tDVCH); #(`tCHSH); ///S active hold time
   S = 1'b1; #(`tSHSL); ///S Deselect time
end
endtask

//===============================================
task PAGE_WRITE_SAME_DATA;
input n;                //the number of data byte that be written in
input[7:0] data;        //the data written in memory
input[23:0] address;    //the accessed location's address
integer n;
begin
  S = 1'b1; #(`tCHSL);  ///S not active hold time
  S = 1'b0; #(`tSLCH-`tDVCH); ///S active setup time
  for(i=0;i<=7;i=i+1)
  begin
    if((i==4)||(i==6)) D = 1'b1; else D = 1'b0;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  //address input
  for(i=0;i<=23;i=i+1)
  begin
    D = address[23-i];
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  //data bytes input
  for(i=0;i<=n-1;i=i+1)
  begin
    for(j=0;j<=7;j=j+1)
    begin
      D = data[7-j];
      #(`tDVCH); C = 1'b1;
      #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
    end
  end
  //------------------
  #(`tDVCH); #(`tCHSH);  ///S active hold time
   S = 1'b1; #(`tSHSL);  ///S Deselect time
end
endtask
//===============================================
task PAGE_PROGRAM_DIFF_DATA;
input n;
input[23:0] address;     //the accessed location's address
reg[7:0] data;
integer n;
begin
  S = 1'b1; #(`tCHSL);   ///S not active hold time
  S = 1'b0; #(`tSLCH-`tDVCH); ///S active setup time
  for(i=0;i<=7;i=i+1)
  begin
    if(i==6) D = 1'b1; else D = 1'b0;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  //address input
  for(i=0;i<=23;i=i+1)
  begin
    D = address[23-i];
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  //data byte input
  for(i=0;i<=n-1;i=i+1)
  begin
    data = page_pg_buf[i];
    for(j=0;j<=7;j=j+1)
    begin
      D = data[7-j];
      #(`tDVCH); C = 1'b1;
      #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
    end
  end
  //------------------
  #(`tDVCH); #(`tCHSH);  ///S active hold time
   S = 1'b1; #(`tSHSL);  ///S Deselect time
end
endtask
//===============================================
task PAGE_PROGRAM_SAME_DATA;
input n;                 //the number of data byte that be written in
input[7:0] data;         //the data written in memory
input[23:0] address;     //the accessed location's address
integer n;
begin
  S = 1'b1; #(`tCHSL);   ///S not active hold time
  S = 1'b0; #(`tSLCH-`tDVCH); ///S active setup time
  for(i=0;i<=7;i=i+1)
  begin
    if(i==6) D = 1'b1; else D = 1'b0;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  //address input
  for(i=0;i<=23;i=i+1)
  begin
    D = address[23-i];
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  //data byte input
  for(i=0;i<=n-1;i=i+1)
  begin
    for(j=0;j<=7;j=j+1)
    begin
      D = data[7-j];
      #(`tDVCH); C = 1'b1;
      #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
    end
  end
  //------------------
  #(`tDVCH); #(`tCHSH);  ///S active hold time
   S = 1'b1; #(`tSHSL);  ///S Deselect time
end
endtask
//===============================================
task PAGE_ERASE;
input[23:0] address;
begin
  S = 1'b1; #(`tCHSL);   ///S not active hold time
  S = 1'b0; #(`tSLCH-`tDVCH); ///S active setup time
  for(i=0;i<=7;i=i+1)
  begin
    if((i==2)||(i==5)) D = 1'b0; else D = 1'b1;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  for(i=0;i<=23;i=i+1)
  begin
    D = address[23-i];
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  #(`tDVCH); #(`tCHSH);  ///S active hold time
   S = 1'b1; #(`tSHSL);  ///S Deselect time
end
endtask
//===============================================
task SECTOR_ERASE;
input[23:0] address;
begin
  S = 1'b1; #(`tCHSL);   ///S not active hold time
  S = 1'b0; #(`tSLCH-`tDVCH); ///S active setup time
  for(i=0;i<=7;i=i+1)
  begin
    if((i==2)||(i==5)||(i==6)||(i==7)) D = 1'b0; else D = 1'b1;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  for(i=0;i<=23;i=i+1)
  begin
    D = address[23-i];
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  #(`tDVCH); #(`tCHSH);  ///S active hold time
   S = 1'b1; #(`tSHSL);  ///S Deselect time
end
endtask
//===============================================
// task BULK_ERASE;
// begin
//   S = 1'b1; #(`tCHSL);
//   S = 1'b0; #(`tSLCH-`tDVCH);
//   for(i=0;i<=7;i=i+1)
//   begin
//     if((i==2)||(i==3)||(i==4)) D = 1'b0; else D = 1'b1;
//     //data setup time, and /S active setup time with #(`tSLCH-`tDVCH)
//     #(`tDVCH); C = 1'b1;
//     #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
//   end
//   #(`tDVCH); #(`tCHSH);  ///S active hold time
//    S = 1'b1; #(`tSHSL);  ///S Deselect time
// end
// endtask
//===============================================
task DEEP_POWER_DOWN;
begin
  S = 1'b1; #(`tCHSL);   ///S not active hold time
  S = 1'b0; #(`tSLCH-`tDVCH); ///S active setup time
  for(i=0;i<=7;i=i+1)
  begin
    if((i==1)||(i==5)||(i==6)) D = 1'b0; else D = 1'b1;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  #(`tDVCH); #(`tCHSH);  ///S active hold time
   S = 1'b1; #(`tSHSL);  ///S Deselect time
end
endtask
//===============================================
task RELEASE_FROM_DEEP_POWER_DOWN;
begin
  S = 1'b1; #(`tCHSL);   ///S not active hold time
  S = 1'b0; #(`tSLCH-`tDVCH); ///S active setup time
  for(i=0;i<=7;i=i+1)
  begin
    if((i==1)||(i==3)||(i==5)) D = 1'b0; else D = 1'b1;
    #(`tDVCH); C = 1'b1;
    #(`tCH+2); C = 1'b0; #(`tCL+2-`tDVCH);
  end
  #(`tDVCH); #(`tCHSH);  ///S active hold time
   S = 1'b1; #(`tSHSL);  ///S Deselect time
end
endtask
//===============================================
endmodule
