FROM ghcr.io/rivet-gg/godot-docker/godot:4.2 AS builder
WORKDIR /app
COPY . .
RUN mkdir -p build/linux \
    && godot -v --export-release "Linux/X11" ./build/linux/game.x86_64 --headless

# Validate build exists since Godot exits quietly if the export mode doesn't exist
RUN test -f ./build/linux/game.x86_64 || (echo "Error: ./build/linux/game.x86_64 not found. Check that Linux/X11 export is configured." && exit 1)

FROM ubuntu:22.04
RUN apt update -y \
    && apt install -y expect-dev \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -ms /bin/bash rivet

COPY --from=builder /app/build/linux/ /app


# Change to user rivet
USER rivet

# Unbuffer output so the logs get flushed
CMD ["sh", "-c", "unbuffer /app/game.x86_64 --verbose --headless -- --server | cat"]
