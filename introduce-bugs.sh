#!/bin/bash
set -euo pipefail

echo "🐛 Introducing bugs in calculator.py for Nova CI-Rescue demo..."

# Create backup
cp src/calculator.py src/calculator.py.backup

# Introduce bugs using sed
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS sed syntax
  # Add function - change + to -
  sed -i '' 's/return a + b/return a - b  # BUG: Using subtraction instead of addition/' src/calculator.py
  # Subtract function - change - to +
  sed -i '' 's/return a - b/return a + b  # BUG: Using addition instead of subtraction/' src/calculator.py
  # Multiply function - change * to +
  sed -i '' 's/return a \* b/return a + b  # BUG: Using addition instead of multiplication/' src/calculator.py
  # Divide function - change / to *
  sed -i '' 's/return a \/ b/return a * b  # BUG: Using multiplication instead of division/' src/calculator.py
  # Power function - change ** to *
  sed -i '' 's/return base \*\* exponent/return base * exponent  # BUG: Using multiplication instead of power/' src/calculator.py
  # Square root - return the input instead of sqrt
  sed -i '' 's/return math\.sqrt(n)/return n  # BUG: Returning input instead of square root/' src/calculator.py
  # Percentage - multiply by 10 instead of dividing by 100
  sed -i '' 's/return (value \* percent) \/ 100/return (value * percent) * 10  # BUG: Multiplying by 10 instead of dividing by 100/' src/calculator.py
  # Average - return sum instead of sum/len
  sed -i '' 's/return sum(seq) \/ len(seq)/return sum(seq)  # BUG: Returning sum instead of average/' src/calculator.py
else
  # Linux sed syntax
  # Add function - change + to -
  sed -i 's/return a + b/return a - b  # BUG: Using subtraction instead of addition/' src/calculator.py
  # Subtract function - change - to +
  sed -i 's/return a - b/return a + b  # BUG: Using addition instead of subtraction/' src/calculator.py
  # Multiply function - change * to +
  sed -i 's/return a \* b/return a + b  # BUG: Using addition instead of multiplication/' src/calculator.py
  # Divide function - change / to *
  sed -i 's/return a \/ b/return a * b  # BUG: Using multiplication instead of division/' src/calculator.py
  # Power function - change ** to *
  sed -i 's/return base \*\* exponent/return base * exponent  # BUG: Using multiplication instead of power/' src/calculator.py
  # Square root - return the input instead of sqrt
  sed -i 's/return math\.sqrt(n)/return n  # BUG: Returning input instead of square root/' src/calculator.py
  # Percentage - multiply by 10 instead of dividing by 100
  sed -i 's/return (value \* percent) \/ 100/return (value * percent) * 10  # BUG: Multiplying by 10 instead of dividing by 100/' src/calculator.py
  # Average - return sum instead of sum/len
  sed -i 's/return sum(seq) \/ len(seq)/return sum(seq)  # BUG: Returning sum instead of average/' src/calculator.py
fi

echo "✅ Bugs introduced! The following functions are now broken:"
echo "  - add() now subtracts instead of adding"
echo "  - subtract() now adds instead of subtracting"
echo "  - multiply() now adds instead of multiplying"
echo "  - divide() now multiplies instead of dividing"
echo "  - power() now multiplies instead of exponentiating"
echo "  - square_root() returns input instead of square root"
echo "  - percentage() multiplies by 10 instead of dividing by 100"
echo "  - average() returns sum instead of average"
echo ""
echo "🚀 Ready to commit and push to trigger Nova CI-Rescue!"
