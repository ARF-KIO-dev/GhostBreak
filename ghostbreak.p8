pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
 -- ghostbreaker! (main 🅾️❎)
-- alex fletcher 2024

game_state = "menu"
level_state = 0
level_selected = 1

round_end_timer = 30

function _init()
 cls()
	load_level_from_data()
	
end

function _update()

	if game_state == "game" then
	 
	 -- ------------------
	 --   level state
	 -- ------------------
	 
	 
	 if #ghosts == 0 then
	  level_state = 1
	 end
	 
	 if p_dead then
	 
	 	-- no lives! 
	 	
	 	if p_lives <= 0 then
	 
		  level_state = 2
		  if round_end_timer > 0 then
		   round_end_timer -= 1
		 	elseif btnp(❎) then
		 		load_game_from_menu()
		 	end
		 	
		 else
		 
		 	p_dead_timer -= 1
		 	if p_dead_timer <= 0 then
		 	
		 		p_dead = false
		 		p_inv_timer = 150
		 		px = 64
		 		py = 128
		 	
		 	end
		 
		 end
	 end
	 
	 -- --------------------
	 --      main loop
	 -- --------------------
	 
	 if level_state != 1 then
	 		
	 	update_particles()
		 update_player()
		 update_items()
		 update_ghosts()
		 update_saws()
		 update_projectiles()
	 	
 	else
 	
 	 round_end_timer -= 1
 	 if round_end_timer <= 0 then
 	  level_selected += 1
 	  load_game_from_menu()
 	  
 	 end
 	end
 	
 elseif game_state == "menu" then
  update_menu()
 end
 
end

function _draw()
	
	-- border.
 cls()
 rect(0,5,127,127,1)
 
 if game_state == "game"
 or game_state == "menu" then
	 
	 draw_bricks()
	 draw_ghosts()
	 draw_saws()
 
 end
 
 if game_state == "game" then
 	
 	-- main game objects
 	
 	draw_particles()
 	draw_items()
 	draw_projectiles()
	 draw_game_ui()
	 draw_player()	 
	 
	 -- win or lose screen.
	 
	 if level_state != 0 then
	 	
	 	rectfill(0,48,127,72,1)
	 	
	 	-- win or lose test.
	 	local _text = level_state == 2 and "game over!" or "level complete!"
	  print_centre(_text,64,56,7,0)
	 
	 	-- prompt to next / restart
	 	
	 	if round_end_timer <= 0 then
	 	 print_centre("press ❎ to restart",64,80,7,0)
	 	end
	 
	 end
 	
 end
 
 if game_state == "menu" then
  draw_menu()
 end
 
 -- debug 
 print(stat(1),2,8,7)

end

-- ============================

-- 		game state handlers!

-- ============================

function update_menu()

	if btnp(❎) or btnp(🅾️) then
	 load_game_from_menu()
	end

	if (btnp(➡️)) change_level(true)
	if (btnp(⬅️)) change_level(false)

end

function load_game_from_menu()
	
	level_state = 0
	round_end_timer = 60
	
	p_dead = false
	if (p_lives <= 0) p_lives = 3
	game_state = "game"
	
	clear_level()
	load_level_from_data()
	
end

function draw_menu()
	
	print_centre("menu screen!", 64,48,7,2)
	print_centre("press x to start",64,64,7,1)
	
end

-- ============================

--    level loading parser

-- ============================

-- pick a level!
function change_level(go_next)
 level_selected += (go_next and 1 or -1)
 if (level_selected < 0) level_selected = 16
 if (level_selected > 16) level_selected = 1
 load_level_from_data()
end

-- reset a level to the start.
function clear_level()
	ammo = 1
 init_bricks()
 projectiles = {}
 items = {}
 ghosts = {}
 saws = {}
 particles = {}
 score = 0
 px,py = 60,128
end


function load_level_from_data()

	id = level_selected

 clear_level()
	local i_offset,j_offset = (id-1)*16,0
	
	for i = 1,15 do
	for j = 1,15 do
			load_tile(i,j,mget(i-1 + i_offset,j-1 + j_offset))
	end
	end

end


levels = {"128*1."}

-- post-fix run-length encoded
-- "*" encodes amount
-- "." encodes type

--[[
function load_level_from_data(id)
	
	-- setup empty map.
	
	init_bricks()

	local _data = levels[id]
	local _type,_amount,_char = "", ""
	local i,j = 1,1
	
	local state = "run"
	
	-- ===========================
	
	-- parse data
	
	-- ===========================
	
	for k = 1,#_data do 
	
		_char = sub(_data,k,k)
		
		-- --------
		--  states
		-- --------
		
		print(_char)
		
		-- get the run length.
		if _char == "*" then
		
			_amount = _type
			_type = ""
		
		-- --------------------------
		--     parse the tile!
		-- --------------------------
	
		elseif _char == "." then
		
			_amount = _amount == "" and 1 or tonum(_amount)
			_type = tonum(_type)
			
			
			-- load in values!
			for x = 1,_amount do 
			
				load_tile(i,j,_type)
				
				i += 1
				if (i > bricks_w) i = 1 j += 1
			
			end
		
			_amount = ""
			_type = ""
		
		-- get next id place value.
		else
		
			_type ..= _char
		
		end

	end
end
--]]



-->8
-- math and collision ∧♪

function lerp(a,b,t)
	if (abs(a-b) < 0.005) return 0
 return a+(b-a)*t
end

function as_sign(a,v)
 return a >= 0 and v or -v
end

-- warning! no overflow guard!
function dist(x,y,x2,y2)
 return v_len(vector(x2-x,y2-y))
