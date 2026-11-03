#!/usr/bin/env bash
set -e

mkdir -p bin

TARGET_MODE="${1:-host}"
BUILD_LOG=$(mktemp /tmp/remlang_build_XXXXXX)

TARGET_FLAG=""
OUTPUT_BIN="bin/rem"

case "$TARGET_MODE" in
    linux|linux-x64)
        TARGET_FLAG="-target x86_64-linux-musl"
        OUTPUT_BIN="bin/rem-linux-x86_64"
        echo "💙 Target Platform: Linux (x86_64 musl static)"
        ;;
    windows|win64)
        TARGET_FLAG="-target x86_64-windows-gnu"
        OUTPUT_BIN="bin/rem.exe"
        echo "💙 Target Platform: Windows (x86_64)"
        ;;
    all)
        echo "💙 Building RemLang for all platforms (macOS, Linux, Windows)..."
        echo ""
        echo "1/3 [macOS] Compiling native binary..."
        zig build-exe compiler/main.zig -target aarch64-macos-none -O ReleaseFast -femit-bin=bin/rem
        echo "2/3 [Linux] Cross-compiling standalone binary..."
        zig build-exe compiler/main.zig -target x86_64-linux-musl -O ReleaseFast -femit-bin=bin/rem-linux-x86_64
        echo "3/3 [Windows] Cross-compiling Windows executable..."
        zig build-exe compiler/main.zig -target x86_64-windows-gnu -O ReleaseFast -femit-bin=bin/rem.exe
        
        ln -sf "$(pwd)/bin/rem" /opt/homebrew/bin/rem 2>/dev/null || true
        ln -sf "$(pwd)/bin/rem" /opt/homebrew/bin/remlang 2>/dev/null || true
        
        echo ""
        echo "✨ All platforms built successfully!"
        echo "   • macOS   : $(pwd)/bin/rem"
        echo "   • Linux   : $(pwd)/bin/rem-linux-x86_64"
        echo "   • Windows : $(pwd)/bin/rem.exe"
        echo ""
        
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -f "${SCRIPT_DIR}/compiler/cli/rem_art.txt" ]; then
            cat "${SCRIPT_DIR}/compiler/cli/rem_art.txt"
            echo ""
        fi
        
        cat << EOF
================================================================================
💙 RemLang Built Successfully for All Targets!
================================================================================

RemLang is a programming language born out of love for Rem from Re:Zero.
Dedicated to her unwavering loyalty, gentle smile, and devotion, RemLang is
crafted from scratch to deliver blazing systems-level performance with
clean, modern ergonomics—seamlessly uniting both Procedure-Oriented Programming (POP)
and Object-Oriented Programming (OOP).

"Starting from zero, let's build the ultimate language." 💙

   • macOS   : $(pwd)/bin/rem
   • Linux   : $(pwd)/bin/rem-linux-x86_64
   • Windows : $(pwd)/bin/rem.exe
================================================================================
EOF
        exit 0
        ;;
    *)
        ARCH=$(uname -m)
        if [ "$ARCH" = "arm64" ]; then
            TARGET_FLAG="-target aarch64-macos-none"
        fi
        echo "💙 Target Platform: Native Host ($ARCH)"
        ;;
esac

zig build-exe compiler/main.zig $TARGET_FLAG -O ReleaseFast -femit-bin="$OUTPUT_BIN" > "$BUILD_LOG" 2>&1 &
BUILD_PID=$!

echo "💙 Compiling RemLang..."

PROGRESS=1
BAR_WIDTH=30

while kill -0 "$BUILD_PID" 2>/dev/null; do
    if [ "$PROGRESS" -lt 90 ]; then
        PROGRESS=$((PROGRESS + 2))
    fi
    FILLED=$((PROGRESS * BAR_WIDTH / 100))
    EMPTY=$((BAR_WIDTH - FILLED))
    
    BAR_STR=""
    for ((i=0; i<FILLED; i++)); do BAR_STR="${BAR_STR}█"; done
    for ((i=0; i<EMPTY; i++)); do BAR_STR="${BAR_STR}░"; done
    
    printf "\r   [%s] %3d%%  Compiling core compiler modules..." "$BAR_STR" "$PROGRESS"
    sleep 0.06
done

wait "$BUILD_PID"
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "❌ Build failed!"
    cat "$BUILD_LOG"
    rm -f "$BUILD_LOG"
    exit $EXIT_CODE
fi

rm -f "$BUILD_LOG"

while [ "$PROGRESS" -le 100 ]; do
    FILLED=$((PROGRESS * BAR_WIDTH / 100))
    EMPTY=$((BAR_WIDTH - FILLED))
    BAR_STR=""
    for ((i=0; i<FILLED; i++)); do BAR_STR="${BAR_STR}█"; done
    for ((i=0; i<EMPTY; i++)); do BAR_STR="${BAR_STR}░"; done
    printf "\r   [%s] %3d%%  Finalizing RemLang executable...   " "$BAR_STR" "$PROGRESS"
    PROGRESS=$((PROGRESS + 2))
    sleep 0.01
done

printf "\r   [%s] 100%%  Build finished successfully!        \n\n" "$BAR_STR"

if [ "$TARGET_MODE" = "host" ]; then
    cp bin/rem bin/remlang 2>/dev/null || true
    ln -sf "$(pwd)/bin/rem" /opt/homebrew/bin/rem 2>/dev/null || true
    ln -sf "$(pwd)/bin/rem" /opt/homebrew/bin/remlang 2>/dev/null || true
fi

ROOT_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "${SCRIPT_DIR}/compiler/cli/rem_art.txt" ]; then
    cat "${SCRIPT_DIR}/compiler/cli/rem_art.txt"
    echo ""
fi

cat << EOF
================================================================================
💙 Kon'nichiwa minna at RemLang!
================================================================================

RemLang is a programming language born out of love for Rem from Re:Zero.
Dedicated to her unwavering loyalty, gentle smile, and devotion, RemLang is
crafted from scratch to deliver blazing systems-level performance with
clean, modern ergonomics—seamlessly uniting both Procedure-Oriented Programming (POP)
and Object-Oriented Programming (OOP).

Quotes: "Starting from zero, let's build the ultimate language." 💙

Location : ${ROOT_DIR}/${OUTPUT_BIN}
================================================================================
EOF
