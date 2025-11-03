module logic_ops #(parameter WIDTH = 4) (
    input  [WIDTH-1:0] A, B,
    input  [1:0] sel,   // 00: AND, 01: OR, 10: XOR
    output reg [2*WIDTH-1:0] result,
    output reg carry_out
);
    always @(*) begin
        case (sel)
            2'b00: result = { {WIDTH{1'b0}}, (A & B) };  // AND
            2'b01: result = { {WIDTH{1'b0}}, (A | B) };  // OR
            2'b10: result = { {WIDTH{1'b0}}, (A ^ B) };  // XOR
            default: result = {2*WIDTH{1'b0}};
        endcase
        carry_out = 1'b0;  // Logic ops don’t produce carry
    end
endmodule
