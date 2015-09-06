--[[
	Show level in kick menu
]]--
function KickPlayer:modify_node(node, up)
	--node:clean_items()
	local new_node = deep_clone( node )
	if managers.network:session() then
		for __,peer in pairs( managers.network:session():peers() ) do
			local rank = peer:rank()
			local params = {
							name			= peer:name(),
							text_id			= ProHUD:peerRankName(peer),
							callback		= 'kick_player',
							to_upper		= false,
							localize		= 'false',
							rpc				= peer:rpc(),
							peer			= peer,
							}
			local new_item = node:create_item( nil, params )
			new_node:add_item( new_item )
		end
	end
	managers.menu:add_back_button( new_node )
	return new_node
end