#include <cctype>
#include <iostream>
#include <stack>
#include <string>

static std::string expression_buffer;

// Helper function to determine the precedence of an operator
int precedence(char op) {
  if (op == '+' || op == '-') return 1;
  if (op == '*' || op == '/') return 2;
  return 0;  // For parentheses
}

// Helper function to apply an operator to two values (no error checking)
void evaluate(std::stack<int> &values, std::stack<char> &ops) {
  int val2 = values.top();
  values.pop();

  int val1 = values.top();
  values.pop();

  char op = ops.top();
  ops.pop();

  switch (op) {
    case '+':
      values.push(val1 + val2);
      break;
    case '-':
      values.push(val1 - val2);
      break;
    case '*':
      values.push(val1 * val2);
      break;
    case '/':
      values.push(val1 / (val2 == 0 ? 1 : val2));  // Avoid division by zero
      break;
    default:
      values.push(0);
      break;
  }
}

// This is the internal C++ function that performs the calculation.
int calculator(const std::string &expression) {
  std::stack<int> values;
  std::stack<char> ops;

  for (int i = 0; i < expression.length(); ++i) {
    char token = expression[i];

    // Ignore whitespace and the equals sign
    if (isspace(token) || token == '=') {
      continue;
    }

    if (isdigit(token)) {
      int num = 0;
      while (i < expression.length() && isdigit(expression[i])) {
        num = (num * 10) + (expression[i] - '0');
        i++;
      }
      i--;
      values.push(num);
    } else if (token == '(') {
      ops.push(token);
    } else if (token == ')') {
      while (!ops.empty() && ops.top() != '(') {
        evaluate(values, ops);
      }
      ops.pop();  // Pop the opening parenthesis
    } else {      // Operator
      while (!ops.empty() && precedence(ops.top()) >= precedence(token)) {
        evaluate(values, ops);
      }
      ops.push(token);
    }
  }

  while (!ops.empty()) {
    evaluate(values, ops);
  }

  return values.top();
}

extern "C" void append_expression(unsigned char c) { expression_buffer += c; }

extern "C" void show_expression() {
  std::cout << "Expression: \"" << expression_buffer << "\"" << std::endl;
}

extern "C" void reset_expression() { expression_buffer.clear(); }

extern "C" int calculate_golden() { return calculator(expression_buffer); }
