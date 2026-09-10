module sipo #(parameter WIDTH = 20) (

    // INPUTS
    input wire clk,
    input wire rst_n,
    input wire shift_en,
    input wire serial_in,

    // OUTPUT
    output reg [WIDTH-1:0] parallel_out

);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            parallel_out <= 0;

        else if (shift_en)
            parallel_out <= {parallel_out[WIDTH-2:0], serial_in};
    end

endmodule

module ALU #(parameter WIDTH = 8) (

    // INPUTS
    input wire [WIDTH-1:0] in_a,
    input wire [WIDTH-1:0] in_b,
    input wire [2:0] opcode,
    input wire alu_en,

    // OUTPUTS
    output reg [WIDTH-1:0] alu_out,
    output wire a_is_zero

);

    assign a_is_zero = (in_a == 0);

    always @(*) begin
        if (!alu_en) begin
            alu_out = 0;
        end else begin
            case (opcode)

                3'b000:  alu_out = in_a + in_b;   // ADD
                3'b001:  alu_out = in_a - in_b;   // SUB
                3'b010:  alu_out = in_a & in_b;   // AND
                3'b011:  alu_out = in_a ^ in_b;   // XOR
                3'b100:  alu_out = in_a | in_b;   // OR
                3'b101:  alu_out = in_a;          // OUT A

                default: alu_out = 0;
                
            endcase
        end
    end

endmodule

module SIPO_ALU (

    // INPUTS
    input wire clk,
    input wire rst_n,
    input wire shift_en,
    input wire serial_in,

    // OUTPUTS
    output wire [7:0] alu_out,
    output wire a_is_zero

);

    wire [19:0] parallel_out;

    sipo #(.WIDTH(20)) SIPO (

        .clk(clk),
        .rst_n(rst_n),
        .shift_en(shift_en),
        .serial_in(serial_in),
        .parallel_out(parallel_out)

    );

    ALU #(.WIDTH(8)) ALU1 (

        .alu_en(parallel_out[19]),
        .opcode(parallel_out[18:16]),
        .in_a(parallel_out[15:8]),
        .in_b(parallel_out[7:0]),
        .alu_out(alu_out),
        .a_is_zero(a_is_zero)

    );

endmodule


module SIPO_ALU_tb;

    reg        clk;
    reg        rst_n;
    reg        shift_en;
    reg        serial_in;

    wire [7:0] alu_out;
    wire       a_is_zero;

    SIPO_ALU dut (

        .clk(clk),
        .rst_n(rst_n),
        .shift_en(shift_en),
        .serial_in(serial_in),
        .alu_out(alu_out),
        .a_is_zero(a_is_zero)

    );

    always #5 clk = ~clk;

    task send_cmd(input [19:0] cmd);

        integer i;

        begin
            shift_en = 1'b1;

            for (i = 19; i >= 0; i = i - 1) begin
                serial_in = cmd[i];
                @(posedge clk);
            end

            shift_en  = 1'b0;
            serial_in = 1'b0;

        end

    endtask

    initial begin
        $monitor("Time = %0t  rst_n = %b  shift_en = %b  serial_in = %b  alu_out = %b  a_is_zero = %b", 
                 $time, rst_n, shift_en, serial_in, alu_out, a_is_zero);
    end

    initial begin
        clk       = 0;
        rst_n     = 0;
        shift_en  = 0;
        serial_in = 0;

        #20;
        rst_n = 1;
        #10;

        //ADD
        send_cmd({1'b1, 3'b000, 8'b00001111, 8'b00001010});
        #10;

        //SUB
        send_cmd({1'b1, 3'b001, 8'b00110010, 8'b00010100});
        #10;

        //AND
        send_cmd({1'b1, 3'b010, 8'b11111111, 8'b00001111});
        #10;

        //XOR
        send_cmd({1'b1, 3'b011, 8'b10101010, 8'b11111111});
        #10;

        //OR
        send_cmd({1'b1, 3'b100, 8'b11110000, 8'b00001111});
        #10;

        //OUT A
        send_cmd({1'b1, 3'b101, 8'b00101010, 8'b01100011});
        #10;

        //Default Opcode
        send_cmd({1'b1, 3'b110, 8'b00001010, 8'b00001010});
        #10;

        //Disabled ALU
        send_cmd({1'b0, 3'b000, 8'b00000101, 8'b00000101});
        #10;

        
        send_cmd({1'b1, 3'b000, 8'b00000000, 8'b00001010});
        #10;


        rst_n = 0;
        #10;
        rst_n = 1;
        #20;
        $finish;
    end

endmodule