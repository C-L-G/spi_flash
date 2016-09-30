/*========================================================================

 M25PE20: 2M BITS, 25MHz SPI BUS FLASH MEMORY VERILOG SIMULATION MODEL

==========================================================================

 These verilog models are provided "as is" without warranty
 of any kind, included but not limited to, implied warranty
 of merchantability and fitness for a particular purpose.

 Copyright 2005, STMicroelectronics Corporation, All Right Reserved.

========================================================================*/

`timescale 1ns/1ns
`include "E:/work/other_module/spi_flash/ST_M25PE20_VG_1.0/code/M25PE20_macro.v"

//=========================================================
//M25PE20 MEMORY SIMULATION MODEL
//=========================================================
module M25PE20_MEMORY(C,D,Q,S,TSL,RESET,VCC,VSS);

//=========================================================
//I/O Signal Definition
//=========================================================
input C,D,S,TSL,RESET,VCC,VSS;
output Q;

//=========================================================
//Define Parameters Regarding Memory
//=========================================================
parameter manufacturer_id    =  8'b00100000;  //20h
parameter memory_type        =  8'b10000000;  //80h
parameter memory_capacity    =  8'b00010010;  //12h
parameter address_highest    = `MEM_ADDR_BITS'h3ffff;
parameter address_zero       = `MEM_ADDR_BITS'h00000;
parameter address_increase   = `MEM_ADDR_BITS'h00001;
parameter page_addr_highest  = `PAGE_OFFSET_BITS'hff;
parameter page_addr_zero     = `PAGE_OFFSET_BITS'h00;
parameter page_addr_increase = `PAGE_OFFSET_BITS'h01;

//=========================================================
//Define Parameters Regarding Instructions
//=========================================================
parameter WREN_INS  = 4'b0001;
parameter WRDI_INS  = 4'b0010;
parameter RDID_INS  = 4'b0011;
parameter RDSR_INS  = 4'b0100;
parameter READ_INS  = 4'b0101;
parameter HSRD_INS  = 4'b0110;
parameter PGWR_INS  = 4'b0111;
parameter PGPG_INS  = 4'b1000;
parameter PGES_INS  = 4'b1001;
parameter SCES_INS  = 4'b1010;
parameter DPPD_INS  = 4'b1011;
parameter RLDP_INS  = 4'b1100;

//=========================================================
//Define Parameter Regarding Operations
//=========================================================
parameter WREN_OP   = 4'b0001;
parameter WRDI_OP   = 4'b0010;
parameter RDID_OP   = 4'b0011;
parameter RDSR_OP   = 4'b0100;
parameter READ_OP   = 4'b0101;
parameter HSRD_OP   = 4'b0110;
parameter PGWR_OP   = 4'b0111;
parameter PGPG_OP   = 4'b1000;
parameter PGES_OP   = 4'b1001;
parameter SCES_OP   = 4'b1010;
parameter DPPD_OP   = 4'b1011;
parameter RLDP_OP   = 4'b1100;

//=========================================================
//Define Parameters Regarding Device Mode
//=========================================================
parameter np_mode = 2'b00, sb_mode = 2'b01;
parameter ap_mode = 2'b10, dp_mode = 2'b11;

//=========================================================
//Define Variable Regarding Timing Check
//=========================================================
reg din_change,r_S,f_S,r_C,r_Cr,f_C,f_W,r_W,r_RESET,f_RESET,r_VCC;
//---------------------------------------------------------
time t_rCr,t_rCr1,Tcr,Tc,t_d,t_rC1,current_time;
time t_rS,t_fS,t_rC,t_fC,t_fW,t_rW,t_rVCC,t_rRESET,t_fRESET;
time tVSL,tCH,tCL,tSLCH,tCHSL,tDVCH,tCHDX;
time tCHSH,tSHCH,tSHSL,tRHSL,tRLRH,tSHRH,tTHSL,tSHTL;

