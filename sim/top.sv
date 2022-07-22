module top;
    logic[3:0] a;
    logic[3:0] b;
    logic[3:0] sum;

    adder adder_inst(
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 5;
        b = 6;
        assert(sum == 12) else $finish;
        $display($time,, "successful!");
        $display($time,, "successful2!");
    end

    initial begin
        $fsdbDumpfile("top.fsdb");
        $fsdbDumpvars();
    end
endmodule
