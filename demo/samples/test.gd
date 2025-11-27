extends Node2D

var apple_sign_in:= AppleSignIn.new()

func _ready() -> void:
	apple_sign_in.sign_in()
