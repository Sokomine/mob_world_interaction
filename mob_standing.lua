

-- there are some nodes the mob cannot really stand in - but where a "real" human would be
-- able to get through (i.e. several benches, climbing in a bed etc.)
mob_world_interaction.can_get_through = {};

-- the mob can use beds even if standing on them would not work
mob_world_interaction.can_get_through[ 'beds:bed_top'] = 1;
mob_world_interaction.can_get_through[ 'beds:bed_bottom'] = 1;
mob_world_interaction.can_get_through[ 'beds:bed_fancy_top'] = 1;
mob_world_interaction.can_get_through[ 'beds:bed_fancy_boottom'] = 1;
mob_world_interaction.can_get_through[ 'cottages:bed_head'] = 1;
mob_world_interaction.can_get_through[ 'cottages:bed_foot'] = 1;
-- benches and tables may sometimes be tricky - still the mob ought to be able to use them
mob_world_interaction.can_get_through[ 'cottages:bench'] = 1;
mob_world_interaction.can_get_through[ 'cottages:table'] = 1;

-- helper function; determines weather a mob can stand in a given node or not
mob_world_interaction.can_stand_in_node_type = function( node )
	if( not( node ) or not( node.name ) or not( minetest.registered_nodes[ node.name ])) then
		return false;
	end
end


-- most ceilings will be too low for the mob to successfully jump/walk onto a bed or bench;
-- benches frequently cannot be reached directly either
-- this function finds a position next to the bed/bench/.. where the mob can stand.
-- does a recursive search and may fail to find a position; in that case it will return {iteration == 99}
-- iteration has to be 0 and vector = {x=0,y=0,z=0} at the beginning
mob_world_interaction.find_place_next_to = function( pos, iteration, vector)

	local n1 = minetest.get_node( pos );
	-- node where the head of the mob is
	local n2 = minetest.get_node( {x=pos.x, y=pos.y+1, z=pos.z});
	-- can the mob stand at this position? then we are finished
	if(   n1 and not( mob_world_interaction.walkable( n1, 0, 1 ))
	  and n2 and not( mob_world_interaction.walkable( n2, 1, 1 ))) then
		return {x=pos.x, y=pos.y, z =pos.z, iteration=iteration};
	end

	-- do not search endlessly; allow only 6 iterations
	if( iteration > 6 or not( n1 ) or not( n1.name ) or not(  mob_world_interaction.can_get_through[ n1.name ])) then
		return {iteration=99}; -- we failed to find a suitable position
	end

	-- the mob can be at this place; try to find a position from where it can reach this place
	local p_curr_opt = {iteration=99}; -- current optimum
	local p = {};

	-- avoid going backwards and checking places that are already checked or cannot be reached
	if( vector.x ~= -1 ) then
		p = mob_world_interaction.find_place_next_to( {x=pos.x+1, y=pos.y, z=pos.z  }, iteration+1, {x= 1,y=0,z= 0});
		if( p.iteration < p_curr_opt.iteration ) then
			p_curr_opt = p;
		end
	end
	if( vector.x ~=  1 ) then
		p = mob_world_interaction.find_place_next_to( {x=pos.x-1, y=pos.y, z=pos.z  }, iteration+1, {x=-1,y=0,z= 0});
		if( p.iteration < p_curr_opt.iteration ) then
			p_curr_opt = p;
		end
	end
	if( vector.z ~= -1 ) then
		p = mob_world_interaction.find_place_next_to( {x=pos.x,   y=pos.y, z=pos.z+1}, iteration+1, {x= 0,y=0,z= 1});
		if( p.iteration < p_curr_opt.iteration ) then
			p_curr_opt = p;
		end
	end
	if( vector.z ~=  1 ) then
		p = mob_world_interaction.find_place_next_to( {x=pos.x,   y=pos.y, z=pos.z-1}, iteration+1, {x= 0,y=0,z=-1});
		if( p.iteration < p_curr_opt.iteration ) then
			p_curr_opt = p;
		end
	end
	return p_curr_opt;
end
