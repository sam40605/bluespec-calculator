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

// Helper function to apply an operator to two values
bool evaluate(std::stack<int64_t> &values, std::stack<char> &ops) {
  int64_t val1 = 0, val2 = 0;
  char op = ' ';

  if (values.size() < 2 || ops.empty()) return false;

  val2 = values.top();
  values.pop();

  val1 = values.top();
  values.pop();

  op = ops.top();
  ops.pop();

  if (val2 == 0 && op == '/') return false;  // Handle division by zero

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
      values.push(val1 / val2);
      break;
    default:
      values.push(0);
      break;
  }

  return true;
}

int64_t calculator(const std::string &expression) {
  std::stack<int64_t> values;
  std::stack<char> ops;

  for (int i = 0; i < expression.length(); ++i) {
    char token = expression[i];

    // Ignore whitespace and the equals sign
    if (isspace(token) || token == '=') {
      continue;
    }

    if (isdigit(token)) {
      int64_t num = 0;
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
        if (!evaluate(values, ops)) return -99999999;
      }
      if (!ops.empty()) ops.pop();  // Pop the opening parenthesis
    } else {                        // Operator
      while (!ops.empty() && precedence(ops.top()) >= precedence(token)) {
        if (!evaluate(values, ops)) return -99999999;
      }
      ops.push(token);
    }
  }

  while (!ops.empty()) {
    if (!evaluate(values, ops)) return -99999999;
  }

  return values.top();
}

extern "C" void append_expression(unsigned char c) { expression_buffer += c; }

extern "C" void show_expression() {
  std::cout << "Expression: \"" << expression_buffer << "\"" << std::endl;
}

extern "C" void reset_expression() { expression_buffer.clear(); }

extern "C" int64_t calculate_golden() { return calculator(expression_buffer); }
