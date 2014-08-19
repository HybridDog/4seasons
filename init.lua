-- 4SEASONS

-- Begin tunables

-- Seasons last 61 minutes by default, that's just over 3 days, one
-- hour in game.
local SEASON_LENGTH = 60*61
-- Every WEATHER_CHANGE_INTERVAL, each active block that does not
-- match the current season will have a 1/WEATHER_CHANCE chance to be
-- replaced with one of the current season.
local WEATHER_CHANGE_INTERVAL = 1
local WEATHER_CHANCE = 60
-- If True, birds can spawn and make sound.
local BIRDS = false
-- If True, ice only forms with an air block directly above it.
local CLASSIC_ICE = true
-- If True, winter leaves are walkable instead of climbable.
local CLASSIC_WINTER_LEAVES = false

-- End tunables

local SEASON_FILE = minetest.get_worldpath()..'/4seasons.season'
local SEASON_PAUSE = nil
local CURRENT_SEASON = nil

function PLANTLIKE(nodeid, nodename,type,option)
   if option == nil then option = false end

   local params = { description = nodename, drawtype = 'plantlike', tile_images = {'4seasons_'..nodeid..'.png' },
		    inventory_image = '4seasons_'..nodeid..'.png',	wield_image = '4seasons_'..nodeid..'.png', paramtype = 'light' }
   
   if type == 'veg' then
      params.groups = {snappy=2,dig_immediate=3,flammable=2}
      params.sounds = default.node_sound_leaves_defaults()
      if option == false then params.walkable = false end
   elseif type == 'met' then			-- metallic
      params.groups = {cracky=3}
      params.sounds = default.node_sound_stone_defaults()
   elseif type == 'cri' then			-- craft items
      params.groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,flammable=3}
      params.sounds = default.node_sound_wood_defaults()
      if option == false then params.walkable = false end
   elseif type == 'eat' then			-- edible
      params.groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,flammable=3}
      params.sounds = default.node_sound_wood_defaults()
      params.walkable = false
      params.on_use = minetest.item_eat(option)
   end
   minetest.register_node('4seasons:'..nodeid, params)
end

-- ***********************************************************************************
--		SEASONAL CHANGES					**************************************************
-- ***********************************************************************************

local function set_season(t)
   if t ~= -1 then
      CURRENT_SEASON = t

      SEASON_PAUSE = nil
   end
   -- write to file
   local f = io.open(SEASON_FILE, 'w')
   f:write(CURRENT_SEASON..'\n'..tostring(SEASON_PAUSE))
   io.close(f)
end

local f = io.open(SEASON_FILE, 'r')
if f ~= nil then
   CURRENT_SEASON = f:read('*n')
   f:read('*l')
   SEASON_PAUSE = f:read('*l') == 'true'
   io.close(f)
else
   print('could not find season file, creating one (setting summer).')
   set_season(3)
end

function switch_seasons()
   if SEASON_PAUSE then
      minetest.after(SEASON_LENGTH,switch_seasons)
   elseif CURRENT_SEASON == 1 then 
      set_season(2)		-- set to spring
      print('changing to spring')
      minetest.after(SEASON_LENGTH,switch_seasons)
   elseif  CURRENT_SEASON == 2 then 
      set_season(3)		-- set to summer
      print('changing to summer')
      minetest.after(SEASON_LENGTH,switch_seasons)
   elseif  CURRENT_SEASON == 3 then
      set_season(4) 		-- set to autumn
      print('changing to autumn')
      minetest.after(SEASON_LENGTH,switch_seasons)
   elseif  CURRENT_SEASON == 4 then
      set_season(1) 		-- set to winter
      print('changing to winter')
      minetest.after(SEASON_LENGTH,switch_seasons)

   end
end

minetest.after(SEASON_LENGTH,switch_seasons)

