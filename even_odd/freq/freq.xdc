
create_clock -period 1.980 -name CLK [get_ports CLK]
# create_clock -period 5.540 -name CLK [get_ports CLK]
set_property PACKAGE_PIN AK34 [get_ports CLK]
set_property IOSTANDARD LVDS [get_ports CLK]

