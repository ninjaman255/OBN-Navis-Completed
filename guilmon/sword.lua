local SLASH_TEXTURE = Engine.load_texture(_modpath.."spell_sword_slashes.png")
local BLADE_TEXTURE = Engine.load_texture(_modpath.."spell_sword_blades.png")
local AUDIO = Engine.load_audio(_modpath.."sword.ogg")

local function create_slash(user, animation_state, damage)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_texture(SLASH_TEXTURE)
	spell:set_facing(user:get_facing())

    spell:set_hit_props(
        HitProps.new(
            damage,
            Hit.Impact | Hit.Flinch | Hit.Flash,
            Element.Sword,
            user:get_id(),
            Drag.None
        )
    )

	local anim = spell:get_animation()
	anim:load(_modpath.."spell_sword_slashes.animation")
	anim:set_state(animation_state)
	anim:on_complete(
		function()
			spell:erase()
		end
	)

	spell.update_func = function(self, dt)
        local middle_tile = spell:get_tile()
        middle_tile:highlight(Highlight.Solid)
        middle_tile:attack_entities(self)
    end	

	spell.can_move_to_func = function(tile)
		return true
	end

	Engine.play_audio(AUDIO, AudioPriority.Low)

	return spell
end

local function card_create_action(actor, damage)
	local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())

	action.execute_func = function(self, user)
		self:add_anim_action(3,
			function()
				local hilt = self:add_attachment("HILT")
				local hilt_sprite = hilt:sprite()
				hilt_sprite:set_texture(actor:get_texture())
				hilt_sprite:set_layer(-2)

				local hilt_anim = hilt:get_animation()
				hilt_anim:copy_from(actor:get_animation())
				hilt_anim:set_state("HILT")

				local blade = hilt:add_attachment("ENDPOINT")
				local blade_sprite = blade:sprite()
				blade_sprite:set_texture(BLADE_TEXTURE)
				blade_sprite:set_layer(-1)

				local blade_anim = blade:get_animation()
				blade_anim:load(_modpath.."spell_sword_blades.animation")
				blade_anim:set_state("DEFAULT")
			end
		)

		self:add_anim_action(3,
            function()
                local sword = create_slash(user, "DEFAULT", damage)
                local tile = user:get_tile(user:get_facing(), 1)
                actor:get_field():spawn(sword, tile)
            end
        )
    end


	return action
end

return card_create_action
