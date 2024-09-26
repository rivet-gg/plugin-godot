# MARK: Builder
FROM ghcr.io/rivet-gg/godot-docker/godot:4.2 AS builder
WORKDIR /app
COPY . .

# Overwrite export preset specific for Linux
RUN echo '[preset.0]\n\
\n\
name="RivetServer"\n\
platform="Linux/X11"\n\
runnable=true\n\
dedicated_server=false\n\
custom_features=""\n\
export_filter="all_resources"\n\
include_filter=""\n\
exclude_filter="addons/rivet/*"\n\
export_path=""\n\
encryption_include_filters=""\n\
encryption_exclude_filters=""\n\
encrypt_pck=false\n\
encrypt_directory=false\n\
\n\
[preset.0.options]\n\
\n\
custom_template/debug=""\n\
custom_template/release=""\n\
debug/export_console_wrapper=1\n\
binary_format/embed_pck=false\n\
texture_format/bptc=true\n\
texture_format/s3tc=true\n\
texture_format/etc=false\n\
texture_format/etc2=false\n\
binary_format/architecture="x86_64"\n\
ssh_remote_deploy/enabled=false\n\
ssh_remote_deploy/host="user@host_ip"\n\
ssh_remote_deploy/port="22"\n\
ssh_remote_deploy/extra_args_ssh=""\n\
ssh_remote_deploy/extra_args_scp=""\n\
ssh_remote_deploy/run_script="#!/usr/bin/env bash\n\
export DISPLAY=:0\n\
unzip -o -q \"{temp_dir}/{archive_name}\" -d \"{temp_dir}\"\n\
\"{temp_dir}/{exe_name}\" {cmd_args}"\n\
ssh_remote_deploy/cleanup_script="#!/usr/bin/env bash\n\
kill $(pgrep -x -f \"{temp_dir}/{exe_name} {cmd_args}\")\n\
rm -rf \"{temp_dir}\""\n\
dotnet/include_scripts_content=false\n\
dotnet/include_debug_symbols=true\n\
dotnet/embed_build_outputs=false' > /app/export_presets.cfg

# Build
RUN mkdir -p build/linux \
    && godot -v --export-release "RivetServer" ./build/linux/game.x86_64 --headless \
	&& (test -f ./build/linux/game.x86_64 || (echo "Error: ./build/linux/game.x86_64 not found, export may have failed." && exit 1))

# MARK: Runner
FROM ubuntu:22.04
RUN apt update -y \
    && apt install -y expect-dev \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -ms /bin/bash rivet

COPY --from=builder /app/build/linux/ /app

# Change user
USER rivet

# Unbuffer output so the logs get flushed
CMD ["sh", "-c", "unbuffer /app/game.x86_64 --verbose --headless -- --server | cat"]

