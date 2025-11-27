extends Control

@onready var apple_button = $Panel/AppleLoginButton
@onready var error_label = $Panel/MarginContainer/ErrorLabel

# Variable for the extension instance
var my_library: Object = null

# Plugin configuration for Apple Sign-In (exported so you can change it in the editor)
@export var APPLE_PLUGIN_NAME: String = "AppleSignInLibrary"  # Matches your Swift extension name

func _ready() -> void:
    initialize_plugins()
    apple_button.pressed.connect(_on_apple_button_pressed)

func initialize_plugins() -> void:
    if my_library == null && ClassDB.class_exists(APPLE_PLUGIN_NAME):
        my_library = ClassDB.instantiate(APPLE_PLUGIN_NAME)
        # Connect to signals defined in AppleSignInLibrary.swift
        my_library.connect("Output", _on_apple_output_signal)
        my_library.connect("Signout", _on_apple_signout_signal)
        print("AppleSignInLibrary initialized via ClassDB")
    else:
        push_error("Apple Sign-In extension not found: %s" % APPLE_PLUGIN_NAME)
        error_label.show()
        error_label.text = "Apple Sign-In unavailable"

func _on_apple_button_pressed() -> void:
    if my_library:
        if my_library.has_method("signIn"):
            my_library.signIn()
    else:
        error_label.show()
        push_error("Apple plugin not initialized")
        error_label.text = "Apple Sign-In error"

func _on_apple_output_signal(output: String) -> void:
    # Handle the Output signal from MyLibrary
    error_label.show()
    error_label.text = output

func _on_apple_signout_signal(signout: String) -> void:
    # Handle the Signout signal from MyLibrary
    error_label.show()
    error_label.text = signout
