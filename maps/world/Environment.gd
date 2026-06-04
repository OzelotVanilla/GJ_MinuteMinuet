@tool
extends Node3D


func _ready() -> void: return self.__onReady__()
func _process(delta: float) -> void: return self.__process__(delta)


#region Child nodes
## The [member WorldEnvironment.environment] property of the [WorldEnvironment] node.
@onready var world_env: Environment = ($WorldEnvironment).environment

@onready var sunlight: DirectionalLight3D = $WorldEnvironment/SunLight

@onready var moonlight: DirectionalLight3D = $WorldEnvironment/MoonLight

@onready var sky_shader: ShaderMaterial = self.world_env.sky.sky_material
#endregion


## Current time of the biome. Stored in seconds, counting from [code]00:00[/code] of the day, with 24 hours a day.
@export_range(0, Biome.length_of_one_day_in_seconds) var time_of_day: float = Biome.default_start_time:
    set = setTimeOfDay

@export var time_of_day__digital: String = "00:00":
    get:
        return str(
            str(int(self.time_of_day / 3600)).pad_zeros(2),
            ":",
            str(int(fmod(self.time_of_day, 3600) / 60)).pad_zeros(2)
        )

var time_scale: float


func __onReady__() -> void:
    # For testing only.
    self.time_of_day = Biome.getTimeOfNOClock(9)
    self.time_scale = Biome.default_time_scale

## [param delta] is in seconds.
func  __process__(delta: float) -> void:
    if Engine.is_editor_hint():
        return

    self.time_of_day = fposmod(
        (self.time_of_day + delta * self.time_scale),
        Biome.length_of_one_day_in_seconds
    )

#region impl Biome // Time related.
## Warning: this is a [b]setter[/b].
## [param time] is the seconds value counted from the start of day (00:00).
func setTimeOfDay(time: float):
    # If invalid then keep old value.
    if time < 0 or time > Biome.length_of_one_day_in_seconds:
        return

    # Set the value (setter method should not use `self` when assign)
    time_of_day = time

    # Avoid meaningless setting of node.
    if not self.is_node_ready(): return
    else: self.applyTimeChange(time)


const sky_morning_colour := Color("#6d93b9")

const sky_noon_colour    := Color("#a0d8ef")

const sky_evening_colour := Color("#55295b")

const sky_night_colour   := Color("#171917")

const sky_horizon_morning_colour := Color("#c4a3bf")

const sky_horizon_evening_colour := Color("#ee7800")

const sun_dawn_evening_colour  := Color("#fffceb")

const sun_daylight_colour      := Color("#fffffc")

const cloud_morning_colour := Color("#68699b")

const cloud_noon_colour    := Color("#fffffc")

const cloud_evening_colour := Color("#f39800")

const cloud_night_colour   := Color("#455765")


