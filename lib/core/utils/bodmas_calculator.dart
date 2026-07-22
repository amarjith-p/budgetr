class BodmasCalculator {
  static String evaluate(String expr) {
    if (expr.isEmpty) return '0';
    try {
      // 1. Sanitize the string for pure math symbols
      String sanitized = expr.replaceAll('×', '*').replaceAll('÷', '/').replaceAll(' ', '');
      
      // Handle implicit multiplication (e.g., "5(2)" becomes "5*(2)" and ")( becomes ")*(")
      sanitized = sanitized.replaceAllMapped(RegExp(r'(\d)\('), (m) => '${m[1]}*(');
      sanitized = sanitized.replaceAllMapped(RegExp(r'\)\('), (m) => ')*(');
      sanitized = sanitized.replaceAllMapped(RegExp(r'\)(\d)'), (m) => ')*${m[1]}');

      // Handle unary minus at the start or immediately after an open bracket
      if (sanitized.startsWith('-')) sanitized = '0$sanitized';
      sanitized = sanitized.replaceAll('(-', '(0-');

      // Strip trailing operators to keep live-preview from crashing
      if (RegExp(r'[\+\-\*/]$').hasMatch(sanitized)) {
        sanitized = sanitized.substring(0, sanitized.length - 1);
      }

      // Auto-close any unclosed brackets for the live-preview calculation
      int openBrackets = sanitized.split('(').length - 1;
      int closeBrackets = sanitized.split(')').length - 1;
      for (int i = 0; i < openBrackets - closeBrackets; i++) {
        sanitized += ')';
      }

      List<String> output = [];
      List<String> ops = [];
      Map<String, int> precedence = {'+': 1, '-': 1, '*': 2, '/': 2};

      // Extract numbers (including decimals), operators, and brackets
      RegExp regex = RegExp(r'(\d+\.?\d*|[\+\-\*/\(\)])');
      var matches = regex.allMatches(sanitized);

      // 2. Shunting-Yard Algorithm: Convert Infix to Postfix (Reverse Polish Notation)
      for (var match in matches) {
        String token = match.group(0)!;
        
        if (double.tryParse(token) != null) {
          output.add(token);
        } else if (token == '(') {
          ops.add(token);
        } else if (token == ')') {
          while (ops.isNotEmpty && ops.last != '(') {
            output.add(ops.removeLast());
          }
          if (ops.isNotEmpty && ops.last == '(') {
            ops.removeLast(); // Discard the '('
          }
        } else {
          // It's an operator (+, -, *, /)
          while (ops.isNotEmpty && ops.last != '(' &&
              precedence[ops.last] != null &&
              precedence[ops.last]! >= precedence[token]!) {
            output.add(ops.removeLast());
          }
          ops.add(token);
        }
      }
      while (ops.isNotEmpty) output.add(ops.removeLast());

      // 3. Evaluate the Postfix stack
      List<double> stack = [];
      for (var token in output) {
        if (double.tryParse(token) != null) {
          stack.add(double.parse(token));
        } else {
          if (stack.length < 2) continue; // Skip safely if equation is incomplete
          double b = stack.removeLast();
          double a = stack.removeLast();
          if (token == '+') stack.add(a + b);
          if (token == '-') stack.add(a - b);
          if (token == '*') stack.add(a * b);
          if (token == '/') stack.add(b == 0 ? 0 : a / b);
        }
      }

      // 4. Format Output
      if (stack.isNotEmpty) {
        double res = stack.last;
        if (res.isInfinite || res.isNaN) return '0';
        if (res == res.toInt()) return res.toInt().toString(); // Clean integer
        return res.toStringAsFixed(2); // Retain 2 decimals for currency
      }
    } catch (_) {
      // Fail silently and let the user continue typing safely
    }
    return '0';
  }
}