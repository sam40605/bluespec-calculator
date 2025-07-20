add_library(golden_calculator STATIC golden_calculator.cc)

add_bluesim_executable(testCalculator mkTestCalculator TestCalculator.bsv
  LINK_LIBS   Calculator
  LINK_C_LIBS golden_calculator)

# add_bluesim_systemc_library(mkCalculator_systemc mkTestCalculator TestCalculator.bsv LINK_LIBS Calculator)
