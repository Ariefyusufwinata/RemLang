#!/usr/bin/env bash
set -e

REPO="Ariefyusufwinata/RemLang"
INSTALL_DIR="${REMLANG_INSTALL_DIR:-$HOME/.rem}"
BIN_DIR="${INSTALL_DIR}/bin"

echo ""
echo "💙 Installing RemLang..."

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Darwin)
        PLATFORM="macos"
        ;;
    Linux)
        PLATFORM="linux"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        PLATFORM="windows"
        ;;
    *)
        echo "❌ Unsupported operating system: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64)
        CPU="x86_64"
        ;;
    arm64|aarch64)
        CPU="arm64"
        ;;
    *)
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

TARGET="${PLATFORM}-${CPU}"
BINARY_NAME="rem"
if [ "$PLATFORM" = "windows" ]; then
    BINARY_NAME="rem.exe"
fi

mkdir -p "$BIN_DIR"

RELEASE_URL="https://github.com/${REPO}/releases/latest/download/rem-${TARGET}"
if [ "$PLATFORM" = "windows" ]; then
    RELEASE_URL="${RELEASE_URL}.exe"
fi

DOWNLOAD_SUCCESS=false

echo "   • Target: ${TARGET}"
echo "   • Destination: ${BIN_DIR}/${BINARY_NAME}"

if curl -fsSL -o "${BIN_DIR}/${BINARY_NAME}" "$RELEASE_URL" 2>/dev/null; then
    chmod +x "${BIN_DIR}/${BINARY_NAME}"
    DOWNLOAD_SUCCESS=true
elif [ -f "./build.sh" ]; then
    echo "   • Installing from local RemLang repository..."
    if [ ! -f "bin/${BINARY_NAME}" ]; then
        ./build.sh >/dev/null 2>&1
    fi
    cp "bin/${BINARY_NAME}" "${BIN_DIR}/${BINARY_NAME}" 2>/dev/null || cp "bin/rem" "${BIN_DIR}/${BINARY_NAME}"
    chmod +x "${BIN_DIR}/${BINARY_NAME}"
    DOWNLOAD_SUCCESS=true
else
    echo "   • Release asset not found online yet. Building from source..."
    TMP_DIR=$(mktemp -d /tmp/remlang_install_XXXXXX)
    git clone --depth 1 "https://github.com/${REPO}.git" "$TMP_DIR" >/dev/null 2>&1
    (
        cd "$TMP_DIR"
        chmod +x build.sh 2>/dev/null || true
        ./build.sh >/dev/null 2>&1
    )
    cp "${TMP_DIR}/bin/rem" "${BIN_DIR}/${BINARY_NAME}" 2>/dev/null || true
    chmod +x "${BIN_DIR}/${BINARY_NAME}"
    rm -rf "$TMP_DIR"
    DOWNLOAD_SUCCESS=true
fi

if [ -w "/usr/local/bin" ]; then
    ln -sf "${BIN_DIR}/${BINARY_NAME}" "/usr/local/bin/rem" 2>/dev/null || true
fi
if [ -w "/opt/homebrew/bin" ]; then
    ln -sf "${BIN_DIR}/${BINARY_NAME}" "/opt/homebrew/bin/rem" 2>/dev/null || true
fi

SHELL_NAME=$(basename "${SHELL:-bash}")
RC_FILE=""

case "$SHELL_NAME" in
    zsh)
        RC_FILE="$HOME/.zshrc"
        ;;
    bash)
        if [ -f "$HOME/.bashrc" ]; then
            RC_FILE="$HOME/.bashrc"
        else
            RC_FILE="$HOME/.bash_profile"
        fi
        ;;
    *)
        RC_FILE="$HOME/.profile"
        ;;
esac

PATH_STRING="export PATH=\"\$HOME/.rem/bin:\$PATH\""
if [ -f "$RC_FILE" ]; then
    if ! grep -q ".rem/bin" "$RC_FILE" 2>/dev/null; then
        echo "" >> "$RC_FILE"
        echo "$PATH_STRING" >> "$RC_FILE"
    fi
fi

cat << 'EOF'

                      .-===+%+*%=--.
                  :=*%%*++*+*==*+****++*==:
               .+%#%*=:-==-+-  :..+*+%## %+%*..
             .+%#*=.   :=+*##%%%%#*+=:   %@=@###@@@+
            ++##-   :*%@@@@@@@@@@@@%*: =  ::=#@@=%##@#@@=
           %-@#   +%@@@@@@@@@@@@@@@@# :*  .- :#@*#+*#@@+=
          %.%@  *@@@@@@@@@@@@@@@@@@.   @+:.=#@%@#@+*@@#**
         *- @  %@@@@@@@@@@@@@@@@@#    .=*#%@##=*@@+@@@@@@
        :* .: =@@@@@@@@@@@@@@@@@=     := -@+ :: *@@-@*@*@
        %- :  #@@@@@@@@@@@@@@@@+      -=*..-@# * %*#@@@@@%
        @= =: @@@@@@@@@@@@@@@@*       -=*=::  *#@   @##@=@@
       .@=::= *@@@@@@@@@@@*-::        %***===.  %.  %@@@@@:
       :@+- %= =@@@@@@@#=:            @@*@@@@@@@+--=@*=@@@
       .@%::@@==%@@@@@-               #@%  @@#@-@#=:@+%=@@@
        @#= %*@#*@:+#= :+%=..*+        --. -@=@%=+-@@#
        =@*-:=#@@@-                   .@@@##*:+@@@.
         =@@# -=%@-         .         . #=.*:#@#=@.
          .%@@%+.++       \___/        += -@@@@-.@
             .=@@#@*=.               +%+@%@*:=@.
                 =@*@@%+:        :+#@@+@*.   :.
                    .#@@.:--::--:.@@@:
    ::.  :.         .%=-=:.    .:=-=*          .:  .::
   :* .:=**%=..    :-%=  + +..+ +  =%-:    ..=%**=:. *:
   -=      .*@.-*+:.   = :: %% :: =   .:+*-.@*.      =-
    #        +-:@@      .=#*%%*#=.      @@:-+        #
    :%@+:--- == .#@   =%*==@@@@==*%=   @#. == ---:+@%:
     -@. .-+=.#++ *@+ =@=*@@..@@*=@= +@* ++#.=+-. .@-
     #%      =+*+*. %@***=**  **=***@% .*+*==      %#
    -= %. .-:%*: +=.+= *=#=#**#=#=* =+.=+ :*%:-. .% =-
EOF
cat << EOF
================================================================================
💙 RemLang Installed Successfully!
================================================================================

RemLang is a programming language born out of love for Rem from Re:Zero.
Dedicated to her unwavering loyalty, gentle smile, and devotion, RemLang is
crafted from scratch to deliver blazing systems-level performance with
clean, modern ergonomics—seamlessly uniting both Procedure-Oriented Programming (POP)
and Object-Oriented Programming (OOP).

"Starting from zero, let's build the ultimate language." 💙

   • Binary Location : $HOME/.rem/bin/rem
   • Shell Config    : Added to ${RC_FILE:-$HOME/.profile}

To start using RemLang immediately in this session, run:
   export PATH="$HOME/.rem/bin:$PATH"

Or reload your shell:
   source ${RC_FILE:-~/.profile}
================================================================================
EOF
