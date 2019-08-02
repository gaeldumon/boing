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

function create_sprite(ptype, pname, px, py, ptable)  
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

    table.insert(ptable, sprite)

    return sprite
end

function create_moving_obj(ptype, pname, px, py, pvx, pvy, ptable)
    local obj = createSprite(ptype, pname, px, py)
    obj.vx = pvx
    obj.vy = pvy
    table.insert(ptable, obj)
    return obj 
end

function bounce(pobj, pgravity, psurface, pmaxy--[[150]], --[[2.5]]pforcefactor, --[[700]]pforceloss, psound, dt)
	pobj.vy = (pgravity - pobj.force) * dt
	pobj.y = pobj.y + pobj.vy

	if pobj.y >= def.SCREEN_HEIGHT - pobj.h - pSurface then
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
	player.tframes = pframes_table
	player.maxframe = 4
--************************************i'm here**************************

	player.moveon = function(dt)
		player.vx = player.speed * (60*dt)
		player.x = player.x + player.vx

		if player.x - player.w/2 > def.SCREEN_WIDTH then
			player.kill = true
			levelUp()
			return true
		end
		return false
	end

	return player
end

function createTarget(py, pLevel)
	local target = createSprite('target', 'target', def.SCREEN_WIDTH - map.TILE_WIDTH/2, py)
	if pLevel == 1 then
		target.vy = 2
	elseif pLevel == 2 then
		target.vy = 3
	elseif pLevel >= 3 then
		target.vy = 4
	end
	target.rand_dir = math.rsign()
	target.maxY = def.SCREEN_HEIGHT/4
	target.minY = def.SCREEN_HEIGHT - map.TILE_HEIGHT - target.h
	table.insert(this.targets, target)
	return target
end

function createExplosion(px, py)
	local newExplosion = createSprite('explosion', '/effects/explosion-1', px, py)
	newExplosion.tframes = this.explosionImgs
	newExplosion.maxFrame = 14
	return newExplosion
end

function newGame()
	this.current_level = 1
	this.playerTries = 3
	this.playerWin = false
	this.playerLose = false

	local randX = love.math.random(def.SCREEN_WIDTH/8, def.SCREEN_WIDTH/4)
	createPlayer(def.SCREEN_WIDTH/3, 0)
	createTarget(def.SCREEN_HEIGHT/2, this.current_level)

	map.load()
end

function levelUp()
	--Re-think this : don't use newGame here, write like a "level up new game"
	newGame()
	this.current_level = this.current_level + 1
end

function this.load()
	--Re-think this : put in in levelUp ?
	this.playerScore = 0

	this.gravity = 380
	this.PLAYER_ANIM_ON = false
	this.timer_scoreScreen = 10

	this.font = love.graphics.newFont('fonts/ArcadeAlternate.ttf', 35)
	this.bg = love.graphics.newImage('images/bg.png')

	this.sound_bounce = love.audio.newSource('sounds/bounce.wav','static')
	this.sound_freeze = love.audio.newSource('sounds/freeze.wav', 'static')

	this.tsprites = {}
	this.tshoots = {}
	this.targets = {}

	do
		this.playerImgs = {}
		local i
		for i = 1, 4 do
			this.playerImgs[i] = love.graphics.newImage('images/player-'..tostring(i)..'.png')
		end
	end

	do
		this.explosionImgs = {}
		local i
		for i = 1, 14 do
			this.explosionImgs[i] = love.graphics.newImage('images/effects/explosion-'..i..'.png')
		end
	end

	newGame()
end

function this.update(dt)

	if this.playerLose == true then
		if this.timer_scoreScreen > 0 then
			this.timer_scoreScreen = this.timer_scoreScreen - (10*dt)
		else
			local n
			for n, sprite in ipairs(this.tsprites) do
				if sprite.kill == false then sprite.kill = true end
			end
			def.current_screen = 'gameover'
		end
	end

	----MAKE PLAYER BOUNCE AND MOVE WHEN WIN
	local shit = true
	do
		local n
		for n, sprite in ipairs(this.tsprites) do
			if sprite.type == 'player' and sprite.kill == false then

				sprite.bounce(this.gravity, map.TILE_HEIGHT, 2.5, 700, this.sound_bounce, dt)

				if this.playerWin == true then
					sprite.moveOn(dt)
				end
			end
		end
	end
	----

	----UPDATE SHOOTS (MOVE, REMOVE, COLLISION WITH TARGET)
	do
		local n
		for n, shoot in ipairs(this.tshoots) do

			shoot.x = shoot.x + shoot.vx * (60*dt)

			--Shoot go off screen
			if shoot.x > def.SCREEN_WIDTH then
				shoot.kill = true
				table.remove(this.tshoots, n)

				--LAST stone go off screen (doesn't collide with stars)
				if this.playerTries == 0 and this.playerLose == false then
					this.playerLose = true
				end
			end

			----SHOOT COLLISION WITH TARGET => Water tile replaced by ice tile + freeze sound + player score update
			local n_target
			for n_target, target in ipairs(this.targets) do

				----WIN STATE
				if collide(shoot, target) == true and target.kill == false and shoot.kill == false and this.playerWin == false then
					this.playerWin = true

				    --Player gets a point (1 star)
				    this.playerScore = this.playerScore + 1

					--Star explode
					createExplosion(target.x, target.y)

					shoot.kill = true
					table.remove(this.tshoots, n)

					--Star disapear
					target.kill = true
					table.remove(this.targets, n)

					----Water becomes ice
				    local c, l
				    for l = 1, map.MAP_HEIGHT do
				      	for c = 1, map.MAP_WIDTH do
				        	local id = map.grid[l][c]
				        	if map.tileTypes[id] == 'water' then
				        		map.grid[l][c] = 4
				        	end
				      	end
				    end
				    this.sound_freeze:play()
				    ----
				end
				----
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

	----SPRITES PURGE
	do
		local n
		for n, sprite in ipairs(this.tsprites) do
			if sprite.kill == true then
				table.remove(this.tsprites, n)
			end
		end
	end
	----

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