end

-- ============================

-- 								 vectors

-- ============================

function vector(x,y) return {x=x,y=y} end
function vector_ang(ang,len) return {x = cos(ang) * len, y = sin(ang) * len} end
function v_ang(v) return atan2(v.x,v.y) end
function v_add(v,v2) return vector(v.x + v2.x,v.y + v2.y) end
function v_len(v) return sqrt((v.x * v.x) + (v.y * v.y)) end
function v_scale(v,a) return vector(v.x * a, v.y * a) end
function v_unit(v) return vector_ang(v_ang(v),1) end

function v_lerp_zero(v,lpf)
	return vector(lerp(v.x,0,lpf),lerp(v.y,0,lpf))
end

function v_max(v,len)
	return (v_len(v) < len) and v or (vector_ang(v_ang(v),len))
end

function v_min(v,len)
 return (v_len(v) > len) and v or (vector_ang(v_ang(v),len))
end
-- ============================

-- 								collision

-- ============================

function new_box(x,y,w,h)
 return {x=x,y=y,xr=x+w-1,yr=y+h-1,w=w,h=h}
end

function new_box_from(obj)
 return new_box(obj.x,obj.y,obj.size,obj.size)
end

function move_box(b,x,y)
 return new_box(x,y,b.w,b.h)
end

-- debug : remove later!
function draw_box(b)
 rect(b.x,b.y,b.xr-1,b.yr-1,8)
end

-- get the 4 corner points
-- of an 8x8 tile.
-- insets squish the square in.

function corners_8x8(x,y,scale)

	-- corners.
	
	local _half = scale / 2
	
	local _r = {
		vector(x,y),
		vector(x + scale,y),
		vector(x + scale,y + scale),
		vector(x,y + scale)
	}
	
	-- handler for oversized objs.
	-- midpoints of rect.
	
	if scale >= 8 then
		add(_r,vector(x + _half,y))
		add(_r,vector(x + scale,y + _half))
		add(_r,vector(x,y + _half))
		add(_r,vector(x + _half,y + scale))
	end
	
	return _r

end

-- col : point in a rectangle

function p_in_rect(x,y,box)

	return not (x < box.x or x > box.xr)
	and 			not (y < box.y or y > box.yr)

end

-- col : rectangles overlapping.

function r_in_rect(box,box2)
 return not(box.x > box2.xr 
	       or box.xr < box2.x)
	and    not (box.y > box2.yr
	       or box.yr < box2.y)						
end
-->8
-- player + io! 웃♥

px,py = 60,120
p_box = new_box(px,py,0,0)
pspd,pspd_max = 0,2

p_lives = 3
p_dead = false
p_inv_timer = 0
p_dead_timer = 0

p_2frame = false
p_2frame_timer = 3
p_face_left = false
p_looking_up = false
p_looking_down = false
p_spr = 1

p_grav = 0
p_jumping = false
p_grounded = false
p_passthrough = false
p_double_jump = true
p_jump_dy = 2.75
p_jump_dy_max = 2.75

btno,btnx,btnx_held,btno_held = false,false,false,false

-- reuseable death trigger.

function p_die()

	if (p_dead) return

	p_dead = true
	p_dead_timer = 90
				
	for _ = 1,8 do
		new_particle(px,py,{8,2,14})
	end
				
	sfx(8)
	p_lives -= 1

end

-- --------------------
-- player main loop
-- --------------------

