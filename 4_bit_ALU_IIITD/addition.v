module add #(parameter WIDTH = 4) (
    input [WIDTH-1:0] A, B,
    output [2*WIDTH-1:0] result,  // 8-bit for 4-bit inputs
    output carry_out
);
    assign {carry_out, result[WIDTH-1:0]} = A + B;  // Add with carry
    assign result[2*WIDTH-1:WIDTH] = 0;  // Zero-extend upper bits
endmodule