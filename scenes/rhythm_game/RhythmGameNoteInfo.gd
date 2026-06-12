class_name RhythmGameNoteInfo
extends Resource


## Start with 1.
@export var measure_pos: int

## Start with 1.
@export var beat_pos: int

## Time to appear, calculated. Unit is [code]s[/code].
var time: float = -1

@export var type: RhythmGameNote.NoteType

## Used in runtime. Assigned when [method RhythmGame.loadSheet].
var index: int = 0

## Used in runtime. If judged, this note become invalid.
var is_judged := false

func isValid():
    return not self.is_judged and self.time >= 0
