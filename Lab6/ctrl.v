module	ctrl (
	input	wire	[31:0] instr, 
	input	wire	[2:0] state,
	//input	wire	stall,

	output	reg	[6:0] cond,
	output	reg	[2:0] next_state,
	output	reg	RegWrite,
	output	reg	MemWrite,
	output	reg	MemtoReg,
	output	reg	ALUCLK,
	output	reg	ALU_EX_A,
	output	reg	[1:0] ALU_EX_B,
	output	reg	ALU_PC,
	output	reg	ALUc0,
	output 	reg	[2:0] ALUOP,
	output	reg	imm_CLK
	);
	

	always @(*) begin
//	inst type
	case (instr[6:2])
		5'b01100 : cond <=7'b0000001; //R
		5'b00100 : cond <=7'b0000010; //I_ALU
		5'b11001 : cond <=7'b0000100; //I_JALR
		5'b00000 : cond <=7'b0001000; //L
		5'b01000 : cond <=7'b0010000; //S
		5'b11000 : cond <=7'b0100000; //B
		5'b11011 : cond <=7'b1000000; //JAL
		default : cond <= 0;
	endcase

//	comb. logic for next state
	next_state[2] = state[1] * ((state[2]*cond[3]) | ((~cond[5])*(~state[2])));
	next_state[1] = state[0] + ~state[2]*state[1]*(cond[3]+cond[4]);
	next_state[0] = state == 3'b000;
	
//	control signals
	RegWrite = (state==3'b100) * (~cond[4]*~cond[5]);
	MemtoReg = ~cond[3]; //approach MEM stage only for L or S 
	MemWrite = (state==3'b110)*cond[4];

	ALUCLK	= (state==3'b010);
	ALU_EX_A = cond[0]+cond[1]+cond[3]+cond[4]+cond[5];
	ALU_EX_B[1] = cond[1]+cond[3]+cond[4];
	ALU_EX_B[0] = cond[2]+cond[6]; 
	ALU_PC = cond[2]+cond[6];
	
	ALUc0 = (state==3'b010) * (cond[0]*(instr[14:12]==3'b000 | instr[14:12]==3'b101)*instr[30] | cond[1]*(instr[14:12]==3'b101)*instr[30]);
	ALUOP = (state==3'b010) * (cond[0]+cond[1]+cond[5])* instr[14:12];

	imm_CLK = state==3'b001;
	end
endmodule
