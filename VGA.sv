module VGA(
	input clk,
	input rst_n,
	input img_reg,
	
	output [3:0]red,
	output [3:0]green,
	output [3:0]blue,
	output VGA_VS,
	output VGA_HS,
	output active
);

	parameter H_A_VID = 800;
	parameter H_F_PORCH = 56;
	parameter H_SYNC = 120;
	parameter H_B_PORCH = 64;
	parameter H_TOT = H_A_VID + H_F_PORCH + H_SYNC + H_B_PORCH;
	parameter H_CNTR_BIT_SIZE = $clog2(H_TOT);


	parameter V_A_VID = 600;
	parameter V_F_PORCH = 37;
	parameter V_SYNC = 6;
	parameter V_B_PORCH = 23;
	parameter V_TOT = V_A_VID + V_F_PORCH + V_SYNC + V_B_PORCH;
	parameter V_CNTR_BIT_SIZE = $clog2(V_TOT);

	//Counters for vertical and horizontal timings
	logic [H_CNTR_BIT_SIZE - 1:0]h_cntr;
	logic [V_CNTR_BIT_SIZE - 1:0]v_cntr;
	
	//////////////////////////
	//  Horizontal Counter  //
	//////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			h_cntr <= '0;
		else if(h_cntr == H_TOT - 1'b1)
			h_cntr <= '0;
		else
			h_cntr <= h_cntr + 1'b1;
	end
	
	assign VGA_HS = ~((H_A_VID + H_F_PORCH + H_SYNC > h_cntr) & (h_cntr >= H_A_VID + H_F_PORCH));
	
	////////////////////////
	//  Vertical Counter  //
	////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			v_cntr <= '0;
		else if(v_cntr == V_TOT - 1'b1)
			v_cntr <= '0;
		else if(h_cntr == H_TOT - 1'b1)		//increment v_cntr when h_cntr row finishes
			v_cntr <= v_cntr + 1'b1;
	end
	
	assign VGA_VS = ~((V_A_VID + V_F_PORCH + V_SYNC > v_cntr) & (v_cntr >= V_A_VID + V_F_PORCH));
	
	////////////////////
	//  Video Output  //
	////////////////////
	assign active = (h_cntr - 1'b1 < H_A_VID) & (v_cntr < V_A_VID);
	
	//Only green and red? In 12 bit color? How queer...
	//Guess we doin amber now
	
	assign red[3:0] 	= (active & img_reg) ? 4'hF : '0; //img_reg[7:4];	
	assign green[3:0] 	= (active & img_reg) ? 4'h8 : '0; //img_reg[3:0];
	assign blue[3:0] 	= '0;

endmodule
