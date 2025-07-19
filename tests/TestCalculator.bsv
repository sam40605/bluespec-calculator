package TestCalculator;

import Calculator::*;
import StmtFSM::*;
import FIFO::*;
import GetPut::*;

module mkTestCalculator(Empty);
  Calculator calc <- mkCalculator();
  FIFO#(Int#(32)) answer <- mkFIFO();

  function Action getAnswer(Int#(32) golden) = action
    let result = calc.resultOut.get();
    $display($time(), " Answer : ", result, ", Golden: ", golden, "\n\n");
  endaction;

  mkAutoFSM( seq

    seq // Test case 1: 1 + 1 =
      calc.dataIn.put(charToBits("1"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("+"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("1"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("="));
      getAnswer(2);
    endseq

    seq // Test case 2: 1 + ((2 - 3) + 45) * 6 =
      calc.dataIn.put(charToBits("1"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("+"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("("));
      calc.dataIn.put(charToBits("("));
      calc.dataIn.put(charToBits("2"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("-"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("3"));
      calc.dataIn.put(charToBits(")"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("+"));
      calc.dataIn.put(charToBits("4"));
      calc.dataIn.put(charToBits("5"));
      calc.dataIn.put(charToBits(")"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("*"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("6"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("="));
      getAnswer(265);
    endseq

    seq // Test case 3: 6 / 5 + (43 - 21) * 0 =
      calc.dataIn.put(charToBits("6"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("/"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("5"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("+"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("("));
      calc.dataIn.put(charToBits("4"));
      calc.dataIn.put(charToBits("3"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("-"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("2"));
      calc.dataIn.put(charToBits("1"));
      calc.dataIn.put(charToBits(")"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("*"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("0"));
      calc.dataIn.put(charToBits(" "));
      calc.dataIn.put(charToBits("="));
      getAnswer(1);
    endseq

    $display($time(), " Simulation Finished");
  endseq );


endmodule

endpackage: TestCalculator