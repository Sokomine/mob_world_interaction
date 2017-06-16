

-- use this function instead of the local function "walkable" in burlis pathfinder algorithm
-- (burlis pathfinder can be found at https://github.com/MarkuBu/pathfinder)
--
-- curr_height and max_height are used in order to check for thin slabs (<=2/16 tick) as
-- those allow the mob to walk below and on them and still get through
--
mob_world_interaction.walkable = function(node, curr_height, max_height)
	if( not( node ) or not( node.name ) or not( minetest.registered_nodes[node.name])) then
		return true;
	elseif( mob_world_interaction.door_type[ node.name ]=="thin_slab" ) then
		--print( "CHECKING node="..tostring(node.name).." param2="..tostring(node.param2).." for curr="..tostring(curr_height).." max="..tostring(max_height));
		-- thin slabs acting as floors are ok
		if( node.param2 and node.param2 < 4 and curr_height==1 ) then
			return false;
		-- thin slabs acting as ceiling at the head position are ok as well
		elseif( node.param2 and node.param2 > 19 and max_height>1 and curr_height==max_height) then
			return false;
		-- all else is really far too complicated
		else
			return true;
		end
	elseif( mob_world_interaction.door_type[ node.name ]) then
		return false;
	else
		return minetest.registered_nodes[node.name].walkable;
	end
end


-- open doors and gates
-- 	pos	position that is to be checked for door-status
-- 	entity	the npc (required: entity.pos)
-- 	target	the position the mob wants to reach; distance to entity.pos is calculated to some degree
mob_world_interaction.open_door = function( entity, pos, target )
	-- open the closed door in front of the npc (the door is the next target on the path)
	local node = minetest.get_node( pos );
	if( not( node ) or not( node.name )) then
		return;
	end
	local door_type = mob_world_interaction.door_type[ node.name ];

	-- doors from minetest_game and from the cottages mod
	if(     door_type == "door_a_b" and entity and entity.pos and target) then
		-- we cannot rely on the open/closed state as stored in "state" of the door as that depends on how
		-- the door was placed; instead, check if the door is "open" in the direction in which the mob
		-- wants to move
		local move_in_z_direction = math.abs( entity.pos.z - target.z ) > math.abs( entity.pos.x - target.x );
		if( (    move_in_z_direction  and node.param2 % 2 == 0)
		  or(not(move_in_z_direction) and node.param2 % 2 == 1)) then
			-- open the door by emulating a right-click
			minetest.registered_nodes[node.name].on_rightclick(pos,node,nil)
			-- TODO: store a list of all opened doors?
			entity._door_pos = pos;
		end

	-- open a closed gate or trapdoor; gates have a diffrent node type for open and closed
	elseif( door_type == "gate_closed" or door_type == "trapdoor_closed") then
		minetest.registered_nodes[node.name].on_rightclick(pos,node,nil)
		-- TODO: really store the gate position seperate from the door pos?
		entity._gate_pos = pos;
	end
end


-- a single right-click ought to be enough (it is no problem if that opens the door again)
mob_world_interaction.close_door = function( entity, pos )
	if( not( pos )) then
		return;
	end
	local node = minetest.get_node( pos );
	if( not( node ) or not( node.name ) or not( minetest.registered_nodes[node.name])) then
		return;
	end
	local door_type = mob_world_interaction.door_type[ node.name ];

	-- toggle doors, close gates
	if( door_type == "door_a_b" or door_type == "gate_open" or door_type == "trapdoor_open") then
		minetest.registered_nodes[node.name].on_rightclick(pos,node,nil);
	end
end


-- mob_world_interaction.door_type[ node_name ]  stores for a given door node the type of door:
--   door_a_b        typical door from minetest_game; the question of weather it
--                   is open or closed depends on from where to where the mob
--                   wants to go
--   gate_closed     a closed gate
--   gate_open       opened gate
--   trapdoor_open   opened trapdoor
--   trapdoor_closed closed trapdoor
--   ignore          can be walked through but requires no action
--                   (used for doors:hidden, the upper part of a door)

-- this function needs to be called just once during init
mob_world_interaction.initialize_door_types = function()
	-- the table where we store the data
	mob_world_interaction.door_type = {};

	for k,v in pairs( minetest.registered_nodes ) do
		if( string.sub( k, 1, 6)=="doors:" ) then
			local str = string.sub( k, -2, -1 );
			-- a door from minetest_game
			if(     string.sub( k, -2, -1) == "_a"
			     or string.sub( k, -2, -1) == "_b" ) then
				mob_world_interaction.door_type[ k ] = "door_a_b";
	
			-- a (closed) gate from minetest_game
			elseif( string.sub( k, -7, -1) == "_closed") then
				mob_world_interaction.door_type[ k ] = "gate_closed";
	
			-- opened gate from minetest_game
			elseif( string.sub( k, -5, -1) == "_open") then
				-- are we dealing with a trapdoor?
				if( v.drop and type(v.drop)=="string" and string.sub( v.drop, -7, -1 ) ~= "_closed" ) then
					mob_world_interaction.door_type[ k      ] = "trapdoor_open";
					-- it will drop a closed trapdoor
					mob_world_interaction.door_type[ v.drop ] = "trapdoor_closed";
				-- or with a regular gate?
				else	
					mob_world_interaction.door_type[ k ] = "gate_open";
				end
	
			-- the upper part of a door
			elseif( k == "doors:hidden" ) then
				mob_world_interaction.door_type[ k ] = "ignore";
			end
		

		-- half door and half door inverted from the cottages mod
		elseif( k == "cottages:half_door" ) then
			mob_world_interaction.door_type[ k ] = "door_a_b";
		elseif( k == "cottages:half_door_inverted" ) then
			mob_world_interaction.door_type[ k ] = "door_a_b";
	
		-- gates from the gottages mod
		elseif( k == "cottages:gate_closed") then
			mob_world_interaction.door_type[ k ] = "gate_closed";
		elseif( k == "cottages:gate_open") then
			mob_world_interaction.door_type[ k ] = "gate_open";
	
		-- gates from the gates_long mod
		elseif( string.sub( k, 1, 29 ) == "gates_long:fence_gate_closed_") then
			mob_world_interaction.door_type[ k ] = "gate_closed";
		elseif( string.sub( k, 1, 21 ) == "gates_long:gate_open_") then
			mob_world_interaction.door_type[ k ] = "gate_open";
	
		elseif( v and v.drawtype and v.drawtype == 'nodebox' and v.node_box
		      and v.node_box.type and v.node_box.type=='fixed'
		      and v.node_box.fixed ) then

			local nb = v.node_box.fixed;

			-- might be a slab (or something which has a sufficiently similar surface compared to a slab)
			if(    ( #nb == 1
			         and math.max( nb[1][2], nb[1][5]) <= -0.5+2/16+0.01 
				 and math.abs( nb[1][4] - nb[1][1] ) >= 0.9
				 and math.abs( nb[1][6] - nb[1][3] ) >= 0.9 )
		
			    or ( type( nb[1] )~='table'
				and #nb == 6
				and math.max( nb[2], nb[5] )<= -0.5+2/16 +0.001
				and math.abs( nb[4]-nb[1] ) >= 0.9 
				and math.abs( nb[6]-nb[3] ) >= 0.9 ))  then

				-- it depends a lot on param2 weather such a thin slab is an obstacle or not; even if
				-- two such slabs are present on ceiling and floor the player can still get through
				-- it all depends on param2
				mob_world_interaction.door_type[ k ] = "thin_slab";
			end
		end

		-- just for debugging
--		if( mob_world_interaction.door_type[k] ) then print( "permits_passage: "..tostring(k)); end
	end
end
