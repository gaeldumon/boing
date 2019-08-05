local def = require('define')
local map = require('map')

local this = {}

function this.create_sprite(ptype, pname, px, py)  
    local sprite = {}
    sprite.x = px
    sprite.y = py
    sprite.img = love.graphics.newImage("images/"..pname..".png")
    sprite.w = sprite.img:getWidth()
    sprite.h = sprite.img:getHeight()
    sprite.type = ptype
    sprite.kill = false
    sprite.frame = 1
    sprite.tframes = {}
    sprite.maxframe = 1
    sprite.animation_speed = 0.2

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

function this.create_shot(pname, px, py, pvx, pvy)
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
				this.create_explosion(target.x, target.y, this.explosion_imgs)

				def.transform_tile('water', 4, this.sound_freeze)

				shoot.kill = true
				target.kill = true
			end
		end
	end

	table.insert(this.tshots, shot)

    return shot 
end

function this.create_player(px, py, pframes_table--[[this.playerImgs]])
	local player = this.create_sprite('player', 'player-1', px, py)
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
	player.anim_on = false

	player.moveon = function(dt)
		player.vx = player.speed * (60*dt)
		player.x = player.x + player.vx
	end

	player.update = function(dt, ptimer)
		def.bounce(player, this.gravity, def.SCREEN_HEIGHT - map.TILE_HEIGHT, 150, 2.5, 700, this.sound_bounce, dt)

		if player.isoffscreen() == true then
			this.new_game()
		end

		if player.lose == true then
			def.change_screen('gameover', 10)
		end

		if player.win == true then
			player.moveon(dt)
			player.score = player.score + 1
		end
	end

	player.shoot = function()
		if player.ammo >= 1 and player.win == false and player.lose == false then
			this.create_shot('stone', player.x, player.y, 20, 0)
			player.ammo = player.ammo - 1
			player.anim_on = true
		end
	end

	player.anim = function(dt)
		if player.anim_on == true then
			player.frame = player.frame + player.animation_speed * (60*dt)
			if math.floor(player.frame) > player.maxframe then
				player.frame = 1
				player.anim_on = false
			else
				player.img = player.tframes[math.floor(player.frame)]
			end
		end
	end

	return player
end

function this.create_target(py, plevel)
	local target = this.create_sprite('target', 'target', def.SCREEN_WIDTH - map.TILE_WIDTH/2, py)

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

	target.udate = function(dt)
		target.y = target.y + (target.rand_dir * target.vy) * (60*dt)

		if target.y >= target.miny then
			target.y = target.miny
			target.vy = 0 - target.vy
		elseif target.y <= target.maxy then
			target.y = target.maxy
			target.vy = 0 - target.vy
		end
	end

	table.insert(this.targets, target)
		
	return target
end

function this.create_explosion(px, py, pframes_table)
	local explosion = this.create_sprite('explosion', '/effects/explosion-1', px, py)
	explosion.tframes = pframes_table
	explosion.maxframe = 14

	explosion.anim = function(dt)
		explosion.frame = explosion.frame + explosion.animation_speed * (60*dt)
		if math.floor(explosion.frame) > explosion.maxframe then
			explosion.kill = true
		else
			explosion.img = explosion.tframes[math.floor(explosion.frame)]
		end
	end

	return explosion
end

function this.new_game()
	this.current_level = 1
	local randx = love.math.random(def.SCREEN_WIDTH/8, def.SCREEN_WIDTH/4)
	this.create_player(randx, 0)
	this.create_target(def.SCREEN_HEIGHT/2, this.current_level)

	map.load()
end

function this.display_infos(pmargin_left, pmargin_up)
	love.graphics.setFont(this.font)
	love.graphics.setColor(def.color.white)
	love.graphics.print("STONES : " .. tostring(player.ammo), pmargin_left, pmargin_up)
	love.graphics.print("LEVEL " .. tostring(this.current_level), 445, pmargin_up)
	love.graphics.print("SCORE : " .. tostring(player.score), def.SCREEN_WIDTH-205, pmargin_up)
	love.graphics.setColor(1,1,1)
end

function this.load()
	this.gravity = 380
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

	def.load_imgs('images/player-', this.player_imgs, 4)
	def.load_imgs('images/effects/explosion-', this.explosion_imgs, 14)

	this.new_game()
end

function this.update(dt)
	def.purge_sprites(this.targets)
	def.purge_sprites(this.tshots)
	def.purge_sprites(this.tsprites)

	local nsp
	for n, sp in ipairs(this.tsprites) do
		sp.isoffscreen()
	end

	local nt
	for nt, t in ipairs(this.targets) do
		t.update(dt)
		t.anim(dt)
	end

	local ns
	for ns, s in ipairs(this.tshots) do
		s.update(dt)
		s.anim(dt)
	end

	player.update(dt)
	player.anim(dt)
end

function this.draw()
	love.graphics.draw(this.bg)
	this.display_infos(30, 15)
	def.draw_sprites(this.tsprites, 2)
end

function this.keypressed(key)
	if key == 'space' then
		player.shoot()
	end
end

return this