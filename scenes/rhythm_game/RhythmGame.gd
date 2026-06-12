@tool
class_name RhythmGame
extends ColorRect


signal sheet_load_finished

signal finished(sheet_name: StringName)


enum JudgeGrade
{
    not_set,
    perfect,
    great,
    good,
    ok,
    bad,
    miss
}


## Set how wide/tall the ring should occupy in the rhythm game bounding rect.
@export var ring_ratio_of_game: float = 0.8

@export_group("Gameplay: Timing and Judging")

## How many degrees will the ring rotate when 1 second passes.
## Unit is [code]deg/s[/code].
@export_custom(PropertyHint.PROPERTY_HINT_NONE, "suffix:deg/s")
var ring_rotation_speed: float = 45:
    set(new_speed):
        if ring_rotation_speed != new_speed:
            ring_rotation_speed = new_speed
            if self.is_node_ready():
                self.display_root.ring_rotation_speed = new_speed

## Unit is [code]ms[/code].
## If too many fast, adjust to positive number.
## If too many slow, adjust to negative number.
@export_custom(PropertyHint.PROPERTY_HINT_NONE, "suffix:ms")
var judge_offset: float = 0.0:
    set(new_offset):
        if judge_offset != new_offset:
            judge_offset = new_offset
            if self.is_node_ready():
                self.judge_line.refreshJudgeArea()

## Bigger is easier.
@export var difficulty_adjust: float = 1.0:
    set(new_adjust):
        if difficulty_adjust != new_adjust:
            difficulty_adjust = new_adjust
            if self.is_node_ready():
                self.judge_line.refreshJudgeArea()

@export_group("Gameplay: UI", "ui__")

## Show combo after judge text.
@export var ui__show_combo_count := true

@export_custom(PropertyHint.PROPERTY_HINT_NONE, "suffix:s")
var ui__hide_count_after: float = 1.0:
    set(new_value):
        if ui__hide_count_after != new_value:
            ui__hide_count_after = new_value
            if self.is_node_ready():
                self.judge_text_disappear_timer.wait_time = new_value
            else:
                self.ready.connect(
                    func(): self.judge_text_disappear_timer.wait_time = new_value,
                    ConnectFlags.CONNECT_ONE_SHOT
                )

@export var ui__perfect__text: StringName = "PERFECT"

@export var ui__perfect__colour: Color = Color("#ffd900")

@export var ui__great__text: StringName = "GREAT"

@export var ui__great__colour: Color = Color("#f69e22")

@export var ui__good__text: StringName = "GOOD"

@export var ui__good__colour: Color = Color("#f5b1aa")

@export var ui__ok__text: StringName = "OK"

@export var ui__ok__colour: Color = Color("#7b8d42")

@export var ui__bad__text: StringName = "BAD"

@export var ui__bad__colour: Color = Color("#005243")

@export var ui__miss__text: StringName = "MISS"

@export var ui__miss__colour: Color = Color("83959f")


@onready var display_root: RhythmGameDisplayRoot = $DisplayRoot

@onready var judge_line: RhythmGameJudgeLine = $DisplayRoot/RhythmGameJudgeLine

@onready var note_container: Node2D = $DisplayRoot/NoteContainer

@onready var judge_text: Label = $UI/JudgeText

@onready var judge_text_disappear_timer: Timer = $UI/JudgeTextDisappearTimer

@onready var bgm_player: AudioStreamPlayer = $Audio/BGMPlayer


## Runtime only data. Assigned when loading sheet.
var playing_sheet_name: StringName

## Runtime only data. The note which is rendered and interacted.
var parsed_notes: Array[RhythmGameNoteInfo] = []

var combo_count: int = 0

## Unit is [code]ms[/code].
var timestamp__start__in_ms: int

var is_sheet_loading_finished := false


func _ready() -> void: self.__onReady__()
func _process(delta: float) -> void: self.__onProcess__(delta)
func _physics_process(delta: float) -> void: self.__onPhysicsProcess__(delta)
func _unhandled_input(event: InputEvent) -> void: self.__onUnhandledInput__(event)


func __onReady__():
    # Will be enabled if the game start.
    self.set_process(false)
    self.set_physics_process(false)

    self.putAndScaleDisplayRoot()

    # # Post Init.
    self.judge_line.postInit()

    # # Signals.
    self.bgm_player.finished.connect(self.on_BGMPlayer_finished)

    # # Test code.
    #self.loadSheet(load("res://scenes/rhythm_game/test_sheet.tres"))
    #self.start()

func __onProcess__(delta: float):
    ## In seconds.
    var now := self.getAccurateBGMPlaybackPosition()

    # # Render notes.
    self.display_root.ring_rotation_speed = self.ring_rotation_speed
    self.display_root.renderNotes(now)

func __onPhysicsProcess__(delta: float):
    pass

func __onUnhandledInput__(event: InputEvent):
    if event.is_action_pressed("rhythm_game__lower_note_trigger"):
        self.judge_line.triggerJudge(RhythmGameNote.NoteType.lower_note)
    if event.is_action_pressed("rhythm_game__upper_note_trigger"):
        self.judge_line.triggerJudge(RhythmGameNote.NoteType.upper_note)