minetest.register_chatcommand('season',{
				 params = '<season>',
				 description = 'set the season',
				 privs = {server=true},	
				 func = function(name, param)
					   if param == 'winter' or param == 'Winter' then set_season(1)
					   elseif param == 'spring' or param == 'Spring' then set_season(2)
					   elseif param == 'summer' or param == 'Summer' then set_season(3)
					   elseif param == 'fall' or param == 'Fall' then set_season(4)
					   elseif param == 'pause' or param == 'Pause' then
					      SEASON_PAUSE = true
					      set_season(-1)
					      minetest.chat_send_player(name, 'Season paused.')
					      return
					   elseif param == 'Unpause' or param == 'Unpause' then
					      SEASON_PAUSE = nil
					      set_season(-1)
					      minetest.chat_send_player(name, 'Season unpaused.')
					      return
					   elseif param == 'stop' or param == 'Stop' then
					      set_season(0)
					      minetest.chat_send_player(name, 'Season stopped.')
					      return
					   else
					      minetest.chat_send_player(name, 'Invalid paramater "'..param..'", try "winter","spring","summer", "fall", "pause", "unpause", or "stop".')
					      return		
					   end
					   minetest.chat_send_player(name, 'Season changed.')
					end})

-- Special
minetest.register_abm({
			 nodenames={'default:water_source', 'default:water_flowing', 'default:cactus', 'default:sand', 'default:desert_sand'},
			 neighbors={'air'},
			 interval=WEATHER_CHANGE_INTERVAL,
			 chance=WEATHER_CHANCE,
			 action=function(pos,node,active_object_count,active_object_count_wider)
				   if CURRENT_SEASON ~= 1 then
				      return
				   elseif node.name=='default:water_source' then
				      if CLASSIC_ICE then
					 local above=minetest.env:get_node_or_nil({x=pos.x,y=pos.y+1,z=pos.z})
					 if above==nil or above.name~='air' then
					    return
					 end
				      end
				      minetest.env:add_node(pos,{type='node',name='4seasons:ice_source'})
				   elseif node.name=='default:water_flowing' then
				      if CLASSIC_ICE then
					 local above=minetest.env:get_node_or_nil({x=pos.x,y=pos.y+1,z=pos.z})
					 if above==nil or above.name~='air' then
					    return
					 end
				      end
				      minetest.env:add_node(pos,{type='node',name='4seasons:ice_flowing'})
				   elseif node.name=='default:cactus' then
				      above = minetest.env:get_node_or_nil({x=pos.x,y=pos.y+1,z=pos.z})
				      if above~=nil and above.name=='air' then
					 minetest.env:add_node(pos,{type='node',name='4seasons:cactus_winter'})
				      end
				   elseif node.name=='default:sand' then
				      above = minetest.env:get_node_or_nil({x=pos.x,y=pos.y+1,z=pos.z})
				      if above~=nil and above.name=='air' then
					 minetest.env:add_node(pos,{type='node',name='4seasons:sand_winter'})
				      end
				   elseif node.name=='default:desert_sand' then
				      above = minetest.env:get_node_or_nil({x=pos.x,y=pos.y+1,z=pos.z})
				      if above~=nil and above.name=='air' then
					 minetest.env:add_node(pos,{type='node',name='4seasons:desertsand_winter'})
				      end
				   end
				end})

-- Summer
minetest.register_abm({
			 nodenames = {'default:dirt_with_grass','default:leaves'},
			 interval = WEATHER_CHANGE_INTERVAL,
			 chance = WEATHER_CHANCE,
			 action = function(pos, node, active_object_count, active_object_count_wider)
				     if CURRENT_SEASON == 3 or CURRENT_SEASON == 0 then
					return
				     elseif CURRENT_SEASON == 1 then
					if node.name == 'default:dirt_with_grass' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:grass_winter'})
					elseif node.name == 'default:leaves' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:leaves_winter'})
					end
				     elseif CURRENT_SEASON == 2 then
					if node.name == 'default:dirt_with_grass' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:grass_spring'})
					elseif node.name == 'default:leaves' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:leaves_spring'})
					end
				     elseif CURRENT_SEASON == 4 then
					if node.name == 'default:leaves' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:leaves_autumn'})
					elseif node.name == 'default:dirt_with_grass' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:grass_autumn'})
					end
				     end
				  end})

