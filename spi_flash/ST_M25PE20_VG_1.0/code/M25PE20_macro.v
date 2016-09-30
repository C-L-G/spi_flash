/*========================================================================

 Parameters Definition for M25PE20 SPI Bus Flash Memory Simulation Model

==========================================================================

 These verilog models are provided "as is" without warranty
 of any kind, included but not limited to, implied warranty
 of merchantability and fitness for a particular purpose.

 Copyright 2005, STMicroelectronics Corporation, All Right Reserved.

========================================================================*/

`timescale 1ns/1ns

`define STOP 1

//===============================================
//Parameters Regarding Memory Attribute
//===============================================
`define DATA_BITS 8
//Bytes in Memory, 2M bits = 256K bytes
`define MEM_SIZE 262144
//Address Bits for Whole Memory
`define MEM_ADDR_BITS 18
//No. of Pages in Memory
`define PAGES 1024
//No. of Bytes in Each Page
`define PAGE_SIZE 256
//Address Bits for Page Access
`define PAGE_ADDR_BITS 10
//Address Bits for Byte Access in One Page
`define PAGE_OFFSET_BITS 8
//No. of Sectors in Memory
`define SECTORS 4
//No. of Bytes in Each Sector
`define SECTOR_SIZE 65536
//Address Bits for Sector Access
`define SECTOR_ADDR_BITS 2
//Address Bits for Byte Access in One Sector
`define SECTOR_OFFSET_BITS 16

//===============================================
//Parameters Regarding AC Characteristics
//===============================================
//Vcc(min) to /S low is 30us
`define tVSL 30e3
//Min. Time delay before the first WR/PG/ES Ins.
`define tPUW_MIN 1e6
//Max. Time delay before the first WR/PG/ES Ins.
`define tPUW_MAX 10e6
//Clock Cycle for Read Instruction
`define tR 50
//Clock Cycle for All Instructions except Read Ins.
`define tC 40
//Read Clock Low Time
`define tRL 25
//Read Clock High Time
`define tRH 25
//Clock Low Time
`define tCL 18
//Clock High Time
`define tCH 18
//Chip Select Active Setup Time (relative to C)
`define tSLCH 10
//Chip Select Not Active Hold Time (relative to C)
`define tCHSL 10
//Data In Setup Time
`define tDVCH 5
//Data In Hold Time
`define tCHDX 5
//Chip Select Active Hold Time (relative to C)
`define tCHSH 10
//Chip Select Not Active Setup Time (relative to C)
`define tSHCH 10
//Chip Select Deselect Time
`define tSHSL 200
//Data Output Disable Time
`define tSHQZ 15
//Clock Low to Output Valid
`define tCLQV 15
//Data Output Hold Time
`define tCLQX 0
//Top Sector Lock Setup Time
`define tTHSL 50
//Top Sector Lock Hold Time
`define tSHTL 100
//Chip Select to Deep Power Down
`define tDP 3000
//Chip Select High to Standby Mode
`define tRDP 30000
//Chip Select High to Reset High
`define tSHRH 10
//Reset Pulse Width
`define tRLRH 10e3
//Reset Recovery Time
`define tRHSL1 30e3
`define tRHSL2 25e6
`define tRHSL3 5e9
//Max. Page Write Cycle Time
`define tPW_MAX 25e6
//Max. Page Program Cycle Time
`define tPP_MAX 5e6
//Max. Page Erase Cycle Time
`define tPE_MAX 20e6
//Max. Sector Erase Cycle Time
`define tSE_MAX 5e9