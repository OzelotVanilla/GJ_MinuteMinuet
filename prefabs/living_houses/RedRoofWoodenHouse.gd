extends Node3D


const default_light_energy := 0.3


@onready var light_near_bed: OmniLight3D = $furniture/bed_lamp_wall/Lights/AtmosphereOmni
@onready var light_kitchen: OmniLight3D = $furniture/kitchen_lamp_wall/Lights/AtmosphereOmni
@onready var light_table_lamp: OmniLight3D = $furniture/lamp_round_table/OmniLight3D


var lights: Array[OmniLight3D]:
    get: return [self.light_near_bed, self.light_kitchen, self.light_table_lamp]

var tween__for_lights: Tween


func turnOnLight(fade_duration: float = 1.5, target_light_energy: float = self.default_light_energy):
    if self.tween__for_lights != null:
        self.tween__for_lights.kill()

    self.tween__for_lights = ($furniture).create_tween()

    for l in self.lights:
        # 0 to target_energy is done in 0 to fade_duration second
        self.tween__for_lights.tween_property(
            l, "light_energy",
            target_light_energy,
            remap(l.light_energy,  0, target_light_energy,  fade_duration, 0)
        )