//=========================================================
//Define Variable, Reflecting the Device Operation Status
//=========================================================
integer i,sr_bit,bytes;
//---------------------------------------------------------
reg power_on,power_off,power_on_rst,byte_ok,bit_counter_en,bit_counter_ld,bit7;
reg page_write,page_program;
reg page_erase,sector_erase,read_data_bytes,read_data_bytes_fast;
reg instruction_byte,address_h_byte,address_m_byte,address_l_byte,data_byte,dummy_byte;
reg wren_id,wrdi_id,pges_id,sces_id,dppd_id,rldp_id,wrda_id;
reg wr_protect,bk_protect,sc_protect,dout,hw_rst,ins_rej,rst_in_cycle;
reg device_power_down,deep_pd_delay,release_pd_delay,not_deep_pd,not_release_pd;
//---------------------------------------------------------
reg[5:0] lk_reg_no;
reg[3:0] instruction,operation,sector,sub_sector;
reg[7:0] shift_in_reg,instruction_code,address_h_code,address_m_code,address_l_code;
reg[7:0] status_reg,bit_counter,data_out_buf;
reg[1:0] mode,previous_op;
//---------------------------------------------------------
reg[23:0] device_id,memory_address;
reg[`DATA_BITS-1:0] memory[`MEM_SIZE-1:0],data_latch[`PAGE_SIZE-1:0];
reg[`PAGE_ADDR_BITS-1:0] page_address;
reg[`SECTOR_ADDR_BITS-1:0] sector_address;

//=========================================================
//Variables Initialization
//=========================================================
initial begin
  $display("%t: NOTE: Preliminary model: Please check ST web site or your ST contact for final version.\n",$realtime);
  mode = np_mode;
  power_on = 1'b0;
  power_off = 1'b1;
  power_on_rst = 1'b0;
  not_deep_pd = 1'b0;
  not_release_pd = 1'b0;
end
//---------------------------------------------------------
assign Q = dout;

//#########################################################
//Power on Reset
//#########################################################
always@(power_on_rst)
begin
  if(power_on_rst == 1'b1)
  begin
    mode = sb_mode; power_on_rst = 1'b0; hw_rst = 1'b0;
    byte_ok = 1'b0; rst_in_cycle = 1'b0; ins_rej = 1'b0;
    //-----------------------------------------------------
    status_reg = 8'b00; previous_op = 2'b00;
    operation = 4'b0000; instruction = 4'b0000;
    //-----------------------------------------------------
    wr_protect = 1'b0; bit_counter_en = 1'b0;
    bk_protect = 1'b0; page_erase = 1'b0; sector_erase = 1'b0;
    sc_protect = 1'b0; page_write = 1'b0; page_program = 1'b0;
    //-----------------------------------------------------
    read_data_bytes = 1'b0; read_data_bytes_fast = 1'b0;
    release_pd_delay = 1'b0; deep_pd_delay = 1'b0;
    //-----------------------------------------------------
    wren_id = 1'b0; wrdi_id = 1'b0; pges_id = 1'b0; wrda_id = 1'b0;
    sces_id = 1'b0; dppd_id = 1'b0; rldp_id = 1'b0;
    //-----------------------------------------------------
    address_h_byte = 1'b0; dummy_byte = 1'b0;
    address_m_byte = 1'b0; data_byte = 1'b0;
    address_l_byte = 1'b0; instruction_byte = 1'b0;
    //-----------------------------------------------------
    $display("%t, Notes: Device Power-On-Reset is OK!\n",$realtime);
  end
end

//#########################################################
//Top Sector Lock
//#########################################################
always@(TSL)
begin
  if((TSL == 1'b0) && (S == 1'b0)) wr_protect = 1'b1;
end

//#########################################################
//Device Power On/Off
//#########################################################
always@(VCC)
begin
  if((VCC == 1'b1) && (power_off == 1'b1))
  begin
    t_rVCC = $time; r_VCC = 1'b1;
    $display("%t, Notes: Device is Powered on!\n",$realtime);
    power_on = 1'b1; power_off = 1'b0;
    power_on_rst = 1'b1; mode = sb_mode;
  end
  if((VCC == 1'b0) && (power_on == 1'b1))
  begin
    $display("%t, Notes: Device is Powered off!\n",$realtime);
    power_on = 1'b0; power_off = 1'b1;
    if(mode == dp_mode)
      $display("%t, Notes: The Deep Power Down mode automatically stops at Power Off.\n",$realtime);
    mode = np_mode; device_power_down = 1'b0;
  end
end

//#########################################################
//Device Hardware Reset
//#########################################################
always@(RESET)
begin
  if(power_on == 1'b1)
  begin
  //=============================================
    if(RESET == 1'b0)
    begin
      f_RESET = 1'b1; t_fRESET = $time;
      dout = 1'bx; #(`tSHQZ);
      dout = 1'bz; //status_reg = 8'h00;
      //-----------------------------------------
      //reset is driven low while an internal operation is in progress,
      //all internal operations related to Write, Program or Erase will be stopped.
      //-----------------------------------------
      if(S == 1'b1)
      begin
        if(status_reg[0] == 1'b1)
        begin
          case(operation)
          PGPG_OP: begin previous_op = 2'b10; $display("%t, Warning: Driving reset low during internal operation cycle, page program operation is interrupted and data may be lost.",$realtime); end
          PGWR_OP: begin previous_op = 2'b10; $display("%t, Warning: Driving reset low during internal operation cycle, page write operation is interrupted and data may be lost.",$realtime); end
          PGES_OP: begin previous_op = 2'b10; $display("%t, Warning: Driving reset low during internal operation cycle, page erase operation is interrupted and data may be lost.",$realtime); end
          SCES_OP: begin previous_op = 2'b11; $display("%t, Warning: Driving reset low during internal operation cycle, sector erase operation is interrupted and data may be lost.",$realtime); end
          endcase
          rst_in_cycle = 1'b1;
        end
      end
      //-----------------------------------------
      //reset is driven low before cs is driven high ( or sametime )
      //hardware reset, all operations related to Read will be terminated.
      //-----------------------------------------
      else begin
        hw_rst = 1'b1; //hardware reset flag is set
        if(operation == RDID_OP) begin operation = 4'b0000; instruction = 4'b0000;
          $display("%t, Warning: This READ IDENTIFICATION instruction is terminated because RESET pin is driven low.",$realtime);
        end
        if(operation == RDSR_OP) begin operation = 4'b0000; instruction = 4'b0000;
          $display("%t, Warning: This READ STATUS REGISTER instruction is terminated because RESET pin is driven low.",$realtime);
        end
        if(operation == READ_OP) begin operation = 4'b0000; instruction = 4'b0000;
          $display("%t, Warning: This READ DATA BYTES instruction is terminated because RESET pin is driven low.",$realtime);
        end
        if(operation == HSRD_OP) begin operation = 4'b0000; instruction = 4'b0000;
          $display("%t, Warning: This FAST READ DATA BYTES instruction is terminated because RESET pin is driven low.",$realtime);
        end
      end
      //power_on_rst = 1'b1;
    end
  //=============================================
    else if(RESET == 1'b1)
    begin
      r_RESET = 1'b1; t_rRESET = $time;
      if(status_reg[0] == 1'b0) rst_in_cycle = 1'b0;
      if((f_RESET == 1'b1) && ((t_rRESET - t_fRESET) < `tRLRH))
      begin
        $display("%t, Error: Reset Pluse Width(tRLRH) violated.\n",$realtime);
        if(`STOP == 1) $stop;
      end
      if((r_S == 1'b1) && ((t_rRESET - t_rS) < `tSHRH))
      begin
        $display("%t, Error: Chip Select High to RESET High Time(tSHRH) violated.\n",$realtime);
        if(`STOP == 1) $stop;
      end
      if((f_RESET == 1'b1) && (S == 1'b0))
      begin
        $display("%t, Warning: Invalid stimuli, RESET is driven high when chip select is low.\n",$realtime);
      end
    end
  end
  else $display("%t, Error: Device has not been powered on before level change on RESET pin.\n",$realtime);
end

//###################################################################
//chip select driven low(enable), device enters "active power mode".
//###################################################################
always@(negedge S)
begin
  if(power_on == 1'b1)
  begin
    f_S = 1'b1; t_fS = $time;
    //-----------------------------------------------------
    //TSL=0 when cs enable, device in hardware protect mode
    //-----------------------------------------------------
    if(TSL == 1'b0) wr_protect = 1'b1;
    //-----------------------------------------------------
    if(r_VCC == 1'b1)
    begin
      r_VCC = 1'b0; tVSL = t_fS - t_rVCC;
      if(tVSL < `tVSL) begin
        $display("%t, Error: The time of VCC to /S low(tVSL) violated.\n",$realtime);
        if(`STOP == 1) $stop;
      end
    end
    //-----------------------------------------------------
    if(r_RESET == 1'b1)
    begin
      r_RESET = 1'b0; tRHSL = t_fS - t_rRESET;
      if((previous_op == 2'b00) && (tRHSL < `tRHSL1))
      begin
        $display("%t, Error: Reset Recovery Time(tRHSL) violated after any operation except for PW,PP,PE,SE.\n",$realtime);
        if(`STOP == 1) $stop;
      end
      if((previous_op == 2'b11) && (tRHSL < `tRHSL3))
      begin
        $display("%t, Error: Reset Recovery Time(tRHSL) violated after SE.\n",$realtime);
        if(`STOP == 1) $stop;
      end
      if((previous_op == 2'b10) && (tRHSL < `tRHSL2))
      begin
        $display("%t, Error: Reset Recovery Time(tRHSL) violated after PW,PP,PE.\n",$realtime);
        if(`STOP == 1) $stop;
      end
      previous_op = 2'b00;
    end
    //=====================================================
    //chip select is driven low and reset is driven high
    //memory is in normal operation.
    if(RESET == 1'b1)
    begin
      //chip select is driven low during the delay of tDP or tRDP,
      //device won't enter or release from "deep power down mode".
      if(deep_pd_delay == 1'b1) not_deep_pd = 1'b1;
      if(release_pd_delay == 1'b1) not_release_pd = 1'b1;
      //the timing of Vcc to chip select is satisfied,
      //device begins to receive a "instruction code".
      if(tVSL >= `tVSL)
      begin
        instruction_byte = 1'b1;  //ready for instruction
      //---------------------------------------------------
        mode = ap_mode;
        bit_counter_en = 1'b1;
        bit_counter_ld = 1'b1;    //enable the bit_counter
      end
    end
    //=====================================================
    //chip select is driven low and reset is driven low
    //memory is in reset mode and instruction will be rejected.
    if(RESET == 1'b0)
    begin
      //chip select is driven low during the delay of tDP or tRDP,
      //device won't enter or release from "deep power down mode".
      if(deep_pd_delay == 1'b1) not_deep_pd = 1'b1;
      if(release_pd_delay == 1'b1) not_release_pd = 1'b1;
      //memory is in reset mode, device rejects "instruction code"
      //even if the timing of Vcc to chip select is satisfied.
      if(tVSL >= `tVSL)
      begin
        ins_rej = 1'b1;           //instruction rejected
        instruction_byte = 1'b1;  //ready for instruction
      //---------------------------------------------------
        mode = ap_mode;
        bit_counter_en = 1'b1;
        bit_counter_ld = 1'b1;    //enable the bitcounter
      end
    end
  end
  else $display("%t, Error: Device has not been powered on before chip select enable!\n",$realtime);
end

//#########################################################
//Serial Data (on the "D" line) Input
//#########################################################
always@(posedge C)
begin
  if(power_on == 1'b1)
  begin
    if(S == 1'b0)
    begin
      if((bit_counter_en == 1'b1) && (bit_counter_ld == 1'b1))
      begin
        shift_in_reg = {shift_in_reg[6:0],D}; bit_counter = 3'b111;
        //-------------------------------------------------
        if(operation == WREN_OP) wren_id = 1'b0 ;
        if(operation == WRDI_OP) wrdi_id = 1'b0 ;
        if(operation == PGWR_OP) wrda_id = 1'b0 ;
        if(operation == PGPG_OP) wrda_id = 1'b0 ;
        if(operation == PGES_OP) pges_id = 1'b0 ;
        if(operation == SCES_OP) sces_id = 1'b0 ;
        if(operation == RLDP_OP) rldp_id = 1'b0 ;
        if(operation == DPPD_OP) dppd_id = 1'b0 ;
        //-------------------------------------------------
      end
      else if((bit_counter_en == 1'b1) && (bit_counter_ld == 1'b0))
      begin
        shift_in_reg = {shift_in_reg[6:0],D}; bit_counter = bit_counter - 3'b001;
      end
      if((bit_counter_en == 1'b1) && (bit_counter == 3'b000))
      begin
        byte_ok = 1'b1; bit_counter_en = 1'b0;
      end
      else if(bit_counter_en == 1'b1) bit_counter_ld = 1'b0;
    end
    else $display("%t, Warning: Device is in standby mode! Falling edge on chip select is required!\n",$realtime);
  end
  else $display("%t, Error: Device has not been powered on before clock starts!\n",$realtime);
end

//#########################################################
//Instruction Reception, Decode and Treatment
//Address Reception and Data Bytes Reception
//#########################################################
always@(negedge C)
begin
  //=================================== Instruction Byte Reception and Decode
  if((mode == ap_mode)&&(instruction_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    instruction_byte = 1'b0; byte_ok = 1'b0;
    instruction_code = shift_in_reg;
    instruction_decode(instruction_code);
  end
  //=================================== Instruction Treatment
   instruction_treat(instruction);
  //=================================== Address High Byte Reception
  if((mode == ap_mode) && (address_h_byte == 1'b1) && (byte_ok == 1'b1))
  begin
    address_h_byte = 1'b0; byte_ok = 1'b0;
    address_h_code = shift_in_reg;     //saves address high byte
    address_m_byte = 1'b1;             //receives address middle byte
    bit_counter_en = 1'b1;
    bit_counter_ld = 1'b1;
  end
  //=================================== Address Middle Byte Reception
  if((mode == ap_mode) && (address_m_byte == 1'b1) && (byte_ok == 1'b1))
  begin
    address_m_byte = 1'b0; byte_ok = 1'b0;
    address_m_code = shift_in_reg;     //saves address middle byte
    address_l_byte = 1'b1;             //receives address low byte
    bit_counter_en = 1'b1;
    bit_counter_ld = 1'b1;
  end
  //=================================== Address Low Byte Reception
  if((mode == ap_mode) && (address_l_byte == 1'b1) && (byte_ok == 1'b1))
  begin
    address_l_byte = 1'b0; byte_ok = 1'b0;
    address_l_code = shift_in_reg;     //saves address low byte,address ok
    //---------------------------------
    memory_address = {address_h_code,address_m_code,address_l_code};
    //---------------------------------
    if(page_erase == 1'b1)
    begin
      operation = PGES_OP;
      page_erase = 1'b0; pges_id = 1'b1;
    end
    //---------------------------------
    if(sector_erase == 1'b1)
    begin
      operation = SCES_OP;
      sector_erase = 1'b0; sces_id = 1'b1;
    end
    //---------------------------------
    if(read_data_bytes == 1'b1)
    begin
      operation = READ_OP; i = 8;
      read_data_bytes = 1'b0;
    end
    //---------------------------------
    if(read_data_bytes_fast == 1'b1)
    begin
      bit_counter_en = 1'b1; dummy_byte = 1'b1;
      bit_counter_ld = 1'b1; read_data_bytes_fast = 1'b0;
    end
    //---------------------------------
    if(page_write == 1'b1)
    begin
      operation = PGWR_OP;
      bit_counter_en = 1'b1; data_byte = 1'b1;
      bit_counter_ld = 1'b1; page_write = 1'b0;
      page_address = memory_address[`MEM_ADDR_BITS-1:`MEM_ADDR_BITS-`PAGE_ADDR_BITS];
      //load the data value of addressed page to data buffer
      for(i=1;i<=`PAGE_SIZE;i=i+1)
      begin
        data_latch[memory_address[`PAGE_OFFSET_BITS-1:0]] = memory[memory_address[`MEM_ADDR_BITS-1:0]];
        if(memory_address[`PAGE_OFFSET_BITS-1:0] == page_addr_highest)
          memory_address[`PAGE_OFFSET_BITS-1:0] = page_addr_zero;
        else memory_address[`PAGE_OFFSET_BITS-1:0] = memory_address[`PAGE_OFFSET_BITS-1:0] + page_addr_increase;
      end
    end
    //---------------------------------
    if(page_program == 1'b1)
    begin
      operation = PGPG_OP;
      bit_counter_en = 1'b1; data_byte = 1'b1; bytes = 0;
      bit_counter_ld = 1'b1; page_program = 1'b0;
      page_address = memory_address[`MEM_ADDR_BITS-1:`MEM_ADDR_BITS-`PAGE_ADDR_BITS];
      //load the data value of addressed page to data buffer
      for(i=1;i<=`PAGE_SIZE;i=i+1)
      begin
        data_latch[memory_address[`PAGE_OFFSET_BITS-1:0]] = memory[memory_address[`MEM_ADDR_BITS-1:0]];
        if(memory_address[`PAGE_OFFSET_BITS-1:0] == page_addr_highest)
          memory_address[`PAGE_OFFSET_BITS-1:0] = page_addr_zero;
        else memory_address[`PAGE_OFFSET_BITS-1:0] = memory_address[`PAGE_OFFSET_BITS-1:0] + page_addr_increase;
      end
    end
  end
  //=================================== Dummy Byte Reception
  if((mode == ap_mode) && (dummy_byte == 1'b1) && (byte_ok == 1'b1))
  begin
    operation = HSRD_OP; i = 8;
    byte_ok = 1'b0; dummy_byte = 1'b0;
  end
  //=================================== Data Bytes Reception
  if((mode == ap_mode) && (data_byte == 1'b1) && (byte_ok == 1'b1))
  begin
    //---------------------------------
    //data write in data buffer
    //---------------------------------
    if(operation == PGWR_OP)
    begin
      //indicates one byte data is latched in
       bit_counter_en = 1'b1; byte_ok = 1'b0;
       bit_counter_ld = 1'b1; wrda_id = 1'b1;
      //data write in data buffer
      data_latch[memory_address[`PAGE_OFFSET_BITS-1:0]] = shift_in_reg;
      //address increase and page boundary roll over
      if(memory_address[`PAGE_OFFSET_BITS-1:0] == `PAGE_OFFSET_BITS'hff)
        memory_address[`PAGE_OFFSET_BITS-1:0] = `PAGE_OFFSET_BITS'h00;
      else memory_address[`PAGE_OFFSET_BITS-1:0] = memory_address[`PAGE_OFFSET_BITS-1:0] + `PAGE_OFFSET_BITS'h01;
    end
    //---------------------------------
    //data program in data buffer
    //only change bit from 1 to 0
    //---------------------------------
    if(operation == PGPG_OP)
    begin
      //indicates one byte data is latched in
       bytes = bytes + 1;
       bit_counter_en = 1'b1; byte_ok = 1'b0;
       bit_counter_ld = 1'b1; wrda_id = 1'b1;
      //data program in data buffer
      //only change bit from 1 to 0
      data_latch[memory_address[`PAGE_OFFSET_BITS-1:0]] =
      data_latch[memory_address[`PAGE_OFFSET_BITS-1:0]] & shift_in_reg;
      //address increase and page boundary roll over
      if(memory_address[`PAGE_OFFSET_BITS-1:0] == `PAGE_OFFSET_BITS'hff)
        memory_address[`PAGE_OFFSET_BITS-1:0] = `PAGE_OFFSET_BITS'h00;
      else memory_address[`PAGE_OFFSET_BITS-1:0] = memory_address[`PAGE_OFFSET_BITS-1:0] + `PAGE_OFFSET_BITS'h01;
    end
  end
  //################################### DATA OUTPUT REGARDING READ OPERATION
  if(operation == READ_OP) begin
    if(i==0) begin i = 8;
      if(memory_address[`MEM_ADDR_BITS-1:0] == address_highest)
        memory_address[`MEM_ADDR_BITS-1:0] = address_zero;
      else memory_address[`MEM_ADDR_BITS-1:0] = memory_address[`MEM_ADDR_BITS-1:0] + address_increase;
    end
    dout = 1'bx; //output "x" between last data and next data
    #(`tCLQV);   //clock low to output valid
    data_out_buf = memory[memory_address[`MEM_ADDR_BITS-1:0]];
    dout = data_out_buf[i-1]; i = i-1;
  end
  //-----------------------------------
  if(operation == HSRD_OP) begin
    if(i==0) begin i = 8;
      if(memory_address[`MEM_ADDR_BITS-1:0] == address_highest)
        memory_address[`MEM_ADDR_BITS-1:0] = address_zero;
      else memory_address[`MEM_ADDR_BITS-1:0] = memory_address[`MEM_ADDR_BITS-1:0] + address_increase;
    end
    dout = 1'bx; //output "x" between last data and next data
    #(`tCLQV);   //clock low to output valid
    data_out_buf = memory[memory_address[`MEM_ADDR_BITS-1:0]];
    dout = data_out_buf[i-1]; i = i-1;
  end
end
//#########################################################

//#########################################################
//chip selected is driven high; read sr operation is
//terminated while internal write cycle is in progress
//#########################################################
always@(posedge S)
begin
  if((status_reg[0] == 1'b1) && (operation == RDSR_OP))
  begin
    instruction = 4'b0000;
    dout = 1'bz; operation = 4'b0000;
  end
end

//#########################################################
//chip select is driven high; internal cycle is triggered
//read operation is terminated and device into standby
//#########################################################
always@(posedge S)
begin
  mode = sb_mode;
  //======================================== incorrect /S input checking
  if(instruction_byte == 1'b1)
    $display("%t, Warning: /CS should not be driven high during the instruction byte reception.\n",$realtime);
  if(dummy_byte == 1'b1)
    $display("%t, Warning: /CS should not be driven high during the dummy byte reception.\n",$realtime);
  if(address_h_byte == 1'b1)
    $display("%t, Warning: /CS should not be driven high during the high address byte reception.\n",$realtime);
  if(address_m_byte == 1'b1)
    $display("%t, Warning: /CS should not be driven high during the middle address byte reception.\n",$realtime);
  if(address_l_byte == 1'b1)
    $display("%t, Warning: /CS should not be driven high during the low address byte reception.\n",$realtime);
  //======================================== write enable instruction execution
  if(operation == WREN_OP)
  begin
    operation = 4'b0000;
    dout = 1'bz;
    if((wren_id == 1'b1) && (hw_rst == 1'b0))
    begin
      status_reg[1] = 1'b1; wren_id = 1'b0; $display("%t, Notes: WRITE ENABLE.\n",$realtime);
    end
    else begin
    if(hw_rst == 1'b1) begin hw_rst = 1'b0;
      $display("%t, Warning: This WRITE ENABLE instruction is rejected because RESET pin is driven low.",$realtime);
    end
    if(wren_id == 1'b0)
      $display("%t, Warning: This WRITE ENABLE instruction is not executed. Chip Select must be driven high after the eighth bit of instruction byte has been latched in.\n",$realtime);
    end
  end
  //======================================== write disable instruction execution
  if(operation == WRDI_OP)
  begin
    operation = 4'b0000;
    dout = 1'bz;
    if((wrdi_id == 1'b1) && (hw_rst == 1'b0))
    begin
      status_reg[1] = 1'b0; wrdi_id = 1'b0; $display("%t, Notes: WRITE DISABLE.\n",$realtime);
    end
    else begin
    if(hw_rst == 1'b1) begin hw_rst = 1'b0;
      $display("%t, Warning: This WRITE DISABLE instruction is rejected because RESET pin is driven low.",$realtime);
    end
    if(wrdi_id == 1'b0)
      $display("%t, Warning: This WRITE DISABLE instruction is not executed. Chip Select must be driven high after the eighth bit of instruction byte has been latched in.\n",$realtime);
    end
  end
  //======================================== read id is terminated
  if(operation == RDID_OP)
  begin
    instruction = 4'b0000; operation = 4'b0000;
    dout = 1'bx; #(`tSHQZ); dout = 1'bz;
  end
  //======================================== read sr is terminated
  if(operation == RDSR_OP)
  begin
    instruction = 4'b0000; operation = 4'b0000;
    dout = 1'bx; #(`tSHQZ); dout = 1'bz;
  end
  //======================================== data rd is terminated
  if(operation == READ_OP)
  begin
    operation = 4'b0000; dout = 1'bx; #(`tSHQZ); dout = 1'bz;
    $display("%t, Notes: Read data bytes operation is finished.\n",$realtime);
  end
  //======================================== fast rd is terminated
  if(operation == HSRD_OP)
  begin
    operation = 4'b0000; dout = 1'bx; #(`tSHQZ); dout = 1'bz;
    $display("%t, Notes: Fast Read data bytes operation is finished.\n",$realtime);
  end
  //======================================== the self-timed page write cycle is triggered
  if(operation == PGWR_OP)
  begin
    dout = 1'bz; data_byte = 1'b0;
    if((wrda_id == 1'b1) && (hw_rst == 1'b0))
    begin
      if((wr_protect == 1'b1) && (page_address >= `PAGE_ADDR_BITS'h300))
        $display("%t, Warning: Device in the Hardware Protected mode, the top 256 pages can't be written in!\n",$realtime);
      else begin
        $display("%t, Notes: Page[%d] Write Cycle is started!",$realtime,page_address);
        //In order to avoid mistake caused by checking internal cycle by WEL, WEL is X during this cycle.
        //because WEL bit will be reset at some unspecified time before the cycle is complete.
        status_reg[1] = 1'bx;
        //WIP is 1 during this cycle
        status_reg[0] = 1'b1;
        //previous_op = 2'b10;
        #(`tPW_MAX);
        //previous_op = 2'b00;
        if(rst_in_cycle == 1'b0)
        begin
          //Step one: Page Erase
          memory_address[`PAGE_OFFSET_BITS-1:0] = `PAGE_OFFSET_BITS'h00;
          for(i=1;i<=`PAGE_SIZE;i=i+1)
          begin
            memory[memory_address[`MEM_ADDR_BITS-1:0]] = `DATA_BITS'hff;
            memory_address[`PAGE_OFFSET_BITS-1:0] = memory_address[`PAGE_OFFSET_BITS-1:0] + `PAGE_OFFSET_BITS'h01;
          end
          //Step two: Page Program
          memory_address[`PAGE_OFFSET_BITS-1:0] = `PAGE_OFFSET_BITS'h00;
          for(i=1;i<=`PAGE_SIZE;i=i+1)
          begin
            memory[memory_address[`MEM_ADDR_BITS-1:0]] = data_latch[memory_address[`PAGE_OFFSET_BITS-1:0]];
            memory_address[`PAGE_OFFSET_BITS-1:0] = memory_address[`PAGE_OFFSET_BITS-1:0] + `PAGE_OFFSET_BITS'h01;
          end
          $display("%t, Notes: Page[%d] Write Cycle is completed!\n",$realtime,page_address);
        end
        else rst_in_cycle = 1'b0;
        operation = 4'b0000;
        status_reg[1] = 1'b0; //WEL is reset when this cycle is completed
        status_reg[0] = 1'b0; //WIP is reset when this cycle is completed
      end
      wrda_id = 1'b0;
    end
    else begin
      if(hw_rst == 1'b1) begin hw_rst = 1'b0;
        $display("%t, Warning: This PAGE WRITE instruction is rejected because RESET pin is driven low.",$realtime);
      end
      if(wrda_id == 1'b0)
        $display("%t, Warning: This PAGE WRITE instruction is rejected because chip select is not driven high after the eighth bit of data byte has been latched in.\n",$realtime);
    end
  end
  //======================================== the self-timed page program cycle is triggered
  if(operation == PGPG_OP)
  begin
    dout = 1'bz; data_byte = 1'b0;
    if(bytes < `PAGE_SIZE)
    begin
      bytes = 0; $display("%t, Warning: Page Program instruction is optimized (time) for 256-byte sequence. Ensure that largest byte sequence is implemented. See datasheet and dedicated application note on programming time.\n",$realtime);
    end
    if((wrda_id == 1'b1) && (hw_rst == 1'b0))
    begin
      if((wr_protect == 1'b1) && (page_address >= `PAGE_ADDR_BITS'h300))
        $display("%t, Warning: Device in the Hardware Protected mode, the top 256 pages can't be programmed!\n",$realtime);
      else begin
        $display("%t, Notes: Page[%d] Program Cycle is started!",$realtime,page_address);
        status_reg[1] = 1'bx;
        status_reg[0] = 1'b1;
        //previous_op = 2'b10;
        #(`tPP_MAX);
        //previous_op = 2'b00;
        if(rst_in_cycle == 1'b0)
        begin
          memory_address[`PAGE_OFFSET_BITS-1:0] = `PAGE_OFFSET_BITS'h00;
          for(i=1;i<=`PAGE_SIZE;i=i+1)
          begin
            memory[memory_address[`MEM_ADDR_BITS-1:0]] = data_latch[memory_address[`PAGE_OFFSET_BITS-1:0]];
            memory_address[`PAGE_OFFSET_BITS-1:0] = memory_address[`PAGE_OFFSET_BITS-1:0] + `PAGE_OFFSET_BITS'h01;
          end
          $display("%t, Notes: Page[%d] Program Cycle is completed!\n",$realtime,page_address);
        end
        else rst_in_cycle = 1'b0;
        operation = 4'b0000;
        status_reg[1] = 1'b0; //WEL is reset when this cycle is completed
        status_reg[0] = 1'b0; //WIP is reset when this cycle is completed
      end
      wrda_id = 1'b0;
    end
    else begin
      if(hw_rst == 1'b1) begin hw_rst = 1'b0;
        $display("%t, Warning: This PAGE PROGRAM instruction is rejected because RESET pin is driven low.",$realtime);
      end
      if(wrda_id == 1'b0)
        $display("%t, Warning: This PAGE PROGRAM instruction is rejected because chip select is not driven high after the eighth bit of data byte has been latched in.\n",$realtime);
    end
  end
  //======================================== the self-timed page erase cycle is triggered
  if(operation == PGES_OP)
  begin
    dout = 1'bz;
    page_address = memory_address[`MEM_ADDR_BITS-1:`MEM_ADDR_BITS-`PAGE_ADDR_BITS];
    if((pges_id == 1'b1) && (hw_rst == 1'b0))
    begin
      if((wr_protect == 1'b1) && (page_address >= `PAGE_ADDR_BITS'h300))
        $display("%t, Warning: Device in the Hardware Protected mode, the top 256 pages can't be erased!\n",$realtime);
      else begin
        $display("%t, Notes: Page[%d] Erase Cycle is started!",$realtime,page_address);
        status_reg[1] = 1'bx; //WEL is X during this cycle
        status_reg[0] = 1'b1; //WIP is 1 during this cycle
        //previous_op = 2'b10;
        #(`tPE_MAX);
        //previous_op = 2'b00;
        if(rst_in_cycle == 1'b0)
        begin
          memory_address[`PAGE_OFFSET_BITS-1:0] = `PAGE_OFFSET_BITS'h00;
          for(i=1;i<=`PAGE_SIZE;i=i+1)
          begin
            memory[memory_address[`MEM_ADDR_BITS-1:0]] = `DATA_BITS'hff;
            memory_address[`PAGE_OFFSET_BITS-1:0] = memory_address[`PAGE_OFFSET_BITS-1:0] + `PAGE_OFFSET_BITS'h01;
          end
          $display("%t, Notes: Page[%d] Erase Cycle is completed!\n",$realtime,page_address);
        end
        else rst_in_cycle = 1'b0;
        operation = 4'b0000;
        status_reg[1] = 1'b0; //WEL is reset when this cycle completed
        status_reg[0] = 1'b0; //WIP is reset when this cycle completed
      end
      pges_id = 1'b0;
    end
    else begin
      if(hw_rst == 1'b1) begin hw_rst = 1'b0;
        $display("%t, Warning: This PAGE ERASE instruction is rejected because RESET pin is driven low.",$realtime);
      end
      if(pges_id == 1'b0)
        $display("%t, Warning: This PAGE ERASE instruction is rejected because chip select is not driven high after the eighth bit of the last address byte has been latched in.\n",$realtime);
    end
  end
  //======================================== the self-timed sector erase cycle is triggered
  if(operation == SCES_OP)
  begin
    dout = 1'bz;
    sector_address = memory_address[`MEM_ADDR_BITS-1:`MEM_ADDR_BITS-`SECTOR_ADDR_BITS];
    if((sces_id == 1'b1) && (hw_rst == 1'b0))
    begin
      if((wr_protect == 1'b1) && (sector_address >= `SECTOR_ADDR_BITS'h3))
        $display("%t, Warning: Device in the Hardware Protected mode, the top sector can't be erased!\n",$realtime);
      else begin
        $display("%t, Notes: Sector[%d] Erase Cycle is started!",$realtime,sector_address);
        status_reg[1] = 1'bx; //WEL is X during this cycle
        status_reg[0] = 1'b1; //WIP is 1 during this cycle
        //previous_op = 2'b11;
        #(`tSE_MAX);
        //previous_op = 2'b00;
        if(rst_in_cycle == 1'b0)
        begin
          memory_address[`SECTOR_OFFSET_BITS-1:0] = `SECTOR_OFFSET_BITS'h0000;
          for(i=1;i<=`SECTOR_SIZE;i=i+1)
          begin
            memory[memory_address[`MEM_ADDR_BITS-1:0]] = `DATA_BITS'hff;
            memory_address[`SECTOR_OFFSET_BITS-1:0] = memory_address[`SECTOR_OFFSET_BITS-1:0] + `SECTOR_OFFSET_BITS'h0001;
          end
          $display("%t, Notes: Sector[%d] Erase Cycle is completed!\n",$realtime,sector_address);
        end
        else rst_in_cycle = 1'b0;
        operation = 4'b0000;
        status_reg[1] = 1'b0; //WIP is reset when this cycle completed
        status_reg[0] = 1'b0; //WIP is reset when this cycle completed
        //se_busy = 1'b0;
      end
      sces_id = 1'b0;
    end
    else begin
      if(hw_rst == 1'b1) begin hw_rst = 1'b0;
        $display("%t, Warning: This SECTOR ERASE instruction is rejected because RESET pin is driven low.",$realtime);
      end
      if(sces_id == 1'b0)
        $display("%t, Warning: This SECTOR ERASE instruction is rejected because chip select is not driven high after the eighth bit of the last address byte has been latched in.\n",$realtime);
    end
  end
  //-----------------------------------
  wr_protect = 1'b0;
  //======================================== deep power down instruction execution
  if(operation == DPPD_OP)
  begin
    dout = 1'bz; operation = 4'b0000;
    if((dppd_id == 1'b1) && (hw_rst == 1'b0))
    begin
      dppd_id = 1'b0; mode = sb_mode;
      deep_pd_delay = 1'b1; #(`tDP);
      deep_pd_delay = 1'b0;
      if(not_deep_pd == 1'b0)
      begin
        $display("%t, Notes: Device enter the DEEP POWER DOWN MODE,the supply current is reduced!\n",$realtime);
        device_power_down = 1'b1; mode = dp_mode;
      end
      else begin not_deep_pd = 1'b0;
        $display("%t, Warning: Chip Select falling edge happens during a delay of tDP before the DEEP POWER DOWN MODE is entered.",$realtime);
      end
    end
    else begin
      if(hw_rst == 1'b1) begin hw_rst = 1'b0;
        $display("%t, Warning: This DEEP POWER DOWN instruction is rejected because RESET pin is driven low.",$realtime);
      end
      if(dppd_id == 1'b0)
        $display("%t, Warning: This DEEP POWER DOWN instruction is rejected because chip select is not driven high after the eighth bit of instruction code has been latched in.\n",$realtime);
    end
  end
  //======================================== release from deep power down instruction execution
  if(operation == RLDP_OP)
  begin
    dout = 1'bz; operation = 4'b0000;
    if((rldp_id == 1'b1) && (hw_rst == 1'b0))
    begin
      rldp_id = 1'b0;
      release_pd_delay = 1'b1; #(`tRDP);
      release_pd_delay = 1'b0;
      if(not_release_pd == 1'b0)
      begin
        $display("%t, Notes: Device release from the DEEP POWER DOWN MODE!\n",$realtime);
        device_power_down = 1'b0; mode = sb_mode;
      end
      else begin not_release_pd = 1'b0;
        $display("%t, Warning: Chip Select falling edge happens during a delay of tRDP before the DEEP POWER DOWN MODE is released.",$realtime);
      end
    end
    else begin
      if(hw_rst == 1'b1) begin hw_rst = 1'b0;
        $display("%t, Warning: This RELEASE FROM DEEP POWER DOWN instruction is rejected because RESET pin is driven low.",$realtime);
      end
      if(rldp_id == 1'b0)
        $display("%t, Warning: This RELEASE FROM DEEP POWER DOWN instruction is rejected because chip select is not driven high after the eighth bit of instruction code has been latched in.\n",$realtime);
    end
  end
  hw_rst = 1'b0;
  dout = 1'bx; #(`tSHQZ); dout = 1'bz;
end

//###############################################
//AC timing Characteristics Check
//###############################################
always@(posedge S)
begin
  t_rS = $time; r_S = 1'b1;
  if(r_C == 1'b1)
  begin
    tCHSH = t_rS - t_rC;
    if(tCHSH < `tCHSH) begin
      $display("%t, Error: /S active hold time(tCHSH) violated.\n",$realtime);
      if(`STOP == 1) $stop;
    end
  end
end
//===============================================
always@(negedge S)
begin
  t_fS = $time; f_S = 1'b1;
  if(r_S == 1'b1)
  begin
    tSHSL = t_fS - t_rS;
    if(tSHSL < `tSHSL) begin
      $display("%t, Error: /S Deselect time(tSHSL) violated.\n",$realtime);
      if(`STOP == 1) $stop;
    end
  end
  if(r_C == 1'b1)
  begin
    tCHSL = t_fS - t_rC;
    if(tCHSL < `tCHSL) begin
      $display("%t, Error: /S not active hold time(tCHSL) violated.\n",$realtime);
      if(`STOP == 1) $stop;
    end
  end
  if(r_W == 1'b1)
  begin
    tTHSL = t_fS - t_rW;
    if(tTHSL < `tTHSL) begin
      $display("%t, Error: Write Protect Setup Time(tTHSL) violated.\n",$realtime);
      if(`STOP == 1) $stop;
    end
  end
end
//===============================================
always@(negedge TSL)
begin
  t_fW = $time; f_W = 1'b1;
  if(r_S == 1'b1)
  begin
    tSHTL = t_fW - t_rS;
    if(tSHTL < `tSHTL) begin
      $display("%t, Error: Write Protect Hold Time(tSHTL) violated.\n",$realtime);
      if(`STOP == 1) $stop;
    end
  end
end
//===============================================
always@(posedge TSL)
begin
  t_rW = $time; r_W = 1'b1;
end
//===============================================
always@(posedge C)
begin
  if(operation == READ_OP)
  begin
    t_rCr = $time;
    if(r_Cr == 1'b1)
    begin
      Tcr = t_rCr - t_rCr1;
      if(Tcr < `tR) begin
        $display("%t, Error: Clock for read instruction frequency(fR) violated, fC>20MHz.\n",$realtime);
        if(`STOP == 1) $stop;
      end
    end
    r_Cr = 1'b1; t_rCr1 = t_rCr;
  end
  else begin
    t_rC = $time;
    if(r_C == 1'b1)
    begin
      Tc = t_rC - t_rC1;
      if(Tc < `tC) begin
        $display("%t, Error: Clock frequency(fC) violated, fC>25MHz.\n",$realtime);
        if(`STOP == 1) $stop;
      end
    end
    r_C = 1'b1;
    if(r_S == 1'b1)
    begin
      tSHCH = t_rC - t_rS;
      if(tSHCH < `tSHCH) begin
        $display("%t, Error: /S not active setup time(tSHCH) violated.\n",$realtime);
        if(`STOP == 1) $stop;
      end
    end
    if(f_S == 1'b1)
    begin
      tSLCH = t_rC - t_fS;
      if(tSLCH < `tSLCH) begin
        $display("%t, Error: /S active setup time(tSLCH) violated.\n",$realtime);
        if(`STOP == 1) $stop;
      end
    end
    if(f_C == 1'b1)
    begin
      tCL = t_rC - t_fC;
      if(tCL < `tCL) begin
        $display("%t, Error: Clock low time(tCL) violated.\n",$realtime);
        if(`STOP == 1) $stop;
      end
    end
    if(din_change == 1'b1)
    begin
      tDVCH = t_rC - t_d;
      if(tDVCH < `tDVCH) begin
        $display("%t, Error: Data in setup time(tDVCH) violated.\n",$realtime);
        if(`STOP == 1) $stop;
      end
    end
    t_rC1 = t_rC;
  end
end
//=========================================================
always@(negedge C)
begin
  t_fC = $time; f_C = 1'b1;
  if(r_C == 1'b1)
  begin
    tCH = t_fC - t_rC;
    if(tCH < `tCH) begin
      $display("%t, Error: Clock high time(tCH) violated.\n",$realtime);
      if(`STOP == 1) $stop;
    end
  end
end
//=========================================================
always@(D)
begin
  t_d = $time; din_change = 1'b1;
  if(r_C == 1'b1)
  begin
    tCHDX = t_d - t_rC;
    if(tCHDX < `tCHDX) begin
      $display("%t, Error: Data in hold time(tCHDX) violated.\n",$realtime);
      if(`STOP == 1) $stop;
    end
  end
end

//#########################################################
//instruction decode task
//#########################################################
task instruction_decode;
input[7:0] command_code;
begin
  case(command_code)
  8'b0000_0110: // WREN
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: WREN is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else instruction = WREN_INS;
  end
  8'b0000_0100: // WRDI
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: WRDI is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else instruction = WRDI_INS;
  end
  8'b1001_1111: // RDID
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: RDID is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else begin instruction = RDID_INS; i = 24; end
  end
  8'b0000_0101: // RDSR
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: RDSR is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else begin instruction = RDSR_INS; sr_bit = 8; end
  end
  8'b0000_0011: // READ DATA
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: READ is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else instruction = READ_INS;
  end
  8'b0000_1011: // FAST READ
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: FAST READ is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else instruction = HSRD_INS;
  end
  8'b0000_1010: // PAGE WRITE
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: PW is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else instruction = PGWR_INS;
  end
  8'b0000_0010: // PAGE PROGRAM
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: PP is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else instruction = PGPG_INS;
  end
  8'b1101_1011: // PAGE ERASE
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: PE is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else instruction = PGES_INS;
  end
  8'b1101_1000: // SECTOR ERASE
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: SE is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else instruction = SCES_INS;
  end
  8'b1011_1001: // DEEP POWER DOWN
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: DP is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else instruction = DPPD_INS;
  end
  8'b1010_1011: // RELEASE FROM DEEP POWER DOWN
  begin
    if(ins_rej == 1'b1)
    begin
      $display("%t, Warning: RDP is rejected because Reset is driven Low when Chip Select Enable.",$realtime);
      ins_rej = 1'b0;
    end
    else instruction = RLDP_INS;
  end
  default: begin
      $display("%t, Warning: This Instruction Code[%b] is Undefined!\n",$realtime,command_code);
  end
  endcase
end
endtask

//#########################################################
//instruction treatment task
//#########################################################
task instruction_treat;
input[3:0] command;
begin
  case(command)
  //-----------------------------------------------------------------
  WREN_INS: begin instruction = 4'b0000; current_time = $time;
    if((status_reg[0] == 1'b1)||(device_power_down == 1'b1)||(current_time - t_rVCC < `tPUW_MAX))
    begin
      if(status_reg[0] == 1'b1)
        $display("%t, Warning: An Erase, Program or Write Cycle is in progress, WREN is rejected!",$realtime);
      if(device_power_down == 1'b1)
        $display("%t, Warning: Device is in DEEP POWER DOWN MODE, WREN is rejected!",$realtime);
      if(current_time - t_rVCC < `tPUW_MAX)
        $display("%t, Warning: Device ignores WREN during a time delay of tPUW!",$realtime);
    end
    else begin operation = WREN_OP; wren_id = 1'b1; end
  end
  //-----------------------------------------------------------------
  WRDI_INS: begin instruction = 4'b0000;
    if((status_reg[0] == 1'b1)||(device_power_down == 1'b1))
    begin
      if(status_reg[0] == 1'b1)
        $display("%t, Warning: An Erase, Program or Write Cycle is in progress, WRDI is rejected!",$realtime);
      if(device_power_down == 1'b1)
        $display("%t, Warning: Device is in DEEP POWER DOWN MODE, WRDI is rejected!",$realtime);
    end
    else begin operation = WRDI_OP; wrdi_id = 1'b1; end
  end
  //-----------------------------------------------------------------
  RDID_INS: begin
    if((status_reg[0] == 1'b1)||(device_power_down == 1'b1))
    begin
      instruction = 4'b0000;
      if(status_reg[0] == 1'b1)
        $display("%t, Warning: An Erase, Program or Write Cycle is in progress, RDID is rejected!",$realtime);
      if(device_power_down == 1'b1)
        $display("%t, Warning: Device is in DEEP POWER DOWN MODE, RDID is rejected!",$realtime);
    end
    else begin
      device_id = {manufacturer_id,memory_type,memory_capacity};
      operation = RDID_OP;
      if(i==0) i = 24;
      //during the period of clock low to output valid, output "x" on Q line.
      //output "x" between last data and next data
      dout = 1'bx; #(`tCLQV);
      dout = device_id[i-1];
      i = i - 1;
    end
  end
  //-----------------------------------------------------------------
  RDSR_INS: begin
    if(device_power_down == 1'b1)
    begin
      instruction = 4'b0000;
      $display("%t, Warning: Device is in DEEP POWER DOWN MODE, RDSR is rejected!",$realtime);
    end
    else begin
      operation = RDSR_OP;
      if(sr_bit==0) sr_bit = 8;
      //during the period of clock low to output valid, output "x" on Q line.
      //output "x" between last data and next data
      dout = 1'bx; #(`tCLQV);
      dout = status_reg[sr_bit-1];
      sr_bit = sr_bit - 1;
    end
  end
  //-----------------------------------------------------------------
  READ_INS: begin instruction = 4'b0000;
    if((status_reg[0] == 1'b1)||(device_power_down == 1'b1))
    begin
      if(status_reg[0] == 1'b1)
        $display("%t, Warning: An Erase, Program or Write Cycle is in progress, READ is rejected!",$realtime);
      if(device_power_down == 1'b1)
        $display("%t, Warning: Device is in DEEP POWER DOWN MODE, READ is rejected!",$realtime);
    end
    else begin
      read_data_bytes = 1'b1; address_h_byte = 1'b1; bit_counter_en = 1'b1; bit_counter_ld = 1'b1;
    end
  end
  //-----------------------------------------------------------------
  HSRD_INS: begin instruction = 4'b0000;
    if((status_reg[0] == 1'b1)||(device_power_down == 1'b1))
    begin
      if(status_reg[0] == 1'b1)
        $display("%t, Warning: An Erase, Program or Write Cycle is in progress, FAST READ is rejected!",$realtime);
      if(device_power_down == 1'b1)
        $display("%t, Warning: Device is in DEEP POWER DOWN MODE, FAST READ is rejected!",$realtime);
    end
    else begin
      read_data_bytes_fast = 1'b1; address_h_byte = 1'b1; bit_counter_en = 1'b1; bit_counter_ld = 1'b1;
    end
  end
  //-----------------------------------------------------------------
  PGWR_INS: begin instruction = 4'b0000; current_time = $time;
    if((status_reg[0] == 1'b1)||(device_power_down == 1'b1)||(current_time - t_rVCC < `tPUW_MAX))
    begin
      if(status_reg[0] == 1'b1)
        $display("%t, Warning: An Erase, Program or Write Cycle is in progress, PW is rejected!",$realtime);
      if(device_power_down == 1'b1)
        $display("%t, Warning: Device is in DEEP POWER DOWN MODE, PW is rejected!",$realtime);
      if(current_time - t_rVCC < `tPUW_MAX)
        $display("%t, Warning: Device ignores PW during a time delay of tPUW!",$realtime);
    end
    else begin
      if(status_reg[1] == 1'b1)
      begin
        $display("%t, Warning: When updating contiguous bytes in a page, optimized timings are obtained using a single Page Write sequence including all updated bytes versus using several Page Write sequences with each containing a just single byte. See datasheet and dedicated application note on programming times.\n",$realtime);
        page_write = 1'b1; address_h_byte = 1'b1; bit_counter_en = 1'b1; bit_counter_ld = 1'b1;
      end
      else $display("%t, Warning: Write Disable! PW can not be accepted!",$realtime);
    end
  end
  //-----------------------------------------------------------------
  PGPG_INS: begin instruction = 4'b0000; current_time = $time;
    if((status_reg[0] == 1'b1)||(device_power_down == 1'b1)||(current_time - t_rVCC < `tPUW_MAX))
    begin
      if(status_reg[0] == 1'b1)
        $display("%t, Warning: An Erase, Program or Write Cycle is in progress, PP is rejected!",$realtime);
      if(device_power_down == 1'b1)
        $display("%t, Warning: Device is in DEEP POWER DOWN MODE, PP is rejected!",$realtime);
      if(current_time - t_rVCC < `tPUW_MAX)
        $display("%t, Warning: Device ignores PP during a time delay of tPUW!",$realtime);
    end
    else begin
      if(status_reg[1] == 1'b1)
      begin
        page_program = 1'b1; address_h_byte = 1'b1; bit_counter_en = 1'b1; bit_counter_ld = 1'b1;
      end
      else $display("%t, Warning: Write Disable! PP can not be accepted!",$realtime);
    end
  end
  //-----------------------------------------------------------------
  PGES_INS: begin instruction = 4'b0000; current_time = $time;
    if((status_reg[0] == 1'b1)||(device_power_down == 1'b1)||(current_time - t_rVCC < `tPUW_MAX))
    begin
      if(status_reg[0] == 1'b1)
        $display("%t, Warning: An Erase, Program or Write Cycle is in progress, PE is rejected!",$realtime);
      if(device_power_down == 1'b1)
        $display("%t, Warning: Device is in DEEP POWER DOWN MODE, PE is rejected!",$realtime);
      if(current_time - t_rVCC < `tPUW_MAX)
        $display("%t, Warning: Device ignores PE during a time delay of tPUW!",$realtime);
    end
    else begin
      if(status_reg[1] == 1'b1)
      begin
        page_erase = 1'b1; address_h_byte = 1'b1; bit_counter_en = 1'b1; bit_counter_ld = 1'b1;
      end
      else $display("%t, Warning: Write Disable! PE can not be accepted!",$realtime);
    end
  end
  //-----------------------------------------------------------------
  SCES_INS: begin instruction = 4'b0000; current_time = $time;
    if((status_reg[0] == 1'b1)||(device_power_down == 1'b1)||(current_time - t_rVCC < `tPUW_MAX))
    begin
      if(status_reg[0] == 1'b1)
        $display("%t, Warning: An Erase, Program or Write Cycle is in progress, SE is rejected!",$realtime);
      if(device_power_down == 1'b1)
        $display("%t, Warning: Device is in DEEP POWER DOWN MODE, SE is rejected!",$realtime);
      if(current_time - t_rVCC < `tPUW_MAX)
        $display("%t, Warning: Device ignores SE during a time delay of tPUW!",$realtime);
    end
    else begin
      if(status_reg[1] == 1'b1)
      begin
        sector_erase = 1'b1; address_h_byte = 1'b1; bit_counter_en = 1'b1; bit_counter_ld = 1'b1;
      end
      else $display("%t, Warning: Write Disable! SE can not be accepted!",$realtime);
    end
  end
  //-----------------------------------------------------------------
  DPPD_INS: begin instruction = 4'b0000;
    if((status_reg[0] == 1'b1)||(device_power_down == 1'b1))
    begin
      if(device_power_down == 1'b1)
        $display("%t, Warning: Device is in DEEP POWER DOWN MODE, DP is rejected!",$realtime);
      if(status_reg[0] == 1'b1)
        $display("%t, Warning: An Erase, Program or Write Cycle is in progress, DP is rejected!",$realtime);
    end
    else begin operation = DPPD_OP; dppd_id = 1'b1; end
  end
  //-----------------------------------------------------------------
  RLDP_INS: begin instruction = 4'b0000;
    if(status_reg[0] == 1'b1)
      $display("%t, Warning: An Erase, Program or Write Cycle is in progress, RDP is rejected!",$realtime);
    else begin operation = RLDP_OP; rldp_id = 1'b1; end
  end
  endcase
end
endtask
//###################################################################

endmodule
