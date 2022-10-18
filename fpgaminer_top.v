/*
*
* Copyright (c) 2011 fpgaminer@bitcoin-mining.com
*
*
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* 
*/

`timescale 1ns/1ps

`define SIM_STLA
`define CycloneV 1
//`define Zinq7000 1

`define CONFIG_LOOP_LOG2 0

module fpgaminer_top #(
	parameter WIDTH = 64,
		  DUFF = 32,
		  CLK_FRQ = 100_000_000,
		  REL_USEC = CLK_FRQ/1_000_000,
		  REL_MSEC = 1_000,
		  REL_SEC = 1_000,
		  REL_MIN = 60,
		  REL_H = 60,
		  REL_DAY = 24,
		  W_USEC = $clog2(REL_USEC),
		  W_MSEC = $clog2(REL_MSEC),
		  W_SEC = $clog2(REL_SEC),
		  W_MIN = $clog2(REL_MIN),
		  W_H = $clog2(REL_H),
		  W_DAY = $clog2(REL_DAY) 
)(osc_clk, RxD, TxD,reset_in
 ,HASH_o,clk_o, UP,LED,
 cnt_clk,
 cnt_usec,
 cnt_msec,
 cnt_sec,
 cnt_min,
 cnt_h,
 cnt_day
 
	//, segment, disp_switch
	);
	
	// The LOOP_LOG2 parameter determines how unrolled the SHA-256
	// calculations are. For example, a setting of 1 will completely
	// unroll the calculations, resulting in 128 rounds and a large, fast
	// design.
	//
	// A setting of 2 will result in 64 rounds, with half the size and
	// half the speed. 3 will be 32 rounds, with 1/4th the size and speed.
	// And so on.
	//
	// Valid range: [0, 5]
`ifdef CONFIG_LOOP_LOG2
	parameter LOOP_LOG2 = `CONFIG_LOOP_LOG2;
`else
	parameter LOOP_LOG2 = 0;