-- Fall
minetest.register_abm({
			 nodenames = { '4seasons:grass_autumn','4seasons:leaves_autumn' },
			 interval = WEATHER_CHANGE_INTERVAL,
			 chance = WEATHER_CHANCE,
			 
			 action = function(pos, node, active_object_count, active_object_count_wider)
				     if CURRENT_SEASON == 4 or CURRENT_SEASON == 0 then
					return
				     elseif CURRENT_SEASON == 1 then
					if node.name == '4seasons:grass_autumn' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:grass_winter'})
					elseif node.name == '4seasons:leaves_autumn' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:leaves_winter'})
					end
				     elseif CURRENT_SEASON == 2 then
					if node.name == '4seasons:grass_autumn' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:grass_spring'})
					elseif node.name == '4seasons:leaves_autumn' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:leaves_spring'})
					end
				     elseif CURRENT_SEASON == 3 then
					if node.name == '4seasons:leaves_autumn' then
					   minetest.env:add_node(pos,{type='node',name='default:leaves'})
					elseif node.name == '4seasons:grass_autumn' then
					   minetest.env:add_node(pos,{type='node',name='default:dirt_with_grass'})
					end
				     end
				  end})

-- Winter
minetest.register_abm({
			 nodenames = { '4seasons:grass_winter','4seasons:leaves_winter','4seasons:desertsand_winter', '4seasons:sand_winter','4seasons:cactus_winter','4seasons:ice_source','4seasons:ice_flowing' },
			 interval = WEATHER_CHANGE_INTERVAL,
			 chance = WEATHER_CHANCE,
			 
			 action = function(pos, node, active_object_count, active_object_count_wider)
				     if CURRENT_SEASON == 1 or CURRENT_SEASON == 0 then
					return
				     elseif CURRENT_SEASON == 2 then
					if node.name == '4seasons:grass_winter' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:grass_spring'})
					elseif node.name == '4seasons:leaves_winter' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:leaves_spring'})
					elseif node.name == '4seasons:desertsand_winter' then
					   minetest.env:add_node(pos,{type='node',name='default:desert_sand'})
					elseif node.name == '4seasons:sand_winter' then
					   minetest.env:add_node(pos,{type='node',name='default:sand'})
					elseif node.name == '4seasons:cactus_winter' then
					   minetest.env:add_node(pos,{type='node',name='default:cactus'})
					elseif node.name == '4seasons:ice_source' then
					   minetest.env:add_node(pos,{type='node',name='default:water_source'})
					elseif node.name == '4seasons:ice_flowing' then
					   minetest.env:remove_node(pos)
					   --minetest.env:add_node(pos,{name='default:water_flowing'})
					end
				     elseif CURRENT_SEASON == 3 then
					if node.name == '4seasons:leaves_winter' then
					   minetest.env:add_node(pos,{type='node',name='default:leaves'})
					elseif node.name == '4seasons:grass_winter' then
					   minetest.env:add_node(pos,{type='node',name='default:dirt_with_grass'})
					elseif node.name == '4seasons:desertsand_winter' then
					   minetest.env:add_node(pos,{type='node',name='default:desert_sand'})
					elseif node.name == '4seasons:sand_winter' then
					   minetest.env:add_node(pos,{type='node',name='default:sand'})
					elseif node.name == '4seasons:cactus_winter' then
					   minetest.env:add_node(pos,{type='node',name='default:cactus'})
					elseif node.name == '4seasons:ice_source' then
					   minetest.env:add_node(pos,{type='node',name='default:water_source'})
					elseif node.name == '4seasons:ice_flowing' then
					   minetest.env:remove_node(pos)
					   --minetest.env:add_node(pos,{type='node',name='default:water_flowing'})
					end
				     elseif CURRENT_SEASON == 4 then
					if node.name == '4seasons:leaves_winter' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:leaves_autumn'})
					elseif node.name == '4seasons:grass_winter' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:grass_autumn'})
					elseif node.name == '4seasons:desertsand_winter' then
					   minetest.env:add_node(pos,{type='node',name='default:desert_sand'})
					elseif node.name == '4seasons:sand_winter' then
					   minetest.env:add_node(pos,{type='node',name='default:sand'})
					elseif node.name == '4seasons:cactus_winter' then
					   minetest.env:add_node(pos,{type='node',name='default:cactus'})
					elseif node.name == '4seasons:ice_source' then
					   minetest.env:add_node(pos,{type='node',name='default:water_source'})
					elseif node.name == '4seasons:ice_flowing' then
					   minetest.env:remove_node(pos)
					   --minetest.env:add_node(pos,{type='node',name='default:water_flowing'})
					end
				     end
				  end
		      })

