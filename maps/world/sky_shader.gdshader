shader_type sky;
render_mode use_debanding;

uniform vec4 sky_top_color : source_color = vec4(0.385, 0.454, 0.55, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.646, 0.656, 0.67, 1.0);

uniform float sun_size_override : hint_range(0.0, 2.0) = 1.0;
uniform vec4 sun_colour_override: source_color = vec4(1, 1, 1, 1.0);

uniform float inv_sky_curve : hint_range(1, 100) = 4.0;
uniform vec4 ground_bottom_color : source_color = vec4(0.2, 0.169, 0.133, 1.0);
uniform vec4 ground_horizon_color : source_color = vec4(0.646, 0.656, 0.67, 1.0);
uniform float inv_ground_curve : hint_range(1, 100) = 30.0;
uniform float sun_angle_max = 0.877;
uniform float moon_angle_max = 0.9965;
uniform float moon_light_energy_scale = 6.5;
uniform float inv_sun_curve : hint_range(1, 100) = 22.78;
uniform float inv_moon_curve : hint_range(1, 100) = 22.78;
uniform float exposure : hint_range(0, 128) = 1.0;

// Reference: https://www.youtube.com/watch?v=XKz0S2GU068
uniform sampler2D cloud_1_texture;
uniform sampler2D cloud_2_texture;
uniform vec2 cloud_1_direction = vec2(-1.0, 1.0);
uniform vec2 cloud_2_direction = vec2(1.0, -1.0);
uniform float cloud_1_speed = 0.5;
uniform float cloud_2_speed = 0.5;
uniform vec2 cloud_scale = vec2(0.05, 0.05);
uniform float cloud_distance = 0.035;

uniform float cloud_height_scale = 0.4;
uniform vec4 cloud_colour_modifier : source_color;

void sky()
{
    float v_angle = clamp(EYEDIR.y, -1.0, 1.0);
    vec3 sky = mix(sky_top_color.rgb, sky_horizon_color.rgb, clamp(pow(1.0 - v_angle, inv_sky_curve), 0.0, 1.0));

    // Sun.
    if (LIGHT0_ENABLED)
    {
        float sun_angle = dot(LIGHT0_DIRECTION, EYEDIR);
        //float sun_size = cos(LIGHT0_SIZE) ;
        float sun_size = 1.0 + sun_size_override / 100.0 ;
        if (sun_angle > sun_size)
        {
            //sky = LIGHT0_COLOR * LIGHT0_ENERGY;
            sky = sun_colour_override.xyz * LIGHT0_ENERGY;
        } 
        else if (sun_angle > sun_angle_max)
        {
            //float c2 = (sun_size - sun_angle) / (sun_size - sun_angle_max);
            ////sky = mix(sky, LIGHT0_COLOR * LIGHT0_ENERGY, clamp(pow(1.0 - c2, inv_sun_curve), 0.0, 1.0));
            //sky = mix(sky, sun_colour_override.xyz * LIGHT0_ENERGY, clamp(pow(1.0 - c2, inv_sun_curve), 0.0, 1.0));
            // Reference: ChatGPT.
            float c2 = (sun_size - sun_angle) / (sun_size - sun_angle_max);
            float intensity = clamp(pow(1.0 - c2, inv_sun_curve), 0.0, 1.0);
            sky += sun_colour_override.rgb * LIGHT0_ENERGY * intensity; // additive
        }
    }
    
    // Moon.
    if (LIGHT1_ENABLED)
    {
        float moon_angle = dot(LIGHT1_DIRECTION, EYEDIR);
        float moon_size = cos(LIGHT1_SIZE);
        vec3 moon_light = LIGHT1_COLOR * LIGHT1_ENERGY * moon_light_energy_scale;
        if (moon_angle > moon_size)
        {
            sky = moon_light;
        }
        else if (moon_angle > moon_angle_max)
        {
            float c2 = (moon_size - moon_angle) / (moon_size - moon_angle_max);
            sky = mix(sky, moon_light, clamp(pow(1.0 - c2, inv_moon_curve), 0.0, 1.0));
        }
    }

    vec3 ground = mix(ground_bottom_color.rgb, ground_horizon_color.rgb, clamp(pow(1.0 + v_angle, inv_ground_curve), 0.0, 1.0));

    // Reference: https://www.youtube.com/watch?v=XKz0S2GU068
    // Cloud, impl-ed as grayscale mask (explaination from ChatGPT).
    vec2 sky_uv = EYEDIR.xz / EYEDIR.y / cloud_height_scale;
    vec3 clouds = texture(cloud_1_texture, (sky_uv * cloud_scale) + (TIME * cloud_1_direction * cloud_1_speed * 0.01)).rgb 
                - texture(cloud_2_texture, (sky_uv * cloud_scale) + (TIME * cloud_2_direction * cloud_2_speed * 0.01)).rgb;
    clouds = clouds - smoothstep(0.0, EYEDIR.y, cloud_distance);
    clouds = clamp(clouds, 0, 1);
    
    // Reference: ChatGPT.
    // Add colour modifier to the cloud.
    sky = mix(sky, cloud_colour_modifier.rgb, clouds);

    COLOR = mix(ground, sky, step(0.0, EYEDIR.y)) * exposure;
}
