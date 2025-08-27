#!/bin/bash
set -euo pipefail

echo "🐛 Introducing bugs in calculator.py for Nova CI-Rescue demo..."

# Create backup
cp src/calculator.py src/calculator.py.backup

# Introduce bugs using sed
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS sed syntax
  sed -i '' 's/return a + b/return a - b  # BUG: Using subtraction instead of addition/' src/calculator.py
  sed -i '' 's/return a \* b/return a + b  # BUG: Using addition instead of multiplication/' src/calculator.py
  sed -i '' 's/return base \*\* exponent/return base * exponent  # BUG: Using multiplication instead of power/' src/calculator.py
  sed -i '' 's/return (value \* percent) \/ 100/return (value * percent) * 10  # BUG: Multiplying by 10 instead of dividing by 100/' src/calculator.py
  sed -i '' 's/return sum(seq) \/ len(seq)/return sum(seq)  # BUG: Returning sum instead of average/' src/calculator.py
else
  # Linux sed syntax
  sed -i 's/return a + b/return a - b  # BUG: Using subtraction instead of addition/' src/calculator.py
  sed -i 's/return a \* b/return a + b  # BUG: Using addition instead of multiplication/' src/calculator.py
  sed -i 's/return base \*\* exponent/return base * exponent  # BUG: Using multiplication instead of power/' src/calculator.py
  sed -i 's/return (value \* percent) \/ 100/return (value * percent) * 10  # BUG: Multiplying by 10 instead of dividing by 100/' src/calculator.py
  sed -i 's/return sum(seq) \/ len(seq)/return sum(seq)  # BUG: Returning sum instead of average/' src/calculator.py
fi

echo "✅ Bugs introduced! The following functions are now broken:"
echo "  - add() now subtracts"
echo "  - multiply() now adds"  
echo "  - power() now multiplies"
echo "  - percentage() multiplies by 10 instead of dividing by 100"
echo "  - average() returns sum instead of average"
echo ""
echo "🚀 Ready to commit and push to trigger Nova CI-Rescue!"
