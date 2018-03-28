	`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"
`include "newGame.v"
`include "ps2controller.v"

module DE2Tron(
    CLOCK_50,    // On Board 50 MHz
    PS2_KBCLK,
    PS2_KBDAT,

	 HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,

    // The ports below are for the VGA output.  Do not change.
    VGA_CLK,       //    VGA Clock
    VGA_HS,        //    VGA H_SYNC
    VGA_VS,        //    VGA V_SYNC
    VGA_BLANK_N,   //    VGA BLANK
    VGA_SYNC_N,    //    VGA SYNC
    VGA_R,         //    VGA Red[9:0]
    VGA_G,         //    VGA Green[9:0]
    VGA_B         //    VGA Blue[9:0]
    );

	 output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
	 
	 hex_display h7(p4[14:11], HEX7[6:0]);
	 hex_display h6(p4[10:7], HEX6[6:0]);
	 hex_display h5(p4[6:4], HEX5[6:0]);
	 hex_display h4(p4[3:0], HEX4[6:0]);

	 hex_display h3(p2[14:11], HEX3[6:0]);
	 hex_display h2(p2[10:7], HEX2[6:0]);
	 hex_display h1(p2[6:4], HEX1[6:0]);
	 hex_display h0(p2[3:0], HEX0[6:0]);
	 
    input PS2_KBCLK, PS2_KBDAT;
    input           CLOCK_50;    //    50 MHz

    // Declare your inputs and outputs here
    // Do not change the following outputs
    output             VGA_CLK;       //    VGA Clock
    output             VGA_HS;        //    VGA H_SYNC
    output             VGA_VS;        //    VGA V_SYNC
    output             VGA_BLANK_N;   //    VGA BLANK
    output             VGA_SYNC_N;    //    VGA SYNC
    output    [9:0]    VGA_R;         //    VGA Red[9:0]
    output    [9:0]    VGA_G;         //    VGA Green[9:0]
    output    [9:0]    VGA_B;         //    VGA Blue[9:0]


  keyboard kb(
    .CLOCK_50(CLOCK_50),
    .PS2_KBCLK(PS2_KBCLK),

    .PS2_KBDAT(PS2_KBDAT),
    .KEY_PRESSED(KEY_PRESSED)
    );

  wire [4:0] KEY_PRESSED;
  wire clonke;

  wire [14:0] p1, p2, p3, p4;
  /*
  always@(posedge clonke) begin
    p1 = p1 - 1'b1; // start bottom right, move up
    //p2 = p2 + 1'b1; // start top left, move down
    //p3 = p3 - 8'b10000000;// start top right, move left
    //p4 = p4 + 8'b10000000; // start bottom left, move right
  end  */

  //assign p3 = players.p3;
  //assign p4 = players.p4;


  game g(
    .CLOCK_50(CLOCK_50),
    .clonke(clonke),
    .KEY_PRESSED(KEY_PRESSED),
	 .p1(p1),
	 .p2(p2),
	 .p3(p3),
	 .p4(p4)
    );


  control c(
    .CLOCK_50(CLOCK_50),
    .ld_p1(ld_p1),
    .ld_p2(ld_p2),
    .ld_p3(ld_p3),
    .ld_p4(ld_p4)
    );

  wire ld_p1, ld_p2, ld_p3, ld_p4;

  datapath d(
    .CLOCK_50(CLOCK_50),
    .ld_p1(ld_p1),
    .ld_p2(ld_p2),
    .ld_p3(ld_p3),
    .ld_p4(ld_p4),
    .p1(p1[14:0]),
    .p2(p2[14:0]),
    .p3(p3[14:0]),
    .p4(p4[14:0]),
    .x(x),
    .y(y),
    .colour(colour)
    );



  wire [2:0] colour;
  wire [7:0] x;
  wire [6:0] y;

  wire resetn;
  assign resetn = 1'b1; // assign resetn = something to clear the display
  wire writeEn;
  assign writeEn = 1'b1; // for now

  vga_adapter VGA(
          .resetn(resetn),
          .clock(CLOCK_50),
          .colour(colour),
          .x(x),
          .y(y),
          .plot(writeEn),
          /* Signals for the DAC to drive the monitor. */
          .VGA_R(VGA_R),
          .VGA_G(VGA_G),
          .VGA_B(VGA_B),
          .VGA_HS(VGA_HS),
          .VGA_VS(VGA_VS),
          .VGA_BLANK(VGA_BLANK_N),
          .VGA_SYNC(VGA_SYNC_N),
          .VGA_CLK(VGA_CLK));
      defparam VGA.RESOLUTION = "160x120";
      defparam VGA.MONOCHROME = "FALSE";
      defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
      defparam VGA.BACKGROUND_IMAGE = "background.mif";

endmodule


module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [6:0] OUT;

	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;

			default: OUT = 7'b0111111;
		endcase

	end
endmodule


module datapath(
  CLOCK_50,
  ld_p1, ld_p2, ld_p3, ld_p4,
  p1, p2, p3, p4,
  x, y,
  colour
  );

  input CLOCK_50;
  input ld_p1, ld_p2, ld_p3, ld_p4;

  input [14:0] p1, p2, p3, p4; // location information for players

  output reg [7:0] x;
  output reg [6:0] y;
  output reg [2:0] colour;

  always@(posedge CLOCK_50)
  begin

    if (ld_p1)
      begin
        x <= p1[14:7];
        y <= p1[6:0];
        colour <= 3'b001;
      end

    else if (ld_p2)
      begin
        x <= p2[14:7];
        y <= p2[6:0];
        colour <= 3'b010;
      end

    else if (ld_p3)
      begin
        x <= p3[14:7];
        y <= p3[6:0];
        colour <= 3'b100;
      end

    else if (ld_p4)
      begin
        x <= p4[14:7];
        y <= p4[6:0];
        colour <= 3'b110;
      end

  end

endmodule


module control(
  CLOCK_50,
  ld_p1, ld_p2, ld_p3, ld_p4
  );

  input CLOCK_50;
  output reg ld_p1, ld_p2, ld_p3, ld_p4;

  reg [4:0] current_state, next_state;

  localparam  DRAW_P1 = 5'd0,
              DRAW_P2 = 5'd1,
              DRAW_P3 = 5'd2,
              DRAW_P4 = 5'd3;

  always@(*)
  begin: state_table
    case (current_state)
      DRAW_P1 : next_state = DRAW_P2;
      DRAW_P2 : next_state = DRAW_P3;
      DRAW_P3 : next_state = DRAW_P4;
      DRAW_P4 : next_state = DRAW_P1;
      default : next_state = DRAW_P1;
    endcase
  end

  always@(*)
  begin: enable_signals
    ld_p1 = 0;
    ld_p2 = 0;
    ld_p3 = 0;
    ld_p4 = 0;
    case (current_state)
      DRAW_P1 : begin
          ld_p1 = 1;
        end
      DRAW_P2 : begin
          ld_p2 = 1;
        end
      DRAW_P3 : begin
          ld_p3 = 1;
        end
      DRAW_P4 : begin
          ld_p4 = 1;
        end
    endcase
  end

  always@(posedge CLOCK_50)
  begin: state_FFS
    current_state <= next_state;
  end
endmodule
