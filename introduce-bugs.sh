#!/usr/bin/env bash
set -euo pipefail

echo "🐛 Introducing bugs in calculator.py for Nova CI-Rescue demo..."

if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' 's/return a + b/return a - b/' src/calculator.py
  sed -i '' 's/return a - b/return a + b/' src/calculator.py
  sed -i '' 's/return a \* b/return a + b/' src/calculator.py
  sed -i '' 's/return a \/ b/return a * b/' src/calculator.py
  sed -i '' 's/return base \*\* exponent/return base * exponent/' src/calculator.py
  sed -i '' 's/return math\.sqrt(n)/return n/' src/calculator.py
  sed -i '' 's/return (value \* percent) \/ 100/return (value * percent) * 10/' src/calculator.py
  sed -i '' 's/return sum(seq) \/ len(seq)/return sum(seq)/' src/calculator.py
else
  sed -i 's/return a + b/return a - b/' src/calculator.py
  sed -i 's/return a - b/return a + b/' src/calculator.py
  sed -i 's/return a \* b/return a + b/' src/calculator.py
  sed -i 's/return a \/ b/return a * b/' src/calculator.py
  sed -i 's/return base \*\* exponent/return base * exponent/' src/calculator.py
  sed -i 's/return math\.sqrt(n)/return n/' src/calculator.py
  sed -i 's/return (value \* percent) \/ 100/return (value * percent) * 10/' src/calculator.py
  sed -i 's/return sum(seq) \/ len(seq)/return sum(seq)/' src/calculator.py
fi

echo "✅ Bugs introduced!"
