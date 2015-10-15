-- https://steamcommunity.com/app/218620/discussions/15/617336568076214362/#c617336568076277182
if RequiredScript == "lib/units/beings/player/huskplayermovement" then

	local _get_max_move_speed_original = HuskPlayerMovement._get_max_move_speed

	HuskPlayerMovement.SPEED_FACTOR = 3
	
	function HuskPlayerMovement:_get_max_move_speed(...)
		return _get_max_move_speed_original(self, ...) * HuskPlayerMovement.SPEED_FACTOR
	end
	
elseif RequiredScript == "lib/units/enemies/cop/actions/lower_body/copactionwalk" then

	local _get_current_max_walk_speed_original = CopActionWalk._get_current_max_walk_speed

	CopActionWalk.FAST_SPEED_FACTOR = 3
	CopActionWalk.NORMAL_SPEED_FACTOR = 1
	CopActionWalk.SPEED_FACTOR = CopActionWalk.NORMAL_SPEED_FACTOR	--Don't screw with this
	
	function CopActionWalk:_get_current_max_walk_speed(...)
		return _get_current_max_walk_speed_original(self, ...) * (Network:is_server() and 1 or CopActionWalk.SPEED_FACTOR)
	end

elseif RequiredScript == "lib/units/beings/player/states/playerstandard" then

	inventory_clbk_listener_original = PlayerStandard.inventory_clbk_listener

	function PlayerStandard:inventory_clbk_listener(...)
		inventory_clbk_listener_original(self, ...)
		
		if alive(self._equipped_unit) and self._equipped_unit:base():weapon_tweak_data().category == "grenade_launcher" then
			CopActionWalk.SPEED_FACTOR = CopActionWalk.FAST_SPEED_FACTOR
		else
			CopActionWalk.SPEED_FACTOR = CopActionWalk.NORMAL_SPEED_FACTOR
		end
	end

end