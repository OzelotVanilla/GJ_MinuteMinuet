@tool
class_name Player
extends CharacterBody3D
## Programed character in this game.


func _ready() -> void: self.__onReady__()
func _process(delta: float) -> void: self.__process__(delta)
func _physics_process(delta: float) -> void: self.__physicsProcess__(delta)
func _unhandled_input(event: InputEvent) -> void: self.__onUnhandledInput__(event)


@onready var anime_player: AnimationPlayer = $Mesh/AnimationPlayer

@onready var camera_pivot: Node3D = $CameraPivot

@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm


@export var walk_speed: float = 4.0

@export var run_speed: float = 8.0

@export var rotation_speed: float = 10.0

@export var mouse_sensitivity: float = 0.003

@export var camera_pitch_min: float = deg_to_rad(-45.0)

@export var camera_pitch_max: float = deg_to_rad(35.0)

@export var spring_arm_length: float = 5.0:
    get:
        if self.spring_arm == null:
            return spring_arm_length
        return self.spring_arm.spring_length
    set(value):
        spring_arm_length = value
        if self.spring_arm != null and self.spring_arm.spring_length != value:
            self.spring_arm.spring_length = value


var camera_yaw: float = 0.0

var camera_pitch: float = deg_to_rad(-15.0)

var is_rotating_camera: bool = false


func __onReady__():
    if Engine.is_editor_hint():
        self.set_process(false)
        self.set_physics_process(false)
    else:
        self.set_process(true)
        self.set_physics_process(true)

        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

        self.camera_yaw = self.global_rotation.y + PI
        self.camera_pitch = deg_to_rad(-15.0)
        self.spring_arm.spring_length = self.spring_arm_length

        self.applyCameraRotation()

## [param delta] is in seconds.
func __process__(delta: float) -> void:
    if Engine.is_editor_hint():
        return

func __physicsProcess__(delta: float) -> void:
    if Engine.is_editor_hint():
        return

    var input_direction := Input.get_vector(
        "move_left",
        "move_right",
        "move_backward",
        "move_forward"
    )

    var direction := self.getMoveDirectionByCamera(input_direction)

    var current_speed := self.walk_speed
    if Input.is_action_pressed("run"):
        current_speed = self.run_speed

    self.velocity.x = direction.x * current_speed
    self.velocity.z = direction.z * current_speed

    if not self.is_on_floor():
        # Should be `+=` because gravity is negative.
        self.velocity.y += get_gravity().y * delta
    else:
        self.velocity.y = 0.0

    self.move_and_slide()

    self.updateAnimationBy(direction, current_speed)
    self.updateRotationBy(direction, delta)
    self.updateCameraBy(delta)

func __onUnhandledInput__(event: InputEvent) -> void:
    if Engine.is_editor_hint():
        return

    if get_tree().paused:
        return

    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            self.is_rotating_camera = event.pressed

            if self.is_rotating_camera:
                Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            else:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

            get_viewport().set_input_as_handled()

    if event is InputEventMouseMotion:
        if not self.is_rotating_camera:
            return

        self.camera_yaw -= event.relative.x * self.mouse_sensitivity
        self.camera_pitch -= event.relative.y * self.mouse_sensitivity

        self.camera_pitch = clamp(
            self.camera_pitch,
            self.camera_pitch_min,
            self.camera_pitch_max
        )

        self.applyCameraRotation()

func getMoveDirectionByCamera(input_direction: Vector2) -> Vector3:
    if input_direction.length() == 0.0:
        return Vector3.ZERO

    var camera_basis := Basis(Vector3.UP, self.camera_yaw)

    var camera_right := camera_basis * Vector3.RIGHT
    var camera_forward := camera_basis * Vector3.FORWARD

    var direction := (
        camera_right * input_direction.x
        + camera_forward * input_direction.y
    )

    direction.y = 0.0

    return direction.normalized()

func updateAnimationBy(direction: Vector3, current_speed: float):
    if direction.length() == 0.0:
        self.playAnimation("idle")
    elif current_speed >= run_speed:
        self.playAnimation("sprint")
    else:
        self.playAnimation("walk")

func playAnimation(animation_name: String):
    if self.anime_player.has_animation(animation_name):
        if self.anime_player.current_animation != animation_name:
            self.anime_player.play(animation_name)

func updateRotationBy(direction: Vector3, delta: float) -> void:
    if direction.length() == 0.0:
        return

    var target_angle := atan2(direction.x, direction.z)

    self.rotation.y = lerp_angle(
        self.rotation.y,
        target_angle,
        self.rotation_speed * delta
    )

func updateCameraBy(delta: float) -> void:
    self.camera_pivot.position.y = 1.5
    self.applyCameraRotation()

func applyCameraRotation() -> void:
    self.camera_pivot.rotation.y = self.camera_yaw - self.rotation.y
    self.spring_arm.rotation.x = self.camera_pitch
