package CalculatorTop;

import Calculator::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;

interface CalculatorTop;
  // Input interface
  method Action putData(Bit#(8) c);

  // Output interface
  (* always_ready, always_enabled *) method Bool result_valid();
  (* always_ready, enable = "result_ack" *) method Action result_ack();
  (* always_ready, always_enabled *) method Data_t result();
  (* always_ready, always_enabled *) method Bool fault_expression();
endinterface

module mkCalculatorTop(CalculatorTop);
  Reg#(Maybe#(Data_t)) result_ <- mkReg(Invalid);
  Reg#(Bool) has_result_ <- mkReg(False);
  PulseWire result_ack_ <- mkPulseWire();

  // Calculator instance
  Calculator calc_ <- mkCalculator();

  rule handle_result (!has_result_);
    let res <- calc_.resultOut.get();
    result_ <= res;
    has_result_ <= True;
  endrule

  rule handle_ready (has_result_ && result_ack_);
    has_result_ <= False;
  endrule

  // Input interface methods
  method Action putData(Bit#(8) c) = calc_.dataIn.put(c);

  // Output interface methods
  method Bool result_valid() = has_result_;
  method Action result_ack() = result_ack_.send();
  method Data_t result() = fromMaybe(-99999999, result_);
  method Bool fault_expression() = !isValid(result_);
endmodule

endpackage