-- Spring
minetest.register_abm({
			 nodenames = { '4seasons:grass_spring','4seasons:leaves_spring' },
			 interval = WEATHER_CHANGE_INTERVAL,
			 chance = WEATHER_CHANCE,
			 
			 action = function(pos, node, active_object_count, active_object_count_wider)
				     if CURRENT_SEASON == 2 or CURRENT_SEASON == 0 then
					return
				     elseif CURRENT_SEASON == 1 then
					if node.name == '4seasons:grass_spring' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:grass_winter'})
					elseif node.name == '4seasons:leaves_spring' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:leaves_winter'})
					end
				     elseif CURRENT_SEASON == 3 then
					if node.name == '4seasons:leaves_spring' then
					   minetest.env:add_node(pos,{type='node',name='default:leaves'})
					elseif node.name == '4seasons:grass_spring' then
					   minetest.env:add_node(pos,{type='node',name='default:dirt_with_grass'})
					end
				     elseif CURRENT_SEASON == 4 then
					if node.name == '4seasons:leaves_spring' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:leaves_autumn'})
					elseif node.name == '4seasons:grass_spring' then
					   minetest.env:add_node(pos,{type='node',name='4seasons:grass_autumn'})
					end
				     end
				  end})


-- ***********************************************************************************
--		BIRDS SPRING/SUMMER				**************************************************
-- ***********************************************************************************
if BIRDS == true then
   local bird = {}
   bird.sounds = {}
   bird_sound = function(p)
		   local wanted_sound = {name='bird', gain=0.6}
		   bird.sounds[minetest.hash_node_position(p)] = {
		      handle = minetest.sound_play(wanted_sound, {pos=p, loop=true}),
		      name = wanted_sound.name, }
		end

   bird_stop = function(p)
		  local sound = bird.sounds[minetest.hash_node_position(p)]
		  if sound ~= nil then
		     minetest.sound_stop(sound.handle)
		     bird.sounds[minetest.hash_node_position(p)] = nil
		  end
	       end
   minetest.register_on_dignode(function(p, node)
				   if node.name == '4seasons:bird' then
				      bird_stop(p)

				   end
				end)
   minetest.register_abm({
			    nodenames = { '4seasons:leaves_spring','default:leaves' },
			    interval = NATURE_GROW_INTERVAL,
			    chance = 200,
			    action = function(pos, node, active_object_count, active_object_count_wider)
					local air = { x=pos.x, y=pos.y+1,z=pos.z }
					local is_air = minetest.env:get_node_or_nil(air)
					if is_air ~= nil and is_air.name == 'air' then
					   minetest.env:add_node(air,{type='node',name='4seasons:bird'})
					   bird_sound(air)
					end
				     end
			 })
   minetest.register_abm({
			    nodenames = {'4seasons:bird' },
			    interval = NATURE_GROW_INTERVAL,
			    chance = 2,
			    action = function(pos, node, active_object_count, active_object_count_wider)
					minetest.env:remove_node(pos)
					bird_stop(pos)
				     end
			 })
end

