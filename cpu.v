module cpu(input [7:0]a,input [7:0]b,input clk,output [39:0]result,   output [7:0] pc_out,
    output [3:0] opcode_out);
reg [15:0] memory [0:255];
reg insig;
wire [15:0] instructionregister;
wire [3:0]  op_code;
wire [2:0]  destination;
wire [2:0]  source;
wire [7:0]  address;
wire [7:0] pc;
wire [15:0] instruction;
wire [7:0]new_address;
wire zero_flag;
wire carry_flag;
wire [7:0] reg_a;
wire [7:0] reg_b;
wire halt;
wire [15:0] alu_result;
assign alu_result = result[15:0];
assign pc_out = pc;
assign opcode_out = op_code;
integer i;

initial begin
    for(i=0;i<256;i=i+1)
    memory[i]=16'b0000_000000_000_000;
    memory[0]  = 16'b0010_000000_000_001; // A -> AR1
memory[1]  = 16'b0010_000000_001_010; // B -> AR2

memory[2]  = 16'b0101_000000_001_010; // MUL AR1,AR2
memory[3]  = 16'b1101_000000_000_011; // RESULT -> AR3

memory[4]  = 16'b0100_000000_001_010; // SUB AR1,AR2
memory[5]  = 16'b1101_000000_000_100; // RESULT -> AR4

memory[6]  = 16'b0110_000000_001_010; // DIV AR1,AR2
memory[7]  = 16'b1101_000000_000_101; // RESULT -> AR5

memory[8]  = 16'b0011_000000_011_100; // AR3 + AR4
memory[9]  = 16'b1101_000000_000_110; // RESULT -> AR6

memory[10] = 16'b0011_000000_110_101; // AR6 + AR5
memory[11] = 16'b1101_000000_000_001; // RESULT -> AR1

memory[12] = 16'b1111_000000_000_000; // HALT
end
always @(posedge clk) begin
    insig<=1'b1;
end
assign instruction = memory[pc];
register re(.a(a),.b(b),.memory(instruction),.insig(insig),.clk(clk),.instructionregister(instructionregister),.pc(pc));
controlunit cu(
    .instructionregister(instructionregister),
    .clk(clk),
    .a(a),
    .b(b),
    .alu_result(result[15:0]),
    .new_address(new_address),
    .op_code(op_code),
    .destination(destination),
    .source(source),
    .address(address),
    .reg_a(reg_a),
    .reg_b(reg_b)
);
alu alu(.clk(clk),.a(reg_a),.b(reg_b),.op_code(op_code),.result(result),.zero_flag(zero_flag),.carry_flag(carry_flag));
always @(posedge clk)
begin
    $display("PC=%d OPCODE=%b AR1=%d AR2=%d RESULT=%d",
              pc, op_code, reg_a, reg_b, result);
end
endmodule
module register(input [7:0]a,input [7:0]b,output [7:0]pc,input [15:0]memory,input insig,input clk,output reg [15:0]instructionregister);
reg [7:0]addressregister;
reg [7:0]programcounter;
reg [15:0]memorydataregister;
initial begin
    programcounter = 0;
end
always @(posedge clk)begin
if(insig==1) begin
addressregister<=programcounter;
programcounter<=programcounter+1;
end
end
always @(posedge clk)
begin
    instructionregister <= memory;
end
assign pc = programcounter;
endmodule
module controlunit(
    input [15:0] instructionregister,
    input clk,
    input [7:0] a,
    input [7:0] b,
    input [15:0] alu_result,
    input [7:0] new_address,

    output reg [3:0] op_code,
    output reg [2:0] destination,
    output reg [2:0] source,
    output reg [7:0] address,

    output reg [7:0] reg_a,
    output reg [7:0] reg_b
);

reg [15:0] ar1;
reg [15:0] ar2;
reg [15:0] ar3;
reg [15:0] ar4;
reg [15:0] ar5;
reg [15:0] ar6;

reg halt;

initial begin
    ar1 = 0;
    ar2 = 0;
    ar3 = 0;
    ar4 = 0;
    ar5 = 0;
    ar6 = 0;
    halt = 0;
end

always @(*) begin
    op_code     = instructionregister[15:12];
    address     = instructionregister[11:6];
    source      = instructionregister[5:3];
    destination = instructionregister[2:0];
end

