module sub #(parameter WIDTH = 4) (
    input [WIDTH-1:0] A, B,
    output [2*WIDTH-1:0] result,
    output carry_out  // Borrow flag
);
    assign {carry_out, result[WIDTH-1:0]} = A - B;  // Sub with borrow
    assign result[2*WIDTH-1:WIDTH] = 0;
endmodule