-- ***********************************************************************************
--		SLIMTREES							**************************************************
-- ***********************************************************************************
minetest.register_abm({
			 nodenames = { '4seasons:slimtree' },
			 interval = 120,
			 chance = 1,
			 
			 action = function(pos, node, active_object_count, active_object_count_wider)
				     minetest.env:add_node({x=pos.x,y=pos.y,z=pos.z},{type='node',name='4seasons:slimtree_wood'})
				     minetest.env:add_node({x=pos.x,y=pos.y+1,z=pos.z},{type='node',name='4seasons:slimtree_wood'})
				     minetest.env:add_node({x=pos.x,y=pos.y+2,z=pos.z},{type='node',name='4seasons:slimtree_wood'})

				     minetest.env:add_node({x=pos.x,y=pos.y+3,z=pos.z},{type='node',name='4seasons:slimtree_wood'})			
				     minetest.env:add_node({x=pos.x+1,y=pos.y+3,z=pos.z},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x-1,y=pos.y+3,z=pos.z},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x,y=pos.y+3,z=pos.z+1},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x,y=pos.y+3,z=pos.z-1},{type='node',name='default:leaves'})			


				     minetest.env:add_node({x=pos.x,y=pos.y+4,z=pos.z},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x+1,y=pos.y+4,z=pos.z},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x-1,y=pos.y+4,z=pos.z},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x,y=pos.y+4,z=pos.z+1},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x,y=pos.y+4,z=pos.z-1},{type='node',name='default:leaves'})			


				     minetest.env:add_node({x=pos.x,y=pos.y+5,z=pos.z},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x+1,y=pos.y+5,z=pos.z},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x-1,y=pos.y+5,z=pos.z},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x,y=pos.y+5,z=pos.z+1},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x,y=pos.y+5,z=pos.z-1},{type='node',name='default:leaves'})			

				     minetest.env:add_node({x=pos.x,y=pos.y+6,z=pos.z},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x+1,y=pos.y+6,z=pos.z},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x-1,y=pos.y+6,z=pos.z},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x,y=pos.y+6,z=pos.z+1},{type='node',name='default:leaves'})			
				     minetest.env:add_node({x=pos.x,y=pos.y+6,z=pos.z-1},{type='node',name='default:leaves'})			
				  end
		      })
-- ***********************************************************************************
--		PALM TREES							**************************************************
-- ***********************************************************************************
minetest.register_abm({
			 nodenames = { '4seasons:palmtree' },
			 interval = 120,
			 chance = 1,
			 
			 action = function(pos, node, active_object_count, active_object_count_wider)
				     minetest.env:add_node({x=pos.x,y=pos.y,z=pos.z},{type='node',name='4seasons:slimtree_wood'})
				     minetest.env:add_node({x=pos.x,y=pos.y+1,z=pos.z},{type='node',name='4seasons:slimtree_wood'})
				     minetest.env:add_node({x=pos.x,y=pos.y+2,z=pos.z},{type='node',name='4seasons:slimtree_wood'})
				     minetest.env:add_node({x=pos.x,y=pos.y+3,z=pos.z},{type='node',name='4seasons:slimtree_wood'})
				     minetest.env:add_node({x=pos.x,y=pos.y+4,z=pos.z},{type='node',name='4seasons:slimtree_wood'})
				     minetest.env:add_node({x=pos.x,y=pos.y+5,z=pos.z},{type='node',name='4seasons:slimtree_wood'})
				     minetest.env:add_node({x=pos.x,y=pos.y+6,z=pos.z},{type='node',name='4seasons:slimtree_wood'})
				     minetest.env:add_node({x=pos.x,y=pos.y+7,z=pos.z},{type='node',name='4seasons:slimtree_wood'})
				     minetest.env:add_node({x=pos.x,y=pos.y+8,z=pos.z},{type='node',name='4seasons:slimtree_wood'})
				     minetest.env:add_node({x=pos.x+2,y=pos.y+8,z=pos.z},{type='node',name='4seasons:palmleaves'})
				     minetest.env:add_node({x=pos.x-2,y=pos.y+8,z=pos.z},{type='node',name='4seasons:palmleaves'})
				     minetest.env:add_node({x=pos.x,y=pos.y+8,z=pos.z+2},{type='node',name='4seasons:palmleaves'})
				     minetest.env:add_node({x=pos.x,y=pos.y+8,z=pos.z-2},{type='node',name='4seasons:palmleaves'})
				     minetest.env:add_node({x=pos.x,y=pos.y+9,z=pos.z},{type='node',name='4seasons:palmleaves'})
				     minetest.env:add_node({x=pos.x+1,y=pos.y+9,z=pos.z},{type='node',name='4seasons:palmleaves'})
				     minetest.env:add_node({x=pos.x-1,y=pos.y+9,z=pos.z},{type='node',name='4seasons:palmleaves'})
				     minetest.env:add_node({x=pos.x,y=pos.y+9,z=pos.z+1},{type='node',name='4seasons:palmleaves'})
				     minetest.env:add_node({x=pos.x,y=pos.y+9,z=pos.z-1},{type='node',name='4seasons:palmleaves'})
				  end
		      })

