
set_false_path -from {*fifo_nto1_inst*wr_b_flag[*]} -to {*fifo_nto1_inst*rd_b_flag[*]}
set_false_path -from {*fifo_nto1_inst*wr_b_flag[*]} -to {*fifo_nto1_inst*rd_point[*]}
set_false_path -from {*fifo_nto1_inst*rd_b_flag[*]} -to {*fifo_nto1_inst*wr_b_flag[*]}
set_false_path -from {*fifo_nto1_inst*rd_b_flag[*]} -to {*fifo_nto1_inst*wr_point[*]}

set_false_path -from {*fifo_nto1_inst*data[*][*]} -to {*fifo_nto1_inst*rd_data_reg[*]}
set_false_path -from {*fifo_nto1_inst*rd_b_flag[*]} -to {*fifo_nto1_inst*full_flag}
set_false_path -from {*fifo_nto1_inst*rd_point[*]} -to {*fifo_nto1_inst*wr_last_exec}
set_false_path -from {*fifo_nto1_inst*wr_b_flag[*]} -to {*fifo_nto1_inst*empty_flag}
set_max_delay 6.667 -from {*fifo_nto1_inst*wr_point[*]} -to {*fifo_nto1_inst*last_byte_exec}

set_false_path -from {*fifo_1ton_inst*wr_b_flag[*]} -to {*fifo_1ton_inst*rd_b_flag[*]}
set_false_path -from {*fifo_1ton_inst*wr_b_flag[*]} -to {*fifo_1ton_inst*rd_point[*]}
set_false_path -from {*fifo_1ton_inst*rd_b_flag[*]} -to {*fifo_1ton_inst*wr_b_flag[*]}
set_false_path -from {*fifo_1ton_inst*rd_b_flag[*]} -to {*fifo_1ton_inst*wr_point[*]}
set_false_path -from {*fifo_1ton_inst*data[*][*]} -to {*fifo_1ton_inst*rd_data_reg[*]}
set_false_path -from {*fifo_1ton_inst*wr_b_flag[*]} -to {*fifo_1ton_inst*empty_flag}
set_false_path -from {*fifo_1ton_inst*rd_b_flag[*]} -to {*fifo_1ton_inst*full_flag}
set_max_delay 6.667 -from {*fifo_1ton_inst*rd_point[*]} -to {*fifo_1ton_inst*last_byte_exec}
