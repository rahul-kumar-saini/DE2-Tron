`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"
`include "game_files/mechanics.v"
`include "game_files/ps2controller.v"
`include "game_files/ram32768x3.v"

module TurfWars(
    CLOCK_50,    // On Board 50 MHz
    PS2_KBCLK, PS2_KBDAT,

    VGA_CLK,
    VGA_HS, VGA_VS,
    VGA_BLANK_N, VGA_SYNC_N,
    VGA_R, VGA_G, VGA_B
  );

  /*
    This is the main module of the game and should be used as the top level
    module when creating the project using Quartus or other software.
  */


  input PS2_KBCLK, PS2_KBDAT;
  input CLOCK_50;

  output             VGA_CLK;       //    VGA Clock
  output             VGA_HS;        //    VGA H_SYNC
  output             VGA_VS;        //    VGA V_SYNC
  output             VGA_BLANK_N;   //    VGA BLANK
  output             VGA_SYNC_N;    //    VGA SYNC
  output    [9:0]    VGA_R;         //    VGA Red[9:0]
  output    [9:0]    VGA_G;         //    VGA Green[9:0]
  output    [9:0]    VGA_B;         //    VGA Blue[9:0]


  // instantiate the keyboard module for keyboard input
  keyboard kb(
    .CLOCK_50(CLOCK_50),
    .PS2_KBCLK(PS2_KBCLK),
    .PS2_KBDAT(PS2_KBDAT),
    .KEY_PRESSED(KEY_PRESSED)
  );

  // Space bar only needs to be used once in the game and is assigned here
  wire space_pressed;
  assign space_pressed = KEY_PRESSED == 5'd16;

  wire [4:0] KEY_PRESSED;
  wire clock25, clonke, timer;

  RateDivider div(CLOCK_50, clock25, clonke, timer);

  wire [14:0] p1, p2, p3, p4;

  move m(
    .clonke(clonke),
    .running(running),
    .game_started(game_started),
    .p1d(p1d),
    .p2d(p2d),
    .p3d(p3d),
    .p4d(p4d),
    .p1(p1),
    .p2(p2),
    .p3(p3),
    .p4(p4)
  );

  wire [2:0] p1d, p2d, p3d, p4d;

  directions d(
    .CLOCK_50(CLOCK_50),
    .KEY_PRESSED(KEY_PRESSED),
    .p1d(p1d),
    .p2d(p2d),
    .p3d(p3d),
    .p4d(p4d)
  );

  wire wren; // 1 : write data to the ram, 0 : don't write data to the ram
  wire [14:0] address;//, address1; // 15 bits, 8 X bits, 7 Y bits
  wire [2:0] out; // data in the ram at the given address (3 bits)
  wire [2:0] data; // data to be written (3 bits)

  ram32768x3 ram(
    .address(address),
    .clock(CLOCK_50),
    .data(data),
    .wren(wren),
    .q(out)
  );

  wire [11:0] ordered_colours;
  wire [14:0] p1_count, p2_count, p3_count, p4_count;
  wire running, game_started, done_ordering;

  update_ram update(
    .clock25(clock25),
    .running(running),
    .address(address),
    .wren(wren),
    .data_to_ram(data),
    .ram_output(out),
    .p1(p1),
    .p2(p2),
    .p3(p3),
    .p4(p4),
    .p1_count(p1_count),
    .p2_count(p2_count),
    .p3_count(p3_count),
    .p4_count(p4_count),
    .done_ordering(done_ordering),
    .ordered_colours(ordered_colours)
  );

  // Main game running modules below

  control c(
    .space_pressed(space_pressed),
    .CLOCK_50(CLOCK_50),
    .running(running),
    .ld_p1(ld_p1),
    .ld_p2(ld_p2),
    .ld_p3(ld_p3),
    .ld_p4(ld_p4),
    .reset_state(reset_state),
    .reset_inc_state(reset_inc_state),
    .reset_wait_state(reset_wait_state),
    .ld_timer(ld_timer),
    .done(done),
    .game_started(game_started),
    .done_ordering(done_ordering),
    .done_waiting(done_waiting),
    .draw_bars(draw_bars),
    .increment_bars(increment_bars),
    .done_bars(done_bars),
    .done_bar_wait(done_bar_wait),
    .wait_bars(wait_bars),
    .starting(starting),
    .ld_one(ld_one),
    .ld_two(ld_two),
    .ld_three(ld_three),
    .ld_four(ld_four),
    .done_numbers(done_numbers),
    .decrement_pixel(decrement_pixel),
    .inc_number_positions(inc_number_positions)
  );

  wire ld_p1, ld_p2, ld_p3, ld_p4, ld_timer;
  wire reset_state, reset_inc_state, done, reset_wait_state;

  wire ld_one, ld_two, ld_three, ld_four, inc_number_positions;
  wire decrement_pixel, done_numbers, done_waiting;

  wire draw_bars, increment_bars, done_bars;
  wire starting, done_bar_wait, wait_bars;

  datapath dp(
    .CLOCK_50(CLOCK_50),
    .clonke(clonke),
    .timer(timer),
    .ld_p1(ld_p1),
    .ld_p2(ld_p2),
    .ld_p3(ld_p3),
    .ld_p4(ld_p4),
    .ld_timer(ld_timer),
    .reset_state(reset_state),
    .reset_inc_state(reset_inc_state),
    .reset_wait_state(reset_wait_state),
    .starting(starting),
    .done_waiting(done_waiting),
    .p1(p1),
    .p2(p2),
    .p3(p3),
    .p4(p4),
    .x(x),
    .y(y),
    .colour(colour),
    .running(running),
    .game_started(game_started),
    .ordered_colours(ordered_colours),
    .done(done),
    .ld_one(ld_one),
    .ld_two(ld_two),
    .ld_three(ld_three),
    .ld_four(ld_four),
    .draw_bars(draw_bars),
    .increment_bars(increment_bars),
    .done_bars(done_bars),
    .done_bar_wait(done_bar_wait),
    .wait_bars(wait_bars),
    .done_numbers(done_numbers),
    .decrement_pixel(decrement_pixel),
    .inc_number_positions(inc_number_positions)
  );

  wire [2:0] colour;
  wire [7:0] x;
  wire [6:0] y;

  // VGA display module
  vga_adapter VGA(
    .resetn(1'b1),
    .clock(CLOCK_50),
    .colour(colour),
    .x(x),
    .y(y),
    .plot(1'b1),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_BLANK(VGA_BLANK_N),
    .VGA_SYNC(VGA_SYNC_N),
    .VGA_CLK(VGA_CLK)
  );
  defparam VGA.RESOLUTION = "160x120";
  defparam VGA.MONOCHROME = "FALSE";
  defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
  defparam VGA.BACKGROUND_IMAGE = "background.mif";

endmodule

module datapath(
    CLOCK_50, clonke, timer,
    ld_p1, ld_p2, ld_p3, ld_p4, ld_timer,
    reset_state, reset_inc_state, reset_wait_state,
    p1, p2, p3, p4,
    x, y,
    colour, running,
    ordered_colours, done, game_started, done_waiting,
    ld_one, ld_two, ld_three, ld_four,
    inc_number_positions, decrement_pixel, done_numbers,

    draw_bars, increment_bars, done_bars, done_bar_wait, wait_bars, starting
  );

  /*
    This module is the main datapath of the game.
  */

  output done;
  assign done = reset_address > 15'b10011111_1111111;

  input [11:0] ordered_colours;
  input CLOCK_50, clonke, timer, game_started;
  input ld_p1, ld_p2, ld_p3, ld_p4, ld_timer;
  input reset_state, reset_inc_state, reset_wait_state;

  input [14:0] p1, p2, p3, p4; // location information for players

  output reg [7:0] x;
  output reg [6:0] y;

  reg [14:0] reset_address = 0;
  reg [27:0] reset_counter;
  output done_waiting;
  assign done_waiting = reset_counter == 0;

  output reg [2:0] colour;
  output reg running = 1;
  reg [7:0] timer_x;

  input ld_one, ld_two, ld_three, ld_four;
  input inc_number_positions, decrement_pixel, starting;
  output reg done_numbers;

  reg [5:0] pixel = 6'd34;

  reg [34:0] one   = 35'b11100_00100_00100_00100_00100_00100_11111;
  reg [34:0] two   = 35'b11111_00001_00001_11111_10000_10000_11111;
  reg [34:0] three = 35'b11111_00001_00001_11111_00001_00001_11111;
  reg [34:0] four  = 35'b10001_10001_10001_11111_00001_00001_00001;

  reg [14:0] one_address   = 15'b00100001_0100100; // 33, 36 -> 5x7
  reg [14:0] two_address   = 15'b00111111_0110000; // 63, 48
  reg [14:0] three_address = 15'b01011101_0111100; // 93, 60
  reg [14:0] four_address  = 15'b01111011_1001000; // 123, 72

  reg [14:0] bars_address = 15'b1111110_11111110;

  input increment_bars, draw_bars;
  output done_bars;
  assign done_bars = bars_address == 15'b0010000_00000000;

  input wait_bars;
  output done_bar_wait;
  assign done_bar_wait = bar_counter == 0;
  reg [27:0] bar_counter;

  // Controls what gets displayed to the monitor
  always@(posedge CLOCK_50)
    begin
      if (increment_bars)
        bars_address <= bars_address - 1'b1;
      if (wait_bars)
        bar_counter <= bar_counter - 1'b1;
      if (draw_bars)
        begin
          bar_counter <= 28'd5999;
          y <= bars_address[14:8];
          x <= bars_address[7:0];
          if (x >= 8'b00011100 && x <= 8'b00101011 && y >= 7'b0011110 ||
              x >= 8'b00111010 && x <= 8'b01001001 && y >= 7'b0101010 ||
              x >= 8'b01011000 && x <= 8'b01100111 && y >= 7'b0110110 ||
              x >= 8'b01110110 && x <= 8'b10000101 && y >= 7'b1000010)
            colour <= 3'b000;
          else
            colour <= 3'b111;
        end
      if (ld_p1)
        begin
          reset_address <= 0;
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
      else if (ld_timer)
        begin
          x <= timer_x;
          y <= 7'b1110111;
          colour <= 3'b111;
        end
      else if (reset_state)
        begin
          x <= reset_address[14:7];
          y <= reset_address[6:0];
          reset_counter <= 28'd6999;
          colour <= starting ? 3'b000 : 3'b111;
        end
      else if (reset_wait_state)
        reset_counter <= reset_counter - 1'b1;
      else if (reset_inc_state)
        reset_address <= reset_address + 1'b1;
      else if (ld_one)
        begin
          x <= one_address[14:7];
          y <= one_address[6:0];
          colour <= (one[pixel] == 0) ? 3'b000 : ordered_colours[11:9];
        end
      else if (ld_two)
        begin
          x <= two_address[14:7];
          y <= two_address[6:0];
          colour <= (two[pixel] == 0) ? 3'b000 : ordered_colours[8:6];
        end
      else if (ld_three)
        begin
          x <= three_address[14:7];
          y <= three_address[6:0];
          colour <= (three[pixel] == 0) ? 3'b000 : ordered_colours[5:3];
        end
      else if (ld_four)
        begin
          x <= four_address[14:7];
          y <= four_address[6:0];
          colour <= (four[pixel] == 0) ? 3'b000 : ordered_colours[2:0];
        end
      else if (inc_number_positions)
        begin
          done_numbers <= pixel == 6'd0;
            if (pixel == 6'd30 || pixel == 6'd25 || pixel == 6'd20 ||
                pixel == 6'd15 || pixel == 6'd10 || pixel == 6'd5)
              begin
                one_address[6:0]    <= one_address[6:0] + 1'b1;
                two_address[6:0]    <= two_address[6:0] + 1'b1;
                three_address[6:0]  <= three_address[6:0] + 1'b1;
                four_address[6:0]   <= four_address[6:0] + 1'b1;
                one_address[14:7]   <= 8'b00100001;
                two_address[14:7]   <= 8'b00111111;
                three_address[14:7] <= 8'b01011101;
                four_address[14:7]  <= 8'b01111011;
              end
            else
              begin
                one_address[14:7]   <= one_address[14:7] + 1'b1;
                two_address[14:7]   <= two_address[14:7] + 1'b1;
                three_address[14:7] <= three_address[14:7] + 1'b1;
                four_address[14:7]  <= four_address[14:7] + 1'b1;
              end
        end
      else if (decrement_pixel)
        pixel = pixel - 1'b1;
    end

  // Game timer incrementor
  always@(posedge timer)
    begin
      if (game_started)
        begin
          running = (timer_x >= 8'b10011110) ? 0 : 1;
          timer_x <= timer_x + 1'b1;
        end
    end

endmodule


module control(
  CLOCK_50, space_pressed,
  ld_p1, ld_p2, ld_p3, ld_p4, ld_timer,
  reset_state, reset_inc_state, reset_wait_state, done_waiting,
  running, done, game_started, done_ordering,

  ld_one, ld_two, ld_three, ld_four,
  inc_number_positions, decrement_pixel, done_numbers,

  draw_bars, increment_bars, done_bars, starting, done_bar_wait, wait_bars
  );

  /*
    This is the main module controlling the game behaviour, basically a big FSM
  */

  input CLOCK_50, running, done, space_pressed, done_ordering, done_waiting;
  output reg ld_p1, ld_p2, ld_p3, ld_p4, ld_timer;
  output reg reset_state, reset_inc_state, reset_wait_state;


  output reg ld_one, ld_two, ld_three, ld_four;
  output reg inc_number_positions, decrement_pixel;
  input done_numbers;

  output reg draw_bars, increment_bars, wait_bars;
  input done_bars, done_bar_wait;

  output game_started, starting;

  assign game_started = current_state != START &&
                        current_state != CLEAR_BOARD &&
                        current_state != CLEAR_WAIT &&
                        current_state != CLEAR_INCREMENT;

  assign starting = current_state == CLEAR_BOARD ||
                    current_state == CLEAR_WAIT ||
                    current_state == CLEAR_INCREMENT;

  reg [4:0] current_state, next_state;

  localparam  START               = 5'd0,
              DRAW_P1             = 5'd1,
              DRAW_P2             = 5'd2,
              DRAW_P3             = 5'd3,
              DRAW_P4             = 5'd4,
              DRAW_TIMER          = 5'd5,
              RESET               = 5'd6,
              RESET_INCREMENT     = 5'd7,
              DRAW_WINNER_WAIT    = 5'd8,
              DRAW_ONE            = 5'd9,
              DRAW_TWO            = 5'd10,
              DRAW_THREE          = 5'd11,
              DRAW_FOUR           = 5'd12,
              INC_NUMBER_POS      = 5'd13,
              DECREMENT_PIXEL_POS = 5'd14,
              END                 = 5'd15,
              RESET_WAIT          = 5'd16,
              CLEAR_BOARD         = 5'd17,
              CLEAR_WAIT          = 5'd18,
              CLEAR_INCREMENT     = 5'd19,
              BAR_DRAW            = 5'd20,
              BAR_INCREMENT       = 5'd21,
              BAR_WAIT            = 5'd22;

  // Main FSM
  always@(*)
  begin: state_table
    case (current_state)
      // Start screen
      START : next_state = space_pressed ? CLEAR_BOARD : START;

      // Clear the board when space bar pressed
      CLEAR_BOARD : next_state = CLEAR_WAIT;
      CLEAR_WAIT : next_state = done_waiting ? CLEAR_INCREMENT : CLEAR_WAIT;
      CLEAR_INCREMENT : next_state = done ? DRAW_P1 : CLEAR_BOARD;

      // Draw all the players
      DRAW_P1 : next_state = DRAW_P2;
      DRAW_P2 : next_state = DRAW_P3;
      DRAW_P3 : next_state = DRAW_P4;
      DRAW_P4 : next_state = DRAW_TIMER;

      // Draw timer bar at bottom of the screen
      DRAW_TIMER : next_state = running ? DRAW_P1 : RESET;

      // Clear the board when game finishes
      RESET : next_state = RESET_WAIT;
      RESET_WAIT : next_state = done_waiting ? RESET_INCREMENT : RESET_WAIT;
      RESET_INCREMENT: next_state = done ? DRAW_WINNER_WAIT : RESET;

      // Wait for RAM to be completely read and player order calculated
      DRAW_WINNER_WAIT:
        next_state = done_ordering ? BAR_DRAW : DRAW_WINNER_WAIT;

      // Draw the bars indicating highest to lowest ranking
      BAR_DRAW : next_state = BAR_WAIT;
      BAR_WAIT : next_state = done_bar_wait ? BAR_INCREMENT : BAR_WAIT;
      BAR_INCREMENT : next_state = done_bars ? DRAW_ONE : BAR_DRAW;

      // Draw individual numbers onto the bars in order and in the colour
      // of the players in order
      DRAW_ONE : next_state = DRAW_TWO;
      DRAW_TWO : next_state = DRAW_THREE;
      DRAW_THREE : next_state = DRAW_FOUR;
      DRAW_FOUR : next_state = INC_NUMBER_POS;
      INC_NUMBER_POS : next_state = DECREMENT_PIXEL_POS;
      DECREMENT_PIXEL_POS : next_state = done_numbers ? END : DRAW_ONE;

      // End state
      END : next_state = END;
      default : next_state = START;
    endcase
  end

  always@(*)
    begin: enable_signals
      ld_p1 = 0;
      ld_p2 = 0;
      ld_p3 = 0;
      ld_p4 = 0;
      ld_timer = 0;
      reset_state = 0;
      reset_wait_state = 0;
      reset_inc_state = 0;

      ld_one = 0;
      ld_two = 0;
      ld_three = 0;
      ld_four = 0;
      inc_number_positions = 0;
      decrement_pixel = 0;

      draw_bars = 0;
      increment_bars = 0;
      wait_bars = 0;

      case (current_state)
        CLEAR_BOARD : reset_state = 1;
        CLEAR_WAIT : reset_wait_state = 1;
        CLEAR_INCREMENT : reset_inc_state = 1;

        DRAW_P1 : ld_p1 = 1;
        DRAW_P2 : ld_p2 = 1;
        DRAW_P3 : ld_p3 = 1;
        DRAW_P4 : ld_p4 = 1;

        DRAW_TIMER : ld_timer = 1;

        RESET : reset_state = 1;
        RESET_WAIT : reset_wait_state = 1;
        RESET_INCREMENT : reset_inc_state = 1;

        BAR_DRAW : draw_bars = 1;
        BAR_WAIT : wait_bars = 1;
        BAR_INCREMENT : increment_bars = 1;

        DRAW_ONE : ld_one = 1;
        DRAW_TWO : ld_two = 1;
        DRAW_THREE : ld_three = 1;
        DRAW_FOUR : ld_four = 1;
        INC_NUMBER_POS : inc_number_positions = 1;
        DECREMENT_PIXEL_POS : decrement_pixel = 1;
      endcase
    end

  always@(posedge CLOCK_50)
    begin: state_FFS
      current_state <= next_state;
    end

endmodule