func start():
    # # Wait for loading finishes.
    if not self.is_sheet_loading_finished:
        await self.sheet_load_finished

    # # Start BGM and rendering of note.
    self.set_process(true)
    self.set_physics_process(true)
    self.bgm_player.play(0)
    self.timestamp__start__in_ms = Time.get_ticks_msec()
    self.display_root.ring_rotation_speed = self.ring_rotation_speed
    self.display_root.notes__ref = self.parsed_notes
    self.display_root.bad_judge_window = self.judge_line.judge_window__bad
    self.display_root.ring_radius_displayed = self.display_root.ring.get_rect().size.y / 2
    self.display_root.set_process(true)
    self.display_root.set_physics_process(true)

    # # Hide judge text and start its disappear timer.
    self.judge_text.hide()
    self.judge_text_disappear_timer.start()

func loadSheet(sheet: RhythmGameSheet):
    self.is_sheet_loading_finished = false

    # # Set name.
    self.playing_sheet_name = sheet.name

    # # Set BGM.
    var bgm_file: AudioStream = load(sheet.bgm)
    if bgm_file == null or bgm_file is not AudioStream:
        printerr("Not a valid bgm file assigned.")
    self.bgm_player.stream = bgm_file

    # # Parse note, calculate time property.
    self.parsed_notes = []
    var note_index := 0
    var result := sheet.notes.duplicate(true) # deep_copy is true.
    var one_beat_len__in_second: float = 60.0 / sheet.bpm
    var one_measure_len__in_second: float = one_beat_len__in_second * sheet.n_beat_per_measure
    for note in result: if note is RhythmGameNoteInfo:
        note.time = (note.measure_pos - 1) * one_measure_len__in_second \
            + (note.beat_pos - 1) * one_beat_len__in_second
        note.index = note_index
        note_index += 1
    self.parsed_notes = result

    # # Emit signal.
    self.is_sheet_loading_finished = true
    self.sheet_load_finished.emit()

## Put the ring root to the visual center, and scale it properly.
func putAndScaleDisplayRoot() -> void:
    var rhythm_game_rect := self.get_rect()

    # # Put to center.
    self.display_root.position = rhythm_game_rect.get_center()

    # # Scale the ring if necessary.
    ## Radius of the circle defined in SVG file.
    var ring_width := self.display_root.ring.get_rect().size.x
    var x_axis_scale := rhythm_game_rect.size.x / ring_width
    var y_axis_scale := rhythm_game_rect.size.y / ring_width
    self.display_root.scaleAndRearrangeEntitiesBy(
        min(x_axis_scale, y_axis_scale) * self.ring_ratio_of_game
    )

func on_JudgeLine_note_judged(note: RhythmGameNote, grade: JudgeGrade) -> void:
    # # Delete from note container and prevent next time rendering.
    self.note_container.remove_child.bind(note).call_deferred()
    note.distroy()
    # Mark as invalid for next rendering.
    self.parsed_notes[note.index_in_note_array].is_judged = true

    # # Count status, show text of judge
    var text_to_show: String
    var text_colour: Color
    match grade:
        JudgeGrade.perfect:
            text_to_show = self.ui__perfect__text
            text_colour  = self.ui__perfect__colour
            self.combo_count += 1
        JudgeGrade.great:
            text_to_show = self.ui__great__text
            text_colour  = self.ui__great__colour
            self.combo_count += 1
        JudgeGrade.good:
            text_to_show = self.ui__good__text
            text_colour  = self.ui__good__colour
            self.combo_count += 1
        JudgeGrade.ok:
            text_to_show = self.ui__ok__text
            text_colour  = self.ui__ok__colour
            self.combo_count += 1
        JudgeGrade.bad:
            text_to_show = self.ui__bad__text
            text_colour  = self.ui__bad__colour
            self.combo_count = 0
        JudgeGrade.miss:
            text_to_show = self.ui__miss__text
            text_colour  = self.ui__miss__colour
            self.combo_count = 0

    # If combo greater than 1, that means, must not be bad or miss.
    if self.ui__show_combo_count and self.combo_count > 1:
            text_to_show = str(text_to_show, " ", self.combo_count)

    self.judge_text.add_theme_color_override("font_color", text_colour)
    self.judge_text.text = text_to_show
    self.judge_text.show()
    self.judge_text_disappear_timer.start()

func on_JudgeTextDisappearTimer_timeout() -> void:
    self.judge_text.hide()

func on_BGMPlayer_finished():
    self.finished.emit(self.playing_sheet_name)
    self.playing_sheet_name = ""
    self.parsed_notes = []
    self.combo_count = 0

## Unit is [code]s[/code].
func getAccurateBGMPlaybackPosition() -> float:
    return self.bgm_player.get_playback_position() \
        + AudioServer.get_time_since_last_mix() \
        - AudioServer.get_output_latency()
