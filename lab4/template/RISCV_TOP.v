`include "immediate.v"
`include "ALU.v"
`include "ctrl.v"

module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN,
	input wire [31:0] I_MEM_DI,//input from IM
	output reg [11:0] I_MEM_ADDR,//in byte address

	//D-Memory Signals
	output wire D_MEM_CSN,
	input wire [31:0] D_MEM_DI,
	output wire [31:0] D_MEM_DOUT,
	output wire [11:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN,
	output wire [3:0] D_MEM_BE,

	//RegFile Signals
	output wire RF_WE,
	output wire [4:0] RF_RA1,
	output wire [4:0] RF_RA2,
	output wire [4:0] RF_WA1,
	input wire [31:0] RF_RD1,
	input wire [31:0] RF_RD2,
	output wire [31:0] RF_WD,
	output wire HALT,
	output reg [31:0] NUM_INST,
	output wire [31:0] OUTPUT_PORT
	);


	// TODO: implement multi-cycle CPU
	assign HALT = I_MEM_DI== 'h00c00093 || I_MEM_DI== 'h00008067;
	assign I_MEM_CSN = ~RSTn;

	reg	[2:0] state;	


	wire	[6:0] cond;
	wire	[2:0] next_state;
	wire	RegWrite;
	wire	MemWrite;
	wire	MemtoReg;
	wire	ALUCLK;
	wire	ALUEXA;
	wire	[1:0] ALUEXB;
	wire	ALUPC;
	wire	ALUc0;
	wire	[2:0] ALUOP;
	wire	imm_CLK;
	
	always @ (negedge CLK ) begin
		if (~RSTn) NUM_INST <= 0;
		else if ((state==3'b010)*cond[5]+~cond[5]*(state==3'b100)) NUM_INST <= NUM_INST + 1;
	end

	ctrl	ctrl0 (.instr(I_MEM_DI),
			.state(state),
			.cond(cond),
			.next_state(next_state),
			.RegWrite(RegWrite),
			.MemWrite(MemWrite),
			.MemtoReg(MemtoReg),
			.ALUCLK(ALUCLK),
			.ALU_EX_A(ALUEXA),
			.ALU_EX_B(ALUEXB),
			.ALU_PC(ALUPC),
			.ALUc0(ALUc0),
			.ALUOP(ALUOP),
			.imm_CLK(imm_CLK)
		);

	always @ (posedge CLK) begin
		if (~RSTn) begin
			state <=7;
			end
		else if ( state == 7) begin
			state <=3'b000;
			end
		else	state <= next_state;	
	end
/*	ID stage	*/
//	REG 
	assign RF_RA1	= I_MEM_DI[19:15];
	assign RF_RA2	= I_MEM_DI[24:20];
//	immediate
	wire	[31:0] imm;
	immediate	imm0 (.cond(cond), .instr(I_MEM_DI), .CLK(CLK&imm_CLK), .imm(imm));

/*	EX stage	*/
//	ALU-EX
	wire	[31:0] ALU_EX_A;
	wire	[31:0] ALU_EX_B;
	wire	[31:0] ALU_result;
	assign	ALU_EX_A = (ALUEXA) ? RF_RD1: I_MEM_ADDR;
	assign	ALU_EX_B = (ALUEXB==2'b00)*RF_RD2 + (ALUEXB==2'b01)*4 + (ALUEXB==2'b10)*imm;
	ALU	ALU_Ex	(.A(ALU_EX_A), .B(ALU_EX_B), .c0(ALUc0), .OP(ALUOP), .CLK(CLK * ALUCLK), .C(ALU_result));

	wire	Bcond;
	wire	[5:0] B_type_cond;
	assign	B_type_cond[0] = I_MEM_DI[14:12] == 3'b000;
	assign	B_type_cond[1] = I_MEM_DI[14:12] == 3'b001;
	assign	B_type_cond[2] = I_MEM_DI[14:12] == 3'b100;
	assign	B_type_cond[3] = I_MEM_DI[14:12] == 3'b101;
	assign	B_type_cond[4] = I_MEM_DI[14:12] == 3'b110;
	assign	B_type_cond[5] = I_MEM_DI[14:12] == 3'b111;
	wire	[2:0] B_sat_cond;
	assign	B_sat_cond[0] = RF_RD1==RF_RD2;
	assign	B_sat_cond[1] = $signed(RF_RD1)<$signed(RF_RD2);
	assign	B_sat_cond[2] = $unsigned(RF_RD1)<$unsigned(RF_RD2);		
	assign	Bcond = B_type_cond[0]*B_sat_cond[0]+B_type_cond[1]*(~B_sat_cond[1])+B_type_cond[2]*B_sat_cond[1]+B_type_cond[3]*(~B_sat_cond[1])+B_type_cond[4]*B_sat_cond[2]+B_type_cond[5]*(~B_sat_cond[2]);
//	ALU-PC
	wire	[31:0] ALU_PC_A;
	wire	[31:0] ALU_PC_B;
	wire	[31:0] next_PC;
	assign	ALU_PC_A = I_MEM_ADDR; //extend ADDR
	assign	ALU_PC_B = (ALUPC+cond[5]*Bcond) ? imm : 5'b00100;
	ALU	ALU_Pc	(.A(ALU_PC_A), .B(ALU_PC_B), .c0(1'b0), .OP(3'b000), .CLK(CLK*ALUCLK ), .C(next_PC) );

/*	MEM stage	*/
//	DMEM
	assign	D_MEM_CSN	= ~RSTn;
	assign	D_MEM_ADDR	= ALU_result[11:0];
	assign	D_MEM_DOUT	= RF_RD2;
	assign	D_MEM_WEN	= ~MemWrite;
	assign	D_MEM_BE	= 4'b1111;

/*	WB stage	*/
//	REG
	assign	RF_WE	= RegWrite;
	assign	RF_WA1	= I_MEM_DI[11:7];
	assign	RF_WD	= MemtoReg ? ALU_result : D_MEM_DI; 
	reg	[31:0] 	pre_output_port;
	reg	[31:0]	pre_o_p;
	always @ (negedge CLK) begin
		if (state != 3'b100) begin
			pre_o_p = (cond[5]) ? Bcond: RF_WD ;
			pre_output_port = (cond[3]) ? D_MEM_DI : pre_o_p;
		end

	end
	assign	OUTPUT_PORT = pre_output_port;

/*	IF stage 	*/
	always @ (negedge CLK ) begin
		if (~RSTn) I_MEM_ADDR <=0;	
		else if((state==3'b010)*cond[5]+~cond[5]*(state==3'b100)) I_MEM_ADDR <= next_PC[11:0];  //collide
	end	
	

endmodule //