function update_player()
	
	btnx = btn(❎)
	btno = btn(🅾️)
	btnd = btn(⬇️)
	
	-- --------------------------
	--  have we been ghosted..?
	-- --------------------------
	-- could move into ghost 
	-- to save tokens...
	
	if not p_dead and p_inv_timer <= 0 then
		
		for s in all(saws) do 
		 if r_in_rect(p_box,s.box) then
		  p_die()
				break
		 end
		end
		
		for g in all(ghosts) do 
		
		 if r_in_rect(p_box,g.box) then
				p_die()
				break
			end
		end
	end
	
	if (p_inv_timer > 0) p_inv_timer -= 1

	-- being dead means no input!
	local _is_moving = false
	if not p_dead then
	
	-- pickup items
	for item in all(items) do
		if r_in_rect(p_box,item.box) then
		 pickup_item(item)
		end
	end
	
	
	-- ---------------------------
	--           inputs
	-- ---------------------------

	-- moving left / right
	
	if btn(⬅️) then
		pspd -= (pspd > 0) and 2 or .75
		_is_moving = true
		p_face_left = true
	elseif btn(➡️) then
		pspd += (pspd < 0) and 2 or .75
		_is_moving = true
		p_face_left = false
	end
	
	-- ---------------------------
	--           jumping 
	-- ---------------------------
	-- on the ground or can dbjump
	
	if btno and not btno_held
	and (p_grounded or p_double_jump)
 then
		
		p_jumping = true
		p_double_jump = p_grounded
		sfx(0)
		p_jump_dy = p_jump_dy_max
		py -= 1
		p_grav = 0
	end
	
	-- looking up?
	
	p_looking_up = btn(⬆️)
	p_looking_down = btn(⬇️)
	p_spr = p_looking_up and 3 or 1
	p_spr = p_looking_down and 6 or p_spr

	-- use our weapon!
	
	if btnx then
	 use_weapon()
	else
	 update_weapon()
	end

	------------------------------
	end -- pdead check over.
	------------------------------
	-- ===========================

	-- grav and movement
	
	-- ===========================

	-- moving checks. (anim mostly)
	
	if _is_moving then
	
		p_2frame_timer -= 1
		if p_2frame_timer <= 0 then
			p_2frame = not p_2frame
		 p_2frame_timer = 3
		 if (p_grounded and p_2frame) sfx(1)
		end
	
	else
	 pspd = lerp(pspd,0,p_dead and 0.05 or 0.33)
	 if (abs(pspd) < 0.5) p_2frame = false

	end
	
	-- grav + jumping.
	
	if py < 119 then
		
		-- reduce jump gain.
		if p_jumping then
			
			py -= 	p_jump_dy
			
			p_jump_dy -= 0.25
			p_jumping = p_jump_dy > 0
			
		else
			py += p_grav
			p_grav += 0.25
			if (p_grav > 4) p_grav = 4
		end
		p_grounded = false
	
	end
	
	-- snap to floor
	
	if py >= 119 then
		
		if (p_grav > 0) sfx(2)
	 py = 119
	 p_grav = 0
	 p_grounded = true
	 p_double_jump = true
	 
	end
	
	-- --------------
	-- apply movement
	-- --------------
		
	if (pspd > pspd_max) pspd = pspd_max
	if (pspd < -pspd_max) pspd = -pspd_max
	
	-- ===========================
	
	--  collide on walls x side
	
	-- ===========================
	
	local _points = corners_8x8(px+1,py,6)
	local _did_x_coll = false
	
	for p in all(_points) do
	
		if col_brick(p.x + pspd,p.y) then
			_did_x_coll = true
		end
		
	end
		
	if not _did_x_coll then
		px += pspd
	end
	
	-- out of bounds left right.
	
	if (px > 120) px = 120
	if (px < 0) px = 0
	
	-- --------------------------
	--    bricks below me ?
	-- --------------------------
	
	-- ugly pass-through platforms
	local _lplat = get_brick(px+2,py+8,true)
	local _rplat = get_brick(px+5,py+8,true)

	local _lexist = _lplat != 0
	local _rexist = _rplat != 0
	local _any_solid = (_lexist and _lplat.solid) or (_rexist and _rplat.solid)
	
	if _lexist or _rexist then

	 -- try and fall trhough
	 -- platforms.
	 
	 	if _any_solid
			or not p_passthrough and
	 	((_lexist and _lplat.y >= py+7-p_grav)
			or (_rexist and _rplat.y >= py+7-p_grav)) then
				
				-- ignore platforms if we
				-- are still jumping.
				
	 		if _any_solid or
	 		not p_jumping then
	 		
			  py = j_to_y(y_to_j(py+2))
			  if (p_grav > 0.75) sfx(2)
					p_grav = 0
				 p_grounded = true
				 p_double_jump = true
				 
				end
			end
			
		-- passtrhough platforms when
		-- holding down
		
		if p_grounded and not _any_solid and btnd then
			p_passthrough = true
			py += 1
			p_grav = 1
		end	
		
	else
	 p_passthrough = false
	end
	
	-- --------------------------
	-- bricks above me ?
	-----------------------------

	if p_jumping 
	and (col_brick(px+1,py-1)
	or  col_brick(px+6,py-1)) then
	 p_jump_dy = 0
	 p_grav = 1
	 p_jumping = false
	 py = j_to_y(y_to_j(py + 4))
	 sfx(5)
	end

	-- update collision box
	p_box = new_box(px+3,py,3,8)
	
	-- check any io holds
	btnx_held = btnx
	btno_held = btno

end

function draw_player()

	-- animation local vars.
	local _anim = (p_2frame and 1 or 0)
	local _p_spr = p_spr + _anim
	
	local _g_spr = p_looking_up and 17 or 16
	local _dx = p_face_left and -8 or 8
	local _dy = 0
	local _bdx,_bdy = p_face_left and -11 or 11 ,2
	
	-- anim changes
	if not p_grounded then
	 _p_spr = 5
	end
	
	-- change gun pos on looks
	if p_looking_up then
		_dx /= 2
		_dy = -5
		_bdx = p_face_left and -6 or 6
		_bdy = -8
	end
	
	-- dead...
	if (p_dead) _p_spr = 14 _dy = 0 p_has_bolt = false
	
	-- ================
	
	-- equipped weapons
	
	-- ================
	
	spr(_g_spr + (ammo > 0 and 0 or 2),px + _dx,py + _dy,1,1,p_face_left)

	-- --------------
	-- the crossbolt
	-- --------------
	if current_weapon == "crossbow"
	and ammo > 0 then
		
		if p_looking_up then
		 spr(20,px + (p_face_left and -6 or 6),py-7,1,1,p_face_left)
		else
	 	spr(21,px + (p_face_left and -11 or 11),py+2,1,1,p_face_left)
		end
	end

	-- the goober himself
	pal(11,0)
	
	if p_inv_timer % 2 == 0 then
	 spr(_p_spr,px,py,1,1,p_face_left)
	end
	
	pal()
	
	--draw_box(p_box)

end 
-->8
-- bricks! █░

all_bricks = {}
bricks = {}

bricks_w = 15 -- consts for map
bricks_h = 16  -- i and j size.

bricks_x = 4  -- origins of
bricks_y = 7  -- brick map

bricks_dx = 8 -- size of tile.
bricks_dy = 8

function new_brick(i,j,id)

	local _b = {
	
		i = i,
		j = j,
		x = i_to_x(i),
		y = j_to_y(j),
		
		solid = id != 79,
		hp = 1,
		img = id,
		indestructible = id == 79 or id == 64
		
	}
	
	bricks[i][j] = _b
	

end

-- init an empty bricks map.