always @(posedge clk) begin
    if(op_code == 4'b1111)
        halt <= 1'b1;
end

always @(posedge clk) begin

    case ({source,destination})

        6'b000001: ar1 <= a;
        6'b000010: ar2 <= a;
        6'b000011: ar3 <= a;
        6'b000100: ar4 <= a;
        6'b000101: ar5 <= a;
        6'b000110: ar6 <= a;

        6'b001001: ar1 <= b;
        6'b001010: ar2 <= b;
        6'b001011: ar3 <= b;
        6'b001100: ar4 <= b;
        6'b001101: ar5 <= b;
        6'b001110: ar6 <= b;

        6'b010010: ar2 <= ar1;
        6'b010011: ar3 <= ar1;
        6'b010100: ar4 <= ar1;
        6'b010101: ar5 <= ar1;
        6'b010110: ar6 <= ar1;

        6'b011001: ar1 <= ar2;
        6'b011011: ar3 <= ar2;
        6'b011100: ar4 <= ar2;
        6'b011101: ar5 <= ar2;
        6'b011110: ar6 <= ar2;

        6'b100001: ar1 <= ar3;
        6'b100010: ar2 <= ar3;
        6'b100100: ar4 <= ar3;
        6'b100101: ar5 <= ar3;
        6'b100110: ar6 <= ar3;

        6'b101001: ar1 <= ar4;
        6'b101010: ar2 <= ar4;
        6'b101011: ar3 <= ar4;
        6'b101101: ar5 <= ar4;
        6'b101110: ar6 <= ar4;

        6'b110001: ar1 <= ar5;
        6'b110010: ar2 <= ar5;
        6'b110011: ar3 <= ar5;
        6'b110100: ar4 <= ar5;
        6'b110110: ar6 <= ar5;

        6'b111001: ar1 <= ar6;
        6'b111010: ar2 <= ar6;
        6'b111011: ar3 <= ar6;
        6'b111100: ar4 <= ar6;
        6'b111101: ar5 <= ar6;

        default: ;

    endcase

end

always @(posedge clk) begin

    if(op_code == 4'b1101) begin

        case(destination)

            3'b001: ar1 <= alu_result;
            3'b010: ar2 <= alu_result;
            3'b011: ar3 <= alu_result;
            3'b100: ar4 <= alu_result;
            3'b101: ar5 <= alu_result;
            3'b110: ar6 <= alu_result;

            default: ;

        endcase

    end

end

always @(*) begin

    case(source)
        3'b001: reg_a = ar1[7:0];
        3'b010: reg_a = ar2[7:0];
        3'b011: reg_a = ar3[7:0];
        3'b100: reg_a = ar4[7:0];
        3'b101: reg_a = ar5[7:0];
        3'b110: reg_a = ar6[7:0];
        default: reg_a = 8'd0;
    endcase

    case(destination)
        3'b001: reg_b = ar1[7:0];
        3'b010: reg_b = ar2[7:0];
        3'b011: reg_b = ar3[7:0];
        3'b100: reg_b = ar4[7:0];
        3'b101: reg_b = ar5[7:0];
        3'b110: reg_b = ar6[7:0];
        default: reg_b = 8'd0;
    endcase

end
always @(posedge clk)
begin
    if(op_code == 4'b1101)
    begin
        case(destination)
            3'b001: ar1 <= alu_result;
            3'b010: ar2 <= alu_result;
            3'b011: ar3 <= alu_result;
            3'b100: ar4 <= alu_result;
            3'b101: ar5 <= alu_result;
            3'b110: ar6 <= alu_result;
        endcase
    end
end

endmodule
module alu(input clk,input [7:0]a,input [7:0]b,input [3:0]op_code,output reg [39:0]result,output reg zero_flag,output reg carry_flag);
wire adder_carry;
wire [7:0]sum;
wire [7:0]difference;
wire [7:0]shiftout;
wire [7:0]and_logic;
wire [7:0]or_logic;
wire [7:0]xor_logic;
wire [7:0]nand_logic;
wire [15:0]mul;
wire [7:0]quitient;
wire [7:0]remainder;
wire [7:0]comparitor;
wire [7:0]aiout;
wire [7:0]biout;
wire [7:0]adout;
wire [7:0]bdout;
wire [7:0]alr;
wire [7:0]blr;
wire [15:0]shiftleftout;
wire [15:0]shiftrightout;
wire bit_op;
wire bit_in;
wire bout;
wire [7:0]c;
adder ADD1(.a(a),.b(b),.cin(1'b0),.cout(adder_carry),.sum(sum));
subtractor SUB1(.a(a),.b(b),.difference(difference));
logicoperators LOG1(
    .a(a),
    .b(b),
    .and_logic(and_logic),
    .or_logic(or_logic),
    .xor_logic(xor_logic),
    .nand_logic(nand_logic)
);
multiplier MUL1(
    .a(a),
    .b(b),
    .clk(clk),
    .mul(mul)
);

division DIV1(
    .a(a),
    .b(b),
    .clk(clk),
    .qutient(quitient),
    .remainder(remainder)
);
comparitor com(.a(a),.b(b),.clk(clk),.comparitor(comparitor));
increment inc(.a(a),.b(b),.clk(clk),.aiout(aiout),.biout(biout));
decrement dec(.a(a),.b(b),.clk(clk),.adout(adout),.bdout(bdout));
shiftleft shl(.a(a),.b(b),.clk(clk),.shiftleftout(shiftleftout));
shiftright shr(.a(a),.b(b),.clk(clk),.shiftrightout(shiftrightout));
always @(*) begin
  carry_flag=1'b0;
  zero_flag=1'b1;
    case(op_code)
        4'b0011:begin
         result = {8'b0,sum};
         carry_flag = adder_carry;
         end          
        4'b0100:begin
         result = difference;
         carry_flag = 1'b0;
         end         
        4'b0101: result = mul;          
        4'b0110: result = {quitient,remainder};
        4'b0111: result = {and_logic,xor_logic};          
        4'b1000: result ={ or_logic, nand_logic};         
        4'b1001: result ={shiftleftout,shiftrightout};           
        4'b1010:result={aiout[7:0],biout[7:0]}; 
        4'b1011:result={adout[7:0],bdout[7:0]};
        4'b1100:result=comparitor;
        default: result = result;
    endcase
 if (result == 16'b0)
            zero_flag = 1'b1;
        else
            zero_flag = 1'b0;
    end
endmodule
module adder(input [7:0]a,input [7:0]b,input cin,output cout,output [7:0]sum);
wire [8:0]C;
wire [7:0]g;
wire [7:0]p;
assign C[0]=cin;
assign g=a&b;
assign p=a^b;
assign C[1]=g[0]|(p[0]&C[0]);
assign C[2]=g[1]|(p[1]&(C[1]));
assign C[3]=g[2]|(p[2]&(C[2]));
assign C[4]=g[3]|(p[3]&(C[3]));
assign C[5]=g[4]|(p[4]&(C[4]));
assign C[6]=g[5]|(p[5]&(C[5]));
assign C[7]=g[6]|(p[6]&(C[6]));
assign C[8]=g[7]|(p[7]&(C[7]));
assign sum=p^C;
assign cout=C[8];
endmodule
module subtractor(input [7:0]a,input [7:0]b,output borrow,output [7:0]difference);
wire [7:0]bn;
wire cout;
assign bn=~b;
adder adder1(.a(a),.b(bn),.sum(difference),.cin(1'b1),.cout(cout));
assign borrow=~cout;
endmodule
module logicoperators(input [7:0]a,input [7:0]b,output [7:0]and_logic,output [7:0]xor_logic,output [7:0]nand_logic,output [7:0]or_logic);
assign and_logic=a&b;
assign or_logic=a|b;
assign nand_logic=~(a&b);
assign xor_logic=a^b;
endmodule

module multiplier(
    input [7:0] a,
    input [7:0] b,
    input clk,
    output reg [15:0] mul
);

reg signed [8:0] A;
reg signed [7:0] Q;
reg signed [8:0] M;

reg Q_1;

integer i;

always @(posedge clk) begin

    A = 9'b0;
    Q = a;
    M = {b[7], b};
    Q_1 = 1'b0;

    for(i=0; i<8; i=i+1) begin

        case({Q[0], Q_1})

            2'b01:
                A = A + M;

            2'b10:
                A = A - M;

            default:
                A = A;

        endcase

        // arithmetic right shift

        Q_1 = Q[0];

        Q = {A[0], Q[7:1]};

        A = {A[8], A[8:1]};

    end

    mul = {A[7:0], Q};

end

endmodule
module division(input [7:0]a,input clk,input [7:0]b,output reg [7:0]qutient,output reg [7:0]remainder);
reg [8:0]int;
reg [7:0]divided;
reg [7:0]divisor;
integer i;
always @(posedge clk)begin
int=9'b0;
divided=a;
divisor=b;
for(i=0;i<8;i=i+1) begin
{int,divided}={int,divided}<<1;
int=int-divisor;
case(int[8])
1'b1: begin
int=int+divisor;
divided[0]=1'b0;
end
1'b0: begin
divided[0]=1'b1;
end
endcase
end
qutient<=divided;
remainder<=int[7:0];
end
endmodule
module comparitor(input [7:0]a,input [7:0]b,input clk,output reg [7:0]comparitor);
always @(posedge clk)begin
if(a>b) begin
comparitor<=8'b10000000;
end
else if(b>a) begin
comparitor<=8'b00000001;
end
else begin
comparitor<=8'b00000000;
end
end
endmodule
module increment(input [7:0]a,input [7:0]b,input clk,output reg [7:0]aiout,output reg [7:0]biout);
always @(posedge clk)begin
aiout<=a+1;
biout<=b+1;
end
endmodule
module decrement(input [7:0]a,input [7:0]b,input clk,output reg [7:0]adout,output reg [7:0]bdout);
always @(posedge clk)begin
adout<=a-1;
bdout<=b-1;
end
endmodule
module shiftleft(input [7:0]a,input [7:0]b,input clk,output reg [15:0]shiftleftout);
reg [7:0]aout;
reg [7:0]bout;
always @(posedge clk)begin
aout<=a<<1;
bout<=b<<1;
shiftleftout<={aout,bout};
end
endmodule
module shiftright(input [7:0]a,input [7:0]b,input clk,output reg [15:0]shiftrightout);
reg [7:0]aout;
reg [7:0]bout;
always @(posedge clk)begin
aout<=a>>1;
bout<=b>>1;
shiftrightout<={aout,bout};
end
endmodule


