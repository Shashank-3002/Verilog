//Parameterized Mini CNN Compute Unit(For bonus points consideration)
// This module Supports: MAC, ReLU, MaxPooling, Overflow Detection 
//Problem Statement 1: Mini CNN compute unit
//Our proposed solution is a parameterized Verilog module that implements a mini CNN compute unit capable of performing MAC, ReLU, and MaxPooling operations with overflow detection. 
//The module is designed to be flexible, allowing the window size to be adjusted through parameters.

module mini_cnn_param #(
    parameter integer WINDOW = 3,
    parameter integer ACC_WIDTH = 32
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire [1:0]               mode_select,     // 00: MAC, 01: ReLU, 10: MaxPool
    input  wire signed [7:0]        data_in,         // signed 8-bit input data
    input  wire                     load_enable,     // high to start loading memory
    input  wire                     start_operation, // one-cycle pulse to start processing

    output reg  signed [ACC_WIDTH-1:0] result_out,   // 32-bit signed output
    output reg                        busy,          // high when active
    output reg  [15:0]                current_index,  // debug index
    output reg                        overflow_flag   // high on signed overflow
);

    
    // Derived parameters
    localparam integer NN = WINDOW * WINDOW;
    localparam integer MEM_SIZE = 2 * NN; // pixels + kernels

    // Internal memory    
    reg signed [7:0] data_memory [0:MEM_SIZE-1];

    // FSM States    
    reg [2:0] op_state;
    localparam STATE_IDLE      = 3'd0;
    localparam STATE_LOAD_DATA = 3'd1;
    localparam STATE_RUNNING   = 3'd2;

    // Core registers    
    reg [15:0] index;
    reg signed [ACC_WIDTH-1:0] accumulator_reg;
    reg signed [ACC_WIDTH-1:0] max_pool_reg;
    reg signed [ACC_WIDTH-1:0] product_ext;
    reg signed [ACC_WIDTH-1:0] sum_temp;
    reg start_r;
    reg overflow_this_cycle;

    // Constants    
    localparam MODE_MAC      = 2'b00;
    localparam MODE_RELU     = 2'b01;
    localparam MODE_MAX_POOL = 2'b10;

    wire signed [ACC_WIDTH-1:0] ACC_MAX = {1'b0, {(ACC_WIDTH-1){1'b1}}};
    wire signed [ACC_WIDTH-1:0] ACC_MIN = {1'b1, {(ACC_WIDTH-1){1'b0}}};

    // Main Sequential Logic    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            result_out <= 0;
            busy <= 0;
            op_state <= STATE_IDLE;
            index <= 0;
            accumulator_reg <= 0;
            max_pool_reg <= -ACC_MIN; // most negative value
            current_index <= 0;
            start_r <= 0;
            overflow_flag <= 0;
        end else begin
            start_r <= start_operation;

            case (op_state)
                // STATE_IDLE
                STATE_IDLE: begin
                    if (load_enable) begin
                        busy <= 1;
                        index <= 0;
                        op_state <= STATE_LOAD_DATA;
                    end else if (start_operation && !start_r) begin
                        busy <= 1;
                        index <= 0;
                        accumulator_reg <= 0;
                        max_pool_reg <= -ACC_MIN;
                        overflow_flag <= 0;
                        op_state <= STATE_RUNNING;
                    end
                end

                // STATE_LOAD_DATA
                STATE_LOAD_DATA: begin
                    data_memory[index] <= data_in;
                    current_index <= index;
                    index <= index + 1;

                    if (index == MEM_SIZE - 1) begin
                        busy <= 0;
                        op_state <= STATE_IDLE;
                    end
                end

                // STATE_RUNNING
                STATE_RUNNING: begin
                    current_index <= index;

                    // Signed multiply and sum
                    product_ext = $signed(data_memory[index]) * $signed(data_memory[index + NN]);
                    sum_temp = accumulator_reg + product_ext;

                    // Detect overflow
                    overflow_this_cycle = ((accumulator_reg[ACC_WIDTH-1] == product_ext[ACC_WIDTH-1]) &&
                                            (sum_temp[ACC_WIDTH-1] != accumulator_reg[ACC_WIDTH-1]));
                    if (overflow_this_cycle)
                        overflow_flag <= 1;

                    accumulator_reg <= sum_temp;

                    // Max pooling
                    if (product_ext > max_pool_reg)
                        max_pool_reg <= product_ext;

                    // Final cycle
                    if (index == NN - 1) begin
                        case (mode_select)
                            MODE_MAC: begin
                                if (overflow_flag)
                                    result_out <= (accumulator_reg[ACC_WIDTH-1]) ? ACC_MIN : ACC_MAX;
                                else
                                    result_out <= sum_temp;
                            end

                            MODE_RELU: begin
                                if (overflow_flag)
                                    result_out <= (accumulator_reg[ACC_WIDTH-1]) ? 0 : ACC_MAX;
                                else if (sum_temp < 0)
                                    result_out <= 0;
                                else
                                    result_out <= sum_temp;
                            end

                            MODE_MAX_POOL: begin
                                if (product_ext > max_pool_reg)
                                    result_out <= product_ext;
                                else
                                    result_out <= max_pool_reg;
                            end
                        endcase

                        busy <= 0;
                        op_state <= STATE_IDLE;
                    end else begin
                        index <= index + 1;
                    end
                end
            endcase
        end
    end
endmodule
