#!/bin/bash
set -e

# 1. Download Flutter SDK (stable channel) if not cached
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable channel)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi

# 2. Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# 3. Build Flutter Web for production
echo "Building Flutter Web release..."
flutter doctor -v
flutter build web --release --base-href "/"
