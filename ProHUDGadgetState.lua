-- Gadget State
if string.lower(RequiredScript) == "lib/units/weapons/newraycastweaponbase" then
	local ProHUDNewRaycastWeaponBase_on_equip = NewRaycastWeaponBase.on_equip
	function NewRaycastWeaponBase:on_equip()
		ProHUDNewRaycastWeaponBase_on_equip(self)
		self:set_gadget_on(self._stored_gadget_on or 0, false)
	end

	local ProHUDNewRaycastWeaponBase_toggle_gadget = NewRaycastWeaponBase.toggle_gadget
	function NewRaycastWeaponBase:toggle_gadget()
		if ProHUDNewRaycastWeaponBase_toggle_gadget(self) then
			self._stored_gadget_on = self._gadget_on
			return true
		end
	end
end