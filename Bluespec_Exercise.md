# Bluespec Exercise

### Abstract

Use Bluespec SystemVerilog to develop a hardware calculator that evaluates a given expression encoded in ASCII format.

**Deadline**: 2025/7/22

## Description

### Input

The input is an [infix expression](https://en.wikipedia.org/wiki/Infix_notation) consisting of the following tokens:

1. **Numbers**

    Numbers are non-negative decimal integers. Examples:


    | Number | Description                  |
    | ------ | ---------------------------- |
    | `0`    | Zero                         |
    | `42`   | Forty-two                    |
    | `123`  | One hundred and twenty-three |


2. **Operators**

    Supported operators are:

    | Operator | Description           |
    | -------- | --------------------- |
    | `+`      | Addition              |
    | `-`      | Substraction          |
    | `*`      | Multiplication        |
    | `/`      | Division              |
    | `=`      | End of the expression |

3. **Parentheses**

    | Operator | Description         |
    | -------- | ------------------- |
    | `(`      | Opening parenthesis |
    | `)`      | Closing parenthesis |

    **Order of operations**: The sub-expression enclosed by a pair of parentheses should be evaluated first. In the absence of parentheses, [certain precedence rules](https://en.wikipedia.org/wiki/Order_of_operations) determine the order of operations.

4. **White spaces**

    White spaces (` `) should be ignored during the evaluation of the expression.

Here are some valid input expressions.

* `1 + 1 =`
* `1 + ((2 - 3) + 45) * 6 =`
* `6 / 5 + (43 - 21) * 0 =`

### Output

Output is the evaluation of the input expression. Examples:

| Input                      | Output |
| -------------------------- | ------ |
| `1 + 1 =`                  | `2`    |
| `1 + ((2 - 3) + 45) * 6 =` | `265`  |
| `6 / 5 + (43 - 21) * 0 =`  | `1`    |

## Requirements

### Input interface

`Put#(Bit#(8))`

The input expression is serialized into an ASCII byte stream and the stream is sent to the calculator byte by byte.

### Output interface

`Get#(Int#(32))`

The evaluated result can be obtained at the output interface once the evaluation is done.

### Functional behavior

Your calculator should be able to tokenize, parse and evaluate the given input expression and output the result.

### Testbench

Write a testbench that reads `input.txt`, which stores a single input expression, and sent the serialized expression to the calculator byte by byte. Once the evaluation finishes, output the result to the console.

### Build

Use [Bluespec CMake](https://github.com/yuyuranium/bluespec-cmake) module to write build script in CMake. The testbench should be built into a Bluesim executable.

### Demo

Present your work on 7/22. The presentation should cover:

* Architecture of the calculator
* Design of the testbench
* Evaluation result of any given input expression

## Resources

* [Bluespec Compiler](https://github.com/B-Lang-org/bsc)
* [BSC Libraries Reference Guide](https://github.com/B-Lang-org/bsc/releases/latest/download/bsc_libraries_ref_guide.pdf)
* [BSV Language Reference Guide](https://github.com/B-Lang-org/bsc/releases/latest/download/BSV_lang_ref_guide.pdf)
* [Bluespec Tutorial](https://github.com/WangXuan95/BSV_Tutorial_cn)


## Challenges

1. Debug your calculator without viewing the waveform
    - Use `$display`-based debugging methods.

2. Multiple inputs and automatic verification
    - One expression per line in the `input.txt`
    - The testbench calculates a golden value and compares it with the calculator's output

3. SystemC based testbench
    - Generate the SystemC model of the calculator and instantiate it in a `sc_main`
    - Write the testbench in the `sc_main`

4. Robustness of the design e.g. can quickly adapt to different kind of inputs
