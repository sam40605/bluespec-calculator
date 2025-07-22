package TestCalculator;

import Calculator::*;
import StmtFSM::*;
import FIFO::*;
import GetPut::*;

import "BDPI" function Action append_expression(Bit#(8) c);
import "BDPI" function Action show_expression();
import "BDPI" function Action reset_expression();
import "BDPI" function Bit#(32) calculate_golden();

module mkTestCalculator();
  // Instantiate the Calculator module
  Calculator calc_ <- mkCalculator();

  // Input file handling
  Reg#(Bool) file_opened_ <- mkReg(False);
  Reg#(File) input_file_  <- mkReg(InvalidFile);

  // Count for test cases
  Reg#(UInt#(32)) test_case_count_ <- mkReg(0);

  // FSM for reading the answer and comparing with the golden model
  FSM read_Answer <- mkFSM(seq
    action
      // 1. Get the result from our hardware calculator
      let result <- calc_.resultOut.get();

      // 2. Compute the golden result
      Int#(32) golden_result = unpack(calculate_golden());

      $display("==============================================");
      $display("Test Cases: ", test_case_count_ + 1);
      show_expression();
      reset_expression();
      $display("DUT     result: ", fromMaybe(-99999999, result));
      $display("Golden  result: ", golden_result);

      // 3. Compare results
      if (!isValid(result)) begin
        $display("Compare result: \033[31mInvalid Expression\033[0m");
      end else if (fromMaybe(0, result) == golden_result) begin
        $display("Compare result: \033[32mPASS\033[0m");
      end else begin
        $display("Compare result: \033[31mFAIL\033[0m");
      end
      $display("==============================================");

      test_case_count_ <= test_case_count_ + 1;
    endaction
  endseq);

  rule send_input (file_opened_);
    int ch <- $fgetc(input_file_);

    if (ch != -1) begin
      Bit#(8) c = truncate(pack(ch));

      if (c != charToBits("\n")) begin
        append_expression(c);
        calc_.dataIn.put(c);

        if (c == charToBits("=")) read_Answer.start();
      end
    end else begin
      $fclose(input_file_);
      $finish(0);
    end
  endrule

  rule open_file (!file_opened_);
    File lfh <- $fopen("tests/input.txt", "r");

    if (lfh == InvalidFile) begin
      $display("Error opening file\n");
      $finish(0);
    end

    file_opened_ <= True;
    input_file_  <= lfh;
  endrule
endmodule

endpackage
