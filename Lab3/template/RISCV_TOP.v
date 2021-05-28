`include "immediate.v"
`include "ALU.v"

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
	output wire HALT,                   // if set, terminate program
	output reg [31:0] NUM_INST,         // number of instruction completed
	output wire [31:0] OUTPUT_PORT      // equal RF_WD this port is used for test
	);

	assign OUTPUT_PORT = RF_WD;

	initial begin
		NUM_INST <= 0;
	end

	// Only allow for NUM_INST
	always @ (negedge CLK) begin
		if (RSTn) NUM_INST <= NUM_INST + 1;
	end

	// TODO: implement
//////////////////////  IF stage  //////////////////////////////
	
	assign I_MEM_CSN = ~RSTn;
	assign HALT = I_MEM_DI== 'h00c00093 || I_MEM_DI== 'h00008067;

//////////////////////  ID stage  //////////////////////////////
	wire	[4:0] type;

	wire	[8:0] type_cond;
	assign type_cond[0] = I_MEM_DI[6:2]==5'b01100; //R	=1
	assign type_cond[1] = I_MEM_DI[6:2]==5'b00100; //I-ALU	=2
	assign type_cond[2] = I_MEM_DI[6:2]==5'b11001; //I-JALR	=3
	assign type_cond[3] = I_MEM_DI[6:2]==5'b00000; //I-Load	=4
	assign type_cond[4] = I_MEM_DI[6:2]==5'b01000; //S	=5
	assign type_cond[5] = I_MEM_DI[6:2]==5'b11000; //B	=6
	assign type_cond[6] = I_MEM_DI[6:2]==5'b01101; //U-LUI	=7
	assign type_cond[7] = I_MEM_DI[6:2]==5'b00101; //U-AUIPC=8
	assign type_cond[8] = I_MEM_DI[6:2]==5'b11011; //J	=9

	assign  type = type_cond[0]*1 +type_cond[1]*2+type_cond[2]*3+type_cond[3]*4+type_cond[4]*5+type_cond[5]*6+type_cond[6]*7+type_cond[7]*8+type_cond[8]*9; 
	
	//REG_FILE 
	assign RF_RA1 = I_MEM_DI[19:15];
	assign RF_RA2 = I_MEM_DI[24:20];
	assign RF_WA1 = I_MEM_DI[11:7];	
	
//////////////////////  EX stage  //////////////////////////////
	 //ALU (data) input rd1 and B

	//B ( rd2 or imm)
	wire	[31:0] B;
	wire	[31:0] imm;
	immediate I0 (.type(type), .instr(I_MEM_DI), .imm(imm));

	wire	cond0;
	assign	cond0 = type==1;
	assign B =  (cond0)?  RF_RD2  : imm;

	//OP and c0 of ALU
	wire	[2:0] OP;
	wire	c0;

	wire	cond1_1;
	wire	cond1_2;
	assign	cond1_1 = type==1 ;
	assign	cond1_2 = type==2 ; 
	assign	OP = (cond1_1|cond1_2)*I_MEM_DI[14:12] + (~cond1_1 & ~cond1_2)*3'b000;

	wire	cond2_1;
	wire	cond2_2;
	assign	cond2_1 = I_MEM_DI[14:12]==3'b000;
	assign	cond2_2 = I_MEM_DI[14:12]==3'b101;
	wire	cond1n2 = cond1_1*cond2_1+ cond1_1*cond2_2 + cond1_2*cond2_2;
	assign	c0= I_MEM_DI[30]*(cond1n2)+ (~cond1n2 )*1'b0;


	wire	[31:0] ALU_result;
	ALU	ALU1 (.A(RF_RD1), .B(B), .OP(OP), .c0(c0), .C(ALU_result));
	
//////////////////////  MEM stage  //////////////////////////////

	//DMEM
	assign D_MEM_CSN	= ~RSTn;
	assign D_MEM_DOUT 	= RF_RD2;
	
	assign D_MEM_ADDR	= ALU_result[11:0] ;
	
	assign D_MEM_WEN 	= type!=5 ;

	//for I-Load and S, defire BE
	wire	cond3;
	assign	cond3 = type==4 || type==5;
	wire	cond4;
	assign	cond4 = I_MEM_DI[14:12]==3'b000 || I_MEM_DI[14:12]==3'b100;
	wire	cond5;
	assign	cond5 = I_MEM_DI[14:12]==3'b001 || I_MEM_DI[14:12]==3'b101;
	wire	cond6;
	assign	cond6 = I_MEM_DI[14:12]==3'b010;

	assign 	D_MEM_BE = cond3*( cond4*4'b0001 + cond5*4'b0011 + cond6*4'b1111);

//////////////////////  WB stage  //////////////////////////////

	//control flow for is_4
	wire	cond7;
	assign	cond7 = type==6;
	wire	cond8;
	assign	cond8 = type!=6 && type!=7;
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

	wire	B_satisfy;
	assign	B_satisfy = B_type_cond[0]*B_sat_cond[0]+B_type_cond[1]*(~B_sat_cond[1])+B_type_cond[2]*B_sat_cond[1]+B_type_cond[3]*(~B_sat_cond[1])+B_type_cond[4]*B_sat_cond[2]+B_type_cond[5]*(~B_sat_cond[2]);
	
		
	wire	is_4;		// if B(satisfy condition) or LUI then 0 , else 1
	assign	is_4 = cond8 + cond7*~B_satisfy ;

	//sign extend PC  ( PC+4 or PC+sign_ext(imm) )
	wire	[31:0] A;
	wire	[31:0] ADDR;
	assign A = (is_4) ? 4: imm;		
	assign ADDR[31:12] = {20{I_MEM_ADDR[11]}};
	assign ADDR[11:0] = I_MEM_ADDR;


	//REG_FILE 
	assign RF_WE = (type==5 || type==6) ? 0:1;

	wire	[3:0] WD_cond;
	assign	WD_cond[0] = type==1 || type==2 || type==5; 	//OUTPUT_PORT for S is ALU_result
	assign	WD_cond[1] = type==3 || type==8 || type==9;	//WD is ALU_result
	assign	WD_cond[2] = type==7;				//WD is imm
	assign	WD_cond[3] = type==6; 				//OUTPUT_PORT for B is B_satisfy
	
	wire	[31:0] next_PC;
	ALU	ALU2 (.A(A), .B(ADDR), .OP(3'b000), .c0(1'b0), .C(next_PC));

	wire	[31:0] pre_WD;
	assign	pre_WD = WD_cond[0]*ALU_result+WD_cond[1]*next_PC+WD_cond[2]*imm+WD_cond[3]*B_satisfy +0;
	assign	RF_WD = (type!=4)? pre_WD : D_MEM_DI;		



//IF stage again (for next I_MEM_ADDR, sequential logic 

	wire	[11:0] JALR_PC;
	assign	JALR_PC[11:1] = imm[11:1];
	assign	JALR_PC[0] = 0;

	wire	[31:0] JAL_PC;
	ALU	ALU_J (.A(imm), .B(ADDR), .c0(1'b0), .OP(3'b000), .C(JAL_PC) );
	reg	[31:0] jal_PC;

	always @(negedge CLK) begin	// to prevent new I_MEM_ADDR interrupt JAL_PC value
		jal_PC = JAL_PC;
	end

	always @ (posedge CLK) begin
		if (NUM_INST==0) I_MEM_ADDR <=0;
		else I_MEM_ADDR = (type==3)*JALR_PC+ (type==9)*jal_PC[11:0]+ (type!=3 && type!=9)*next_PC[11:0];
	end

endmodule //

