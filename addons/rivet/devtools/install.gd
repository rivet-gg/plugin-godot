#!/usr/bin/env -S godot -s
extends SceneTree

func _init():
    var output = []
    #print('/bin/bash ', " ".join(['-c', "\"curl -fsSL https://raw.githubusercontent.com/rivet-gg/cli/main/install/unix.sh | sh\""]))
    #OS.execute('/bin/bash', ['-c', "\"curl -fsSL https://raw.githubusercontent.com/rivet-gg/cli/main/install/unix.sh\""], output, true, true)
    var args = ['-c', 'curl -fsSL https://raw.githubusercontent.com/rivet-gg/cli/main/install/unix.sh | sh']
    print("Running ", '/bin/bash ', " ".join(args))
    OS.execute('/bin/bash', args, output, true, true)
    print(output)
    quit()