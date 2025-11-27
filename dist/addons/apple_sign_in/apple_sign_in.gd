class_name AppleSignIn
extends RefCounted

signal apple_output_signal(output: String)
signal apple_signout_signal(signout: String)

# Variable for the extension instance
var my_library: Object = null
@export var verbose: bool = true

# Plugin configuration for Apple Sign-In (exported so you can change it in the editor)
@export var APPLE_PLUGIN_NAME: String = "AppleSignInLibrary"  # Matches your Swift extension name

func _init():
	if my_library == null && ClassDB.class_exists(APPLE_PLUGIN_NAME):
		my_library = ClassDB.instantiate(APPLE_PLUGIN_NAME)
		# Connect to signals defined in AppleSignInLibrary.swift
		my_library.connect("Output", on_apple_output_signal)
		my_library.connect("Signout", on_apple_output_signal)

func sign_in() -> void:
	if my_library && my_library.has_method("signIn"):
			my_library.signIn()

func on_apple_output_signal(output: String):
	print("[AppleSignIn Output] ", output)
	apple_output_signal.emit(output)

func on_apple_signout_signal(signout: String):
	print("[AppleSignIn SignOut] ", signout)
	apple_signout_signal.emit(signout)