`endif

	// No need to adjust these parameters
	localparam [5:0] LOOP = (6'd1 << LOOP_LOG2);
	// The nonce will always be larger at the time we discover a valid
	// hash. This is its offset from the nonce that gave rise to the valid
	// hash (except when LOOP_LOG2 == 0 or 1, where the offset is 131 or
	// 66 respectively).
	localparam [31:0] GOLDEN_NONCE_OFFSET = (32'd1 << (6 - LOOP_LOG2)) + 32'd1;
	
	output [W_USEC-1:0] cnt_clk;
	output [W_MSEC-1:0] cnt_usec;
	output [W_SEC-1:0] cnt_msec;
	output [W_MIN-1:0] cnt_sec;
	output [W_H-1:0] cnt_min;
	output [W_DAY-1:0] cnt_h;
	output [3:0] cnt_day;
	

	input osc_clk,UP;
   input reset_in;
	wire reset;
	output [1:0]LED; 
	reg [23:0]test_cnt;
	reg [255:0] state = 0;
	reg [511:0] data = 0;
   	reg [31:0] 	    nonce = 32'h00000000;

	wire [255:0] hash, hash2; 
	reg [5:0] cnt = 6'd0;
	reg feedback = 1'b0;

	reg [255:0] midstate_buf = 0, data_buf = 0;
	wire [255:0] midstate_vw, data2_vw;
	reg [31:0] golden_nonce = 0;
   	reg 		   serial_send;
	wire 	   serial_busy;

  	wire [55:0] 	 segment_data;
 
	assign reset = !reset_in;

	//// 
   wire hash_clk;
   output clk_o;
	assign clk_o = hash_clk;
  wire [511:0] heder;
  	wire [1:0] i;
	
	
	assign LED[1:0] = i;
	//// PLL
	
	
	
	`ifdef CycloneV
	
     cv_pll pll(
							.refclk(osc_clk),   //  refclk.clk
							.rst(1'b0),      //   reset.reset
							.outclk_0(hash_clk), // outclk0.clk
							.locked()    //  locked.export
	);    
	
	`elsif Zinq7000
	
	pll_xlx pll_xlx_inst
 ( 
  .clk_out1(hash_clk),
  .reset(0),
  .locked(), 
  .clk_in1(osc_clk)
 );  
	
	`else
	
		assign hash_clk = osc_clk;
	`endif


	always @(posedge osc_clk)
		test_cnt<=test_cnt+1;

	//// Hashers


	sha256_transform #(.LOOP(LOOP)) uut (
		.clk(hash_clk),
		.feedback(feedback),
		.cnt(cnt),
		.rx_state(state),
		.rx_input(data),
		.tx_hash(hash)
	);
	sha256_transform #(.LOOP(LOOP)) uut2 (
		.clk(hash_clk),
		.feedback(feedback),
		.cnt(cnt),
		.rx_state(256'h5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667),
		.rx_input({256'h0000010000000000000000000000000000000000000000000000000080000000, hash}),
		.tx_hash(hash2)
	);


	//// Virtual Wire Control


   input 	     RxD;
   
   serial_receive #(.CLK_FRQ(CLK_FRQ)) serrx (.clk(hash_clk), .RxD(RxD), .midstate(midstate_vw), .data2(data2_vw));
   
	//// Virtual Wire Output

   output 	   TxD;

   serial_transmit #(.CLK_FRQ(CLK_FRQ)) sertx (.clk(hash_clk), .TxD(TxD), .send(serial_send), .busy(serial_busy), .word(golden_nonce));
   

	//// Control Unit
	reg is_golden_ticket = 1'b0;
	reg feedback_d1 = 1'b1;
	wire [5:0] cnt_next;
	wire [31:0] nonce_next;
	wire feedback_next;
 

	assign cnt_next =  reset ? 6'd0 : (LOOP == 1) ? 6'd0 : (cnt + 6'd1) & (LOOP-1);
	// On the first count (cnt==0), load data from previous stage (no feedback)
	// on 1..LOOP-1, take feedback from current stage
	// This reduces the throughput by a factor of (LOOP), but also reduces the design size by the same amount
	assign feedback_next = (LOOP == 1) ? 1'b0 : (cnt_next != 0);
	assign nonce_next =reset ? 32'd0 :feedback_next ? nonce : (nonce + 32'd1);

   output reg [255:0] HASH_o;
   always @ (posedge hash_clk)
	  begin 
			  HASH_o = hash2; 
	  end
	
	
	always @ (posedge hash_clk)
	begin
		`ifdef SIM_STLA
			//midstate_buf <= heder[256-1:0];
			//data_buf <= heder[512-1:256];
			//nonce <= heder[256+96+32-1:256+96];
			midstate_buf <= 256'h6a916935733da33c92d327943984e648d53fd1391f180a6cc0585e5b536ebbfc;//modific
			data_buf <= {128'd0,32'd0,32'h1903a30c,32'd1388185914,32'he648d53f};//modific
			nonce <= data_buf[127:96];
		`else
			midstate_buf <= midstate_vw;
			data_buf <= data2_vw;
		`endif

		cnt <= cnt_next;
		feedback <= feedback_next;
		feedback_d1 <= feedback;

		// Give new data to the hasher
		state <= midstate_buf;
		data <= {384'h000002800000000000000000000000000000000000000000000000000000000000000000000000000000000080000000, nonce_next, data_buf[95:0]};
		nonce <= nonce_next; 

		// Check to see if the last hash generated is valid.
		is_golden_ticket <= (hash2[255:255-DUFF] == {DUFF{1'b0}} || (nonce == 32'hFFFFFFFF)) && !feedback_d1;//224 32'h00000000
		if(is_golden_ticket)
		begin
			// TODO: Find a more compact calculation for this
			if (LOOP == 1)
                golden_nonce <= nonce - 32'd133; //32'd131;
			else if (LOOP == 2)
				golden_nonce <= nonce - 32'd66;
			else
				golden_nonce <= nonce - GOLDEN_NONCE_OFFSET;

		   if (!serial_busy) serial_send <= 1;
		end // if (is_golden_ticket)
		else
		  serial_send <= 0;
	   
`ifdef SIM
		if (!feedback_d1)
			$display ("nonce: %8x\nhash2: %64x\n", nonce-GOLDEN_NONCE_OFFSET-3, hash2);
`endif
	end
	
`ifdef CycloneV

	COUNT # (.WIDTH(WIDTH),.REL_USEC(REL_USEC),.REL_MSEC(REL_MSEC),.REL_SEC(REL_SEC),.REL_MIN(REL_MIN),.REL_H(REL_H),.REL_DAY(REL_DAY)) cnt_inst (
						 .clk(hash_clk),
						 .en(1),
						 .tick(is_golden_ticket),
						 .cnt_clk(cnt_clk),
						 .cnt_usec(cnt_usec),
						 .cnt_msec(cnt_msec),
						 .cnt_sec(cnt_sec),
						 .cnt_min(cnt_min),
						 .cnt_h(cnt_h),
						 .cnt_day(cnt_day)
						 ); 

`endif


  /*
  test_heder gen_hed( 
	.UP(!UP),
	.reset(reset),
	.clk(hash_clk),
	.nonce(nonce),
	.heder(heder),
	.i_o(i)
  );
 */
   // die debuggenlichten
   
   //output [55:0] segment;
   //input 	 disp_switch;



   // inverted signals, so 1111.. to turn it off
   //assign segment = disp_switch? segment_data : {56{1'b1}};
	//hexdisp disp(.inword(golden_nonce), .outword(segment_data));
   
endmodule

