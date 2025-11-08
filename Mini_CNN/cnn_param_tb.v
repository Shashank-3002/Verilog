`timescale 1ns/1ps
module testbench_mini_cnn_param();

    parameter integer WINDOW = 5;               // Adjustable window size --> as of now we have set to 5
    localparam integer NN = WINDOW * WINDOW;
    localparam integer MEM_SIZE = 2 * NN;

    reg clk, reset;
    reg [1:0] mode_select;
    reg [7:0] data_in;
    reg load_enable, start_operation;

    wire signed [31:0] result_out;
    wire busy;
    wire [15:0] current_index;
    wire overflow_flag;

    // DUT
    mini_cnn_param #(.WINDOW(WINDOW)) UUT (
        .clk(clk), .reset(reset), .mode_select(mode_select),
        .data_in(data_in), .load_enable(load_enable), .start_operation(start_operation),
        .result_out(result_out), .busy(busy),
        .current_index(current_index), .overflow_flag(overflow_flag)
    );

    reg [7:0] test_data [0:(2*WINDOW*WINDOW)-1];
    integer i;
    integer sum_expected;

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Load data into memory
    task load_all;
        begin
            load_enable = 1;
            #10;
            for (i = 0; i < MEM_SIZE; i = i + 1) begin
                data_in = test_data[i];
                #10;
            end
            load_enable = 0;
            wait(busy == 0);
            #10;
        end
    endtask

    // Run operation
    task run_op;
        begin
            start_operation = 1;
            #10;
            start_operation = 0;
            wait(busy == 0);
            #10;
        end
    endtask

    initial begin
        reset = 1; load_enable = 0; start_operation = 0; data_in = 0;
        #15 reset = 0;
        $display("[%0t] Reset complete", $time);

        $display("\n--- Test 1: MaxPool ---");
        for (i = 0; i < NN; i = i + 1)
            test_data[i] = i + 1; // 1..NN
        for (i = 0; i < NN; i = i + 1)
            test_data[NN + i] = 8'd1;

        load_all();
        mode_select = 2'b10;
        run_op();
        $display("MaxPool result=%0d overflow=%b", result_out, overflow_flag);
        $display("Expected max value = %0d\n", NN);

        $display("\n--- Test 2: ReLU ---");
        for (i = 0; i < NN; i = i + 1) begin
            if (i < NN/2)
                test_data[i] = -8'd5; // negative half
            else
                test_data[i] = 8'd5;  // positive half
            test_data[NN + i] = 8'd1;
        end

        load_all();
        mode_select = 2'b01;
        run_op();

        sum_expected = 0;
        for (i = 0; i < NN; i = i + 1)
            sum_expected = sum_expected + $signed(test_data[i]) * $signed(test_data[NN + i]);
        if (sum_expected < 0)
            sum_expected = 0;
        $display("ReLU result=%0d expected=%0d overflow=%b\n",
                 result_out, sum_expected, overflow_flag);

        $display("\n--- Test 3: MAC ---");
        for (i = 0; i < NN; i = i + 1) begin
            test_data[i] = i + 1;
            test_data[NN + i] = 8'd1;
        end

        load_all();
        mode_select = 2'b00;
        run_op();

        sum_expected = 0;
        for (i = 1; i <= NN; i = i + 1)
            sum_expected = sum_expected + i;
        $display("MAC result=%0d expected=%0d overflow=%b\n",
                 result_out, sum_expected, overflow_flag);

        $display("\n--- Test 4: Overflow Demo ---");
        for (i = 0; i < NN; i = i + 1) begin
            test_data[i] = 8'd120;
            test_data[NN + i] = 8'd120;
        end

        load_all();
        mode_select = 2'b00;
        run_op();
        $display("Overflow Test result=%0d overflow=%b\n",
                 result_out, overflow_flag);

        #50 $finish;
    end

    initial begin
        $dumpfile("mini_cnn_param_wave.vcd");
        $dumpvars(0, testbench_mini_cnn_param);
    end
endmodule
