module DE10_Lite_Top(
    input MAX10_CLK1_50, // 50 MHz Clock
    input [1:0] KEY,     // Buttons (0 = Pressed)
    input [9:0] SW,      // Switches (1 = Up)
    output [9:0] LEDR    // LEDs
);

    wire signed [15:0] sine_out;
    wire signed [15:0] ASK_out;


    ASK_on_FPGA u0 (
        .clock(MAX10_CLK1_50),
        // Reset: Use KEY[0]. Invert it because Keys are 0 when pressed.
        .reset(~KEY[0]),       
        // Data: Use Switch[0].
        .data(SW[0]),    
        .increment({18'h02000, 14'b0}), 
        .phase(8'd0),
        .ASK(ASK_out),
        .sine(sine_out)
    );

    // Visual Check: Connect the top bits of the ASK wave to LEDs.
    assign LEDR = ASK_out[15:6];

endmodule
