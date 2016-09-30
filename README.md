## SPI FLASH 读写控制接口 ##
 
**速度** 上应该是支持你所用的flash能支持的最大速度 （Cyclone 5 跑120M肯定是没问题的）

**资源** 小于700LE

**功能** 因为是interface 设计 很容易拓展功能，和AXI4 多slaver to 单 master 类似，想拓展，**写个slaver 挂到总线就好了**。

**特色** 纯使用system verilog来设计（不用担心综合问题，我已经试了），大量使用 interface 来做互联。

Have fun!!!

**--@--Young--@--**


