module cpu_tb;

reg [7:0] a;
reg [7:0] b;
reg clk;

wire [39:0] result;
wire [7:0] pc_out;
wire [3:0] opcode_out;

cpu cpu1(
    .a(a),
    .b(b),
    .clk(clk),
    .result(result),
    .pc_out(pc_out),
    .opcode_out(opcode_out)
);

initial begin
    clk = 1'b0;
    forever #1 clk = ~clk;
end
initial begin
$dumpfile("cpu.vcd");
$dumpvars(0,cpu_tb);
end

initial begin

    a = 8'd8;
    b = 8'd3;

    #100;

    a = 8'd15;
    b = 8'd3;

    #100;

    $finish;
end

initial begin
    $monitor(
    "T=%0t PC=%0d OP=%b RESULT=%0d",
    $time,
    pc_out,
    opcode_out,
    result[15:0]
    );
end

always @(posedge clk) begin
    $display(
    "PC=%0d OP=%b AR1=%0d AR2=%0d AR3=%0d AR4=%0d AR5=%0d AR6=%0d RESULT=%0d",
    cpu1.pc_out,
    cpu1.op_code,
    cpu1.cu.ar1,
    cpu1.cu.ar2,
    cpu1.cu.ar3,
    cpu1.cu.ar4,
    cpu1.cu.ar5,
    cpu1.cu.ar6,
    cpu1.result[15:0]
    );
end

endmodule
