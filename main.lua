--[[
	Game made for the Gamecodeur game jam #20 : Bounces & Collisions
	Coded with love by me (Hyperdestru)
]]

io.stdout:setvbuf('no')
love.graphics.setDefaultFilter("nearest")

local def = require('define')
local game = require('game')
local menu = require('menu')
local gameover = require('gameover')

local sound_theme = love.audio.newSource('sounds/jam20-theme.mp3', 'stream')
sound_theme:isLooping(true)

function love.load()
	def.current_screen = 'menu'
	menu.load()
	game.load()
	gameover.load()
end

function love.update(dt)
	sound_theme:play()

	if def.current_screen == 'menu' then
		menu.update(dt)
	elseif def.current_screen == 'game' then
		game.update(dt)
	elseif def.current_screen == 'gameover' then
		gameover.update(dt)
	end
end

function love.draw()
	if def.current_screen == 'menu' then
		menu.draw()
	elseif def.current_screen == 'game' then
		game.draw()
	elseif def.current_screen == 'gameover' then
		gameover.draw()
	end
end

function love.keypressed(key)
	if def.current_screen == 'menu' then
		menu.keypressed(key)
	elseif def.current_screen == 'game' then
		sound_theme:setVolume(0.7)
		game.keypressed(key)
	elseif def.current_screen == 'gameover' then
		gameover.keypressed(key)
	end
end