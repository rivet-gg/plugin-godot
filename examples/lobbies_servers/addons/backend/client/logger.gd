# This file is auto-generated by the Open Game Backend (https://opengb.dev) build system.
# 
# Do not edit this file directly.
#
# Generated at 2024-07-18T12:12:50.282Z

class_name BackendLogger

static func log(args):
	print("[Backend] ", args)

static func warning(args):
	print("[Backend] ", args)
	push_warning("[Backend] ", args)

static func error(args):
	print("[Backend] ", args)
	push_error("[Backend] ", args)

