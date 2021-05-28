module immediate(
	input	wire	[6:0] cond,
	input	wire	[31:0] instr,
	input	wire	CLK,
	output	reg	[31:0] imm
	);

	wire	[4:0] ty_cond;
	assign	ty_cond[0] = cond[1]+cond[2]+cond[3]; //I
	assign	ty_cond[1] = cond[4]; //S
	assign	ty_cond[2] = cond[5]; //B
	assign	ty_cond[3] = cond[6]; //JAL
	

	wire	[31:0] imm_0;//I
	assign imm_0[31:11]	= {21{instr[31]}};
	assign imm_0[10:0]	= instr[31:20];

	wire	[31:0] imm_1;//S
	assign imm_1[31:11]	= {21{instr[31]}};
	assign imm_1[10:5]	= instr[30:25];
	assign imm_1[4:0]	= instr[11:7];
	
	wire	[31:0] imm_2;//B
	assign imm_2[31:12]	= {20{instr[31]}};
	assign imm_2[11]		= instr[7];
	assign imm_2[10:5]	= instr[30:25];
	assign imm_2[4:1]		= instr[11:8];
	assign imm_2[0]		= 0;

	wire	[31:0] imm_3;//JAL
	assign imm_3[31:20]	= {12{instr[31]}};
	assign imm_3[19:12]	= instr[19:12];
	assign imm_3[11]	= instr[20];
	assign imm_3[10:1]	= instr[30:21];
	assign imm_3[0] 	= 1'b0;
	
	always @(*) begin
		imm <= ty_cond[0]*imm_0+ty_cond[1]*imm_1+ty_cond[2]*imm_2+ty_cond[3]*imm_3;
	end
endmodule
