module KEY
  (
  input clk,
  input start, 
  output logic out_signal=0
  );
  logic [1:0] mem_key=0;

  always_ff @( posedge clk )
    begin
      mem_key <= {mem_key[0],~start};
    end
	 
  always @(*)
    begin 
      case ( mem_key )
        2'b10:   out_signal = 1;
        2'b00:   out_signal = 0;
        2'b01:   out_signal = 0;
        2'b01:   out_signal = 0;
      endcase
    end
endmodule  