-- ***********************************************************************************
--		NODES									**************************************************
-- ***********************************************************************************

PLANTLIKE('palmtree','Palmtree Sapling','veg')
PLANTLIKE('slimtree','Slimtree Sapling','veg')
PLANTLIKE('bird','Bird','veg')
minetest.register_node('4seasons:palmleaves', {
			  description = 'Rail',
			  drawtype = 'raillike',
			  tile_images = {'4seasons_palmleaves.png', '4seasons_palmleaves_top.png', '4seasons_palmleaves_top.png', '4seasons_palmleaves_top.png'},
			  inventory_image = '4seasons_palmleaves.png',
			  wield_image = '4seasons_palmleaves.png',
			  paramtype = 'light',
			  is_ground_content = true,
			  walkable = false,
			  selection_box = {
			     type = 'fixed',
			     --fixed = <default>
			  },
			  groups = {bendy=2,snappy=1,dig_immediate=2},
		       })
minetest.register_node('4seasons:slimtree_wood', {
			  description = 'Slimtree',
			  drawtype = 'fencelike',
			  tile_images = {'default_tree.png'},
			  --	inventory_image = 'default_tree.png',
			  --	wield_image = 'default_tree.png',
			  paramtype = 'light',
			  is_ground_content = true,
			  selection_box = {
			     type = 'fixed',
			     fixed = {-1/7, -1/2, -1/7, 1/7, 1/2, 1/7},
			  },
			  groups = {tree=1,snappy=2,choppy=2,oddly_breakable_by_hand=2,flammable=2},
			  sounds = default.node_sound_wood_defaults(),
			  drop = 'default:fence_wood',
		       })
minetest.register_node('4seasons:ice_source', {
			  description = 'Ice',
			  tile_images = {'4seasons_ice.png'},
			  is_ground_content = true,
			  groups = {snappy=2,choppy=3},
			  sounds = default.node_sound_stone_defaults(),
		       })
minetest.register_node('4seasons:ice_flowing', {
			  description = 'Ice',
			  tile_images = {'4seasons_ice.png'},
			  is_ground_content = true,
			  groups = {snappy=2,choppy=3},
			  sounds = default.node_sound_stone_defaults(),
		       })
minetest.register_node('4seasons:leaves_autumn', {
			  description = 'Leaves',
			  drawtype = 'allfaces_optional',
			  visual_scale = 1.3,
			  tile_images = {'4seasons_leaves_autumn.png'},
			  paramtype = 'light',
			  groups = {snappy=3, leafdecay=3, flammable=2},
			  drop = {
			     max_items = 1, items = {
				{items = {'default:sapling'},	rarity = 20,},
				{items = {'4seasons:leaves_autumn'},}
			  }},
			  sounds = default.node_sound_leaves_defaults(),
		       })
minetest.register_node('4seasons:leaves_spring', {
			  description = 'Leaves',
			  drawtype = 'allfaces_optional',
			  visual_scale = 1.3,
			  tile_images = {'4seasons_leaves_spring.png'},
			  paramtype = 'light',
			  groups = {snappy=3, leafdecay=3, flammable=2},
			  drop = {
			     max_items = 1, items = {
				{items = {'default:sapling'},	rarity = 20,},
				{items = {'4seasons:leaves_spring'},}
			  }},
			  sounds = default.node_sound_leaves_defaults(),
		       })
