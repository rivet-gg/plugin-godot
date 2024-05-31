class_name RivetConstants


const RIVET_CONFIGURATION_PATH: String = "res://.rivet"
const RIVET_CONFIGURATION_FILE_PATH: String = "res://.rivet/config.gd"
const RIVET_DEPLOYED_CONFIGURATION_FILE_PATH: String = "res://.rivet_config.gd"
const SCRIPT_TEMPLATE: String = """
extends RefCounted
const api_endpoint: String = \"{api_endpoint}\"
const namespace_token: String = \"{namespace_token}\"
const cloud_token: String = \"{cloud_token}\"
const game_id: String = \"{game_id}\"
"""
