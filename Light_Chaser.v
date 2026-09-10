module CLK_Div (

    //INPUTS
    input  wire clk_50MHz,
    input  wire reset_n,

    //OUTPUT
    output reg  clk_8Hz

);

    reg [21:0] count;

    always @(posedge clk_50MHz or negedge reset_n) begin

        if (!reset_n) begin
            count   <= 0;
            clk_8Hz <= 0;

        end else if (count == 3124999) begin  //Toggles every 3,125,000 cycles
            count   <= 0;
            clk_8Hz <= ~clk_8Hz;

        end else begin
            count   <= count + 1;

        end
    end

endmodule


module Light_Chaser (

    //INPUTS
    input  wire       clk,      
    input  wire       reset_n,  
    input  wire       hold_n,

    //OUTPUTS
    output reg  [9:0] reg_out

);

    always @(posedge clk or negedge reset_n) begin
    
        if (!reset_n) begin
            reg_out <= 10'b1000000000;

        end else if (!hold_n) begin
            reg_out <= reg_out;

        end else begin
            reg_out <= {reg_out[0], reg_out[9:1]}; 

        end
    end
    
endmodule


module Light_Chaser_topmodule (

    input  wire       clk_50MHz,
    input  wire       reset_n,
    input  wire       hold_n,

    output wire [9:0] reg_out

);

    wire clk_8Hz;

    CLK_Div clk_div_inst (

        .clk_50MHz(clk_50MHz),
        .reset_n  (reset_n),
        .clk_8Hz  (clk_8Hz)

    );

    Light_Chaser chaser_inst (

        .clk    (clk_8Hz),
        .reset_n(reset_n),
        .hold_n (hold_n),
        .reg_out(reg_out)

    );

endmodule


module Light_Chaser_tb;

    reg        clk = 0;
    reg        reset_n = 0;
    reg        hold_n = 1;

    wire [9:0] reg_out;

    Light_Chaser dut (

        .clk(clk),
        .reset_n(reset_n),
        .hold_n(hold_n),
        .reg_out(reg_out)

    );

    always #5 clk = ~clk;

    initial begin
    
        $monitor("Time = %0t  clk = %b  reset_n = %b  hold_n = %b  reg_out = %b", 
                 $time, clk, reset_n, hold_n, reg_out);

        #10
        reset_n = 1; 

        #50
        hold_n  = 0; 

        #30
        hold_n  = 1; 

        #100
        $finish;

    end

endmodule
