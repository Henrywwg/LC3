module VGA(
	input clk,
	input rst_n,
	input [7:0]img_reg,
	
	output [3:0]red,
	output [3:0]green,
	output [3:0]blue,
	output vsync,
	output hsync,
	output logic active
);

	parameter H_A_VID = 640;
	parameter H_F_PORCH = 16;
	parameter H_SYNC = 96;
	parameter H_B_PORCH = 48;
	parameter H_TOT = H_A_VID + H_F_PORCH + H_SYNC + H_B_PORCH;
	parameter H_CNTR_BIT_SIZE = $clog2(H_TOT);


	parameter V_A_VID = 480;
	parameter V_F_PORCH = 11;
	parameter V_SYNC = 2;
	parameter V_B_PORCH = 31;
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
		else if(h_cntr == H_TOT - 1)
			h_cntr <= '0;
		else
			h_cntr <= h_cntr + 1;
	end
	
	assign VGA_HS = ~((H_A_VID + H_F_PORCH + H_SYNC > h_cntr) & (h_cntr >= H_A_VID + H_F_PORCH));
	
	////////////////////////
	//  Vertical Counter  //
	////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			v_cntr <= '0;
		else if(v_cntr == V_TOT - 1)
			v_cntr <= '0;
		else if(h_cntr == H_TOT - 1)		//increment v_cntr when h_cntr row finishes
			v_cntr <= v_cntr + 1;
	end
	
	assign VGA_VS = ~((V_A_VID + V_F_PORCH + V_SYNC > v_cntr) & (v_cntr >= V_A_VID + V_F_PORCH));
	
	////////////////////
	//  Video Output  //
	////////////////////
	assign active = (h_cntr < H_A_VID) & (v_cntr < V_A_VID);
	
	//Only green and blue? In 12 bit color? How queer...
	//Guess we doin amber now
	
	assign red[3:0] 	= active ? 4'hF : 0; //img_reg[7:4];	
	assign green[3:0] 	= active ? 4'hC : 0; //img_reg[3:0];
	assign blue[3:0] 	= '0;

endmodule
