docker build -t rust-cross-compiler - << 'EOF'
FROM rust:1.80
RUN apt-get update && apt-get install -y \
    gcc-mingw-w64-x86-64 \
    gcc-x86-64-linux-gnu \
    libc6-dev-amd64-cross \
    clang \
    libssl-dev \
    wget \
    xz-utils \
    cmake \
    patch \
    libxml2-dev \
    llvm-dev \
    uuid-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install osxcross
RUN git config --global --add safe.directory '*'
RUN git clone https://github.com/tpoechtrager/osxcross /root/osxcross
WORKDIR /root/osxcross
RUN wget -nc https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz
RUN mv MacOSX11.3.sdk.tar.xz tarballs/
RUN UNATTENDED=yes OSX_VERSION_MIN=10.7 ./build.sh
ENV PATH="/root/osxcross/target/bin:$PATH"

# Install targets
RUN rustup target add x86_64-unknown-linux-gnu \
    x86_64-pc-windows-gnu \
    x86_64-apple-darwin \
    aarch64-apple-darwin

WORKDIR /app

ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-linux-gnu-gcc
ENV CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=x86_64-apple-darwin20.4-clang
ENV CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER=aarch64-apple-darwin20.4-clang
ENV CC_x86_64_apple_darwin=x86_64-apple-darwin20.4-clang
ENV CXX_x86_64_apple_darwin=x86_64-apple-darwin20.4-clang++
ENV CC_aarch64_apple_darwin=aarch64-apple-darwin20.4-clang
ENV CXX_aarch64_apple_darwin=aarch64-apple-darwin20.4-clang++

RUN mkdir -p /root/.cargo && \
    echo '\
[target.x86_64-unknown-linux-gnu]\n\
linker = "x86_64-linux-gnu-gcc"\n\
\n\
[target.x86_64-pc-windows-gnu]\n\
linker = "x86_64-w64-mingw32-gcc"\n\
\n\
[target.x86_64-apple-darwin]\n\
linker = "x86_64-apple-darwin20.4-clang"\n\
ar = "x86_64-apple-darwin20.4-ar"\n\
\n\
[target.aarch64-apple-darwin]\n\
linker = "aarch64-apple-darwin20.4-clang"\n\
ar = "aarch64-apple-darwin20.4-ar"\n\
' > /root/.cargo/config.toml
EOF

docker run -it --rm -v "$(pwd)":/app rust-cross-compiler /bin/sh -c '
set -e
# echo "which"
# ls /root/osxcross/target/bin
# exit 1
echo "Building for x86 Linux..."
cargo build --manifest-path rust/Cargo.toml --target x86_64-unknown-linux-gnu
echo "Building for x86 Windows..."
cargo build --manifest-path rust/Cargo.toml --target x86_64-pc-windows-gnu
echo "Building for x86 macOS..."
cargo build --manifest-path rust/Cargo.toml --target x86_64-apple-darwin
echo "Building for ARM macOS..."
cargo build --manifest-path rust/Cargo.toml --target aarch64-apple-darwin
'

docker run -it --rm -v "$(pwd)":/app rust-cross-compiler /bin/sh -c '
set -e
echo "Building for x86 Linux..."
cargo build --manifest-path rust/Cargo.toml --target x86_64-unknown-linux-gnu --release
echo "Building for x86 Windows..."
cargo build --manifest-path rust/Cargo.toml --target x86_64-pc-windows-gnu --release
echo "Building for x86 macOS..."
cargo build --manifest-path rust/Cargo.toml --target x86_64-apple-darwin --release
echo "Building for ARM macOS..."
cargo build --manifest-path rust/Cargo.toml --target aarch64-apple-darwin --release
'

echo "Build process completed."
echo "Built libraries can be found at:"
echo "x86 Linux:   target/x86_64-unknown-linux-gnu/release/"
echo "x86 Windows: target/x86_64-pc-windows-gnu/release/"
echo "x86 macOS:   target/x86_64-apple-darwin/release/"
echo "ARM macOS:   target/aarch64-apple-darwin/release/"
echo "x86 Linux:   target/x86_64-unknown-linux-gnu/debug/"
echo "x86 Windows: target/x86_64-pc-windows-gnu/debug/"
echo "x86 macOS:   target/x86_64-apple-darwin/debug/"
echo "ARM macOS:   target/aarch64-apple-darwin/debug/"