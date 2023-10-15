%{
#include <stdlib.h>
#include <stdio.h>

enum instruction_format { IF_R, IF_I, IF_UI, IF_S, IF_B, IF_J };

static struct instruction {
  enum instruction_format format;
  int funct3 : 3;
  int funct7 : 7;
  int imm : 20;
  int opcode : 7;
  int rd : 5;
  int rs1 : 5;
  int rs2 : 5;
} instruction;

static void printbin(int val, char bits);
static int bit_range(int val, char begin, char end);
static void print_instruction(struct instruction);
int yylex();
void yyerror(char* s);
%}

%start program
%union {
  long l;
}
%token <l> REGISTER NEWLINE COMMA LEFT_PAREN RIGHT_PAREN MINUS IMMEDIATE
%token ADD SUB ADDI LW SW BEQ J AUIPC
%type <l> imm

%%
program : segments
;
segments : segment
//| segment
;
segment : %empty
| text
;
text : text NEWLINE instruction
| instruction
;
instruction : r-type
{
  print_instruction(instruction);
}
| i-type
{
  print_instruction(instruction);  
}
| s-type 
{
  print_instruction(instruction);
}
| b-type
{
  print_instruction(instruction);
}
| j-type
{
  print_instruction(instruction);
}
| ui-type
{
  print_instruction(instruction);
}
;
//TOKEN DEFINITIONS
//R-TYPE DEFINITIONS
r-type : add
{
  instruction.format = IF_R;
}
| sub 
{
  instruction.format = IF_R; 
}
;
//I-TYPE DEFINITIONS
i-type: addi
{
  instruction.format = IF_I;
}
| lw 
{
  instruction.format = IF_I;
}
;
//S-TYPE DEFINITIONS
s-type : sw
{
  instruction.format = IF_S;
}
;
//B-TYPE DEFINITIONS
b-type : beq 
{
  instruction.format = IF_B;
}
;
//J-TYPE DEFINITIONS
j-type: auipc
{
  instruction.format = IF_J;
}
;
//UI-TYPE DEFINITIONS
ui-type: j 
{
  instruction.format = IF_UI;
}
//INSTRUCTION FORMATS
//R-TYPE INTRCTION FORMATS
add: ADD REGISTER COMMA REGISTER COMMA REGISTER
{
  instruction.opcode = 0b0110011;
  instruction.funct7 = 0;
  instruction.funct3 = 0;
  instruction.rd = $2;
  instruction.rs1 = $4;
  instruction.rs2 = $6;
}
;
sub: SUB REGISTER COMMA REGISTER COMMA REGISTER
{
  instruction.opcode = 0b0110011;
  instruction.funct7 = 0b0100000;
  instruction.funct3 = 0;
  instruction.rd = $2;
  instruction.rs1 = $4;
  instruction.rs2 = $6;
}
;
//I-TYPE INSTRUCTION DEFINITIONS
addi: ADDI REGISTER COMMA REGISTER COMMA imm
{
  instruction.opcode = 0b0010011;
  instruction.funct3 = 0b000;
  instruction.imm = bit_range($6, 0, 12);
  instruction.rd = $2;
  instruction.rs1 = $4;
}
;
lw: LW REGISTER COMMA imm LEFT_PAREN REGISTER RIGHT_PAREN
{
  instruction.opcode = 0b0000011;
  instruction.funct3 = 0b010;
  instruction.imm = bit_range($4, 0, 12);
  instruction.rd = $2;
  instruction.rs1 = $6;
}
;
//S-TYPE INSTRUCTION FORMATS
sw: SW REGISTER COMMA imm LEFT_PAREN REGISTER RIGHT_PAREN
{
  instruction.opcode = 0b0100011;
  instruction.funct3 = 0b010;
  instruction.imm = bit_range($4, 0, 12);
  instruction.rs2 = $2;
  instruction.rs1 = $6;
}
;
//B-TYPE INSTRUCTION FOMATS (SAME AS S TYPE BUT PHUQUE IT)
beq: BEQ REGISTER COMMA REGISTER COMMA imm
{
  instruction.opcode = 0b1100011;
  instruction.funct3 = 000; 
  instruction.rs1 = $2;
  instruction.rs2 = $4;
  instruction.imm = bit_range($6, 0, 12);
}
;
//J-TYPE INSTRUCTION FORMATS
auipc: AUIPC REGISTER COMMA imm
{
  instruction.opcode = 0b0010111;
  instruction.imm = bit_range($4, 0, 20);
  instruction.rd = $2;
} 
;
//UI-TYPE INSTRUCTION
j: J imm
{
  instruction.opcode = 0b1101111;
  instruction.imm = bit_range($2, 0, 20);
  instruction.rd = 0;
}
//TYPE DEFINITIONS
imm : MINUS IMMEDIATE
{
$$ = -1 * $2;
}
| IMMEDIATE
{
$$ = $1;
}
;
%%
static void print_instruction(struct instruction instruction) {
  switch (instruction.format) {
    case IF_R:
        printbin(instruction.funct7, 7);
        printbin(instruction.rs2, 5);
        printbin(instruction.rs1, 5);
        printbin(instruction.funct3, 3);
        printbin(instruction.rd, 5);
        printbin(instruction.opcode, 7);
      break;
    case IF_I:
        printbin(instruction.imm, 12);
        printbin(instruction.rs1, 5);
        printbin(instruction.funct3, 3);
        printbin(instruction.rd, 5);
        printbin(instruction.opcode, 7);
      break;
    case IF_UI:
        printbin(bit_range(instruction.imm, 0, 20), 20);
        printbin(instruction.rd, 5);
        printbin(instruction.opcode, 7); 
      break;
    case IF_S:
        printbin(bit_range(instruction.imm, 5, 12), 7);
        printbin(instruction.rs2, 5);
        printbin(instruction.rs1, 5);
        printbin(instruction.funct3, 3);
        printbin(bit_range(instruction.imm, 0, 5), 5);
        printbin(instruction.opcode, 7);
      break;
    case IF_B:
        printbin(bit_range(instruction.imm, 5, 12), 7);
        printbin(instruction.rs2, 5);
        printbin(instruction.rs1, 5);
        printbin(instruction.funct3, 3);
        printbin(bit_range(instruction.imm, 0, 5), 5);
        printbin(instruction.opcode, 7);
      break;
    case IF_J:
        printbin(bit_range(instruction.imm, 0, 20), 20);
        printbin(instruction.rd, 5);
        printbin(instruction.opcode, 7);
      break;
    default:
      exit(-1);
  }
  printf("\n");
}
static void printbin(int val, char bits) {
  for (char i = bits - 1; i >= 0; i--) {
    if (val & (1 << i)) {
      putchar('1');
    } else {
      putchar('0');
    }
  }
}

static int bit_range(int val, char begin, char end) {
  int mask = ((1 << end) - 1) ^ ((1 << begin) - 1);
  return (val & mask) >> begin;
}

void yyerror(char *msg){
    // If your assembler cannot parse input it will exit, make sure to test locally using the tests on canvas
    fprintf(stderr, "Error: %s\n", msg);
}

int main(){
 #ifdef YYDEBUG
 int yydebug = 1;
 #endif /* YYDEBUG */
  yyparse();  
  return 0;
}
