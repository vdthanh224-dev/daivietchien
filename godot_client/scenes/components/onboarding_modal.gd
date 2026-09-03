extends Control

signal tutorial_chosen()
signal veteran_chosen()

@onready var btn_tutorial: Button = $DimBackground/ModalBox/Margin/VBox/CardsContainer/CardTutorial/Margin/VBox/BtnTutorial
@onready var btn_veteran: Button = $DimBackground/ModalBox/Margin/VBox/CardsContainer/CardVeteran/Margin/VBox/BtnVeteran

func _ready() -> void:
	btn_tutorial.pressed.connect(func():
		tutorial_chosen.emit()
	)
	btn_veteran.pressed.connect(func():
		veteran_chosen.emit()
	)

	if "--screenshot" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://onboarding_screenshot.png")
		print("[Screenshot] Đã lưu onboarding_screenshot.png!")
		get_tree().quit()
