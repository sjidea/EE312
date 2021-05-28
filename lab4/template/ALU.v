module 	ALU (
	input	wire	[31:0] A,
	input	wire	[31:0] B,
	input	wire	c0,
	input	wire	[2:0] OP,
	input	wire	CLK,

	output	reg	[31:0] C
	);

	reg	[4:0] shtamt;
	reg	[4:0] i;
	reg	[32:0] uA;
	reg	[32:0] uB;
	reg	[32:0] pre_C;
	
	always @(posedge CLK)  begin
	shtamt = B[4:0];

	case (OP)
		3'b000 : begin				//ADD and SUB
			if (c0==0) begin
				pre_C = A+B;
				C = pre_C[31:0];
			end
			else		C = A-B;
			end
		3'b001 : begin					//SLL
			C = A << shtamt;
			end
		3'b010 : C <= ($signed(A)<$signed(B)) ? 1:0;	//SLT
		3'b011 : begin					//SLTU
			uA = { 1'b0, A};
			uB = { 1'b0, B};
			C = (A<B)? 1:0;
			end
		3'b100 : C = A^B;				//XOR
		3'b101 : begin					//SRL and SRA
			assign	shtamt = B[4:0];
			C =(c0 ==1)? A >>> shtamt : A >>shtamt;
		end	
		3'b110 : C = A|B;				//OR
		3'b111 : C = A&B;				//AND
	endcase
	end



endmodule