function load_tile(i,j,v)
	
	local _x,_y = i_to_x(i),j_to_y(j)
	
	if v > 63 then
		new_brick(i,j,v)
	end
	
	-- saw blades
	if (v == 42) new_hazard_saw(_x,_y)
	
	-- ghosts
	for k = 1,3 do
		 if (v == 31 + k) new_ghost(_x,_y,1,k) 
	end	


end

function init_bricks()

	bricks = {}
	for i = 1,bricks_w do
		add(bricks,{})
	 for j = 1,bricks_h do
	 	add(bricks[i],0) 
	 end
	end
	
end

function t_is_solid(t)
	return true
end

function draw_bricks()

	local _t

	for i = 1,bricks_w do
		for j = 1,bricks_h do
	 	_t = bricks[i][j]
			if _t != 0 then
			 spr(_t.img,_t.x,_t.y)
			end
	 end
	end

end

-- ============================

-- tile map helpers 
-- collision, indexing etc

-- ============================

-- convert x,y to tile coords
-- and vice versa.

function x_to_i(x)
 return 1 + flr((x - bricks_x) / bricks_dx)
end

function y_to_j(y)
 return 1 + flr((y - bricks_y) / bricks_dy)
end

function i_to_x(i)
 return bricks_x + ((i-1) * bricks_dx)
end

function j_to_y(j)
 return bricks_y + ((j-1) * bricks_dy) 
end

-- check if i,j is valid in map.
function in_bounds(i,j)
 return i > 0 and i <= bricks_w
 			and j > 0 and j <= bricks_h
end

-- safely get a tile obj.
function get_brick_ij(i,j)
	if (not in_bounds(i,j)) return 0
	return bricks[i][j]
end

function get_brick(x,y)
 return get_brick_ij(x_to_i(x),y_to_j(y))
end

function col_brick(x,y,nonsolid)
	
	if (nonsolid == nil) nonsolid = false
	local _brk = get_brick(x,y)
	return _brk != 0 and (_brk.solid or nonsolid)

end

function or_many(v,list)
 for i in all(list) do if (i == v) return true end
	return false
end

function in_range(v,l,u)
 return v >= l and v <= u
end

function destroy_brick(i,j)
	
	local _t = get_brick_ij(i,j)
		
	if (_t == 0 or _t.indestructible) return
	
	local _x = i_to_x(i)
	local _y = j_to_y(j)
	
	if _t != 0 then
		bricks[i][j] = 0
		del(all_bricks,_t)
 end
 
 sfx(5)

end
-->8
-- ghosts / sawblades 🐱❎

ghosts = {}
ghost_scales = {4,8,16}
ghost_hps = {1,2,4}
ghost_scores = {10,50,100}
ghost_spds = {2,1,0.5}

function new_ghost(x,y,class,size,v) 

 -- randomize v if not passed
 
 if (v == nil) v = vector_ang(rnd({0.33,0.66,.125,5-0.125}),ghost_spds[size])

 local _g = {
 	
 	is_left = true,
 	x = x, y = y,
 	velocity = v,
 	grav = 0,
 	
 	rank = size, -- balls 1,2,3.
 	img = 32 + size - 1,
 	size = ghost_scales[size],
 	halfscale = ghost_scales[size] / 2,
 	
 	energy = 1, -- bounces.
 	spd = ghost_spds[size],
 	max_spd = ghost_spds[size],
 	
 	-- sawblade or ghost?
 	damage_flash = false,
 	class = class,
 	hp = ghost_hps[size],
 	holds_item = nil
 	
 }
 
 _g.box = new_box_from(_g)
 
 add(ghosts, _g)
 return _g

end

-- ---------------------------
--    destroy the ghosts!!!
-- ---------------------------

function ghost_destroy(g)
		
	score += ghost_scores[g.rank]
			  	
	if g.rank > 1 then
		local _a = 0.125
		
		-- drop items
		new_item(g.x,g.y,2)
		
		-- split into 3.
		
		for i = 1,3 do	
			new_ghost(
				g.x,
				g.y,1,g.rank-1,
				vector_ang(_a,ghost_spds[g.rank - 1]))
			_a += 0.125
		end
	end
	
	del(ghosts,g)
			  	
end

-- ----------------------------
--   deflect off of tiles.
-- ----------------------------

function ghost_deflect(g,nx,ny,i,j)

	local _brk = bricks[i][j]

	local _dx,_dy = abs(g.velocity.x),abs(g.velocity.y)

	local _x = i_to_x(i)
	local _y = j_to_y(j)

	-- ball above?
	if (ny + g.size <= _y) then
		g.velocity.y = as_sign(-1,_dy)
	end
	
	-- ball below?
	if (ny >= _y + 7) then
	 g.velocity.y = as_sign(1,_dy)

	end
	
	-- ball left?
	if (nx + g.size <= _x) then
	 g.velocity.x = as_sign(-1,_dx)
	end

	-- ball right?
	if (nx >= _x + 7) then
	 g.velocity.x = as_sign(1,_dx)
	end
	

end


