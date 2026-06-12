extends Node3D


const rhythm_game_scene := preload("res://scenes/rhythm_game/RhythmGame.tscn")


func _ready() -> void: self.__onReady__()


@onready var bgm_manager: Node = $BGMManager

@onready var rhythm_challenge_container: Node3D = $RhythmChallengeContainer

@onready var rhythm_game_container: CanvasLayer = $RhythmGameContainer


func __onReady__():
    self.rhythm_game_container.hide()

    for rhythm_challenge_trigger in self.rhythm_challenge_container.get_children():
        if rhythm_challenge_trigger is RhythmChallengeTrigger:
            rhythm_challenge_trigger.rhythm_game_start_request.connect(
                self.startRhythmGameChallenge
            )

func startRhythmGameChallenge(sheet_path: String):
    var sheet_file: RhythmGameSheet = load(sheet_path)
    if sheet_file == null or sheet_file is not RhythmGameSheet:
        printerr("Not a valid sheet file assigned.")
    var scene: RhythmGame = rhythm_game_scene.instantiate()
    self.rhythm_game_container.add_child(scene)
    scene.loadSheet(sheet_file)
    scene.start()
    scene.finished.connect(self.on_RhythmGame_finished, ConnectFlags.CONNECT_ONE_SHOT)

    self.rhythm_game_container.show()

func on_RhythmGame_finished(sheet_name: StringName):
    self.rhythm_game_container.hide()
    for c in self.rhythm_game_container.get_children():
        self.rhythm_game_container.remove_child(c)
        c.queue_free()

    for bgm_player in self.bgm_manager.get_children(): if bgm_player is AudioStreamPlayer:
        bgm_player.stop()
        if bgm_player.get_meta("sheet_name") == sheet_name:
            bgm_player.playing = true
