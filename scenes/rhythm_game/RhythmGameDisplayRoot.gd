@tool
class_name RhythmGameDisplayRoot
extends Node2D
## Manages display of ring and notes


const note_scene := preload("res://scenes/rhythm_game/RhythmGameNote.tscn")


@onready var ring: Sprite2D = $Ring

@onready var note_container: Node2D = $NoteContainer


## Unit is [code]deg/s[/code].
var ring_rotation_speed: float

var notes__ref: Array[RhythmGameNoteInfo]

## Unit is [code]s[/code].
var bad_judge_window: float

var ring_radius_displayed: float


func _ready() -> void: self.__onReady__()


func __onReady__():
    if Engine.is_editor_hint():
        self.set_process(false)
        self.set_physics_process(false)
    else:
        self.set_process(true)
        self.set_physics_process(true)

var renderNotes__note_detect_start_index := 0

## [param time_elapsed]'s unit is [code]s[/code].[br]
## Render the note fall into the range from the judge line to 270 deg advance.
func renderNotes(time_elapsed: float):
    # # Calculate the window of note to render.
    var time__until_last_render: float = \
        time_elapsed + 270 / self.ring_rotation_speed
    var notes_to_render: Array = []
    for i in range(self.renderNotes__note_detect_start_index, self.notes__ref.size()):
        var note: RhythmGameNoteInfo = self.notes__ref[i]
        if note.time < time_elapsed - self.bad_judge_window:
            self.renderNotes__note_detect_start_index += 1
            continue
        elif time__until_last_render < note.time:
            break
        elif note.isValid(): # Skip rendering of any invalid note.
            notes_to_render.append(note)

    # # Draw it.
    for note in notes_to_render:
        self.drawNoteNearRing(time_elapsed, note)

func drawNoteNearRing(time_elapsed: float, note: RhythmGameNoteInfo):
    ## [code]rad[/code].
    var angle_from_judge_line: float = wrapf(
        PI / 2 - deg_to_rad((note.time - time_elapsed) * self.ring_rotation_speed),
        -PI, PI
    )
    var node_name = str(note.index)
    var note_scene_instance: RhythmGameNote
    if not self.note_container.has_node(node_name):
        note_scene_instance = self.note_scene.instantiate()
        self.note_container.add_child(note_scene_instance)

        var note_length := note_scene_instance.sprite.get_rect().size.y
        var ratio_of_scale := (0.3 * self.ring_radius_displayed) / note_length
        note_scene_instance.scale = Vector2(ratio_of_scale, ratio_of_scale)

        note_scene_instance.name = str(note.index)
        note_scene_instance.time = note.time
        note_scene_instance.type = note.type
        note_scene_instance.index_in_note_array = note.index

        if note.type == RhythmGameNote.NoteType.upper_note:
            note_scene_instance.modulate = Color("#e7609e")
        elif note.type == RhythmGameNote.NoteType.lower_note:
            note_scene_instance.modulate = Color("#0094c8")
    else:
        note_scene_instance = self.note_container.get_node(node_name)

    var length_from_origin := 0.9 * self.ring_radius_displayed

    note_scene_instance.position = \
        Vector2(
            cos(angle_from_judge_line) * length_from_origin,
            sin(angle_from_judge_line) * length_from_origin
        )
    note_scene_instance.rotation = angle_from_judge_line + PI * 1.5

## Scale the entities and rearrange notes.
func scaleAndRearrangeEntitiesBy(scale_value: float):
    self.scaleEntities(scale_value)
    self.placeEntities()

func scaleEntities(scale_value: float):
    # # Set ring scale raw value.
    self.ring.scale = Vector2(scale_value, scale_value)

## Place entites according to their size.
func placeEntities():
    ## Displayed radius of the ring. Not metadata.
    #var ring_radius := self.ring.get_rect().size.y / 2
    pass
