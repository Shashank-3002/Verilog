`timescale 1ns/1ps
module alu_tb;
    parameter WIDTH = 4;
    reg [WIDTH-1:0] A, B;
    reg [2:0] opcode;
    wire [2*WIDTH-1:0] result;
    wire carry_out;

    // Instantiate DUT
    alu_top #(.WIDTH(WIDTH)) dut (
        .A(A), .B(B), .opcode(opcode), .result(result), .carry_out(carry_out)
    );

    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);
        $monitor("Time=%0t | A=%b | B=%b | opcode=%03b | result=%08b | carry_out=%b",
          $time, A, B, opcode, result, carry_out);


        // Test cases for all opcodes
        A = 4'b1010; B = 4'b0101; opcode = 3'b000; #10; // Add
        opcode = 3'b001; #10; // Sub
        opcode = 3'b010; #10; // Mul
        opcode = 3'b011; #10; // Div
        opcode = 3'b100; #10; // AND
        opcode = 3'b101; #10; // OR
        opcode = 3'b110; #10; // XOR

        // Custom operations (opcode = 111)
        B = 4'b0001; opcode = 3'b111; #10;
        B = 4'b0010; opcode = 3'b111; #10;
        B = 4'b0011; opcode = 3'b111; #10;

        // Edge cases
        A = 4'b1111; B = 4'b0001; opcode = 3'b000; #10;
        A = 4'b0000; B = 4'b0000; opcode = 3'b011; #10;
        A = 4'b1100; B = 4'b0000; opcode = 3'b111; #10;

        // Random tests for coverage
        repeat(20) begin
            A = $random % (1<<WIDTH);
            B = $random % (1<<WIDTH);
            opcode = $random % 8;
            #10;
        end

        $finish;
    end
endmodule
