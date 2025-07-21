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
endinterface

module mkCalculatorTop(CalculatorTop);
  Reg#(Maybe#(Data_t)) result_ <- mkReg(Invalid);
  PulseWire result_ack_ <- mkPulseWire();

  // Calculator instance
  Calculator calc_ <- mkCalculator();

  rule handle_result (!isValid(result_));
    let res <- calc_.resultOut.get();
    result_ <= tagged Valid res;
  endrule

  rule handle_ready (isValid(result_) && result_ack_);
    result_ <= tagged Invalid;
  endrule

  // Input interface methods
  method Action putData(Bit#(8) c) = calc_.dataIn.put(c);

  // Output interface methods
  method Bool result_valid() = isValid(result_);
  method Action result_ack() = result_ack_.send();
  method Data_t result() = fromMaybe(0, result_);
endmodule

endpackage
