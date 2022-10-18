module SW
  (
  input clk,
  input start,
  input rst,
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
        2'b10:   out_signal = ~(out_signal & rst);
        2'b00:   out_signal = (out_signal & rst);
        2'b01:   out_signal = (out_signal & rst);
        2'b01:   out_signal = (out_signal & rst);
      endcase
    end
endmodule  