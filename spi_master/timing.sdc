set_false_path -from {*slaver_sck_parse_inst*gen_edge*raising_reg} -to [all_registers] ## slaver only
set_false_path -from {*spi_master_verb*status_ctrl*cnt_point*} -to [all_registers]
set_false_path -from {*spi_master_verb*status_ctrl*wr_cnt_point*} -to [all_registers]
set_false_path -from {*spi_master_verb*status_ctrl*cmd*} -to [all_registers]
set_false_path -from {*spi_master_verb*status_ctrl*busy_reg} -to {*spi_master_verb*status_ctrl*GEN_SPI_CSN.tmp[0]}
set_false_path -from {*spi_master_verb*status_ctrl*cnt_fsh} -to {*spi_master_verb*status_ctrl*}
set_false_path -from {*spi_master_verb*status_ctrl*rst_fifo} -to [all_registers]
