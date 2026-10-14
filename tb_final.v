`timescale 1ns / 1ps

module cic_tb();

    reg data [0:4096025];
    
    reg clk,clk2,clk3,clk4, reset,enable;
    wire outready,outready2;
    wire firvalid; //instead of using clk2 we use the same clk with this condition
    
    reg signed [1:0] bits;
    
    // Changed widths to match cic and fir output.
    wire signed [19:0] cicout;
    wire signed [19:0] firout;
    
    initial begin
       $readmemh("hz500.mem", data); //input data //input data
    end
    

    initial begin
        clk=0;
        clk2=0;
        clk3=0;
        bits=0;
        enable=0;
        reset = 1;
        #51 reset = 0;
        enable=1;
    end

    always #50 clk=~clk;
    always #25600 clk2=~clk2; //change according to filter output frequencies
    always #102400 clk3=~clk3; //change according to filter output frequencies

    
    integer i;
    initial i = 0;
    
    integer fd1,fd2,fd3,fd4;

    initial begin
        fd1 = $fopen("bits.txt","w");
        fd2 = $fopen("cic_n2_500.txt","w"); //ouput file change according to need
        fd3 = $fopen("fir_baseline_500_rtl.txt", "w"); //ouput file change according to need
        fd4 = $fopen("cic512_500_by4.txt","w"); //ouput file change according to need
    end

    always @(posedge clk) begin
        if (i < 4096026) begin
            if(i%2==0) begin
                bits={1'b0,data[i]};
            end
            else begin
                bits={2{data[i]}};
            end
            i <= i + 1;
        end
        else begin
            #200;
            $finish;
        end
    end

    always @(posedge clk) begin
        $fwrite(fd1, "%d\n", bits); 
    end

    always @(posedge clk) begin
        if(outready) begin
            $fwrite(fd2, "%d\n", $signed(cicout));
        end
    end

    always @(posedge clk) begin
    if (firvalid) begin
        $fwrite(fd3, "%d\n", $signed(firout));
    end
end

    always @(posedge clk3) begin
        $fwrite(fd4, "%d\n", $signed(cicout));
    end

  
    cic_filter cic (
    .clk(clk),
    .reset(reset),
    .in_sample(bits),
    .out_sample(cicout),
    .out_valid(outready)
);
    fir_baseline fir (
    .clk(clk),
    .reset(reset),
    .in_valid(outready),
    .in_sample(cicout),
    .out_sample(firout),
    .out_valid(firvalid)
);

endmodule