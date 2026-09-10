module piso #(parameter WIDTH = 20, ADDR_WIDTH = 8) (

    // INPUTS
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] Parallel_in,

    // OUTPUTS
    output reg rd_en,
    output reg [ADDR_WIDTH-1:0] addr,
    output reg serial_out,
    output reg valid

);

    reg [WIDTH-1:0] shift_reg;
    integer count;
    reg busy;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            rd_en      <= 0;
            addr       <= 0;
            serial_out <= 0;
            valid      <= 0;
            shift_reg  <= 0;
            count      <= 0;
            busy       <= 0;
        end

        else begin

            if (rd_en) begin
                rd_en     <= 0;
                shift_reg <= Parallel_in;
                busy      <= 1;
                count     <= 0;
            end

            else if (busy) begin

                if (count < WIDTH) begin
                    valid      <= 1;
                    serial_out <= shift_reg[WIDTH-1];

                    shift_reg <= {shift_reg[WIDTH-2:0], 1'b0};

                    count <= count + 1;
                end

                else begin
                    valid      <= 0;
                    serial_out <= 0;
                    busy       <= 0;
                    addr       <= addr + 1;
                end

            end

            else begin
                rd_en <= 1;
            end

        end

    end

endmodule

module piso_tb;

    reg clk;
    reg rst_n;
    reg [19:0] Parallel_in;

    wire rd_en;
    wire [7:0] addr;
    wire serial_out;
    wire valid;


    piso dut (

        .clk(clk),
        .rst_n(rst_n),
        .Parallel_in(Parallel_in),
        .rd_en(rd_en),
        .addr(addr),
        .serial_out(serial_out),
        .valid(valid)

    );

    always #5 clk = ~clk;

    initial begin
        $monitor("Time = %0t Parallel_in = %b rd_en = %b addr = %d serial_out = %b valid = %b",
                 $time, Parallel_in, rd_en, addr, serial_out, valid);
    end


    initial begin

        clk = 0;
        rst_n = 0;
        Parallel_in = 0;

        #10;
        rst_n = 1;

        Parallel_in = 20'b10110011110000111100;    // Give PISO a 20-bit value
        #250;

        $finish;

    end

endmodule
