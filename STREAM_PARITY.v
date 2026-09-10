module stream_parity_gen (

    // INPUTS
    input  wire clk,
    input  wire reset,
    input  wire serial_in,

    // OUTPUT
    output reg  parity_out = 0
);

    reg [7:0] shift_reg = 0;

    function calc_parity;
        input [7:0] data;

        begin
            calc_parity = ^data;
        end

    endfunction

    always @(posedge clk) begin

        if (reset) begin
            shift_reg  <= 0;
            parity_out <= 0;

        end else begin
            shift_reg  <= {shift_reg[6:0], serial_in};
            parity_out <= calc_parity({shift_reg[6:0], serial_in});

        end
    end
    
endmodule


module stream_parity_gen_topmodule (

    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] addr,       
    input  wire       load_p,

    output wire       parity_out
);

    reg [7:0] memory [0:255];
    
    reg [7:0] reg_d = 0;       
    reg [7:0] reg_p = 0;      

    integer i;

    initial begin

        for (i = 0; i < 256; i = i + 1) begin

            memory[i] = i[7:0];
        end

    end

    always @(posedge clk) begin

        if (reset) begin
            reg_d <= 0;
            reg_p <= 0;

        end else begin
            reg_d <= memory[addr];
            
            if (load_p) begin
                reg_p <= reg_d;

            end else begin
                reg_p <= {reg_p[6:0], 1'b0};

            end
        end
    end

    wire serial_in = reg_p[7];

    stream_parity_gen spg_inst (

        .clk(clk),
        .reset(reset),
        .serial_in(serial_in),
        .parity_out(parity_out)

    );

endmodule


module stream_parity_gen_tb;

    reg       clk = 0;
    reg       reset = 1;
    reg [7:0] addr = 0;
    reg       load_p = 0;

    wire      parity_out;

    integer j;

    stream_parity_gen_topmodule dut (

        .clk(clk),
        .reset(reset),
        .addr(addr),
        .load_p(load_p),
        .parity_out(parity_out)

    );

    always #5 clk = ~clk;

    initial begin

        $monitor("Time = %0t Addr = %b Reg_D = %b Reg_P = %b parity_out = %b", 
                 $time, addr, dut.reg_d, dut.reg_p, parity_out);

    end

    initial begin

        #15;
        reset = 0;

        for (j = 28; j <= 28; j = j + 1) begin
            @(posedge clk);
            addr <= j[7:0];

            @(posedge clk);
            load_p <= 1;

            @(posedge clk);
            load_p <= 0;

            repeat (8) @(posedge clk);
        end

        #20;
        $finish;
    end
    
endmodule
