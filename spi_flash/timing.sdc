create_clock -name "spi_dr_clock_100M" -period 6.000ns [get_ports {dr_spi_clk}]
create_clock -name "spi_api_clock_150M" -period 6.667ns [get_ports {clock}]
set_output_delay -clock "spi_dr_clock_100M" -min -3.000ns [get_ports {spi_dq}] 
