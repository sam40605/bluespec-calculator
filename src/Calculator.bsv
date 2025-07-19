package Calculator;

import FIFO::*;
import FIFOF::*;
import Stack::*;
import GetPut::*;
import StmtFSM::*;

function Bit#(8) charToBits(Char c) = fromInteger(charToInteger(c));

interface Calculator;
  interface Put#(Bit#(8))  dataIn;
  interface Get#(Int#(32)) resultOut;
endinterface

module mkCalculator(Calculator);
  // FIFOs for input and output buffering
  FIFOF#(Bit#(8)) pending_char_ <- mkFIFOF();
  FIFO#(Int#(32)) result_       <- mkFIFO();

  // Stacks for the shunting-yard based algorithm
  Stack#(Int#(32)) values <- mkStack(32);
  Stack#(Bit#(8))  ops    <- mkStack(32);

  // Temporary registers/wire for number accumulation
  Wire#(Bit#(8)) cin_ <- mkDWire(charToBits(" "));
  Wire#(Bit#(8)) op_  <- mkDWire(charToBits(" "));
  Reg#(Int#(32)) numberIn_ <- mkReg(0);
  Reg#(Bool)     has_num_  <- mkReg(False);
  Reg#(Int#(32)) val2 <- mkReg(0);

  // Helper functions
  function Bool isDigit(Bit#(8) ch);
    return ch >= charToBits("0") && ch <= charToBits("9");
  endfunction

  function Bool isOperator(Bit#(8) ch);
    return ch == charToBits("+") || ch == charToBits("-") || ch == charToBits("*") || ch == charToBits("/");
  endfunction

  function Bit#(2) precedence(Bit#(8) op);
    if (op == charToBits("*") || op == charToBits("/"))
      return 2;
    else if (op == charToBits("+") || op == charToBits("-"))
      return 1;
    else
      return 0; // For parentheses
  endfunction

  // Pops two values and an operator, performs the calculation, and pushes the result back
  function Stmt evaluate() = seq
    action
      val2 <= values.top(); values.pop();
      $display($time(), " Pop  value: ", values.top());
    endaction

    action
      let val1 = values.top(); values.pop();
      let op   = ops.top(); ops.pop();
      $display($time(), " Pop  operator: '%c'", op);
      $display($time(), " Pop  value: %d", val1);

      Int#(32) res = case (op)
        charToBits("+"): return val1 + val2;
        charToBits("-"): return val1 - val2;
        charToBits("*"): return val1 * val2;
        charToBits("/"): return val1 / ( (val2 == 0) ? (1) : (val2) ); // Avoid division by zero
        default: return 0;
      endcase;

      values.push(res);
      $display($time(), " Push value: ", res);
    endaction
  endseq;

  // The main FSM that processes the expression stream
  FSM process_char_ <- mkFSM(seq
    while(pending_char_.notEmpty()) seq

      if (isDigit(cin_)) seq

        action // If the character is a digit, accumulate it into numberIn_
          numberIn_ <= 10 * numberIn_ + extend(unpack(cin_ - charToBits("0")));
          has_num_  <= True;
          pending_char_.deq();
        endaction

      endseq else if (has_num_) seq

        action // If we have a complete number, push it onto the values stack
          values.push(numberIn_);
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
          ops.push(cin_);
          pending_char_.deq();
        endaction

      endseq else if (cin_ == charToBits(")")) seq

        while (!ops.empty() && op_ != charToBits("(")) seq
          evaluate();
        endseq

        action // Pop the opening parenthesis '('
          ops.pop();
          $display($time(), " Pop  operator: '%c'", ops.top());
          pending_char_.deq();
        endaction

      endseq else if (cin_ == charToBits("=")) seq

        while (!ops.empty()) seq
          evaluate();
        endseq

        action // Move the final result to the output FIFO
          result_.enq(values.top());
          values.pop();
          pending_char_.deq();
        endaction

      endseq else if (isOperator(cin_)) seq

        while (!ops.empty() && precedence(op_) >= precedence(cin_)) seq
          evaluate();
        endseq

        action
          $display($time, " Push operator: '%c'", cin_);
          ops.push(cin_);
          pending_char_.deq();
        endaction

      endseq else seq

        action
          $display($time(), " Ignoring '%c'", cin_);
          pending_char_.deq();
        endaction

      endseq

    endseq
  endseq);

  rule get_first_op;
    op_ <= ops.top();
  endrule

  rule get_first;
    cin_ <= pending_char_.first();
  endrule

  rule start_processing;
    process_char_.start();
  endrule

  interface Put dataIn    = toPut(pending_char_);
  interface Get resultOut = toGet(result_);
endmodule

endpackage