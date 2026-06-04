@abstract
class_name Biome
extends Node3D
## Interface of all biome of this musicbox
##
## [code]Biome[/code] is a independant unit of the content for the musicibox.
## It contains not only the data for how it looks, but also stores the progress.


#region Time related.
## The default time of starting this biome. Stored in seconds.
const default_start_time: float = 0

## The default value of the time scale. See [member Biome.time_scale].
const default_time_scale: float = 60

const length_of_one_day_in_seconds: float = 60 * 60 * 24

const length_of_half_day_in_seconds := Biome.length_of_one_day_in_seconds / 2

const length_of_one_hour_in_seconds := Biome.length_of_one_day_in_seconds / 24

## [code]00:00[/code].
const timepoint_of_midnight := Biome.length_of_one_day_in_seconds * (0  / 24.0)

## [code]06:00[/code].
const timepoint_of_morning  := Biome.length_of_one_day_in_seconds * (6  / 24.0)

## [code]12:00[/code].
const timepoint_of_noon     := Biome.length_of_one_day_in_seconds * (12 / 24.0)

## [code]18:00[/code].
const timepoint_of_evening  := Biome.length_of_one_day_in_seconds * (18 / 24.0)

## [code]05:00[/code]. Used for appearing of the sun.
const timepoint_before_morning := Biome.length_of_one_day_in_seconds * (5 / 24.0)

## [code]17:00[/code]. Used for appearing of the moon.
const timepoint_before_evening := Biome.length_of_one_day_in_seconds * (17 / 24.0)

## [code]07:00[/code]. Used for hiding of the moon.
const timepoint_after_morning  := Biome.length_of_one_day_in_seconds * (7 / 24.0)

## [code]19:00[/code]. Used for hiding of the sun.
const timepoint_after_evening  := Biome.length_of_one_day_in_seconds * (19 / 24.0)


## Stands for how many seconds will pass when the real world passes 1 second.
## For example, [code]60[/code] stands for: 1 second in real world equals to 1 minute (= 60 seconds) in game.
var time_scale: float = Biome.default_time_scale

## Record how many days had passed in the game.
var day_count: int = 0


## Should be overriden in subclass to control the time-sensitive event.
@abstract func setTimeOfDay(value: float) -> void;

static func getTimeOfNOClock(n_o_clock: float) -> float:
    if n_o_clock < 0: return 0
    else:             return fposmod(n_o_clock, 24) / 24.0 * Biome.length_of_one_day_in_seconds

## Check if [param t] (time of day in seconds) is in 07:00 ~ 11:00.
static func isBeforeNoon(t: float) -> bool:
    return Biome.timepoint_after_morning <= t \
       and t <= Biome.timepoint_of_noon - Biome.length_of_one_hour_in_seconds

## Check if [param t] (time of day in seconds) is in 11:00 ~ 13:00.
static func isNoon(t: float) -> bool:
    return Biome.timepoint_of_noon - Biome.length_of_one_hour_in_seconds <= t \
       and t <= Biome.timepoint_of_noon + Biome.length_of_one_hour_in_seconds

## Check if [param t] (time of day in seconds) is in 13:00 ~ 17:00.
static func isAfterNoon(t: float) -> bool:
    return Biome.timepoint_of_noon + Biome.length_of_one_hour_in_seconds <= t \
       and t <= Biome.timepoint_before_evening

## Check if [param t] (time of day in seconds) is in 05:00 ~ 19:00.
static func isDayLightTime(t: float) -> bool:
    return Biome.timepoint_before_morning <= t and t <= Biome.timepoint_after_evening

## Check if [param t] (time of day in seconds) is in 19:00 ~ 29:00 (05:00).
static func isNightLightTime(t: float) -> bool:
    return t >= Biome.timepoint_after_evening or t <= Biome.timepoint_before_morning

## Possible to use 30-hour-a-day for param.
## [param t] is time-of-day in seconds.
static func isInInterval(from_hour: float, t: float, to_hour: float) -> bool:
    # Reference: Gemini. Code modified.
    var from_norm = fmod(from_hour, 24)
    var t_norm    = fmod(t / 24,    24)
    var to_norm   = fmod(to_hour,   24)

    if from_norm <= to_norm:
        return from_norm <= t_norm and t_norm <= to_norm
    else: # The interval crosses midnight.
        return from_norm <= t_norm or t_norm <= to_norm
#endregion

#region Player related.
## The reference to player of this biome.
var player__ref: Player
#endregion
