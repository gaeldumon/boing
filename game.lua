local def = require('define')
local map = require('map')

local this = {}

function math.rsign() return love.math.random(2) == 2 and 1 or -1 end

function collide(pobj1, pobj2)
	if (pobj1 == pobj2) then 
		return false 
	end

	local dx = pobj1.x - pobj2.x
	local dy = pobj1.y - pobj2.y

	if (math.abs(dx) < pobj1.w + pobj2.w) then
		if (math.abs(dy) < pobj1.h + pobj2.h) then
			return true
		end
	end

	return false
end

function create_sprite(ptype, pname, px, py)  
    local sprite = {}
    sprite.x = px
    sprite.y = py
    sprite.w = sprite.img:getWidth()
    sprite.h = sprite.img:getHeight()
    sprite.type = ptype
    sprite.kill = false
    sprite.img = love.graphics.newImage("images/"..pname..".png")
    sprite.frame = 1
    sprite.tframes = {}
    sprite.maxframe = 1

    sprite.isoffscreen = function()
    	if (sprite.x - sprite.w/2) > def.SCREEN_WIDTH or
    	(sprite.x - sprite.w/2) < 0 or
    	(sprite.y - sprite.h/2) > def.SCREEN_HEIGHT or
    	(sprite.y - sprite.h/2) < 0 then
    		sprite.kill = true
    		return true
    	else
    		return false
    	end 
   	end

    table.insert(this.tsprites, sprite)

    return sprite
end

function transform_tile(pmap, pold_tile--[[tile type]], pnew_tile--[[tile id]], psound)
    local c, l
    for l = 1, pmap.MAP_HEIGHT do
      	for c = 1, pmap.MAP_WIDTH do
        	local id = pmap.grid[l][c]
        	if pmap.tileTypes[id] == pold_tile then
        		map.grid[l][c] = pnew_tile
        	end
      	end
    end
    psound:play()
end

function create_shot(pname, px, py, pvx, pvy)
    local shot = createSprite('shot', pname, px, py)
    shot.vx = pvx
    shot.vy = pvy

    shot.update = function(dt, ptargets)
		shoot.x = shoot.x + shoot.vx * (60*dt)

		local n_target
		for n_target, target in ipairs(ptargets) do

			if collide(shoot, target) == true and target.kill == false and shoot.kill == false and player.win == false then
				player.win = true

				--Star explode
				create_explosion(target.x, target.y, this.explosion_imgs)

				transform_tile(map, 'water', 4, this.sound_freeze)

				shoot.kill = true
				target.kill = true
			end
	end

    table.insert(this.tshots, shot)
    return shot 
end

function bounce(pobj, pgravity, psurface, pmaxy--[[150]], --[[2.5]]pforcefactor, --[[700]]pforceloss, psound, dt)
	pobj.vy = (pgravity - pobj.force) * dt
	pobj.y = pobj.y + pobj.vy

	if pobj.y >= psurface - pobj.h then
		pobj.force = pgravity * pforcefactor
		psound:play()
	end

	if pobj.y <= def.SCREEN_HEIGHT - pobj.h and pobj.y >= pmaxy then
		pobj.force = pobj.force - pforceloss * dt
	end
end

function create_player(px, py, pframes_table--[[this.playerImgs]])
	local player = createSprite('player', 'player-1', px, py)
	player.vy = 0
	player.vx = 0
	player.force = 0
	player.speed = 4
	player.score = 0
	player.win = false
	player.lose = false
	player.ammo = 3
	player.tframes = pframes_table
	player.maxframe = 4

	player.moveon = function(dt)
		player.vx = player.speed * (60*dt)
		player.x = player.x + player.vx
	end

	player.update = function(dt, ptimer)

		bounce(player, this.gravity, def.SCREEN_HEIGHT - map.TILE_HEIGHT, 150, 2.5, 700, this.sound_bounce, dt)

		if player.isoffscreen() == true then
			--refresh screen
		end

		if player.lose == true then
			if ptimer > 0 then
				ptimer = ptimer - (10*dt)
			else
				def.current_screen = 'gameover'
			end
		end

		if player.win == true then
			player.moveon(dt)
			player.score = player.score + 1
		end
	end

	return player
end

function create_target(py, plevel)
	local target = createSprite('target', 'target', def.SCREEN_WIDTH - map.TILE_WIDTH/2, py)

	if plevel == 1 then
		target.vy = 2
	elseif plevel == 2 then
		target.vy = 3
	elseif plevel >= 3 then
		target.vy = 4
	end

	target.rand_dir = math.rsign()
	target.maxy = def.SCREEN_HEIGHT/4
	target.miny = def.SCREEN_HEIGHT - map.TILE_HEIGHT - target.h

	table.insert(this.targets, target)
	return target
