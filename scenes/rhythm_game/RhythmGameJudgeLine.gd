@tool
class_name RhythmGameJudgeLine
extends Node2D


signal note_judged(note: RhythmGameNote, grade: RhythmGame.JudgeGrade)


const judge_grade_names: Array[StringName] = ["Perfect", "Great", "Good", "OK", "Bad"]


@export_group("Judge Window", "judge_window__")

## Timing window of [b]perfect[/b] judge.
@export var judge_window__perfect := 0.01667

## Timing window of [b]great[/b] judge.
@export var judge_window__great   := 0.03333

## Timing window of [b]good[/b] judge.
@export var judge_window__good    := 0.06667

## Timing window of [b]ok[/b] judge.
@export var judge_window__ok     := 0.11667

## Timing window of [b]bad[/b] judge.
@export var judge_window__bad   := 0.25000


@export_group("Judge Area", "judge_area__")

## How many points are used to draw a curve.
@export var judge_area__curve_point := 10


@onready var rhythm_game__ref: RhythmGame:
    get():
        if rhythm_game__ref == null:
            var ref = self.get_parent()
            while ref is not RhythmGame and ref != null:
                ref = ref.get_parent()
            if ref != null:
                rhythm_game__ref = ref
                return ref
            else:
                printerr("RhythmGame class not found. Check node position!")
                return null
        else:
            return rhythm_game__ref


@onready var judge_window_area: Node2D = $JudgeWindowArea

@onready var judge__perfect_area: Area2D = $JudgeWindowArea/PerfectArea

@onready var judge__great_area:   Area2D = $JudgeWindowArea/GreatArea

@onready var judge__good_area:    Area2D = $JudgeWindowArea/GoodArea

@onready var judge__ok_area:      Area2D = $JudgeWindowArea/OKArea

@onready var judge__bad_area:     Area2D = $JudgeWindowArea/BadArea


## The radius of the ring got from [method Sprite2D.get_rect].
var outer_ring_display_radius: float


func _ready() -> void: self.__onReady__()


func __onReady__():
    if Engine.is_editor_hint():
        self.set_process(false)
        self.set_physics_process(false)
    else:
        self.set_process(true)
        self.set_physics_process(true)

func postInit():
    self.refreshJudgeArea()

## Check if there is any notes that can be judged,
##  and give judge score accordingly.
func triggerJudge(note_type: RhythmGameNote.NoteType):
    # # Check if there is any note inside.
    if not self.judge__bad_area.has_overlapping_areas():
        return # Cannot judge because no note to judge.

    # # Add note that should be checked.
    var notes_to_check: Array[RhythmGameNote] = []
    for area in self.judge__bad_area.get_overlapping_areas():
        if area is RhythmGameNote:
            if area.isValidNote() and area.type == note_type:
                notes_to_check.append(area)
    var note_count := notes_to_check.size()
    if note_count <= 0:
        return # No note to judge.

    # # Check from later note to former note.
    # That is, check if there is already note after judge line first.
    if note_count > 1:
        notes_to_check.sort_custom(
            func(a: RhythmGameNote, b: RhythmGameNote): return a.time < b.time
        )
    # Notice: This `note_to_check` must be inside a judge area.
    var note_to_check: RhythmGameNote = notes_to_check.front()
    var grade := RhythmGame.JudgeGrade.bad
    if self.judge__perfect_area.overlaps_area(note_to_check):
        grade = RhythmGame.JudgeGrade.perfect
    elif self.judge__great_area.overlaps_area(note_to_check):
        grade = RhythmGame.JudgeGrade.great
    elif self.judge__good_area.overlaps_area(note_to_check):
        grade = RhythmGame.JudgeGrade.good
    elif self.judge__ok_area.overlaps_area(note_to_check):
        grade = RhythmGame.JudgeGrade.ok
    self.note_judged.emit(note_to_check, grade)

static func isJudgeBadArea(area: Area2D):
    var area_parent := area.get_parent()

    return area.name.begins_with("BadArea") \
        and area_parent != null and area_parent.name.begins_with("JudgeWindowArea")

## Update the circle sector shape and rotation of each judge area.
## Should be called when [member rhythm_game__ref] is init-ed.
func refreshJudgeArea():
    for judge_grade in RhythmGameJudgeLine.judge_grade_names:
        var judge_area: Area2D = self.judge_window_area.get_node(
            str(judge_grade, "Area")
        )
        var judge_shape: CollisionPolygon2D = judge_area.get_node("CollisionPolygon2D")

        # # Calculate the angle.
        var rotation_speed := self.rhythm_game__ref.ring_rotation_speed
        var difficulty_adjust := self.rhythm_game__ref.difficulty_adjust
        var angle_degrees: float = \
            # s * deg/s
            self.get(str("judge_window__", judge_grade.to_lower())) \
            * rotation_speed \
            * difficulty_adjust

        judge_shape.polygon = self.getPointsOfJudgeArea(
            angle_degrees,
            self.rhythm_game__ref.display_root.ring.get_rect().size.y / 2,
            rotation_speed,
            self.rhythm_game__ref.judge_offset
        )

func getPointsOfJudgeArea(
    angle_deg: float, ring_radius: float,
    rotation_speed: float, judge_offset: float
) -> PackedVector2Array:
    # # Calculate step for generating arc
    var points: PackedVector2Array = []
    points.append(Vector2.ZERO) # Center origin
    # Generate downward-facing sector polygon.
    var arc_point_count := maxi(2, self.judge_area__curve_point)

    var half_angle: float = deg_to_rad(angle_deg) * 0.5
    var center_angle: float = PI * 0.5 # Downward in Godot 2D.
    center_angle -= deg_to_rad(rotation_speed * judge_offset / 1000)

    var start_angle: float = center_angle - half_angle
    var end_angle: float = center_angle + half_angle

    for i in range(arc_point_count):
        var t: float = float(i) / float(arc_point_count - 1)
        var current_angle: float = lerp(start_angle, end_angle, t)

        points.append(Vector2(
            cos(current_angle) * ring_radius,
            sin(current_angle) * ring_radius
        ))

    return points

func on_BadArea_area_exited(area: Area2D) -> void:
    if area is RhythmGameNote:
        if area.is_judged:
            return

        area.is_judged = true
        self.note_judged.emit(area, RhythmGame.JudgeGrade.miss)
