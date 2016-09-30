
      ____________________________________ 
     /                                    |
    |                                     |
    |      __________________   __________|
    |     |                 |   |
     \     \                |   |   ___________________________________________
      \     \               |   |
       \     \              |   |    2M Bits, Low Voltage, Page Erasable Serial
        \     \             |   |    Flash Memory with 25MHz SPI Bus 
         \     \            |   |        
          \     \           |   |       
           \     \          |   |    
            \     \         |   |
             \     \        |   |    Device Name:  M25PE20
              \     \       |   |   
 ______________|     \      |   |    Copyright (c) 2003 STMicroelectronics              
|                     |     |   |       
|                     |     |   |  ____________________________________________
|_____________________/     |___|

                                              
*******************************************************************************
  
  Version History
  
  Version : 1.0
  Date    : 21/06/2005

  Author  : Xue-Feng Hu
  e-mail  : xue-feng.hu@st.com
            
  Based on Preview Release of M25PE20 Spec Datasheet (Jan 2005)
  
******************************************************************************   
  
  THIS PROGRAM IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,        
  EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO, THE        
  IMPLIED WARRANTY OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR      
  PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF         
  THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU      
  ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.     
  
******************************************************************************

ST_M25PE20_VG1.0.zip file contains:

Code Files:
    code/M25PE20_memory.v         Verilog model of M25PE20 device
    code/M25PE20_macro.v          Verilog file containing Parameters and DCAC characteristics

Simulation Files:        
    sim/M25PE20_initial.txt       An example of the memory initialization file

Stimuli File:
    stim/M25PE20_driver.v         Stimuli Example for M25PE20 device
    stim/M25PE20_testbench.v      Test Bench

Documentation:
    doc/M25PEXX_VG_UM_V1.0.doc    Model User Manual