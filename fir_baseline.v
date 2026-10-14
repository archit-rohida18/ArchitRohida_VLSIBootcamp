`timescale 1ns / 1ps

module fir_baseline (
    input  wire clk,
    input  wire reset,
    input  wire in_valid,
    input  wire signed [19:0] in_sample,
    output reg  signed [19:0] out_sample,
    output reg out_valid
);
    // this 5 tap fir filter uses symmetric coefficients 
    // Q3.13 coefficients: [954, -2867, 12018, -2867, 954] (method to store decimal values as integers)
    localparam signed [15:0] C0 =  16'sd954;
    localparam signed [15:0] C1 = -16'sd2867;
    localparam signed [15:0] C2 =  16'sd12018;
    localparam signed [15:0] C3 = -16'sd2867;
    localparam signed [15:0] C4 =  16'sd954;

    // previous four CIC output samples.
    reg signed [19:0] d1; //x[n-1]
    reg signed [19:0] d2; //x[n-2]
    reg signed [19:0] d3; //x[n-3]
    reg signed [19:0] d4; //x[n-4]

    // Each multiplication is 20 bits × 16 bits = 36 bits.
    wire signed [35:0] p0 = in_sample * C0;  // p = ax[n] + bx[n-1] + ....
    wire signed [35:0] p1 = d1 * C1;
    wire signed [35:0] p2 = d2 * C2;
    wire signed [35:0] p3 = d3 * C3;
    wire signed [35:0] p4 = d4 * C4;

    // accumulator width increased to prevent overflow
    wire signed [39:0] accumulator =
          {{4{p0[35]}}, p0} + {{4{p1[35]}}, p1} + {{4{p2[35]}}, p2} + {{4{p3[35]}}, p3} + {{4{p4[35]}}, p4};
        
wire signed [39:0] rounded_result; //the actual value using decimal coefficients 
assign rounded_result = (accumulator >= 0) ? ((accumulator + 40'sd4096) >>> 13) : -(((-accumulator + 40'sd4096) >>> 13));
/*the fft algorithm calculates rounded result by discarding the fractional part.
Above step ensures we round to the nearest integer (the 4096 part does this). We divide by using right shift.*/

    always @(posedge clk) begin
        if (reset) begin
            d1 <= 20'sd0;
            d2 <= 20'sd0;
            d3 <= 20'sd0;
            d4 <= 20'sd0;
            out_sample <= 20'sd0;
            out_valid <= 1'b0;
        end
        else begin
            out_valid <= 1'b0;
        
            if (in_valid) begin //the fir runs when cic gives it an input
                out_sample <= rounded_result;
                out_valid  <= 1'b1;
                
                //output shifting
                d4 <= d3;
                d3 <= d2;
                d2 <= d1;
                d1 <= in_sample;
            end
        end
    end

endmodule