add_bsc_library(Calculator.bsv BSC_FLAGS -D DATA_WIDTH=${DATA_WIDTH} -D STACK_SIZE=${STACK_SIZE})
generate_verilog(mkCalculator Calculator.bsv)
