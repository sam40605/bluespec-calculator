package TestCalculator;

import Calculator::*;
import StmtFSM::*;
import FIFO::*;
import GetPut::*;

module mkTestCalculator();
  // Instantiate the Calculator module
  Calculator calc <- mkCalculator();

  // Input file handling
  Reg#(Bool) file_opened <- mkReg(False);
  Reg#(File) input_file  <- mkReg(InvalidFile);

  // FSM for reading the answer
  FSM read_Answer <- mkFSM(seq
    action
      let result = calc.resultOut.get();
      $display($time(), " Answer: ", result, "\n\n");
    endaction
  endseq);

  rule send_input (file_opened);
    int ch <- $fgetc(input_file);

    if (ch != -1) begin
      Bit#(8) c = truncate(pack(ch));
      if (c != charToBits("\n")) calc.dataIn.put(c);
      if (c == charToBits("=") ) read_Answer.start();
    end else begin
      $fclose(input_file);
      $finish(0);
    end
  endrule

  rule open_file (!file_opened);
    File lfh <- $fopen("tests/test_input.txt", "r");

    if (lfh == InvalidFile) begin
      $display("Error opening file\n");
      $finish(0);
    end

    file_opened <= True;
    input_file  <= lfh;
  endrule
endmodule

endpackage