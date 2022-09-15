// Code your testbench here
// or browse Examples

`define STRINGIFY(x) `"x`"
`define HPATH(signal) top.chip.block.signal
`define p(a, b) `"a = b`"
`define assert_equal(_cycle, _expected, _actual) assert((_expected) == (_actual)) else begin $display("cycle = %0d, expected = %0x, actual = %0x %s", (_cycle), (_expected), (_actual)); assert_fail = 1; end

module top;
    logic assert_fail;

    function automatic integer abc(string str);
        return 1;
    endfunction

    function automatic integer def(string str);
        return 2;
    endfunction

    initial begin
        
    end
endmodule