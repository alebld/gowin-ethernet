//Management Data Input/Output
//Before a register access, PHY devices generally require a preamble of 32 ones to be sent by the MAC on the MDIO line
//During a write command, the MAC provides address and data. For a read command, the PHY takes over the MDIO line during the turnaround bit times
//
//MDIO PackET FORMAT
//
//| PRE_32 |
//
//|   0 |  1 |  2 |  3 |   4 |  5 |  6 |  7 |  8 |   9 | 10 | 11 | 12 | 13 | 14 | 15 |
//|  ST |    | OP |    | PA5 |    |    |    |    | RA5 |    |    |    |    | TA |    |
//|  16 | 17 | 18 | 19 |  20 | 21 | 22 | 23 | 24 |  25 | 26 | 27 | 28 | 29 | 30 | 31 |
//| D16 |    |    |    |     |    |    |    |    |     |    |    |    |    |    |    |
//
//PRE_32 Preamble, 32 bits all '1'
//
//ST: start field '01'
//OP: read = '01', write = '10' {rw_i : 0 read, 1 write}
//PA5: 5 bits PHY address {phy_adr_i}
//RA5: 5 bits REGISTER address {reg_adr_i}
//TA: Turn around, '10' when writing, 'ZZ' when reading
//
//D16: data to read or write

module mdio_ct (
	     input	   rst_n, clk, we_i, cyc_i,
	     input [4:0]   phy_adr_i, reg_adr_i,
	     input [15:0]  tx_dat_i 
	     output	   ack_o,
	     output [15:0] rx_dat_o,
	     inout	   mdio;
	     );
   reg [7:0] count;
   reg [15:0] tx_dat;
   reg [15:0] rx_dat;

   assign mdio = rmdio ? 1'bZ : 1'b0;
   
   
   always_ff@(posedge clk or negedge rst_n) begin
      if (rst_n == 1'b0) begin
	 count <= 1'd0;
	 ack_o <= 1'b0;
      end else begin
	 count <= count + 1'd1;

	 if (count == 1'b0 and cyc_i == 1'b1) begin
	    ack_o <= 1'b0;
	    tx_dat <= {2'b01, we_i ? 2'b01 : 2'b10, phy_adr_i, reg_adr_i, we_i ? 2'b10 : 2'b11, we_i ? tx_dat_i : 16'hFFFF};
	 end
	 if (cyc_i == 1'b0) begin
	    ack_o <= 1'b0;
	    count <= 8'b0;
	 end

	 if (count > 31) begin
	    rmdio <= tx_dat[31];
	    tx_dat <= {tx_dat[30:0],1'b0};
	 end
	 
	 if (count > 48) begin
	    rx_dat <= {rx_dat[14:0],mdio};
	 end
	 
		      
	 if (count == 63) begin
	    ack_o <= 1'b1;
	 end
	 
      end
   end // always_ff@ (posedge clk or negedge rst_n)

   always_comb begin
      rx_dat_o <= we_i ? 16'hFFFF : rx_dat;
   end
   
endmodule // mdio

	 
      
      
   
   
