#include <fstream>
#include <iostream>
#include <string>

#include "systemc.h"
#include "mkCalculatorTop_systemc.h"

#ifndef DATA_WIDTH
#define DATA_WIDTH 32
#endif

int64_t calculator(const std::string &expression);

int sc_main(int argc, char *argv[]) {
  /**
   * clock, reset, I/O signals
   */
  sc_clock clk("clk", 10, SC_NS);
  sc_signal<bool> rst_n;

  sc_signal<bool> EN_putData;
  sc_signal<bool> RDY_putData;
  sc_signal<sc_bv<8>> putData_c;

  sc_signal<bool> result_valid;
  sc_signal<bool> result_ack;
  sc_signal<sc_bv<DATA_WIDTH>> result;
  sc_signal<bool> fault_expression;

  /**
   * Instantiate the Calculator module
   */
  mkCalculatorTop Calculator("Calculator");

  Calculator.CLK(clk);
  Calculator.RST_N(rst_n);

  Calculator.EN_putData(EN_putData);
  Calculator.RDY_putData(RDY_putData);
  Calculator.putData_c(putData_c);

  Calculator.result_valid(result_valid);
  Calculator.result_ack(result_ack);
  Calculator.result(result);
  Calculator.fault_expression(fault_expression);

  auto putData = [&](unsigned char ch) {
    while (RDY_putData == false) {
      sc_start(10, SC_NS);
    }

    putData_c = sc_bv<8>(ch);
    EN_putData = true;
    sc_start(10, SC_NS);
    EN_putData = false;
  };

  auto getResult = [&](int64_t &result_value) {
    while (result_valid == false) {
      sc_start(10, SC_NS);
    }

    result_value = result.read().to_int64();
    bool fault_exp = fault_expression;

    result_ack = true;
    sc_start(10, SC_NS);
    result_ack = false;

    return fault_exp;
  };

  auto compareResult = [&](bool fault_exp, int64_t dut_res, int64_t golden) {
    if (fault_exp && golden == -99999999) {
      std::cout << "Compare result: \033[31mInvalid Expression\033[0m"
                << std::endl;
    } else if (dut_res == golden) {
      std::cout << "Compare result: \033[32mPASS\033[0m" << std::endl;
    } else {
      std::cerr << "Compare result: \033[31mFAIL\033[0m" << std::endl;
    }
  };

  // Reset the DUT
  rst_n = 0;
  sc_start(20, SC_NS);
  rst_n = 1;

  // Open the input file
  std::ifstream file("tests/input.txt");
  if (!file.is_open()) {
    std::cerr << "Error: Cannot open tests/input.txt" << std::endl;
    return -1;
  }

  std::string line;
  int test_case = 1;
  int64_t result_value = 0;
  bool fault_exp = false;

  while (std::getline(file, line)) {
    for (char ch : line) {
      putData(ch);

      if (ch == '=') {
        fault_exp = getResult(result_value);
        break;
      }
    }

    int64_t golden = calculator(line);
    std::cout << "==============================================" << std::endl;
    std::cout << "Test Case : " << test_case++ << std::endl;
    std::cout << "Expression: \"" << line << "\"" << std::endl;
    std::cout << "Result    : " << result_value << std::endl;
    std::cout << "Expected  : " << golden << std::endl;
    compareResult(fault_exp, result_value, golden);
    std::cout << "==============================================" << std::endl;
  }

  file.close();
  return 0;
}