end

function create_explosion(px, py, pframes_table)
	local newexplosion = createSprite('explosion', '/effects/explosion-1', px, py)
	newexplosion.tframes = pframes_table
	newexplosion.maxframe = 14
	return newexplosion
end

function new_game()
	local randx = love.math.random(def.SCREEN_WIDTH/8, def.SCREEN_WIDTH/4)
	create_player(randx, 0)
	create_target(def.SCREEN_HEIGHT/2, this.current_level)

	map.load()
end

function load_imgs(pdir, ptable, pnumber)
	local i
	for i = 1, pnumber do
		ptable[i] = love.graphics.newImage(pdir .. tostring(i) .. '.png')
	end
end

function kill_sprites(ptable)
	local n
	for n, sprite in ipairs(ptable) do
		if sprite.kill == false then
			sprite.kill = true
		end
	end
end

function purge_sprites(ptable)
	local n
	for n, sprite in ipairs(ptable) do
		if sprite.kill == true then
			table.remove(ptable, n)
		end
	end
end

function this.load()
	this.gravity = 380
	this.PLAYER_ANIM_ON = false
	this.timer_scorescreen = 10

	this.font = love.graphics.newFont('fonts/ArcadeAlternate.ttf', 35)
	this.bg = love.graphics.newImage('images/bg.png')

	this.sound_bounce = love.audio.newSource('sounds/bounce.wav','static')
	this.sound_freeze = love.audio.newSource('sounds/freeze.wav', 'static')

	this.tsprites = {}
	this.tshots = {}
	this.targets = {}
	this.player_imgs = {}
	this.explosion_imgs = {}

	load_imgs('images/player-', this.player_imgs, 4)
	load_imgs('images/effects/explosion-', this.explosion_imgs, 14)

	new_game()
end

function this.update(dt)

	----UPDATE SHOOTS (MOVE, REMOVE, COLLISION WITH TARGET)
	do
		local n
		for n, shoot in ipairs(this.tshots) do

			end
			----
		end
	end
	----

	----UPDATE TARGET (MOVE UP AND DOWN AT GIVEN SPEED AND RANGE)
	do
		local n
		for n, target in ipairs(this.targets) do

			target.y = target.y + (target.rand_dir * target.vy) * (60*dt)

			if target.y >= target.minY then
				target.y = target.minY
				target.vy = 0 - target.vy
			elseif target.y <= target.maxY then
				target.y = target.maxY
				target.vy = 0 - target.vy
			end

		end
	end
	----

	----SPRITES ANIMATIONS (IF ANIMATED i.e FRAME > 1)
	do
		local n
		for n, sprite in ipairs(this.tsprites) do

			if sprite.maxFrame > 1 then

				if sprite.type == 'player' then

					if this.PLAYER_ANIM_ON == true then

						sprite.frame = sprite.frame + 0.2 * (60*dt)
						if math.floor(sprite.frame) > sprite.maxFrame then
							sprite.frame = 1
							this.PLAYER_ANIM_ON = false
						else
							sprite.img = sprite.tframes[math.floor(sprite.frame)]
						end

					end

				elseif sprite.type == 'explosion' then

					sprite.frame = sprite.frame + 0.2
					if math.floor(sprite.frame) > sprite.maxFrame then
						sprite.kill = true
					else
						sprite.img = sprite.tframes[math.floor(sprite.frame)]
					end

				end
			end

		end
	end
	----

	purge_sprites(this.tsprites)

end



function this.draw()

	----DRAW BACKGROUND
	love.graphics.draw(this.bg)

	----DRAW MAP
	map.draw()

	----DRAW SPRITES
	do
		local n
		for n, sprite in ipairs(this.tsprites) do
			love.graphics.draw(sprite.img, sprite.x, sprite.y, 0, 2, 2, sprite.w/2, sprite.h/2)
		end
	end
	----

	----DRAW INFO/DATA
	love.graphics.setFont(this.font)
	love.graphics.setColor(0,0,0)
	love.graphics.print("STONES : " .. tostring(this.playerTries), 30, 15)
	love.graphics.print("LEVEL " .. tostring(this.current_level), 445, 15)
	love.graphics.print("SCORE : " .. tostring(this.playerScore), def.SCREEN_WIDTH-205, 15)
	love.graphics.setColor(1,1,1)
	----

end

function this.keypressed(key)
	local n
	for n, sprite in ipairs(this.tsprites) do
		if key == 'space' and sprite.type == 'player' and this.playerTries >= 1 and this.playerWin == false then
			createShoot('stone', sprite.x, sprite.y, 20, 0)
			this.playerTries = this.playerTries - 1
			this.PLAYER_ANIM_ON = true
		end
	end
end

return this