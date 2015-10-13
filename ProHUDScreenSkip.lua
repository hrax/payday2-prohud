--[[
    Screen Skip Configuration
]]--
local ProHUD_SCREEN_SKIP_STAT_SCREEN_DELAY = 0
local ProHUD_SCREEN_SKIP_SCREEN_DELAY = 3
local ProHUD_SCREEN_SKIP_BLACKSCREEN = 0
local ProHUD_SCREEN_SKIP_AUTO_CARD = 1

-- Screen Skip
if RequiredScript == "lib/managers/menu/stageendscreengui" then
	local ProHUDStageEndScreenGui_update = StageEndScreenGui.update
	function StageEndScreenGui:update(t, ...)
		ProHUDStageEndScreenGui_update(self, t, ...)
		if not self._button_not_clickable and ProHUD_SCREEN_SKIP_STAT_SCREEN_DELAY > 0 then
			self._auto_continue_t = self._auto_continue_t or (t + ProHUD_SCREEN_SKIP_STAT_SCREEN_DELAY)
			if t >= self._auto_continue_t then
				managers.menu_component:post_event("menu_enter")
				game_state_machine:current_state()._continue_cb()
			end
		end
	end
elseif RequiredScript == "lib/managers/menu/lootdropscreengui" then
	local ProHUDLootDropScreenGui_update = LootDropScreenGui.update
	function LootDropScreenGui:update(t, ...)
		ProHUDLootDropScreenGui_update(self, t, ...)

		if not self._card_chosen and ProHUD_SCREEN_SKIP_AUTO_CARD then
			self:_set_selected_and_sync(math.random(3))
			self:confirm_pressed()
		end
		
		if not self._button_not_clickable and ProHUD_SCREEN_SKIP_SCREEN_DELAY > 0 then
			self._auto_continue_t = self._auto_continue_t or (t + ProHUD_SCREEN_SKIP_SCREEN_DELAY)
			if t >= self._auto_continue_t then
				self:continue_to_lobby()
			end
		end
	end
elseif RequiredScript == "lib/states/ingamewaitingforplayers" then
	local ProHUDIngameWaitingForPlayersState_update = IngameWaitingForPlayersState.update
	function IngameWaitingForPlayersState:update(t, dt)
		if ProHUD_SCREEN_SKIP_BLACKSCREEN == 0 then
			td = 1
		end
		
		ProHUDIngameWaitingForPlayersState_update(self, t, td)
		if self._skip_promt_shown and ProHUD_SCREEN_SKIP_BLACKSCREEN then
			self:_skip()
		end
	end
elseif RequiredScript == "lib/states/missionendstate" then
	local ProHUDMissionEndState_update = MissionEndState.update
	function MissionEndState.update(self, ...)
		ProHUDMissionEndState_update(self, ...)
		if ProHUD_SCREEN_SKIP_STAT_SCREEN_DELAY == 0 then
			self:set_completion_bonus_done(true)
		end
	end
end
