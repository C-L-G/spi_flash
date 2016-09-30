/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/1/19 9:34:57
madified:
***********************************************/
`timescale 1ns/1ps
module fifo_1ton #(
	parameter				DSIZE		= 1	,
	parameter				NSIZE		= 8	,	//1 2 4 8 16
	parameter				DEPTH		= 2	,	//8*n
	parameter				ALMOST		= 2	,
	parameter[DSIZE-1:0]	DEF_VALUE 	= 0
)(
	input					wr_clk			,
	input					wr_rst_n        ,
	input					wr_en           ,
	input [DSIZE-1:0]	    wr_data         ,
	output					wr_full         ,
    output                  wr_last         ,
	output					wr_almost_full  ,
	output[5*NSIZE-1:0]		wr_count        ,
	input					rd_clk          ,
	input					rd_rst_n		,
	input					rd_en           ,
	output[DSIZE*NSIZE-1:0]	rd_data         ,
	output					rd_empty        ,
    output                  rd_last         ,
	output					rd_almost_empty ,
	output[4:0]		        rd_count        ,
	output					rd_vld
);

wire	rst_n;
assign	rst_n	= wr_rst_n && rd_rst_n;

localparam	RDEPTH	= DEPTH,
			WDEPTH	= DEPTH * NSIZE;

reg 	full_flag,empty_flag;
reg 	wr_step,rd_step;
//--->> RING <<------
localparam	WRSIZE	= 	(WDEPTH<=16)?  4 :
						(WDEPTH<=32)?  5 :
      					(WDEPTH<=64)?  6 :
						(WDEPTH<=128)? 7 : 8;

localparam	RRSIZE	= 	(RDEPTH<=16)?  4 :
						(RDEPTH<=32)?  5 :
      					(RDEPTH<=64)?  6 :
						(RDEPTH<=128)? 7 : 8;

localparam	SFBIT	= 	(NSIZE == 1)?  0 :
						(NSIZE == 2)?  1 :
      					(NSIZE == 4)?  2 :
						(NSIZE == 8)?  3 : 4;


reg	[WRSIZE-1:0]	wr_point;
reg [RRSIZE-1:0]	rd_point;
reg [RDEPTH-1:0]    rd_b_flag;
reg [WDEPTH-1:0]    wr_b_flag;
wire[WRSIZE-1:0]           rd_point_wr;
wire[RRSIZE-1:0]           wr_point_rd;

assign rd_point_wr  = (rd_point<<SFBIT)+{SFBIT{1'b1}};
assign wr_point_rd  = wr_point>>SFBIT;
always@(posedge wr_clk,negedge rst_n)begin
    if(~rst_n)  wr_b_flag   <= {WDEPTH{1'b0}};
    else begin
        if(wr_en)begin
            if(wr_b_flag[wr_point] == rd_b_flag[wr_point_rd])
                    wr_b_flag[wr_point] <= !wr_b_flag[wr_point];
            else    wr_b_flag[wr_point] <= wr_b_flag[wr_point];
        end else    wr_b_flag           <= wr_b_flag;
end end

always@(posedge rd_clk,negedge rst_n)begin
    if(~rst_n)  rd_b_flag   <= {RDEPTH{1'b0}};
    else begin
        if(rd_en)begin
            if(rd_b_flag[rd_point] != wr_b_flag[rd_point_wr])
                    rd_b_flag[rd_point] <= ~rd_b_flag[rd_point];
            else    rd_b_flag[rd_point] <= rd_b_flag[rd_point];
        end else    rd_b_flag           <= rd_b_flag;
end end

wire	rd_down_wr,wr_up_rd;
// assign	rd_down_wr	= (wr_step^rd_step) || ((rd_point<<SFBIT) < wr_point);
// assign	wr_up_rd	= !(wr_step^rd_step)|| ( wr_point < (rd_point<<SFBIT));
assign	rd_down_wr	= rd_b_flag[rd_point] != wr_b_flag[rd_point_wr];
assign	wr_up_rd	= wr_b_flag[wr_point] == rd_b_flag[wr_point_rd];

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)		wr_point	<= {WRSIZE{1'b0}};
	else begin
		if(wr_en && wr_up_rd)begin
			if(wr_point == WDEPTH-1)
					wr_point	<= {WRSIZE{1'b0}};
			else	wr_point	<= wr_point + 1'b1;
		end else 	wr_point	<= wr_point;
	end

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)		rd_point	<= {RRSIZE{1'b0}};
	else begin
		if(rd_en && rd_down_wr)begin
			if(rd_point == RDEPTH-1)
					rd_point	<= {RRSIZE{1'b0}};
			else	rd_point	<= rd_point + 1'b1;
		end else	rd_point	<= rd_point;
	end

//---<< RING >>------
//--->> STEP <<------
always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)		wr_step	<= 1'b0;
	else begin
		if(wr_point == WDEPTH-1 && wr_en && !full_flag)
					wr_step	<= ~wr_step;
		else		wr_step	<= wr_step;
	end

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)		rd_step	<= 1'b0;
	else begin
		if(rd_point == RDEPTH-1 && rd_en && !empty_flag)
					rd_step	<= ~rd_step;
		else		rd_step	<= rd_step;
	end
//---<< STEP >>-----------
//--->> FULL EMPTY <<-----
always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	full_flag	<= 1'b0;
	else 		full_flag	<= wr_b_flag[wr_point] != rd_b_flag[wr_point>>SFBIT];

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	empty_flag	<= 1'b1;
	else 		empty_flag	<= rd_b_flag[rd_point] == wr_b_flag[rd_point_wr];
//---<< FULL EMPTY >>------------
//--->> ALMOST FULL EMPTY <<-----
reg 	almost_full_flag,almost_empty_flag;

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	almost_full_flag	<= 1'b0;
	else 		almost_full_flag	<= {wr_step^rd_step,wr_point} >= ((WDEPTH-ALMOST) + (rd_point<<SFBIT));

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	almost_empty_flag	<= 1'b1;
	else 		almost_empty_flag	<= {wr_step^rd_step,wr_point} <= {ALMOST+rd_point,{SFBIT{1'b0}}};
//---<< ALMOST FULL EMPTY >>-----
//--->> WRITE LAST DATA <<--------
reg     last_byte_exec;
always@(posedge wr_clk,negedge rst_n)
    if(~rst_n)  last_byte_exec  <= 1'b0;
    else begin
        if(wr_point_rd == (rd_point-1) && (rd_point != {RRSIZE{1'b0}}))
            last_byte_exec <= 1'b1;
        else if(wr_point_rd == (RDEPTH-1) && (rd_point == {RRSIZE{1'b0}}) )
            last_byte_exec <= 1'b1;
        else
            last_byte_exec <= 1'b0;
    end

reg     wr_last_reg;
always@(posedge wr_clk,negedge rst_n)
    if(~rst_n)  wr_last_reg    <= 1'b0;
    else begin
        if(SFBIT>0)begin
            if( &wr_point[SFBIT-1:0] && last_byte_exec)
                    wr_last_reg    <= wr_en;
            else    wr_last_reg    <= 1'b0;
        end else begin
            wr_last_reg    <= last_byte_exec && wr_en;
        end
    end
assign wr_last  = wr_last_reg;
//---<< READ LAST DATA >>--------
//--->> READ LAST DATA <<-------
reg     rd_last_exec;
always@(posedge rd_clk,negedge rst_n)
    if(~rst_n)  rd_last_exec    <= 1'b0;
    else begin
        if(rd_point == (wr_point_rd-1) && wr_point_rd != 0 )
                rd_last_exec    <= rd_en;
        else if(rd_point == (RDEPTH-1) && wr_point_rd == 0)
                rd_last_exec    <= rd_en;
        else    rd_last_exec    <= 1'b0;
    end

assign rd_last  = rd_last_exec;
//---<< READ LAST DATA >>-------
//--->> MEM <<-------------------
reg [DSIZE-1:0]	data [WDEPTH-1:0];

always@(posedge wr_clk,negedge rst_n)begin:MEM_BLOCK
integer	II;
	if(~rst_n)begin
		for(II=0;II<WDEPTH;II=II+1)
			data[II]	<= DEF_VALUE;
	end else begin
		if(wr_en)begin
            data[wr_point]  <= wr_data;
			// for(II=0;II<NSIZE;II=II+1)
			// 	data[wr_point*NSIZE+II]	<= wr_data[DSIZE*(NSIZE-1-II)+:DSIZE];
		end else begin
			for(II=0;II<WDEPTH;II=II+1)
				data[II]	<= data[II];
end end end

reg [DSIZE*NSIZE-1:0]		rd_data_reg;

always@(posedge rd_clk,negedge rst_n)begin:READ_BLOCK
integer KK;
	if(~rst_n)		rd_data_reg	<= DEF_VALUE;
	else begin
        for(KK=0;KK<NSIZE;KK=KK+1)
    	   rd_data_reg[(NSIZE-KK-1)*DSIZE+:DSIZE]    <= rd_en? data[rd_point*NSIZE+KK] : rd_data_reg[(NSIZE-KK-1)*DSIZE+:DSIZE];
end end
//---<< MEM >>-------------------
//--->> WR RD COUNTER <<---------
reg [5*NSIZE-1:0]	wr_cnt_reg,rd_cnt_reg;

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	wr_cnt_reg	<= 5'd0;
	else if(full_flag)
				wr_cnt_reg	<= DEPTH;
	else if(empty_flag)
				wr_cnt_reg	<= 5'd0;
	else if(wr_step^rd_step)
				wr_cnt_reg	<= (WDEPTH+wr_point)-(rd_point<<SFBIT);
	else		wr_cnt_reg	<= wr_point - (rd_point<<SFBIT);

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	rd_cnt_reg	<= 5'd0;
	else if(full_flag)
				rd_cnt_reg	<= DEPTH;
	else if(empty_flag)
				rd_cnt_reg	<= 5'd0;
	else if(wr_step^rd_step)
				rd_cnt_reg	<= (WDEPTH+wr_point)-(rd_point<<SFBIT);
	else		rd_cnt_reg	<= wr_point - (rd_point<<SFBIT);
//---<< WR RD COUNTER >>---------
//--->> LAST DATA <<-------------
// reg     last_reg;
// always@(posedge clock,negedge rst_n)
//     if(~rst_n)  last_reg    <= 1'b0;
//     else begin
//         if()
//--->> VALID <<-----------------
wire 	rd_en_lat2	;
latency #(
	.LAT		(1		),
	.DSIZE		(1		)
)latency_inst(
	.clk		(rd_clk			),
	.rst_n      (rst_n			),
	.d          (rd_en			),
	.q          (rd_en_lat2		)
);

assign	rd_vld	= rd_en_lat2 && !empty_flag;
// assign	rd_vld	= !empty_flag;
//---<< VALID >>-----------------

assign	wr_full			= full_flag;
assign	rd_empty		= empty_flag;
assign	wr_almost_full	= almost_full_flag;
assign	rd_almost_empty	= almost_empty_flag;

assign	rd_data		= rd_data_reg;

assign	wr_count	= wr_cnt_reg;
assign	rd_count	= rd_cnt_reg[5*NSIZE-1:SFBIT];

endmodule
