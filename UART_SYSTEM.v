module clk_div (

    //INPUTS
    input wire       clk,
    input wire       RST,
    input wire [4:0] prescale,
    input wire       enable,

    //OUTPUT
    output wire      bit_tick

);

    reg [4:0] count;

    assign bit_tick = enable && (count == prescale - 1);


    always @(posedge clk or negedge RST) begin

        if (!RST) begin
            count <= 0;
        end

        else if (!enable) begin
            count <= 0;
        end

        else if (count == prescale - 1) begin
            count <= 0;
        end

        else begin
            count <= count + 1;
        end

    end

endmodule


module parity_calc (

    //INPUTS
    input wire       clk,
    input wire       RST,
    input wire [7:0] p_data,
    input wire       data_valid,
    input wire       par_typ,

    //OUTPUT
    output reg       par_bit

);

    always @(posedge clk or negedge RST) begin

        if (!RST) begin
            par_bit <= 0;
        end

        else if (data_valid) begin

            if (par_typ == 0)
                par_bit <= ^p_data;

            else
                par_bit <= ~(^p_data);

        end

    end

endmodule


module serializer (

    //INPUTS
    input wire       clk,
    input wire       RST,
    input wire [7:0] p_data,
    input wire       data_valid,
    input wire       ser_en,

    //OUTPUTS
    output wire      ser_data,
    output wire      ser_done

);

    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;

    assign ser_data = shift_reg[0];

    assign ser_done = (bit_cnt == 3'b111);


    always @(posedge clk or negedge RST) begin

        if (!RST) begin
            shift_reg <= 0;
            bit_cnt   <= 0;
        end

        else if (data_valid) begin
            shift_reg <= p_data;
            bit_cnt   <= 0;
        end

        else if (ser_en) begin
            shift_reg <= shift_reg >> 1;
            bit_cnt   <= bit_cnt + 1;
        end

    end

endmodule


module tx_mux (

    //INPUTS
    input wire [1:0] mux_sel,
    input wire       ser_data,
    input wire       par_bit,

    //OUTPUT
    output reg       tx_out

);

    always @(*) begin

        case (mux_sel)

            2'b00: tx_out = 0;
            2'b01: tx_out = ser_data;
            2'b10: tx_out = par_bit;
            2'b11: tx_out = 1;

            default: tx_out = 1;

        endcase

    end

endmodule


module tx_fsm (

    //INPUTS
    input wire       clk,
    input wire       RST,
    input wire       data_valid,
    input wire       par_en,
    input wire       bit_tick,
    input wire       ser_done,

    //OUTPUTS
    output reg       ser_en,
    output reg [1:0] mux_sel,
    output reg       busy

);

    reg [2:0] current_state;
    reg [2:0] next_state;


    always @(posedge clk or negedge RST) begin

        if (!RST)
            current_state <= 3'b000;

        else
            current_state <= next_state;

    end


    always @(*) begin

        case (current_state)

            3'b000: begin

                if (data_valid)
                    next_state = 3'b001;

                else
                    next_state = 3'b000;

            end


            3'b001: begin

                if (bit_tick)
                    next_state = 3'b010;

                else
                    next_state = 3'b001;

            end


            3'b010: begin

                if (bit_tick && ser_done) begin

                    if (par_en)
                        next_state = 3'b011;

                    else
                        next_state = 3'b100;

                end

                else
                    next_state = 3'b010;

            end


            3'b011: begin

                if (bit_tick)
                    next_state = 3'b100;

                else
                    next_state = 3'b011;

            end


            3'b100: begin

                if (bit_tick)
                    next_state = 3'b000;

                else
                    next_state = 3'b100;

            end


            default:
                next_state = 3'b000;

        endcase

    end


    always @(*) begin

        ser_en  = 0;
        mux_sel = 2'b11;
        busy    = 1;

        case (current_state)

            3'b000: begin
                busy    = 0;
                mux_sel = 2'b11;
            end


            3'b001: begin
                mux_sel = 2'b00;
            end


            3'b010: begin

                mux_sel = 2'b01;

                if (bit_tick)
                    ser_en = 1;

            end


            3'b011: begin
                mux_sel = 2'b10;
            end


            3'b100: begin
                mux_sel = 2'b11;
            end


            default: begin
                busy    = 0;
                mux_sel = 2'b11;
            end

        endcase

    end

endmodule


module UART_Tx_topmodule (

    input wire       clk,
    input wire       RST,
    input wire [7:0] p_data,
    input wire       data_valid,
    input wire       par_en,
    input wire       par_typ,
    input wire [4:0] Prescale,

    output wire      tx_out,
    output wire      busy

);

    wire       ser_en;
    wire       ser_done;
    wire       ser_data;
    wire       par_bit;
    wire [1:0] mux_sel;
    wire       bit_tick;
    wire       gated_data_valid;


    assign gated_data_valid = data_valid & ~busy;


    clk_div CLK_DIV_BLOCK (

        .clk(clk),
        .RST(RST),
        .prescale(Prescale),
        .enable(busy),
        .bit_tick(bit_tick)

    );


    parity_calc PARITY_BLOCK (

        .clk(clk),
        .RST(RST),
        .p_data(p_data),
        .data_valid(gated_data_valid),
        .par_typ(par_typ),
        .par_bit(par_bit)

    );


    serializer SERIALIZER_BLOCK (

        .clk(clk),
        .RST(RST),
        .p_data(p_data),
        .data_valid(gated_data_valid),
        .ser_en(ser_en),
        .ser_data(ser_data),
        .ser_done(ser_done)

    );


    tx_fsm FSM_BLOCK (

        .clk(clk),
        .RST(RST),
        .data_valid(gated_data_valid),
        .par_en(par_en),
        .bit_tick(bit_tick),
        .ser_done(ser_done),
        .ser_en(ser_en),
        .mux_sel(mux_sel),
        .busy(busy)

    );


    tx_mux MUX_BLOCK (

        .mux_sel(mux_sel),
        .ser_data(ser_data),
        .par_bit(par_bit),
        .tx_out(tx_out)

    );

endmodule


module data_sampling (

    //INPUTS
    input wire       clk,
    input wire       RST,
    input wire       RX_IN,
    input wire       dat_samp_en,
    input wire [4:0] Prescale,
    input wire [4:0] edge_cnt,

    //OUTPUT
    output wire      sampled_bit

);

    reg [2:0] samples;


    assign sampled_bit =
                    (samples[0] & samples[1]) |
                    (samples[0] & samples[2]) |
                    (samples[1] & samples[2]);


    always @(posedge clk or negedge RST) begin

        if (!RST) begin

            samples <= 3'b111;

        end

        else if (dat_samp_en) begin

            if (edge_cnt == ((Prescale >> 1) - 1)) begin
                samples[0] <= RX_IN;
            end

            else if (edge_cnt == (Prescale >> 1)) begin
                samples[1] <= RX_IN;
            end

            else if (edge_cnt == ((Prescale >> 1) + 1)) begin
                samples[2] <= RX_IN;
            end

        end

    end

endmodule


module edge_bit_counter (

    //INPUTS
    input wire       clk,
    input wire       RST,
    input wire       enable,
    input wire       bit_cnt_en,
    input wire [4:0] Prescale,

    //OUTPUTS
    output reg [4:0] edge_cnt,
    output reg [3:0] bit_cnt

);

    always @(posedge clk or negedge RST) begin

        if (!RST) begin

            edge_cnt <= 0;
            bit_cnt  <= 0;

        end

        else if (enable) begin

            if (edge_cnt == Prescale - 1) begin

                edge_cnt <= 0;

                if (bit_cnt_en)
                    bit_cnt <= bit_cnt + 1;

            end

            else begin

                edge_cnt <= edge_cnt + 1;

            end

        end

        else begin

            edge_cnt <= 0;
            bit_cnt  <= 0;
        end

    end

endmodule


module deserializer (

    //INPUTS
    input wire       clk,
    input wire       RST,
    input wire       sampled_bit,
    input wire       deser_en,

    //OUTPUT
    output reg [7:0] P_DATA

);

    always @(posedge clk or negedge RST) begin

        if (!RST)
            P_DATA <= 0;

        else if (deser_en)
            P_DATA <= {sampled_bit, P_DATA[7:1]};

    end

endmodule


module strt_check (

    //INPUTS
    input wire       clk,
    input wire       RST,
    input wire       strt_chk_en,
    input wire       sampled_bit,

    //OUTPUT
    output reg       strt_glitch

);

    always @(posedge clk or negedge RST) begin

        if (!RST)
            strt_glitch <= 0;

        else if (strt_chk_en)
            strt_glitch <= (sampled_bit != 0);

        else
            strt_glitch <= 0;

    end

endmodule


module parity_check (

    //INPUTS
    input wire       par_chk_en,
    input wire       PAR_TYP,
    input wire       sampled_bit,
    input wire [7:0] P_DATA,

    //OUTPUT
    output wire      par_err

);

    assign par_err = par_chk_en ? ((PAR_TYP == 0) ? (sampled_bit != (^P_DATA)) : (sampled_bit != ~(^P_DATA))) : 0;

endmodule


module stop_check (

    //INPUTS
    input wire       stp_chk_en,
    input wire       sampled_bit,

    //OUTPUT
    output wire      stp_err

);

    assign stp_err = stp_chk_en ? (sampled_bit != 1) : 0;

endmodule


module rx_fsm (

    //INPUTS
    input wire       clk,
    input wire       RST,
    input wire       RX_IN,
    input wire       PAR_EN,
    input wire [4:0] Prescale,
    input wire [4:0] edge_cnt,
    input wire [3:0] bit_cnt,
    input wire       strt_glitch,
    input wire       par_err,
    input wire       stp_err,

    //OUTPUTS
    output reg       dat_samp_en,
    output reg       enable,
    output reg       deser_en,
    output reg       strt_chk_en,
    output reg       par_chk_en,
    output reg       stp_chk_en,
    output reg       data_valid

);

    reg [2:0] current_state;
    reg [2:0] next_state;


    always @(posedge clk or negedge RST) begin

        if (!RST)
            current_state <= 3'b000;

        else
            current_state <= next_state;

    end


    always @(*) begin

        case (current_state)

            3'b000: begin

                if (!RX_IN)
                    next_state = 3'b001;

                else
                    next_state = 3'b000;

            end


            3'b001: begin

                if (edge_cnt == Prescale - 1) begin

                    if (strt_glitch)
                        next_state = 3'b000;

                    else
                        next_state = 3'b010;

                end

                else
                    next_state = 3'b001;

            end


            3'b010: begin

                if ((bit_cnt == 4'b0111) &&
                    (edge_cnt == Prescale - 1)) begin

                    if (PAR_EN)
                        next_state = 3'b011;

                    else
                        next_state = 3'b100;

                end

                else
                    next_state = 3'b010;

            end


            3'b011: begin

                if (edge_cnt == Prescale - 1)
                    next_state = 3'b100;

                else
                    next_state = 3'b011;

            end


            3'b100: begin

                if (edge_cnt == Prescale - 1)
                    next_state = 3'b000;

                else
                    next_state = 3'b100;

            end


            default:
                next_state = 3'b000;

        endcase

    end


    always @(*) begin

        dat_samp_en = 0;
        enable      = 0;
        deser_en    = 0;
        strt_chk_en = 0;
        par_chk_en  = 0;
        stp_chk_en  = 0;
        data_valid  = 0;


        case (current_state)

            3'b000: begin

                enable      = 0;
                dat_samp_en = 0;

            end


            3'b001: begin

                enable      = 1;
                dat_samp_en = 1;

                if (edge_cnt == Prescale - 1)
                    strt_chk_en = 1;

            end


            3'b010: begin

                enable      = 1;
                dat_samp_en = 1;

                if (edge_cnt == Prescale - 1)
                    deser_en = 1;

            end


            3'b011: begin

                enable      = 1;
                dat_samp_en = 1;

                if (edge_cnt == Prescale - 1)
                    par_chk_en = 1;

            end


            3'b100: begin

                enable      = 1;
                dat_samp_en = 1;

                if (edge_cnt == Prescale - 1) begin

                    stp_chk_en = 1;

                    if (!par_err && !stp_err)
                        data_valid = 1;

                end

            end


            default: begin

                enable = 0;

            end

        endcase

    end

endmodule


module UART_RX_topmodule (

    input wire       clk,
    input wire       RST,
    input wire       RX_IN,
    input wire       PAR_EN,
    input wire       PAR_TYP,
    input wire [4:0] Prescale,

    output wire [7:0] P_DATA,
    output wire       data_valid

);

    wire       dat_samp_en;
    wire       enable;
    wire       deser_en;
    wire       strt_chk_en;
    wire       par_chk_en;
    wire       stp_chk_en;
    wire       strt_glitch;
    wire       par_err;
    wire       stp_err;
    wire       sampled_bit;

    wire [4:0] edge_cnt;
    wire [3:0] bit_cnt;


    edge_bit_counter EDGE_COUNTER_BLOCK (

        .clk(clk),
        .RST(RST),
        .enable(enable),
        .bit_cnt_en(deser_en),
        .Prescale(Prescale),
        .edge_cnt(edge_cnt),
        .bit_cnt(bit_cnt)

    );


    data_sampling DATA_SAMPLING_BLOCK (

        .clk(clk),
        .RST(RST),
        .RX_IN(RX_IN),
        .dat_samp_en(dat_samp_en),
        .Prescale(Prescale),
        .edge_cnt(edge_cnt),
        .sampled_bit(sampled_bit)

    );


    deserializer DESERIALIZER_BLOCK (

        .clk(clk),
        .RST(RST),
        .sampled_bit(sampled_bit),
        .deser_en(deser_en),
        .P_DATA(P_DATA)

    );


    strt_check START_CHECK_BLOCK (

        .clk(clk),
        .RST(RST),
        .strt_chk_en(strt_chk_en),
        .sampled_bit(sampled_bit),
        .strt_glitch(strt_glitch)

    );


    parity_check PARITY_CHECK_BLOCK (

        .par_chk_en(par_chk_en),
        .PAR_TYP(PAR_TYP),
        .sampled_bit(sampled_bit),
        .P_DATA(P_DATA),
        .par_err(par_err)

    );


    stop_check STOP_CHECK_BLOCK (

        .stp_chk_en(stp_chk_en),
        .sampled_bit(sampled_bit),
        .stp_err(stp_err)

    );


    rx_fsm FSM_BLOCK (

        .clk(clk),
        .RST(RST),
        .RX_IN(RX_IN),
        .PAR_EN(PAR_EN),
        .Prescale(Prescale),
        .edge_cnt(edge_cnt),
        .bit_cnt(bit_cnt),
        .strt_glitch(strt_glitch),
        .par_err(par_err),
        .stp_err(stp_err),
        .dat_samp_en(dat_samp_en),
        .enable(enable),
        .deser_en(deser_en),
        .strt_chk_en(strt_chk_en),
        .par_chk_en(par_chk_en),
        .stp_chk_en(stp_chk_en),
        .data_valid(data_valid)

    );

endmodule


module UART_SYSTEM_topmodule (

    input wire       clk,
    input wire       RST,
    input wire [7:0] tx_p_data,
    input wire       tx_data_valid,
    input wire [4:0] Prescale,
    input wire       PAR_EN,
    input wire       PAR_TYP,

    output wire      TX_OUT,
    output wire      tx_busy,
    output wire [7:0] rx_p_data,
    output wire      rx_data_valid

);

    wire uart_line;


    assign TX_OUT = uart_line;


    UART_Tx_topmodule TX_BLOCK (

        .clk(clk),
        .RST(RST),
        .p_data(tx_p_data),
        .data_valid(tx_data_valid),
        .par_en(PAR_EN),
        .par_typ(PAR_TYP),
        .Prescale(Prescale),
        .tx_out(uart_line),
        .busy(tx_busy)

    );


    UART_RX_topmodule RX_BLOCK (

        .clk(clk),
        .RST(RST),
        .RX_IN(uart_line),
        .PAR_EN(PAR_EN),
        .PAR_TYP(PAR_TYP),
        .Prescale(Prescale),
        .P_DATA(rx_p_data),
        .data_valid(rx_data_valid)

    );

endmodule


module UART_SYSTEM_tb;

    reg        clk;
    reg        RST;
    reg [7:0]  tx_p_data;
    reg        tx_data_valid;
    reg [4:0]  Prescale;
    reg        PAR_EN;
    reg        PAR_TYP;

    wire       TX_OUT;
    wire       tx_busy;
    wire [7:0] rx_p_data;
    wire       rx_data_valid;


    UART_SYSTEM_topmodule DUT (

        .clk(clk),
        .RST(RST),
        .tx_p_data(tx_p_data),
        .tx_data_valid(tx_data_valid),
        .Prescale(Prescale),
        .PAR_EN(PAR_EN),
        .PAR_TYP(PAR_TYP),
        .TX_OUT(TX_OUT),
        .tx_busy(tx_busy),
        .rx_p_data(rx_p_data),
        .rx_data_valid(rx_data_valid)

    );


    always #2.5 clk = ~clk;


    initial begin

        $monitor("Time = %0t  TX_DATA = %b  PAR_EN = %b  PAR_TYP = %b  TX_OUT = %b  BUSY = %b  RX_DATA = %b  RX_VALID = %b",
                 $time, tx_p_data, PAR_EN, PAR_TYP, TX_OUT, tx_busy, rx_p_data, rx_data_valid);

    end


    task send_data;

        input [7:0] data;
        input       parity_enable;
        input       parity_type;

        begin

            tx_p_data     = data;
            PAR_EN        = parity_enable;
            PAR_TYP       = parity_type;

            tx_data_valid = 1;

            #5;

            tx_data_valid = 0;

            wait (rx_data_valid == 1);

            wait (rx_data_valid == 0);

            #20;

        end

    endtask


    initial begin

        clk           = 0;
        RST           = 0;
        tx_p_data     = 0;
        tx_data_valid = 0;

        Prescale      = 5'b01000;

        PAR_EN        = 0;
        PAR_TYP       = 0;


        #10;

        RST = 1;

        #10;


        send_data(8'b10100101, 1, 0);

        send_data(8'b11110011, 1, 1);

        send_data(8'b00111100, 0, 0);


        send_data(8'b00000000, 1, 0);
        send_data(8'b11111111, 1, 1);


        send_data(8'b11001100, 1, 0);
        send_data(8'b00110011, 1, 0);


        #25;

        $finish;

    end

endmodule
