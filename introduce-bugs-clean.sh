#!/usr/bin/env bash
set -euo pipefail

echo "🐛 Introducing bugs in calculator.py for Nova CI-Rescue demo..."

# First, ensure we have a clean calculator.py
if [ -f "src/calculator.py.original" ]; then
    cp src/calculator.py.original src/calculator.py
    echo "✅ Restored original calculator.py"
fi

# Now introduce bugs WITHOUT any comments
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Fix add() method - change + to -
  sed -i '' 's/def add(self, a: float, b: float) -> float:/&\n        """Add two numbers."""\n        return a - b/' src/calculator.py
  sed -i '' '/def add/,/return a + b/{s/return a + b/return a - b/}' src/calculator.py
  
  # Break subtract() - change - to +
  sed -i '' '/def subtract/,/return a - b/{s/return a - b/return a + b/}' src/calculator.py
  
  # Break multiply() - change * to +
  sed -i '' '/def multiply/,/return a \* b/{s/return a \* b/return a + b/}' src/calculator.py
  
  # Break divide() - change / to *
  sed -i '' '/def divide/,/return a \/ b/{s/return a \/ b/return a * b/}' src/calculator.py
  
  # Break power() - change ** to *
  sed -i '' '/def power/,/return base \*\* exponent/{s/return base \*\* exponent/return base * exponent/}' src/calculator.py
  
  # Break square_root() - return n instead of sqrt(n)
  sed -i '' '/def square_root/,/return math\.sqrt(n)/{s/return math\.sqrt(n)/return n/}' src/calculator.py
  
  # Break percentage() - multiply by 10 instead of dividing by 100
  sed -i '' '/def percentage/,/return (value \* percent) \/ 100/{s/return (value \* percent) \/ 100/return (value * percent) * 10/}' src/calculator.py
  
  # Break average() - return sum instead of average
  sed -i '' '/def average/,/return sum(seq) \/ len(seq)/{s/return sum(seq) \/ len(seq)/return sum(seq)/}' src/calculator.py
else
  # Linux version
  sed -i '/def add/,/return a + b/{s/return a + b/return a - b/}' src/calculator.py
  sed -i '/def subtract/,/return a - b/{s/return a - b/return a + b/}' src/calculator.py
  sed -i '/def multiply/,/return a \* b/{s/return a \* b/return a + b/}' src/calculator.py
  sed -i '/def divide/,/return a \/ b/{s/return a \/ b/return a * b/}' src/calculator.py
  sed -i '/def power/,/return base \*\* exponent/{s/return base \*\* exponent/return base * exponent/}' src/calculator.py
  sed -i '/def square_root/,/return math\.sqrt(n)/{s/return math\.sqrt(n)/return n/}' src/calculator.py
  sed -i '/def percentage/,/return (value \* percent) \/ 100/{s/return (value \* percent) \/ 100/return (value * percent) * 10/}' src/calculator.py
  sed -i '/def average/,/return sum(seq) \/ len(seq)/{s/return sum(seq) \/ len(seq)/return sum(seq)/}' src/calculator.py
fi

echo "✅ Bugs introduced (without any BUG comments)!"
