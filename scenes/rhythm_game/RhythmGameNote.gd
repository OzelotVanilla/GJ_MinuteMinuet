class_name RhythmGameNote
extends Area2D


enum NoteType
{
    ## Note that is not yet associated with a valid type.
    ## Should not appear in game.
    not_set,
    ## Trigged by keyboard press of upper area's key.
    upper_note,
    ## Trigged by keyboard press of lower area's key.
    lower_note
}


@onready var sprite: Sprite2D = $Sprite


## Note type that affects which key can trigger.
var type := NoteType.not_set

## Whether this note is already judged.
var is_judged := false

## Runtime only data. Referred to the index in [member RhythmGame.parsed_notes].
var index_in_note_array := -1

## The time offset (from song start) that this note appears.
## Unit is [code]s[/code].
var time: float = -1

var disappear_tween: Tween


func isValidNote() -> bool:
    return not self.is_judged \
        and self.type != NoteType.not_set \
        and self.time >= 0

func distroy():
    self.is_judged = true
    #await self.playDisappearAnimation()
    self.queue_free()

## Should be called when the note is considered played.
func playDisappearAnimation():
    if self.disappear_tween != null:
        return

    self.disappear_tween = create_tween()
    self.disappear_tween.tween_property(
        self.sprite, "self_modulate:a",
        0, 1
    )
    await self.disappear_tween.finished
    self.disappear_tween.kill()
    self.disappear_tween = null
