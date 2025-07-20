package Calculator;

import FIFO::*;
import FIFOF::*;
import Stack::*;
import GetPut::*;
import StmtFSM::*;

typedef Int#(32) Data_t;
typedef 32       StackSize;

function Bit#(8) charToBits(Char c) = fromInteger(charToInteger(c)); // Get the ASCII value of a character

interface Calculator;
  interface Put#(Bit#(8)) dataIn;
  interface Get#(Data_t)  resultOut;
endinterface

module mkCalculator(Calculator);
  // FIFOs for input and output buffering
  FIFOF#(Bit#(8)) pending_char_ <- mkFIFOF();
  FIFO#(Data_t)   result_       <- mkFIFO();

  // Stacks for the operands and operators
  Stack#(Data_t)  values_ <- mkStack(valueOf(StackSize));
  Stack#(Bit#(8)) ops_    <- mkStack(valueOf(StackSize));

  // Temporary registers/wire for calculation
  Wire#(Bit#(8)) cin_ <- mkDWire(charToBits(" "));
  Wire#(Bit#(8)) op_  <- mkDWire(charToBits(" "));
  Reg#(Data_t)   numberIn_ <- mkReg(0);
  Reg#(Bool)     has_num_  <- mkReg(False);
  Reg#(Data_t)   val2_ <- mkReg(0);

  // Helper functions
  function Bool isDigit(Bit#(8) ch);
    return ch >= charToBits("0") && ch <= charToBits("9");
  endfunction

  function Bool isOperator(Bit#(8) ch);
    return ch == charToBits("+") || ch == charToBits("-") || ch == charToBits("*") || ch == charToBits("/");
  endfunction

  function Bit#(2) precedence(Bit#(8) op);
    if      (op == charToBits("*") || op == charToBits("/")) return 2;
    else if (op == charToBits("+") || op == charToBits("-")) return 1;
    else return 0; // For parentheses and other non-operators
  endfunction

  // Pops two values and an operator, performs the calculation, and pushes the result back
  function Stmt evaluate() = seq
    action
      val2_ <= values_.top(); values_.pop();
      $display($time(), " Pop  value: ", values_.top());
    endaction

    action
      let val1 = values_.top(); values_.pop();
      let op   = ops_.top(); ops_.pop();
      $display($time(), " Pop  value: ", values_.top());
      $display($time(), " Pop  operator: '%c'", ops_.top());

      Data_t res = case (op)
        charToBits("+"): return val1 + val2_;
        charToBits("-"): return val1 - val2_;
        charToBits("*"): return val1 * val2_;
        charToBits("/"): return val1 / ( (val2_ == 0) ? (1) : (val2_) ); // Avoid division by zero
        default: return 0;
      endcase;

      values_.push(res);
      $display($time(), " Push value: ", res);
    endaction
  endseq;

  // FSM to processes the expression stream
  FSM process_expression_ <- mkFSM(seq
    while(pending_char_.notEmpty()) seq
      if (isDigit(cin_)) seq

        action // If the character is a digit, accumulate it into numberIn
          numberIn_ <= 10 * numberIn_ + extend(unpack(cin_ - charToBits("0")));
          has_num_  <= True;
          pending_char_.deq();
        endaction

      endseq else if (has_num_) seq

        action // If we have a complete number, push it onto the values stack
          values_.push(numberIn_);
          numberIn_ <= 0;      // Reset the number accumulator
          has_num_  <= False;  // Reset the flag
          $display($time(), " Push value: ", numberIn_);

          if (cin_ == charToBits(" ")) begin // If the character is a space, ignore it
            pending_char_.deq();
          end
        endaction

      endseq else if (cin_ == charToBits("(")) seq

        action // If the character is '(', push it onto the ops stack
          $display($time(), " Push operator: '(' ");
          ops_.push(cin_);
          pending_char_.deq();
        endaction

      endseq else if (cin_ == charToBits(")")) seq

        while (!ops_.empty() && op_ != charToBits("(")) seq
          evaluate();
        endseq

        action // Pop the opening parenthesis '('
          ops_.pop();
          $display($time(), " Pop  operator: '%c'", ops_.top());
          pending_char_.deq();
        endaction

      endseq else if (cin_ == charToBits("=")) seq

        while (!ops_.empty()) seq
          evaluate();
        endseq

        action // Move the final result to the output FIFO
          result_.enq(values_.top());
          values_.pop();
          pending_char_.deq();
        endaction

      endseq else if (isOperator(cin_)) seq

        while (!ops_.empty() && precedence(op_) >= precedence(cin_)) seq
          evaluate();
        endseq

        action
          $display($time, " Push operator: '%c'", cin_);
          ops_.push(cin_);
          pending_char_.deq();
        endaction

      endseq else seq
        pending_char_.deq(); // Ignore space and other characters
      endseq
    endseq
  endseq);

  rule get_first_op;
    op_ <= ops_.top();
  endrule

  rule get_first_char;
    cin_ <= pending_char_.first();
  endrule

  rule start_processing;
    process_expression_.start();
  endrule

  interface Put dataIn    = toPut(pending_char_);
  interface Get resultOut = toGet(result_);
endmodule

endpackage