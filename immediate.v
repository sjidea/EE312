module immediate(
	input reg	[4:0] type
,	input wire	[31:0] instr
,	output wire	[31:0] imm
);
//initial begin
	wire	[4:0] ty_cond;
	assign	ty_cond[0] = type==2||type==3||type==4;
	assign	ty_cond[1] = type==5;
	assign	ty_cond[2] = type==6;
	assign	ty_cond[3] = type==7||type==8;
	assign 	ty_cond[4] = type==9;

	wire	[31:0] imm_0;
	assign imm_0[31:11]	= {21{instr[31]}};
	assign imm_0[10:0]	= instr[31:20];

	wire	[31:0] imm_1;
	assign imm_1[31:11]	= {21{instr[31]}};
	assign imm_1[10:5]	= instr[30:25];
	assign imm_1[4:0]	= instr[11:7];
	
	wire	[31:0] imm_2;
	assign imm_2[31:12]	= {20{instr[31]}};
	assign imm_2[11]		= instr[7];
	assign imm_2[10:5]	= instr[30:25];
	assign imm_2[4:1]		= instr[11:8];
	assign imm_2[0]		= 0;

	wire	[31:0] imm_3;
	assign imm_3[31:12]	= instr[31:12];
	assign imm_3[11:0]	= 12'b000000000000;

	wire	[31:0] imm_4;
	assign imm_4[31:20]	= {12{instr[31]}};
	assign imm_4[19:12]	= instr[19:12];
	assign imm_4[11]	= instr[20];
	assign imm_4[10:1]	= instr[30:21];
	assign imm_4[0] 	= 1'b0;
	
	
	assign imm= ty_cond[0]*imm_0+ty_cond[1]*imm_1+ty_cond[2]*imm_2+ty_cond[3]*imm_3+ty_cond[4]*imm_4;
	
endmodule
			