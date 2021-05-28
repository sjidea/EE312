module 	cache (
	input	wire	CLK,
	input 	wire	[11:0] T_addr,
	input	wire	T_wen,
	input	wire	[31:0] T_dout,
	input 	wire	[31:0] D_di,
	input	wire	type,

	output 	reg	[31:0] D_dout,
	output 	reg	[11:0] D_addr,
	output	reg	D_wen,
	output	reg	[31:0] T_di,
	output	wire	stall
);

	reg	wen;
	always	@(*) wen <= T_wen;  

	reg 	[135:0] cache[7:0];
	reg	[135:0] cache_blk;
	reg	[2:0] idx;
	reg	[1:0] g;
	reg	hit;
	reg	[31:0] data;
	reg	start;
	reg	[5:0]	i;

	initial begin
		cache[0]<=0;
		cache[1]<=0;
		cache[2]<=0;
		cache[3]<=0;
		cache[4]<=0;
		cache[5]<=0;
		cache[6]<=0;
		cache[7]<=0;
		i<=0;
	end
	
	always 	@(*) begin
		idx 	<= T_addr[4:2];
		g	<= T_addr[1:0];
		if (i==0) cache_blk <=  cache[idx];	//access cache
		hit	<= (T_addr[11:5]==cache_blk[135:129]) & cache_blk[128]; // valid & tag match
		case (g) 
			2'b00: data <= cache_blk[31:0];
			2'b01: data <= cache_blk[63:32];
			2'b10: data <= cache_blk[95:64];
			2'b11: data <= cache_blk[127:96];
		endcase
	end

	always	@(negedge CLK) begin
		if (i==0) begin
			if (type) begin
				if (hit) i <= (wen)? 1:7;
				else	 i <= (wen)? 6:12;
			end
		end
		if (i>0) i <= i-1;
	end
	
	reg	ri1;
	reg	ri2;
	always	@(posedge CLK) begin
		ri1<=(i==0);
		ri2<=(i>1);
	end
	always	@(*) start <= type * ri1;
	assign 	stall = start + ri2;

	//access data
	always	@(*) begin
		if (wen) begin	// load
			D_wen <= 1;
			if(i==6) D_addr <= T_addr[11:2]*4;
			if(i==5) D_addr <= T_addr[11:2]*4 +1;
			if(i==4) D_addr <= T_addr[11:2]*4 +2;
			if(i==3) D_addr <= T_addr[11:2]*4 +3;
		end
		else begin	//write allocate (load data)
			D_wen <= (i>6);
			if(i==12) D_addr <= T_addr[11:2]*4;
			if(i==11) D_addr <= T_addr[11:2]*4 +1;
			if(i==10) D_addr <= T_addr[11:2]*4 +2;
			if(i==9) D_addr <= T_addr[11:2]*4 +3;
			
			if(i==6) begin
				D_addr <= T_addr[11:2]*4;
				D_dout <= cache_blk[31:0];
			end
			if(i==5) begin
				D_addr <= T_addr[11:2]*4+1;
				D_dout <= cache_blk[63:32];
			end
			if(i==4) begin
				D_addr <= T_addr[11:2]*4+2;
				D_dout <= cache_blk[95:64];
			end
			if(i==3) begin
				D_addr <= T_addr[11:2]*4+3;
				D_dout <= cache_blk[127:96];
			end
		end
	end

	always @(posedge CLK) begin
		if (i==1) begin
			cache_blk[135:129] <= T_addr[11:5];
			cache_blk[128] <=1;
			if (wen) T_di <= data;
			//cache[idx] <= cache_blk;
		end
	end
	always @(*) begin
		if ((i==1) & CLK) cache[idx]<= cache_blk;
	end

	always	@(negedge CLK) begin
		if(wen) begin
			if (i==6) cache_blk[31:0] <= D_di;
			if (i==5) cache_blk[63:32] <= D_di;
			if (i==4) cache_blk[95:64] <= D_di;
			if (i==3) cache_blk[127:96] <= D_di;
		end
		else begin
			if (i==12) cache_blk[31:0] <= D_di;
			if (i==11) cache_blk[63:32] <= D_di;
			if (i==10) cache_blk[95:64] <= D_di;
			if (i==9) cache_blk[127:96] <= D_di;
			if (i==7) begin	//update cache_block
				case (g)
					2'b00: cache_blk[31:0] <= T_dout;
					2'b01: cache_blk[63:32] <= T_dout;
					2'b10: cache_blk[95:64] <= T_dout;
					2'b11: cache_blk[127:96] <= T_dout;
				endcase				
			end
		end
/*		if (i==1) begin
			cache_blk[135:129] <= T_addr[11:5];
			cache_blk[128] <=1;
			if (wen) T_di <= data;
			cache[idx] <= cache_blk;
		end
*/	end
endmodule

