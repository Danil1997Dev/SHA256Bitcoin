 
module COUNT #(
	parameter WIDTH = 64,
		  REL_USEC = 100,
		  REL_MSEC = 100,
		  REL_SEC = 100,
		  REL_MIN = 100,
		  REL_H = 100,
		  REL_DAY = 100,
		  W_USEC = $clog2(REL_USEC),
		  W_MSEC = $clog2(REL_MSEC),
		  W_SEC = $clog2(REL_SEC),
		  W_MIN = $clog2(REL_MIN),
		  W_H = $clog2(REL_H),
		  W_DAY = $clog2(REL_DAY)
) (
	input clk,
	input en,
	input tick,
	
	output reg [W_USEC-1:0] cnt_clk = 0,
	output reg [W_MSEC-1:0] cnt_usec = 0,
	output reg [W_SEC-1:0] cnt_msec = 0,
	output reg [W_MIN-1:0] cnt_sec = 0,
	output reg [W_H-1:0] cnt_min = 0,
	output reg [W_DAY-1:0] cnt_h = 0,
	output reg [3:0] cnt_day = 0
);
	reg [W_USEC-1:0] r_cnt_clk = 0;
	reg [W_MSEC-1:0] r_cnt_usec = 0;
	reg [W_SEC-1:0] r_cnt_msec = 0;
	reg [W_MIN-1:0] r_cnt_sec = 0;
	reg [W_H-1:0] r_cnt_min = 0;
	reg [W_DAY-1:0] r_cnt_h = 0;
	reg [3:0] r_cnt_day = 0;
	
	reg del_clk = 0; 
	reg del_usec = 0; 
	reg del_msec = 0; 
	reg del_sec = 0; 
	reg del_min = 0; 
	reg del_h = 0; 
	reg del_day = 0;
 
	always @ (posedge clk)
	begin 

		if (!en || tick)
		begin
			r_cnt_clk <= 0; 
			r_cnt_usec <= 0; 
			r_cnt_msec <= 0; 
			r_cnt_sec <= 0; 
			r_cnt_min <= 0; 
			r_cnt_h <= 0; 
			r_cnt_day <= 0;
			
			del_clk <= 0; 
			del_usec <= 0; 
			del_msec <= 0; 
			del_sec <= 0; 
			del_min <= 0; 
			del_h <= 0; 
			del_day <= 0;
		end
		else
		begin
		  if (r_cnt_clk == REL_USEC)
		    begin
			   r_cnt_clk <= 0;
				del_usec <= 1;
			 end
		  else
		    begin
			   r_cnt_clk <= r_cnt_clk + 1;
				del_usec <= 0;
			 end
			 
		  if (r_cnt_usec == REL_MSEC)
		    begin
			   r_cnt_usec <= 0;
				del_msec <= 1;
			 end
		  else
		    begin
			   r_cnt_usec <= r_cnt_usec + del_usec;
				del_msec <= 0;
			 end
			 
		  if (r_cnt_msec == REL_SEC)
		    begin
			   r_cnt_msec <= 0;
				del_sec <= 1;
			 end
		  else
		    begin
			   r_cnt_msec <= r_cnt_msec + del_msec;
				del_sec <= 0;
			 end
			 
		  if (r_cnt_sec == REL_MIN)
		    begin
			   r_cnt_sec <= 0;
				del_min <= 1;
			 end
		  else
		    begin
			   r_cnt_sec <= r_cnt_sec + del_sec;
				del_min <= 0;
			 end
			 
		  if (r_cnt_min == REL_H)
		    begin
			   r_cnt_min <= 0;
				del_h <= 1;
			 end
		  else
		    begin
			   r_cnt_min <= r_cnt_min + del_min;
				del_h <= 0;
			 end
			 
		  if (r_cnt_h == REL_DAY)
		    begin
			   r_cnt_h <= 0;
				del_day <= 1;
			 end
		  else
		    begin
			   r_cnt_h <= r_cnt_h + del_h;
				del_day <= 0;
			 end
		end
	end

	always @ (*)
	begin
		cnt_clk = r_cnt_clk;
		cnt_usec = r_cnt_usec;
		cnt_msec = r_cnt_msec;
		cnt_sec = r_cnt_sec;
		cnt_min = r_cnt_min;
		cnt_h = r_cnt_h;
		cnt_day = r_cnt_day;
	end
endmodule

