function package_init(package)
    package:declare_package_id("com.discord.Konstinople#7692.player.Man")
    package:set_special_description("Before he was Mega, he was Man")
    package:set_speed(1.0)
    package:set_attack(1)
    package:set_charged_attack(10)
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_overworld_animation_path(_modpath.."overworld.animation")
    package:set_overworld_texture_path(_modpath.."overworld.png")
    package:set_mugshot_texture_path(_modpath.."mug.png")
    package:set_mugshot_animation_path(_modpath.."mug.animation")
end

function player_init(player)
    player:set_name("Man")
    player:set_health(1000)
    player:set_element(Element.None)
    player:set_height(40.0)

    local base_texture = Engine.load_texture(_modpath.."battle.png")
    local base_animation_path = _modpath.."battle.animation"
    local base_charge_color = Color.new(57, 198, 243, 255)

    player:set_animation(base_animation_path)
    player:set_texture(base_texture, true)
    player:set_fully_charged_color(base_charge_color)
    player:set_charge_position(0, -20)

    player.normal_attack_func = function(player)
        return Battle.Buster.new(player, false, player:get_attack_level())
    end

    player.charged_attack_func = function(player)
        return Battle.Buster.new(player, true, player:get_attack_level() * 10)
    end

    local mega = player:create_form()
    mega:set_mugshot_texture_path(_modpath.."forms/mega_entry.png")

    local original_attack_level, original_charge_level

    mega.on_activate_func = function(self, player)
        original_attack_level = player:get_attack_level()
        original_charge_level = player:get_charge_level()
        player:set_attack_level(5) -- max attack level
        player:set_charge_level(5) -- max charge level
        player:set_animation(_modpath.."forms/mega.animation")
        player:set_texture(Engine.load_texture(_modpath.."forms/mega.png"), true)
        player:set_fully_charged_color(Color.new(243, 57, 198, 255))
    end

    mega.on_deactivate_func = function(self, player)
        player:set_animation(base_animation_path)
        player:set_texture(base_texture, true)
        player:set_fully_charged_color(base_charge_color)
        player:set_attack_level(original_attack_level)
        player:set_charge_level(original_charge_level)
    end
end
