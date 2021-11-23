local create_sword_action = include("sword.lua")

--local nodes = player:sprite():find_child_nodes_with_tags({})

function package_init(package)
	package:declare_package_id("com.player.Guilmon") 
    package:set_speed(5.0)
    package:set_attack(2)
    package:set_charged_attack(50)
	package:set_special_description("Born hiding new possibilities")
    package:set_icon_texture(Engine.load_texture(_modpath.."GuilmonFace.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_overworld_animation_path(_modpath.."guilmonOW.animation")
    package:set_overworld_texture_path(_modpath.."guilmonOW.png")
    package:set_mugshot_texture_path(_modpath.."mug.png")
    package:set_mugshot_animation_path(_modpath.."mug.animation")
	package:set_emotions_texture_path(_modpath.."emotions.png")
end

function player_init(player)
    player:set_name("Guilmon")
    player:set_health(1000)
    player:set_element(Element.Fire)
    player:set_height(50.0)
    player:set_animation(_modpath.."guilmon.animation")
    player:set_texture(Engine.load_texture(_modpath.."GuilmonBattle.png"), true)
    player:set_fully_charged_color(Color.new(255,0,0,255))
	player.normal_attack_func = create_normal_attack
    player.charged_attack_func = create_charged_attack
    player.special_attack_func = create_special_attack

	player.update_func = function(self, dt) 
        -- nothing in particular
    end
end

function create_normal_attack(player)
    print("buster attack")
    return Battle.Buster.new(player, false, 2)
end

function create_charged_attack(player)
    print("charged attack")
    return Battle.Buster.new(player, false, 50)
end

function create_special_attack(player)
    print("execute special")
    return create_sword_action(player, player:get_attack_level() * 10)
end

--for k,v in ipairs(nodes) do
    --if not v:has_tag("Base Node") then
      --v:hide()
    --end
  --end