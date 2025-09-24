// Controller for a 4 digit seven segment display. Takes in 4-digit number represented in BCD and outputs that number onto a 4-digit 7-segement display
// with a 10.5ms refresh period (380Hz refresh rate), assuming 100MHz clock signal. Input "i_num_bcd" will be seen on the SSD.
module ssd_ctrl (
  input                 clk,
  input                 rst,
  input         [15:0]  i_num_bcd,  // Number to display given in BCD.
  output logic  [3:0]   o_digit_en, // Anode enable signal.
  output logic  [6:0]   o_led       // Value driven to cathode to displau number on LED.
);

// Constants and Parameters
typedef enum logic [6:0] {
    ZERO  = 7'b1000000,
    ONE   = 7'b1111001,
    TWO   = 7'b0100100,
    THREE = 7'b0110000,
    FOUR  = 7'b0011001,
    FIVE  = 7'b0010010,
    SIX   = 7'b0000010,
    SEVEN = 7'b1111000,
    EIGHT = 7'b0000000,
    NINE  = 7'b0010000 
} led_nums_t;


// Signals and Registers
logic [3:0]     bcd_digit;
logic [1:0]     digit_idx;

logic [19:0]   refresh_counter;


// Continuous Assignments
assign digit_idx = refresh_counter[19:18];


// Refresh counter
always @(posedge clk or posedge rst) begin
  if(rst) begin
    refresh_counter <= '0;
  end else begin
    refresh_counter <= refresh_counter + 1;
  end
end

// Drive the anode enable of the SSD to select the number we are currently processing and select the current BCD digit we are processing.
always @(*) begin
  case(digit_idx)
    2'b00: begin
        o_digit_en  = 4'b0111;
        bcd_digit   = i_num_bcd[15:12];
    end
    2'b01: begin
        o_digit_en  = 4'b1011;
        bcd_digit   = i_num_bcd[11:8];
    end 
    2'b10: begin
        o_digit_en  = 4'b1101;
        bcd_digit   = i_num_bcd[7:4];
    end 
    2'b11: begin
        o_digit_en  = 4'b1110;
        bcd_digit   = i_num_bcd[3:0];
    end 
  endcase
end

// Lookup table to match BCD number to SSD encoding for LED display.
always @(*) begin
  case(bcd_digit)
    4'd0: o_led = ZERO; 
    4'd1: o_led = ONE;
    4'd2: o_led = TWO;
    4'd3: o_led = THREE;
    4'd4: o_led = FOUR;
    4'd5: o_led = FIVE;
    4'd6: o_led = SIX;
    4'd7: o_led = SEVEN;
    4'd8: o_led = EIGHT;
    4'd9: o_led = NINE;
    default: o_led = ZERO;
  endcase
end

endmodule
