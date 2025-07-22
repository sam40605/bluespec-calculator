package Calculator;

import FIFO::*;
import FIFOF::*;
import Stack::*;
import GetPut::*;
import StmtFSM::*;

`ifndef DATA_WIDTH
`define DATA_WIDTH 32
`endif

`ifndef STACK_SIZE
`define STACK_SIZE 32
`endif

typedef Int#(`DATA_WIDTH) Data_t;

function Bit#(8) charToBits(Char c) = fromInteger(charToInteger(c)); // Get the ASCII value of a character

interface Calculator;
  interface Put#(Bit#(8)) dataIn;
  interface Get#(Maybe#(Data_t)) resultOut;
endinterface

module mkCalculator(Calculator);
  // FIFOs for input and output buffering
  FIFOF#(Bit#(8)) pending_char_ <- mkFIFOF();
  FIFO#(Maybe#(Data_t)) result_ <- mkFIFO();

  // Stacks for the operands and operators
  Stack#(Data_t)  values_ <- mkStack(`STACK_SIZE);
  Stack#(Bit#(8)) ops_    <- mkStack(`STACK_SIZE);

  // To probe the stack's pop and push, using PulseWire to prevent deadlock
  PulseWire ops_pushing_ <- mkPulseWire();
  PulseWire ops_popping_ <- mkPulseWire();
  PulseWire values_pushing_ <- mkPulseWire();
  PulseWire values_popping_ <- mkPulseWire();
  Wire#(Data_t) value_toPush_ <- mkWire();

  // Temporary registers/wire for calculation
  Wire#(Bit#(8)) cin_ <- mkDWire(charToBits(" "));
  Wire#(Bit#(8)) op_  <- mkDWire(charToBits(" "));
  Wire#(Data_t)  val_ <- mkDWire(0);

  Reg#(Maybe#(Data_t)) numberIn_ <- mkReg(Invalid);
  Reg#(Data_t) val2_ <- mkReg(0);
  Reg#(Bool) fault_exp_ <- mkReg(False);

  // Helper functions
  function Bool isDigit(Bit#(8) ch);
    return ch >= charToBits("0") && ch <= charToBits("9");
  endfunction

  function Bool isOperator(Bit#(8) ch);
    return ch == charToBits("+") || ch == charToBits("-") || ch == charToBits("*") || ch == charToBits("/");
  endfunction

  function Bool invalidInput(Bit#(8) ch);
    return ch != charToBits("(") && ch != charToBits(")") && !isDigit(ch) &&
           ch != charToBits(" ") && ch != charToBits("=") && !isOperator(ch);
  endfunction

  function Bit#(2) precedence(Bit#(8) op);
    if      (op == charToBits("*") || op == charToBits("/")) return 2;
    else if (op == charToBits("+") || op == charToBits("-")) return 1;
    else return 0; // For parentheses and other non-operators
  endfunction

  // Pops two values and an operator, performs the calculation, and pushes the result back
  function Stmt eval() = seq
    action
      val2_ <= val_;
      values_popping_.send();
    endaction

    action
      values_popping_.send();
      ops_popping_.send();

      value_toPush_ <= case (op_)
        charToBits("+"): return val_ + val2_;
        charToBits("-"): return val_ - val2_;
        charToBits("*"): return val_ * val2_;
        charToBits("/"): return val_ / ( (val2_ == 0) ? (1) : (val2_) ); // Avoid division by zero
        default: return 0;
      endcase;

      values_pushing_.send();
    endaction
  endseq;

  // FSM to processes the expression stream
  FSM process_expression_ <- mkFSM(seq
    while(pending_char_.notEmpty()) seq
      if (isDigit(cin_)) seq

        action // If the character is a digit, accumulate it into numberIn
          numberIn_ <= tagged Valid ( 10 * fromMaybe(0, numberIn_) + extend(unpack(cin_ - charToBits("0"))) );
          pending_char_.deq();
        endaction

      endseq else if (isValid(numberIn_)) seq

        action // If we have a complete number, push it onto the values stack
          value_toPush_ <= fromMaybe(0, numberIn_);
          values_pushing_.send();
          numberIn_ <= tagged Invalid;       // Reset the number accumulator

          if (cin_ == charToBits(" ")) begin // If the character is a space, ignore it
            pending_char_.deq();
          end
        endaction

      endseq else if (cin_ == charToBits("(")) seq

        action // If the character is '(', push it onto the ops stack
          ops_pushing_.send();
          pending_char_.deq();
        endaction

      endseq else if (cin_ == charToBits(")")) seq

        while (!ops_.empty() && op_ != charToBits("(")) eval();

        action // Pop the opening parenthesis '('
          ops_popping_.send();
          pending_char_.deq();
        endaction

      endseq else if (cin_ == charToBits("=")) seq

        while (!ops_.empty()) eval();

        action // Move the final result to the output FIFO
          result_.enq( (fault_exp_) ? (tagged Invalid) : (tagged Valid val_) );
          values_popping_.send();
          pending_char_.deq();
        endaction

        while(!values_.empty()) values_popping_.send(); // Clear the values stack
        if (fault_exp_) fault_exp_ <= False;            // Reset the fault flag

      endseq else if (isOperator(cin_)) seq

        while (!ops_.empty() && precedence(op_) >= precedence(cin_)) eval();

        action
          ops_pushing_.send();
          pending_char_.deq();
        endaction

      endseq else seq
        pending_char_.deq(); // Ignore space and other characters
      endseq
    endseq
  endseq);

  rule start_processing (pending_char_.notEmpty());
    process_expression_.start();
  endrule

  rule get_first_char;
    cin_ <= pending_char_.first();
  endrule

  rule get_first_op;
    op_ <= ops_.top();
  endrule

  rule get_first_value;
    val_ <= values_.top();
  endrule

  rule pop_ops (ops_popping_);
    ops_.pop();
    $display($time, " Pop  operator: '%c'", ops_.top());
  endrule

  rule push_ops (ops_pushing_);
    ops_.push(cin_);
    $display($time, " Push operator: '%c'", cin_);
  endrule

  rule pop_values (values_popping_);
    values_.pop();
    $display($time, " Pop  value: ", values_.top());
  endrule

  rule push_values (values_pushing_);
    values_.push(value_toPush_);
    $display($time, " Push value: ", value_toPush_);
  endrule

  rule check_fault_expression (!fault_exp_); // Keep checking fault until the flag is set
    fault_exp_ <= (ops_popping_    && ops_.empty()   ) || (ops_pushing_    && ops_.full()   ) ||
                  (values_popping_ && values_.empty()) || (values_pushing_ && values_.full()) || invalidInput(cin_);
  endrule

  interface Put dataIn    = toPut(pending_char_);
  interface Get resultOut = toGet(result_);
endmodule

endpackage
