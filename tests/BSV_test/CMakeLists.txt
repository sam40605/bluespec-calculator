add_bluesim_executable(testCalculator mkTestCalculator TestCalculator.bsv
  LINK_LIBS   Calculator
  LINK_C_LIBS golden_calculator)
