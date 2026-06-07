@tool
extends Node3D


@onready var omni_light: OmniLight3D = $Lights/OmniLight3D

@onready var mesh: MeshInstance3D = $Mesh

@onready var light_cover__material: StandardMaterial3D:
    get():
        return self.mesh.mesh.surface_get_material(1)

@export_custom(PropertyHint.PROPERTY_HINT_GROUP_ENABLE, "")
var is_light_on: bool = false:
    set(value):
        if is_light_on != value:
            is_light_on = value
            if not self.is_node_ready():
                await self.ready
            self.applyLightOnOff()


func applyLightOnOff():
    if self.is_light_on:
        self.omni_light.show()
        self.light_cover__material.emission_enabled = true
    else:
        self.omni_light.hide()
        self.light_cover__material.emission_enabled = false

func __onReady__():
    self.applyLightOnOff()
