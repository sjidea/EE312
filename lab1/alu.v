`timescale 1ns / 100ps

module ALU(A,B,OP,C,Cout);
	
	input	[15:0]A;
	input	[15:0]B;
	input	[3:0]OP;
	output	[15:0]C;
	output	Cout;

/*	reg and wires	*/
	reg	[15:0]C;
	reg	Cout;

	reg	c;
	reg	dum;

/*	initial		*/
	initial Cout = 0;

/*	reading opcode and operation	*/
	always @(A,B,OP) begin
	case (OP)
		4'b0000: begin	
				{dum, C} = A + B;
				Cout = ~A[15] & ~B[15] & C[15] | A[15] & B[15] & ~C[15];
			end
		4'b0001: begin
				{dum, C} = A - B;
				Cout = ~A[15] & B[15] & C[15] | A[15] & ~B[15] & ~C[15];
			end
		4'b0010: C = A & B;
		4'b0011: C = A | B;
		4'b0100: C = ~( A & B );
		4'b0101: C = ~( A | B );
		4'b0110: C = A ^ B;
		4'b0111: C = A ~^ B;
		4'b1000: C = A;
		4'b1001: C = ~A;
		4'b1010: begin
				C[15] 	<= 0;
				C[14:0]	<= A[15:1];
			end
		4'b1011: begin
				C[15]	<= A[15];
				C[14:0]	<= A[15:1];
			end
		4'b1100: begin	 
				C[15]	<= A[0];
				C[14:0] <= A[15:1];
			end
		4'b1101: begin	 
				C[15:1]	<= A[14:0];
				C[0]	<= 0;
			end
		4'b1110: begin
				C[15:1]	<= A[14:0];
				C[0]	<= 0;
			end
		4'b1111: begin 
				C[15:1]	<= A[14:0];
				C[0] 	<= A[15];
			end
		
	endcase
	end
endmodule



