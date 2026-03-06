`timescale 1 ns/ 1 ps  // FIXED: Changed from ps to ns so the clock is 50MHz, not 50GHz

module test_ASK();

    // Inputs to DUT
    reg clk_50;
    reg reset;
    reg data;
    reg [7:0] phase;
    
    // Outputs from DUT
    wire signed [15:0] sine;
    wire signed [15:0] ASK;
    
    // Debugging counter (optional, but kept from your original code)
    reg [31:0] index;

    // Instantiate the Unit Under Test (UUT)
    ASK_on_FPGA i1 (
        .clock(clk_50),
        .data(data),
        .increment({18'h02000, 14'b0}), // Sets carrier freq to approx 1.5 MHz
        .phase(8'd0),
        .reset(reset),
        .ASK(ASK),
        .sine(sine)
    );

    // 1. Clock Generation: 50 MHz (Period = 20ns)
    initial clk_50 = 0;
    always #10 clk_50 = ~clk_50; // Toggles every 10ns

    // 2. Index Counter (Matches your original logic)
    always @(posedge clk_50) begin
        if (reset) 
            index <= 0;
        else 
            index <= index + 1;
    end

    // 3. Main Stimulus Block
    initial begin
        // Initialize Inputs
        reset = 0;
        data = 0;
        phase = 0;
        index = 0;
        
        $display("Starting Simulation...");

        // Apply Reset Pulse
        #10 reset = 1;  // Assert Reset (Active High)
        #40 reset = 0;  // De-assert Reset
        
        // Wait for system to stabilize
        #100;
        
        // --- DATA PATTERN START ---
        // Frequency check: With increment 0x08000000, 
        // Carrier Period is approx 640ns. 
        // We hold data for 2000ns to see ~3 full sine waves.

        data = 1; // Show Carrier (ON)
        #2000;
        
        data = 0; // Show Flat Line (OFF)
        #2000;
        
        data = 1; // Show Carrier (ON)
        #2000;
        
        data = 0; // Show Flat Line (OFF)
        #2000;

        data = 1; // Show Carrier (ON)
        #2000;

        // End Simulation
        $display("Simulation Finished.");
        $stop; 
    end

endmodule