minetest.register_node('4seasons:grass_spring', {
			  description = 'Dirt with snow',
			  tile_images = {'4seasons_grass_spring.png', 'default_dirt.png', 'default_dirt.png^4seasons_grass_spring_side.png'},
			  is_ground_content = true,
			  groups = {crumbly=3},
			  drop = 'default:dirt',
			  sounds = default.node_sound_dirt_defaults({
								       footstep = {name='default_grass_footstep', gain=0.4},
								    }),
		       })
minetest.register_node('4seasons:grass_autumn', {
			  description = 'Dirt with snow',
			  tile_images = {'4seasons_grass_autumn.png', 'default_dirt.png', 'default_dirt.png^4seasons_grass_autumn_side.png'},
			  is_ground_content = true,
			  groups = {crumbly=3},
			  drop = 'default:dirt',
			  sounds = default.node_sound_dirt_defaults({
								       footstep = {name='default_grass_footstep', gain=0.4},
								    }),
		       })
minetest.register_node('4seasons:grass_winter', {
			  description = 'Dirt with snow',
			  tile_images = {'4seasons_snow.png', 'default_dirt.png', 'default_dirt.png^4seasons_grass_w_snow_side.png'},
			  is_ground_content = true,
			  groups = {crumbly=3},
			  drop = 'default:dirt',
			  sounds = default.node_sound_dirt_defaults({
								       footstep = {name='default_grass_footstep', gain=0.4},
								    }),
		       })

local function winter_leaf_type(type)
   if type=="climbable" then
      return not CLASSIC_WINTER_LEAVES
   elseif type=="walkable" then
      return CLASSIC_WINTER_LEAVES
   else
      print('4seasons: winter_leaf_type called with argument '..tostring(type))
      error()
   end
end

minetest.register_node('4seasons:leaves_winter', {
			  description = 'Leaves',
			  drawtype = 'allfaces_optional',
			  --drawtype= 'plantlike',
			  --visual_scale = 1.3,
			  --visual_scale = 1.2,
			  climbable=winter_leaf_type("climbable"),
			  walkable=winter_leaf_type("walkable"),
			  tile_images = {'4seasons_leaves_winter.png'},
			  paramtype = 'light',
			  groups = {snappy=3, leafdecay=3, flammable=2},
			  drop = {
			     max_items = 1, items = {
				{items = {'default:sapling'},	rarity = 20,},
				{items = {'4seasons:leaves_winter'},}
			  }},
			  sounds = default.node_sound_leaves_defaults(),
		       })
minetest.register_node('4seasons:cactus_winter', {
			  description = 'Cactus',
			  tile_images = {'4seasons_cactus_wsnow_top.png', '4seasons_cactus_wsnow_top.png', '4seasons_cactus_wsnow_side.png'},
			  is_ground_content = true,
			  groups = {snappy=2,choppy=3,flammable=2},
			  sounds = default.node_sound_wood_defaults(),})

minetest.register_node('4seasons:sand_winter', {
			  description = 'Sand with snow',
			  tile_images = {'4seasons_snow.png', 'default_sand.png', 'default_sand.png^4seasons_sand_w_snow_side.png'},
			  is_ground_content = true,
			  groups = {crumbly=3},
			  drop = 'default:sand',
			  sounds = default.node_sound_dirt_defaults({
								       footstep = {name='default_grass_footstep', gain=0.4},
								    }),})

minetest.register_node('4seasons:desertsand_winter', {
			  description = 'Desert Sand with snow',
			  tile_images = {'4seasons_snow.png', 'default_desert_sand.png', 'default_desert_sand.png^4seasons_desertsand_w_snow_side.png'},
			  is_ground_content = true,
			  groups = {crumbly=3},
			  drop = 'default:desert_sand',
			  sounds = default.node_sound_dirt_defaults({
								       footstep = {name='default_grass_footstep', gain=0.4},
								    }),})

minetest.register_craft({
			   output = 'node \'4seasons:slimtree\' 1',	recipe = {
			      {'','default:leaves',''},
			      {'','default:leaves',''},
			      {'','default:stick',''},}})
minetest.register_craft({
			   output = 'node \'4seasons:palmtree\' 1',	recipe = {
			      {'default:leaves','default:stick','default:leaves'},
			      {'','default:stick',''},
			      {'','default:stick',''},}})
