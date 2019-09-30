local def = require('define')
local map = require('map')

local this = {}

function create_sprite(pType, pName, px, py)  
    local sprite = {}
    sprite.x = px
    sprite.y = py
    sprite.type = pType
    sprite.kill = false
    sprite.img = love.graphics.newImage("images/"..pName..".png")
    sprite.w = sprite.img:getWidth()
    sprite.h = sprite.img:getHeight()
    sprite.frame = 1
    sprite.tframes = {}
    sprite.maxFrame = 1
    sprite.scale = 2

    table.insert(this.tsprites, sprite)

    return sprite
end

function create_shoot(pName, px, py, pvx, pvy)
    local shoot = create_sprite('shoot', pName, px, py)
    shoot.vx = pvx
    shoot.vy = pvy
    table.insert(this.tshoots, shoot)
    return shoot 
end

function create_player(px, py)
	local player = create_sprite('player', 'player-1', px, py)
	player.WIDTH = player.img:getWidth()
	player.HEIGHT = player.img:getHeight()
	player.vy = 0
	player.vx = 0
	player.force = 0
	player.speed = 4
	player.tframes = this.player_imgs
	player.maxFrame = 4
	return player
end

function update_player(dt)
	local n
	for n, sprite in ipairs(this.tsprites) do
		if sprite.type == 'player' and sprite.kill == false then
			def.bounce(sprite, this.gravity, def.SCREEN_HEIGHT - map.TILE_HEIGHT, 150, 2.5, 700, this.sound_bounce, dt)
			if this.playerWin == true then
				def.move_x(sprite, dt)
				if def.is_out(sprite) == true then
					new_game()
				end
			end
		end
	end
end

function create_target(py, pscore)
	local target = create_sprite('target', 'target', def.SCREEN_WIDTH - map.TILE_WIDTH/2, py)
	if pscore == 0 or pscore == 1 then
		target.vy = 2
	elseif pscore == 2 then
		target.vy = 3
	elseif pscore >= 3 then
		target.vy = 4
	end

	target.rand_dir = math.rsign()
	target.maxY = def.SCREEN_HEIGHT/4
	target.minY = def.SCREEN_HEIGHT - map.TILE_HEIGHT - target.h

	target.update = function(dt)
		target.y = target.y + (target.rand_dir * target.vy) * (60*dt)

		if target.y >= target.minY then
			target.y = target.minY
			target.vy = 0 - target.vy
		elseif target.y <= target.maxY then
			target.y = target.maxY
			target.vy = 0 - target.vy
		end
	end

	table.insert(this.targets, target)
	return target
end

function create_explosion(px, py, ptable)
	local newExplosion = create_sprite('explosion', '/effects/explosion-1', px, py)
	newExplosion.tframes = ptable
	newExplosion.maxFrame = 14
	return newExplosion
end

function new_game()
	this.playerTries = 3
	this.playerWin = false
	this.playerLose = false

	local randX = love.math.random(def.SCREEN_WIDTH/8, def.SCREEN_WIDTH/4)
	create_player(def.SCREEN_WIDTH/3, 0)
	create_target(def.SCREEN_HEIGHT/2, this.player_score)

	map.load()
end

function this.load()
	this.player_score = 0

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

	this.player_imgs = {}
	this.explosion_imgs = {}

	def.load_imgs('images/player-', this.player_imgs, 4)
	def.load_imgs('images/effects/explosion-', this.explosion_imgs, 14)

	new_game()
end

function this.update(dt)

	update_player(dt)

	if this.playerLose == true then
		if this.timer_scoreScreen > 0 then
			this.timer_scoreScreen = this.timer_scoreScreen - (10*dt)
		else
			def.kill_sprites(this.tsprites)
			def.current_screen = 'gameover'
		end
	end

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
				if def.collide(shoot, target) == true and target.kill == false and shoot.kill == false and this.playerWin == false then
					this.playerWin = true

				    --Player gets a point (1 star)
				    this.player_score = this.player_score + 1

					--Star explode
					create_explosion(target.x, target.y, this.explosion_imgs)

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

			target.update(dt)

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

	def.purge_sprites(this.tsprites)
end

function this.draw()

	----DRAW BACKGROUND
	love.graphics.draw(this.bg)

	----DRAW MAP
	map.draw()

	def.draw_sprites(this.tsprites)

	----DRAW INFO/DATA
	love.graphics.setFont(this.font)
	love.graphics.setColor(0,0,0)
	love.graphics.print("STONES : " .. tostring(this.playerTries), 30, 15)
	love.graphics.print("SCORE : " .. tostring(this.player_score), def.SCREEN_WIDTH-205, 15)
	love.graphics.setColor(1,1,1)
	----

end

function this.keypressed(key)
	local n
	for n, sprite in ipairs(this.tsprites) do
		if key == 'space' and sprite.type == 'player' and this.playerTries >= 1 and this.playerWin == false then
			create_shoot('stone', sprite.x, sprite.y, 20, 0)
			this.playerTries = this.playerTries - 1
			this.PLAYER_ANIM_ON = true
		end
	end
end

return this