class_name RivetConstants


const RIVET_CONFIGURATION_PATH: String = "res://.rivet"
const RIVET_CONFIGURATION_FILE_PATH: String = "res://.rivet/config.gd"
const RIVET_DEPLOYED_CONFIGURATION_FILE_PATH: String = "res://.rivet_config.gd"
const SCRIPT_TEMPLATE: String = """
extends RefCounted
const rivet_api_endpoint: String = \"{rivet_api_endpoint}\"
const backend_endpoint: String = \"{backend_endpoint}\"
const game_version: String = \"{game_version}\"
"""
