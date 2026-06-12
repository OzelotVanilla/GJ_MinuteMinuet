class_name RhythmChallengeTrigger
extends Area3D


signal rhythm_game_start_request(sheet_path: String)


@export_file var sheet_path: String


@onready var interactable_hint_label: Label3D = $InteractableHintLabel


func _ready() -> void: self.__onReady__()


func __onReady__():
    self.interactable_hint_label.hide()

func startChallenge():
    self.rhythm_game_start_request.emit(self.sheet_path)

func on_body_entered(body: Node3D) -> void:
    if body is Player:
        self.interactable_hint_label.show()
        # TODO: Bad way of sending interact request, should fix in future.
        body.interact_request.connect(self.startChallenge, ConnectFlags.CONNECT_ONE_SHOT)

func on_body_exited(body: Node3D) -> void:
    if body is Player:
        self.interactable_hint_label.hide()