function update_ghosts()

	local _vx,_vy,_x,_y,_v,_pcx,_pcy,_i,_j,_cx,_cy
	local _did_coll, _points,_cols = false
		
	for g in all(ghosts) do

	 -- --------------------
	 -- next frame movement.
	 -- --------------------
	 
	 -- min + max speed.
	 _v = g.velocity
	 if (_v.x < 0.5 and _v.x > 0) _v.x = 0.5
	 if (_v.x > -0.5 and _v.x < 0) _v.x = -0.5
	 if (_v.y < 0.5 and _v.y > 0) _v.y = 0.5
	 if (_v.y > -0.5 and _v.y < 0) _v.y = -0.5
	 if (_v.x == 0) _v.x = 0.5
	 _v = v_max(_v,g.max_spd)
	 _v = v_min(_v,g.spd)
	 

	 g.velocity = _v
	 
	 -- x,y pos and velocity.
		_vx,_vy = _v.x,_v.y
		_x,_y = g.x + _vx,g.y + _vy
		_pcx,_pcy = _x + _vx,_y + _vy
		_did_coll = false
		
		-- --------------------------
		--   collide w map bounds!
		-----------------------------
		
		-- up.
		if _pcy <= 5 then
			_y = 5
		 _v.y = -_vy
		 _did_coll = true

		-- down.
		elseif _pcy >= 127-g.size then
			_y = 127-g.size
		 _v.y = -_vy
		 _did_coll = true

		-- right 
		elseif _pcx >= 127-g.size then
		 _x = 127-g.size
		 _v.x = -_vx
		 _did_coll = true

		-- left
		elseif _pcx <= 0 then
		 _x = 1
		 _v.x = -_vx
		 _did_coll = true

		end
		
		-- =========================
		--          bricks!
		-- =========================
		
		-- raycast towards move point
		
		local _abx,_aby = abs(_vx), abs(_vy)
		
		if _abx > _aby then
			_rx = as_sign(_vx,1)
			_ry = _vy / _abx
		else
		 _ry = as_sign(_vy,1)
			_rx = _vx / _aby
		end

		-- ------------------------
		-- raycast and collide 
		-- ------------------------	
	
		local _cols = {}
	 local	_points = corners_8x8(g.x,g.y,g.size)
			
		for _ = 1,g.spd+1 do 
		
			-- check for collisions
			-- along my point box.
			
	
			
			-- bricks
			
			for k = 1, #(_points) do
			
				p = _points[k]
				
				if col_brick(p.x,p.y) then
					add(_cols, {i=x_to_i(p.x),j=y_to_j(p.y)})
				else
				 _points[k].x += _rx
					_points[k].y += _ry
				end
				
			end
			
			-- next ray step.
			
			if (#_cols > 0) then
				_x = _points[1].x - _rx - _rx
				_y = _points[1].y - _ry - _ry
			 break
			end
			
		end
		
		-- -------------------------
		-- sort out the closest coll
		-- -------------------------
		
		local _bst_col,_bst_dst,_dst
		
		for col in all(_cols) do
			
			_dst = dist(
			 g.x + g.halfscale,
			 g.y + g.halfscale,
			 i_to_x(col.i) + 4,
			 j_to_y(col.j) + 4)
			
			if _bst_col == nil
			or _dst < _bst_dst then
				_bst_col = col
				_bst_dst = _dst
			end
		end
			
		-- did we collide?
		
		if _bst_col != nil then
			_did_coll = true
			ghost_deflect(g,_x,_y,_bst_col.i,_bst_col.j)
		end
		
		-- ------------------------
		-- move post any collisions
		-- ------------------------
		

		-- next position
		
		g.velocity = _v
		
		g.x = _x --_x
		g.y = _y --_y
		
		g.box = new_box_from(g)
		
	end
end

-- ============================

-- draw the spooky ghosts..

-- ============================

function draw_ghosts()
	
	local _scale,_img


	for g in all(ghosts) do

		if g.damage_flash then
		 if (g.rank == 2) g.img = 49
		 if (g.rank == 3) g.img = 36
		 for i = 1,15 do pal(i,8) end
		end

		_scale = g.rank == 3 and 2 or 1
		_img = g.img
		
	 spr(_img,g.x,g.y,_scale,_scale)	
	 if (g.damage_flash) pal()
	 g.damage_flash = false
	 
		--draw_box(g.box)
		--line(g.x+4,g.y+4,g.x+4+(_rx*8),g.y+4+(_ry*8),8)
		
	end
end

-->8
-- weapons, projectiles ●

projectiles = {}
current_weapon = "crossbow"

prj_limit = 1
ammo = 1
ammo_max = 1
shot_delay = 0
shot_delay_max = 5

-- ===========================
--          weapons!
-- ===========================

function use_weapon()

	-- guard out : no ammo or too many prj
	if ammo <= 0 
	or #projectiles >= prj_limit then
	 update_weapon() 
	 return
	end
	
	-- shoot!	
	if shot_delay <= 0 then
		shot_delay = shot_delay_max
		new_projectile(0)
		ammo -= 1
		sfx(3)
	else
		shot_delay -= 1
	end

end

function update_weapon()
	
 shot_delay = shot_delay < 0 and 0 or shot_delay - 1

end

-- ---------------------------
--   configure weapon stats
-- ---------------------------

function set_weapon(id)

end

-- ============================

--        projectiles! 

-- ============================

function new_projectile(id)

	local _proj = {
		
		id = id,
		x = px, y = py,
		flag_destroy = false,
		size = 6,
		img = p_looking_up and 20 or 21,
		flipped = p_face_left and not p_looking_up,
	}
	
	_proj.box = new_box(px,py,1,1)
	
	-- velocity based on player
	-- facing and direction.
	
	local _spd = 5
	local _dx,_dy = 0,0

	if p_looking_up then
	 _dy = -_spd
	 _proj.x += p_face_left and -2 or 4
	 _proj.y -= 4
	else
	 _proj.x += p_face_left and -4 or 8
	 _dx = p_face_left and -_spd or _spd
	end
	
	-- add!
	_proj.v = vector(_dx,_dy)
	add(projectiles,_proj)
	return _proj
end

-- ----------------------------
--          update!
-- ----------------------------

function update_projectiles()

	local _points,_i,_j,_brk
	
	for b in all(projectiles) do
		
		local _pre_box = new_box_from(b)
		
		b.x += b.v.x
		b.y += b.v.y
		
		b.box = new_box_from(b)
		
		-- --------------
		-- out of bounds?
		-- --------------
		local _oob_x = b.x < 2 or b.x > 120
		
		if _oob_x or
					b.y < 2 or b.y > 120 then
					b.flag_destroy = true
		end
		
		-- ------------------
		-- collide with tiles
		-- ------------------
		
		_points = corners_8x8(b.x,b.y,7)
		
		for p in all(_points) do
		 
		 _i = x_to_i(p.x)
			_j = y_to_j(p.y)
			_brk = get_brick_ij(_i,_j)
			
			if _brk != 0 and _brk.solid then
				destroy_brick(_i,_j)
	
			 b.flag_destroy = true
			 break
			end
		end
		
		-- -------------------
		-- collide with ghosts
		-- -------------------	
		
		for g in all(ghosts) do
			if r_in_rect(b.box,g.box)
			or r_in_rect(_pre_box,g.box) then
				
				-- damage ghost!
				
				sfx(4)
				
				for _ = 1,8 do
				 new_particle(g.x,g.y,{1,13})
				end
				
				g.hp -= 1
				g.damage_flash = true
				g.spd += 1

				-- destroy the ghost?
				
				if g.hp <= 0 then
				 ghost_destroy(g)
				end
				
				-- destroy the projectile.
				-- and push the ghost!
				
				local _dx,_dy = g.velocity.x,g.velocity.y
				
				if b.v.x > 0 then
				 if (_dx < 0) g.velocity.x = -_dx
				elseif b.v.x < 0 then
				 if (_dx > 0) g.velocity.x = -_dx
				elseif b.v.y < 0 then
				 if (_dy > 0) g.velocity.y = -_dy
				else
				 if (_dy < 0) g.velocity.y = -_dy
				end
				
				g.velocity = v_add(g.velocity,b.v)
			 
				b.flag_destroy = true
				break 
				
			end
		end
		
		if b.flag_destroy then
			
			local _vx = b.v.x
			
			if b.id == 0 then
			
				-- spawn a bolt to pickup.
				
			 local _i = new_item(b.x,b.y,1)
				_i.anim_frames = 0
				if _oob_x and _vx != 0 then
				 	_i.stuck_in_wall = true
				 _i.x = b.x > 64 and 123 or -3
				end
				
				
				if _vx == 0 then
				 _i.img = 20 
				 _i.dy = -.25
				else
					_i.box.h = 3
				 _i.flipped = _vx < 0
				end
			
				_i.dx = -_vx / 2
				
			end
			
		 del(projectiles,b)
		end
			
	end
end


-- ---------------------------
--     draw projectiles
-- ---------------------------

function draw_projectiles()
	for b in all(projectiles) do
		
	 spr(b.img,b.x,b.y,1,1,b.flipped)
	 
	end 
end

-->8
-- pickups! + score ➡️

items = {}

item_imgs = {
 21,56
}

-- ------------------------
-- pickups / crossbow bolt.
-- ------------------------

function new_item(x,y,id)
	local _item = {
	
	 id = id,
	 img = item_imgs[id],
	 anim_frames = 1,
	 anim_frame = 0,
		anim_timer = 5,
	
		-- pos + anim
		
		x=x,y=y,
		dx=0,dy=0,
		flipped = false,
	
		-- bolt conds.
		
		stuck_in_wall = false,
		stuck_timer = 300,	
		land_on_ground = true,
		box = new_box(x,y,7,7),

	}
	

	add(items, _item)
	return _item
end

function pickup_item(item)
 
 if item.id == 1 then
 	ammo = 1
 	sfx(7)
 else
  score += 10
  sfx(6)
 end

 
 del(items,item)
end

function update_items()
	for i in all(items) do
	 
	 -- -----------------
	 
	 -- animate if able
	 
	 -- -----------------
	 
	 if i.anim_frame <= i.anim_frames
	 and i.anim_frames != 0 do
	 	
	 	i.anim_timer -= 1
	 	if i.anim_timer < 0 then
	 		
	 		i.anim_frame += 1
	 		if (i.anim_frame > i.anim_frames) i.anim_frame = 0
	 		i.anim_timer = 5
	 	end
	 end
	 
	 local _floor_y = 127-i.box.h
	 
	 -- items fall slowly.
	 
	 if i.id != 1 then
		 i.y += 1
		 if (i.y > _floor_y and i.land_on_ground) i.y = _floor_y
		
		-- =================
		
		-- except for arrows
		
		-- =================
		
		else
		
			if i.stuck_in_wall then
			
				i.stuck_timer -= 1
				i.stuck_in_wall = i.stuck_timer > 0
			
			else
			
				-- bounce off walls etc
				
				i.x += i.dx
				i.dx = lerp(i.dx,0,0.1)
			
				-- fall to ground.
				
				if get_brick(i.x,i.y+i.box.h+i.dy-1) == 0
				and get_brick(i.x+i.box.w,i.y+i.box.h+i.dy-1) == 0
				and i.y < _floor_y then
				 i.y += i.dy
					i.dy += 0.25
				else
				 i.dy = 0.25
				end
			
				if (i.y > _floor_y) i.y = _floor_y
			
			
			end
		end
		
		i.box = move_box(i.box,i.x,i.y)
		
	end
end

function draw_items()
 for i in all(items) do
  spr(i.img + i.anim_frame,i.x,i.y,1,1,i.flipped)
 end
end


-- fx! + score ░⧗

score = 0
score_flicker = false

-- score + print

function print_shadow(t,x,y,c,s)
	if (c == nil) c,s = 7,1
	print(t,x,y+1,s)
	print(t,x,y,c)
end

function print_centre(t,x,y,c,s)
	
	-- nil s defaults as 0.
	if (c == nil) c,s = 7,1
	
	local dx = (#tostr(t))*2

	print(t,x-dx,y+1,s)
	print(t,x-dx,y,c)

end

function draw_game_ui()

	-- lives
	
	local _x = 2
	
	for i = 1,p_lives do
	 spr(15,_x,2)
	 _x += 8
	end

	-- score
	
	local _c,_s = 13,0
	local _slen = #tostr(score)
	
	_x = 50

	-- bg rect
	
	rectfill(_x - 1,2,_x + 27,9,1)

 -- bg zeros
	
	for i = 1,6-_slen do 
		print_shadow("0",_x,3,_c,_s)
		_x += 4
	end
	
	if (score > 0) _c = 7
	if (score_flicker) _c = 10

	print_shadow(score,_x,3,_c,_s)
	_x += 4*_slen
	
	print_shadow("0",_x,3,_c,_s)
	score_flicker = false

end


-->8
-- hazards + fx

-- ----------
-- sawblades!
-- ----------

saws = {}

-- left / right screen hazards

function new_hazard_saw(x,y)
	
	add(saws, {
		x=x,y=y,
		box = new_box(x,y,7,7),
		moves_right = true
	})

end

function update_saws()
	for saw in all(saws) do
		saw.x += saw.moves_right and 1 or -1
		if (saw.x > 128) saw.x = 0 saw.y += 8
		if (saw.y > 128) saw.y = 0
		
		saw.box = new_box(saw.x,saw.y,7,7)
	end
end

function draw_saws()
	for saw in all(saws) do
	 spr(42,saw.x,saw.y)
	end
end

-- ------
-- vfx! 
-- ------

particles = {}

function new_particle(x,y,c_table)

	local _p = {
	
		-- pos and velocity.
		x=x,y=y,
		v=vector_ang(rnd(1),rnd(2)),lpf=0.2,
		
		-- drawing
		c = rnd(c_table),
		rad = rnd({0,1}),
		rad_lpf = 0
	}
	
	add(particles, _p)
	return _p


end

function update_particles()

	for p in all(particles) do
	
		p.x += p.v.x
		p.y += p.v.y
		p.v = v_lerp_zero(p.v,p.lpf)
	
		if (p.v.x == 0 or p.v.y == 0) del(particles,p)
		
	end
	

end

function draw_particles()
	for p in all(particles) do
		circfill(p.x,p.y,p.rad,p.c)
	end
end
__gfx__
000000000eeeeee00000000007b7e7b7000000000e77e7700eeeeee0000000000000000000000000000000000000000000000000000000000000000008808800
00000000077767770eeeeee00777677707b7e7b7077b6b77077767770eeeeee0000000000000000000000000000000000000000000000000000000008ee8ee80
0000000067b767b7077767776777e7770777677767b767b7677767770777677700000000000000000000000000000000000000000000000000000000eeeee7e0
000000000777e77767b767b700eeeee06777e7770e77e77e07b7e7b76777677700000000000000000000000000000000000000000000000000000000eeeeeee0
0000000000eeeee00777e77700ee2ee000eeeee000ee7ee000eeeee007b7e7b70000000000000000000000000000000000000000000000000000000088888880
0000000000eee00000eeeee000eee00000ee2ee000ee700000eee00000eeeee00000000000000000000000000000000000000000000000000000066d28888820
0000000000eee00000eee00000eee00000eee0000eeee00000eee00000eee000000000000000000000000000000000000000000000000000166d16d612888210
0000000000e0e0000eeeee0000e0e0000eeeee0000000e0000e0e0000eeeee00000000000000000000000000000000000000000000000000e6d6eee001282100
0000000000d6d2000000000000d6d200090000009000990000bb00000d6600000000000000003000000001100000000005000000067760000007700000700000
00000dd00d022d0000000fd00d022d009a90000004a9aa900bb7b00000313bb0000000000000b1bb7bbb3b3000000000006f61d1061160000077770000000070
000ff00d0d022d0000000f0d0fffff009a900000400099000bbbb000d663bbbb000000000000b1b7bbb3b10300000000d6fffd060d6620600077770000000000
00f2222600f2f50000022f2600521000090000000000000003bb3000d663bb7b0000000000003133bbb3b10300000000d66f6d060dddd6000f77f77070000000
245ff22d00f2f50024511f2d005215000a000000000000006133160000313bb000000000000010333bbb3b3000000000441112d2015550000f7777700000000f
44455dd2000f541044455fd2000554100900000000000000636636000d660000000000000000000031000110000000002420d0000111144004f777f000000000
241000000000444024100000000044404040000000000000d0660d00000000000000000000000000130000000000000012200d00051d4440004f7f0000000000
00000000000024200000000000002420000000000000000000dd0000000000000000000000000000000000000000000000000000001d221000000000000f0000
06760000067777600000677777760000000067777776000000009aa0009aaaa00000000000000000888888880000000000000000000000000000000000000000
777d70006717717606777777777777600677777777777760009aaa9009aaa90a0000000000000000888888880000000060000000177777703aaaaaa000000000
7d776000717667170777777777777770077777777777777009aaa9000aaaaa000000000000000000888888880006000d6000000011177100333aa30000000000
6776000066777766677111777771117667777777777777760aaaaa0099aaa9a00000000000000000888888880006600d6006770000177000003aa00000000000
06600000d661166d77177717771777177777227777772277919a91a091191199000000000000000088888888000d6d6677677000001cc000003bb00000000000
d0000000066116607777667777776677777722277772227799191a99999a99920000000000000000888888880000d67677760000001cc000003bb00000000000
0000000001d66d007777777777777777777772277772277729999992099999200000000000000000888888880000676d677700001cccccc03bbbbbb000000000
000000000000d6107771177777771117777777777777777702999920002999920000000000000000888888880ddd66d006776600111111003333330000000000
00000000067777606777111111111177677777777777777700000000000000000000000000000000000000000011dd100d66ddd0000000000000000000949900
00000000627777266777777777777776677777772227777600000000000000000000000000000000000000000000ddd1d6660000000000000000000009a94990
0000000077866877d667777666667766d667777288827766000000000000000000000000000000000000000000001ddd666d0000000000000000000049999494
000000006677776600d666777667766600d66677222776660000000000000000000000000000000000000000000dd1dd66d6d000000000000000000094999492
00000000d628826d0100d667777666600100d66777766660000000000000000000000000000000000000000000dd1001d0066000000000000000000042499424
0000000006622660011d6666666666d0011d6666666666d0000000000000000009aa9000000000000000000000000001d0006000000000000000000044244242
0000000001d66d000111ddd66666dd000111ddd66666dd0000000000000000004a49a4004449a900000000000000000100000000000000000000000004422440
000000000000d61000111d1dd6d1000000111d1dd6d100000000000000000000049a400000000000000000000000000000000000000000000000000000244200
1dddddd144224422111119a41551111115511111111111110000000000000000000000000000000000000000000000000000000000000000000000006666666d
666d666d2244224415559aaa55515551555155511111555100000000000000000000000000000000000000000000000000000000000000000000000001111111
666d666d4999999905554aa455515550555155511151555100000000000000000000000000000000000000000000000000000000000000000000000000000000
01111110499999991155194511115511111155100111555100000000000000000000000000000000000000000000000000000000000000000000000000000000
1ddd1ddd0222222019a1111501111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
1ddd1ddd444444429aa9555005551555115511111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
01111110444444424aa1555115551555111111100111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000222222201441551111551551011111000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000
0222222000000000111119a915511111155111111111155100000000000000000000000000000000000000000000000000000000000000000000000000000000
244444424999999915559aaa55555551555155511555155500000000000000000000000000000000000000000000000000000000000000000000000000000000
494949499999999905554aa455555550555155500555155500000000000000000000000000000000000000000000000000000000000000000000000000000000
49494949499999990155144511155511111155111155111100000000000000000000000000000000000000000000000000000000000000000000000000000000
02222220022222201111111005555111011111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000
42424242444444425551555005555555015511111111551000000000000000000000000000000000000000000000000000000000000000000000000000000000
42424242444444445551555115551555001111511511110000000000000000000000000000000000000000000000000000000000000000000000000000000000
20202020444444421551551111551551000001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02221100000000001551549100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeefff52444444455114aa900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1eeef7f544444444511159a400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1eefeff5244444441499454500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5ffefee10222222049aa911100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5fffeee1444444424aaa911000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5fffeee0444444441aa9415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00112220444444425444115100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d666666d0000000015511111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb
667777662444444455555551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb
676776764444444455995550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb00bbbbbbbb
677777762444444414a9951100000000000000000000000000000000000000000000000000000000000000000000000000000000000bb00000bbbb00bbbbbbbb
d666666d011111104aaa911100000000000000000000000000000000000000000000000000000000000000000000000000000000000bb00000bbbb00bbbbbbbb
d6d66d6d222222219aaa9555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb00bbbbbbbb
dd6666dd2222222214941555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb
1dddddd12222222111451551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb
__map__
4343434343434343434343434343430040404000000000000000000040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4372434343550000005443434243430040404000000000210000000040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4343524355000000000054434362430040404000210000000000210040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4344550000002100210000005444430040404000000000000000000040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4500000000000000000000000000440040404000000000000000000040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000002a000000000000000040404000000000000000000040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000040404000000000000000000040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000414100000000000000414100000040404000000000000000000040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000040400000000000000000000000404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000040400000000000000000000000404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000041414100000000000000404000004f4f4f4f4f4f4f0000404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000040400000000000000000000000404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000040404000000000000000000040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004f4f4f00000000004f4f4f0000004040400000004f4f4f00000040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000040404000000000000000000040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01020000180511c0511f051210510c0000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
930203001162200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a70503000c65500000056000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
95040300366411e6211e6110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9103060011051100510e0510c05100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
931003001c62500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
110a00001c555185551f5550050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
070600000c65500005346550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910d00000c0500c0500c0500c0550c0500c0500e0500e0550f0500f0500f0500f0551305013050130501305512055120551205512055120551205512055120551305013050130501305500000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
110e000010755007050c75500705117550070513755007050070500705117550070510755007050e755007050c7550070507755007050e75500705107550070500705007050e7550070510755007051175500705
110e00000975509000057550b000097550c0000c75500000000000b0000b755177000c7550c0000e7550000010755000000e755000000c755000000f7550000000000000000e755000000c755000000775500000
930e00000c655006000060000600306550060000600006000c600006000c65500600306550060000600006000c655006000060000600306550060000600006000c655006000c6550060030655006000060000600
910e00001a355000001c355180001f355000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 0f111244
02 10111244

