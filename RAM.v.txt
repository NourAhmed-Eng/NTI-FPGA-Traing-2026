module RAM #(parameter ADDR_WIDTH = 8, DATA_WIDTH = 20, DEPTH = 256) (

    // INPUTS
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire rd_en,

    // OUTPUTS
    output reg [DATA_WIDTH-1:0] dout,
    output reg valid

);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            dout  <= 0;
            valid <= 0;
        end

        else begin
            valid <= rd_en;

            if (wr_en)
                mem[addr] <= din;

            if (rd_en)
                dout <= mem[addr];

        end

    end

endmodule


module RAM_tb;

    reg clk;
    reg rst_n;
    reg wr_en;
    reg [7:0] addr;
    reg [19:0] din;
    reg rd_en;

    wire [19:0] dout;
    wire valid;

    RAM dut (

        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .addr(addr),
        .din(din),
        .rd_en(rd_en),
        .dout(dout),
        .valid(valid)

    );

    always #5 clk = ~clk;

    initial begin
        $monitor("Time = %0t | wr_en = %b | rd_en = %b | addr = %d | din = %d | dout = %d | valid = %b",
                 $time, wr_en, rd_en, addr, din, dout, valid);
    end


    initial begin
        clk   = 0;
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        addr  = 0;
        din   = 0;

        #10;
        rst_n = 1;


        @(posedge clk);  //write1
        wr_en = 1;
        addr  = 8'd0;
        din   = 20'd100;
        @(posedge clk);
        wr_en = 0;


        @(posedge clk);  //write2
        wr_en = 1;
        addr  = 8'd1;
        din   = 20'd200;
        @(posedge clk);
        wr_en = 0;


        @(posedge clk);  //read1
        rd_en = 1;
        addr  = 8'd0;
        @(posedge clk);
        rd_en = 0;

    
        @(posedge clk); //read2
        rd_en = 1;
        addr  = 8'd1;
        @(posedge clk);
        rd_en = 0;

        #20;

        $finish;

    end

endmodule