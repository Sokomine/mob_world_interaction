

mob_world_interaction.set_animation = function( entity, anim )
	if( not( entity ) or not( entity.object)) then
		return;
	end
	local a = 0;   -- startframe of animation
	local b = 79;  -- endframe of animation
	local speed = 30; 
	if( anim=='stand' ) then
		a = 0;
		b = 79;
	elseif( anim=='sit' ) then
		a = 81;
		b = 148;
	elseif( anim=='sleep' ) then
		a = 164;
		b = 164;
	end
	entity.object:set_animation({x=a, y=b}, speed)
end