func applyTimeChange(t: float):
    # # Change visibility/angle of sunlight/moonlight.
    # Before dawn and after evening, should adjust sun rotation.
    # Daytime (or, sun should appear, 14 hours), adjust the ambient light's strength and sky colour, etc.
    if Biome.isDayLightTime(t):
        self.sunlight.visible = true

        # # Time parameter calculation.
        ## 0 for morning or evening, 1 for noon. Counting from [constant Biome.timepoint_of_morning].
        var timespan_to_noon_ratio: float = remap(
            abs(t - Biome.timepoint_of_noon),
            0, 21600, # Biome.length_of_half_day_in_seconds / 2,
            1, 0
        )
        ## Used for the light strength or colour calucation for the time period around dawn or evening.
        var daylight_ratio = smoothstep(0.05, 0.3, timespan_to_noon_ratio)
        var dawn_break_ratio = daylight_ratio # Only meaningful before noon.
        var enter_evening_ratio = 1 - dawn_break_ratio # Only meaningful after noon.

        # # Sun rotation.
        var sun_rotation = self.sunlight.rotation_degrees
        sun_rotation.x = (t - Biome.timepoint_before_morning) / Biome.length_of_half_day_in_seconds * -180.0
        self.sunlight.rotation_degrees = sun_rotation

        # # Sun energy.
        self.sunlight.light_energy = \
            remap(dawn_break_ratio,      0, 1,   1.1,  1.25) if t <= Biome.timepoint_of_noon else \
            remap(enter_evening_ratio,   0, 1,   1.25, 1.75)

        # # Ambient light.
        # After morning and before evening, the light strength could be considered 100%.
        self.world_env.ambient_light_energy = remap(daylight_ratio,    0, 1,    0.1, 1.2)

        # # Sky and ground colour.
        var sky_top_colour := (sky_morning_colour.lerp(sky_noon_colour, dawn_break_ratio)
            if t <= Biome.timepoint_of_noon # ^ Sunrise, v Sunset
            else sky_noon_colour.lerp(sky_evening_colour, enter_evening_ratio))
        self.sky_shader.set_shader_parameter("sky_top_color", sky_top_colour)
        self.sky_shader.set_shader_parameter("ground_bottom_color", sky_top_colour)
        var horizon_colour := (sky_horizon_morning_colour.lerp(sky_noon_colour, dawn_break_ratio)
            if t <= Biome.timepoint_of_noon # ^ Sunrise, v Sunset
            else sky_noon_colour.lerp(sky_horizon_evening_colour, enter_evening_ratio))
        self.sky_shader.set_shader_parameter("sky_horizon_color", horizon_colour)
        self.sky_shader.set_shader_parameter("ground_horizon_color", horizon_colour)

        # # Sun colour.
        self.sky_shader.set_shader_parameter(
            "sun_colour_override",
            sun_dawn_evening_colour.lerp(sun_daylight_colour, daylight_ratio)
        )

        # # Cloud colour.
        self.sky_shader.set_shader_parameter(
            "cloud_colour_modifier",
            cloud_morning_colour.lerp(cloud_noon_colour, dawn_break_ratio)
            if t <= Biome.timepoint_of_noon # ^ Sunrise, v Sunset
            else cloud_noon_colour.lerp(cloud_evening_colour, enter_evening_ratio)
        )
    # Night.
    elif Biome.isNightLightTime(t):
        self.moonlight.visible = true

        # # Time parameter calculation.
        var timespan_to_midnight_ratio: float = remap(
            min(t, Biome.length_of_one_day_in_seconds - t),
            0, 21600, # Biome.length_of_half_day_in_seconds / 2,
            1, 0
        )
        ## Used for the light strength or colour calucation for the time period around evening or dawn.
        var nightdark_ratio = smoothstep(0.05, 0.3, timespan_to_midnight_ratio)
        #print_debug("nightdark_ratio: ", nightdark_ratio)
        var evening_break_ratio = nightdark_ratio # Only meaningful before midnight.
        var enter_dawn_ratio = 1 - evening_break_ratio # Only meaningful after midnight.

        # # Moon rotation.
        var moon_rotation = self.moonlight.rotation_degrees
        moon_rotation.x = -180.0 * \
            fmod(
                t - Biome.timepoint_after_evening + Biome.length_of_one_day_in_seconds,
                Biome.length_of_one_day_in_seconds
            ) / Biome.length_of_half_day_in_seconds
        self.moonlight.rotation_degrees = moon_rotation

        # # Moon energy.
        # Considered not changing (being 0.18) during the whole night.
        self.moonlight.light_energy = 0.18

        # # Ambient light.
        # Greater the nightdark_ratio, darker should the environment be.
        self.world_env.ambient_light_energy = remap(nightdark_ratio,    0, 1,    0.1, 0.05)

        # # Sky and ground colour.
        var sky_top_colour := (sky_night_colour.lerp(sky_morning_colour, enter_dawn_ratio)
            if t <= Biome.timepoint_of_morning # ^ Sunrise, v Sunset
            else sky_evening_colour.lerp(sky_night_colour, evening_break_ratio))
        self.sky_shader.set_shader_parameter("sky_top_color", sky_top_colour)
        self.sky_shader.set_shader_parameter("ground_bottom_color", sky_top_colour)
        var horizon_colour := (sky_night_colour.lerp(sky_horizon_morning_colour, enter_dawn_ratio)
            if t <= Biome.timepoint_of_morning # ^ Sunrise, v Sunset
            else sky_horizon_evening_colour.lerp(sky_night_colour, evening_break_ratio))
        self.sky_shader.set_shader_parameter("sky_horizon_color", horizon_colour)
        self.sky_shader.set_shader_parameter("ground_horizon_color", horizon_colour)

        # # Moon colour.
        # Considered not changing (being "#f8f4e6") during the whole night.
        self.moonlight.light_color = Color("#f8f4e6")

        # # Cloud colour.
        self.sky_shader.set_shader_parameter(
            "cloud_colour_modifier",
            cloud_night_colour.lerp(cloud_morning_colour, enter_dawn_ratio)
            if t <= Biome.timepoint_of_morning # ^ Sunrise, v Sunset
            else cloud_evening_colour.lerp(cloud_night_colour, evening_break_ratio)
        )

    # # Hide sun/moon by decrease the light energy in 1 hour (in game), after the sun/moon sinking.
    # If t is 19:00 ~ 20:00.
    if Biome.timepoint_after_evening <= t and t <= Biome.timepoint_after_evening + Biome.length_of_one_hour_in_seconds:
        self.sunlight.light_energy = remap(
            t,
            Biome.timepoint_after_evening, Biome.timepoint_after_evening + Biome.length_of_one_hour_in_seconds,
            1.75, 0
        )
    # If t is 20:00 ~ 29:00 (05:00).
    elif t >= Biome.timepoint_after_evening + Biome.length_of_one_hour_in_seconds or t <= Biome.timepoint_before_morning:
        self.sunlight.rotation_degrees.x = 90
        self.sunlight.light_energy       = 0

    # If t is 07:00 ~ 08:00.
    if Biome.timepoint_after_morning <= t and t <= Biome.timepoint_after_morning + Biome.length_of_one_hour_in_seconds:
        self.moonlight.light_energy = remap(
            t,
            Biome.timepoint_after_morning, Biome.timepoint_after_morning + Biome.length_of_one_hour_in_seconds,
            0.18, 0
        )
    # If t is 08:00 ~ 19:00.
    elif Biome.timepoint_after_morning + Biome.length_of_one_hour_in_seconds <= t and t <= Biome.timepoint_after_evening:
        self.moonlight.rotation_degrees.x = 90
        self.moonlight.light_energy       = 0
#endregion
