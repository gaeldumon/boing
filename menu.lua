local def = require('define')

local this = {}

function this.load()
	this.bg = love.graphics.newImage('images/menu.png')
end

function this.update(dt)
end

function this.draw()
	love.graphics.draw(this.bg)
end

function this.keypressed(key)
	if key == 'space' then
		def.current_screen = 'game'
	end
end

return this