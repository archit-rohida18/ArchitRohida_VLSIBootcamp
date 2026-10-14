module cic_filter (
    input  wire clk,
    input  wire reset,
    input  wire signed [1:0] in_sample,
    output reg  signed [19:0] out_sample,
    output reg out_valid
);

    // CIC paramters :  N = 2, R = 2048, M = 1
    
    reg signed [23:0] integrator_1; // Register width = Bmax = Bin + Nlog2(RM) (accounting for bit growth)
    reg signed [23:0] integrator_2;

    reg signed [23:0] comb_1_delay; // represents the delayed integator I2[k-1] used in the comb stage 1 
    reg signed [23:0] comb_2_delay; // represents the comb 1 delayed signal C1[k-1] used in comb stage 2 

    reg [10:0] sample_count; //counter to 2047 

    wire signed [23:0] input_extended;
    wire signed [23:0] next_integrator_1;
    wire signed [23:0] next_integrator_2;

    wire signed [23:0] next_comb_1;
    wire signed [23:0] next_comb_2;

    assign input_extended = {{22{in_sample[1]}}, in_sample}; //sign extending i/p bits to register width 

    assign next_integrator_1 = integrator_1 + input_extended;   //I1[n] = I1[n-1] + x[n]
    assign next_integrator_2 = integrator_2 + next_integrator_1;  //I2[n] = I2[n-1] + I1[n]

    //comb stages take place after decimation 
    assign next_comb_1 = next_integrator_2 - comb_1_delay; //C1[k] = I2[k] - I2[k-1] where I2 is now decimated by R=2048
    assign next_comb_2 = next_comb_1 - comb_2_delay; //C2[k] = C1[k] - C1[k-1] 

    always @(posedge clk) begin
        if (reset) begin
            integrator_1 <= 24'sd0;
            integrator_2 <= 24'sd0;

            comb_1_delay <= 24'sd0;
            comb_2_delay <= 24'sd0;

            sample_count <= 11'd0;
            out_sample <= 20'sd0;
            out_valid <= 1'b0;
        end
        else begin
            // integrators update at every clock cycle 
            integrator_1 <= next_integrator_1;
            integrator_2 <= next_integrator_2;

            out_valid <= 1'b0;

            if (sample_count == 11'd2047) begin
                sample_count <= 11'd0;
                // combs update after 2048 clock cycles (post decimation)
                comb_1_delay <= next_integrator_2;
                comb_2_delay <= next_comb_1;

                //right shift by 4 bits to preserve sign and truncate to 20 bits (4lsbs gets truncated)
                out_sample <= next_comb_2 >>> 4;

                out_valid <= 1'b1;
            end
            else begin
                sample_count <= sample_count + 11'd1;
            end
        end
    end

endmodule