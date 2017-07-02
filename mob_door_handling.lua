

-- use this function instead of the local function "walkable" in burlis pathfinder algorithm
-- (burlis pathfinder can be found at https://github.com/MarkuBu/pathfinder)
--
-- curr_height and max_height are used in order to check for thin slabs (<=2/16 tick) as
-- those allow the mob to walk below and on them and still get through
--
mob_world_interaction.walkable = function(node, curr_height, max_height)
	if( not( node ) or not( node.name )) then
		return true;
	-- fast decision for air
	elseif( node.name == "air" ) then
		return false;
	elseif( mob_world_interaction.door_type[ node.name ] and mob_world_interaction.door_type[ node.name ]=="thin_slab" ) then
		--print( "CHECKING node="..tostring(node.name).." param2="..tostring(node.param2).." for curr="..tostring(curr_height).." max="..tostring(max_height));
		-- thin slabs acting as floors are ok
		if( node.param2 and node.param2 < 4 and curr_height<=1 ) then
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
	elseif( not( minetest.registered_nodes[node.name])) then
		return true;
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

	-- some schematics may still work with old door types
	mob_world_interaction.door_type[ 'doors:door_wood_t_1' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_wood_t_2' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_wood_b_1' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_wood_b_2' ] = "door_a_b";

	mob_world_interaction.door_type[ 'doors:door_steel_t_1' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_steel_t_2' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_steel_b_1' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_steel_b_2' ] = "door_a_b";

	mob_world_interaction.door_type[ 'doors:door_glass_t_1' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_glass_t_2' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_glass_b_1' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_glass_b_2' ] = "door_a_b";

	mob_world_interaction.door_type[ 'doors:door_obsidian_glass_t_1' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_obsidian_glass_t_2' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_obsidian_glass_b_1' ] = "door_a_b";
	mob_world_interaction.door_type[ 'doors:door_obsidian_glass_b_2' ] = "door_a_b";

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
		      and v.walkable==true
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


-- find paths from beds to outside; identify one front door
-- pos_inside_list usually ought to be building_data.bed_list; it might also contain
-- positions of benches etc. - as long as those are inside the house, behind the front door
mob_world_interaction.find_nearest_front_door = function( building_data, pos_inside_list )
	-- will contain for each pos: pos, a position next to it where the mob can stand, and
	-- a path from where the mob can stand to the front door (if possible)
	local house_info = {};

	-- position of the front door
	local front_door_at      = nil;
	local front_door_next_to = nil;
	local front_door_count   = 0;

	-- the code only works if positions inside the house (usually beds) are provided
	if( not( building_data )
	  or not( building_data.orients )
	  or not( building_data.orients[1] )
	  or not( pos_inside_list )
	  or type(pos_inside_list )~="table"
	  or #pos_inside_list < 1 ) then
		return;
	end

	-- position in front of the house and definitely outside
	local p_outside = {x=-1, y=(building_data.yoff*-1)+2, z=-1};
	if(     building_data.orients[1] == 0 ) then
		p_outside.x = 0;
		p_outside.z = math.floor(building_data.sizez/2 + 0.5);
	elseif( building_data.orients[1] == 1 ) then
		p_outside.x = math.floor(building_data.sizex/2 + 0.5);
		p_outside.z = 0;
	elseif( building_data.orients[1] == 2 ) then
		p_outside.x = building_data.sizex + 1;
		p_outside.z = math.floor(building_data.sizez/2 + 0.5);
	elseif( building_data.orients[1] == 3 ) then
		p_outside.x = math.floor(building_data.sizex/2 + 0.5);
		p_outside.z = building_data.sizez + 1;
	end

	-- check if the (simulated) nodes outside building_data.scm_data_cache are correct
	local n_out_1 = mob_world_interaction.get_node( p_outside, building_data );
	local n_out_0 = mob_world_interaction.get_node( {x=p_outside.x, y=p_outside.y-1, z=p_outside.z}, building_data );
	if( not( n_out_1 ) or not( n_out_0 ) or n_out_1.name ~= "air" or n_out_0.name ~= "default:dirt_with_grass" ) then
		print("ERROR: Nodes outside data area broken: at "..minetest.pos_to_string( p_outside ).." is "..minetest.serialize( n_out ).." (expected: air); below: "..minetest.serialize(n_below).." (expected: default:dirt_with_grass)");
	end

	local str = "";
	-- find a place next to the position where the mob can stand
	for i, pos in ipairs( pos_inside_list ) do
		-- mobs usually cannot stand inside beds or benches
		local p_stand = mob_world_interaction.find_place_next_to( pos, 0, {x=0,y=0,z=0}, building_data);

		house_info[ i ] = {};
		house_info[ i ].poi = pos; -- point of intrest for a mob :-) (i.e. a bed)
		house_info[ i ].next_to = p_stand; -- can be nil if none found

		str = str.."\n  bed at "..minetest.pos_to_string( pos ); -- TODO
		if(p_stand and p_stand.x ) then
			str = str..", stand at "..minetest.pos_to_string( p_stand );
		else
			str = str.." NO place to stand";

		end

		if( p_stand and p_stand.x ) then
			---- do the pathfinding in building_data.scm_data_cache
			local path = mob_world_interaction.find_path( p_stand, p_outside, {collisionbox = {1,0,3,4,2}},building_data);
			-- sometimes paths fail to be generated and end up beeing of length 1
			-- we are only intrested in successfully generated paths
			if( path and #path and #path>1) then
				str = str..", path length: "..tostring(#path);
				local last_door_found = nil;
				local front_door_index = #path-1;
				for j, path_pos in ipairs( path ) do
					local node = mob_world_interaction.get_node( path_pos, building_data );
					if( node and node.name and node.name ~= "air" and node.name ~= "ignore" ) then
						if( mob_world_interaction.door_type[ node.name ]
						  -- some tents use sleeping mats as doors
						  or (node.name == "cottages:sleeping_mat" and node.param2>3 and node.param2<20)) then
if( node.name=="cottages:sleeping_mat") then print( "sleeping mat as door found."); end
							path_pos.is_door = 1;
							last_door_found = path_pos;
							front_door_index = j;
						-- TODO: handle climbable nodes like ladders
						end
					end
				end


				if( last_door_found and last_door_found.x ) then
					-- first front door found
					if( not( front_door_at )) then
						front_door_at      = path[ front_door_index ];
						front_door_next_to = path[ front_door_index + 1];
						front_door_count   = 1;
					-- another front door - consistent with the other ones
					elseif( front_door_at
					   and (front_door_at.x == path[ front_door_index ].x
					     or front_door_at.y == path[ front_door_index ].y
					     or front_door_at.z == path[ front_door_index ].z
					     or front_door_next_to.x == path[ front_door_index+1 ].x
					     or front_door_next_to.y == path[ front_door_index+1 ].y
					     or front_door_next_to.z == path[ front_door_index+1 ].z )) then
						front_door_count = front_door_count + 1;
					else
						print(" ERROR: DIFFRENT FRONT DOOR FOUND.");
					end
					-- store only the relevant parts up to one step in front of the front door
					house_info[ i ].path = {};
					for j=1,front_door_index+1 do
						table.insert( house_info[ i ].path, path[ j ]);
					end
					str = str..", front door at "..minetest.pos_to_string( last_door_found ).." "..tostring(front_door_index);
				else
					house_info[ i ].path = path;
					str = str..", NO FRONT DOOR found";
				end
			else
				str = str.." NO PATH FOUND. Outside: "..minetest.pos_to_string(p_outside);
			end
		end -- end of if
	end -- end of for

	if( front_door_count ~= #pos_inside_list ) then
		front_door_at = nil;
		front_door_next_to = nil;
		print( str.."\n      <<< NO COMMON FRONT DOOR FOUND >>>");
	else
		print( "  --> success: front door found at "..minetest.pos_to_string(front_door_at).." <--");
	end
	-- TODO: further data that might be of intrest: p_outside, common path from front_door_at to p_outside
	-- TODO: re-use calculated positions of house_info.next_to as they are always the same for each poi
	-- TODO: store front doors and paths in a list, i.e. {bed=p1, next_to=p2, paths={to_door_1, to_door_2, ..}
	-- TODO: generate a list of front doors by adding the new one to the existing list
	return { house_info = house_info, front_door_at = front_door_at, front_door_next_to = front_door_next_to };
end



-- tries to find all front doors by subsequently blocking each found one
-- (works on building_data as provided by handle_schematics)
mob_world_interaction.find_all_front_doors = function( building_data, pos_inside_list )
	-- no data on which we might work
	if( not( building_data )
	  or not( building_data.scm_data_cache )
	  or not( pos_inside_list )
	  or #pos_inside_list < 1) then
		return;
	end

	local all_path_info = {};

	-- now try to find the first and nearest front door
	local path_info = mob_world_interaction.find_nearest_front_door( building_data, pos_inside_list );

	-- add a node that is undefined and just acts as a placeholder to the list of nodenames used by building_data
	-- (it will be removed at the end of this function call)
	table.insert( building_data.nodenames, "default:does_not_exist" );

	-- if we found a front door
	while( path_info and path_info.front_door_at and path_info.front_door_at.x) do

		local d = path_info.front_door_at;
		-- store the node type (relative to nodenames) of the door node
		path_info.door_node = building_data.scm_data_cache[ d.y ][ d.x ][ d.z ][1];
		-- store the path info
		table.insert( all_path_info, path_info );

		-- place a nonexisting block where that door was
		building_data.scm_data_cache[ d.y ][ d.x ][ d.z ][1] = #building_data.nodenames;

		-- check if we can still find a path through a diffrent door
		path_info = mob_world_interaction.find_nearest_front_door( building_data, building_data.bed_list );
	end

	print( "  "..tostring( #all_path_info ).." front doors found. orients: "..tostring( building_data.orients[1] ).." yoff: "..tostring( building_data.yoff).. " ground: "..tostring( (building_data.yoff*-1)+1 ).."\n");

	-- place the doors back
	for i,path_info in ipairs( all_path_info ) do
		if( path_info and path_info.front_door_at ) then
			local d = path_info.front_door_at;
			-- place the original door back
			building_data.scm_data_cache[ d.y ][ d.x ][ d.z ][1] = path_info.door_node;
		end
	end

	-- remove the placeholder entry that was used to block identified doors
	if( building_data.nodenames[ #building_data.nodenames ] == "default:does_not_exist" ) then
		table.remove( building_data.nodenames, #building_data.nodenames );
	end

	return all_path_info;
end
