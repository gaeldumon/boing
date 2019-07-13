local def = require('define')

local this = {}

this.TILE_WIDTH = 128
this.TILE_HEIGHT = 128
this.MAP_WIDTH = def.SCREEN_WIDTH / this.TILE_WIDTH
this.MAP_HEIGHT = def.SCREEN_HEIGHT / this.TILE_HEIGHT

this.tileTypes = {}
this.tileTypes[0] = nil
this.tileTypes[1] = 'grass'
this.tileTypes[2] = 'water'
this.tileTypes[3] = 'crate'
this.tileTypes[4] = 'ice'

this.tileTextures = {}
this.tileTextures[0] = nil
this.tileTextures[1] = love.graphics.newImage('images/tiles/1.png')
this.tileTextures[2] = love.graphics.newImage('images/tiles/2.png')
this.tileTextures[3] = love.graphics.newImage('images/tiles/3.png')
this.tileTextures[4] = love.graphics.newImage('images/tiles/4.png')

this.grid = {}

function this.load()
	this.grid = {
		{ 0,0,0,0,0,0,0,0 },
		{ 0,0,0,0,0,0,0,0 },
		{ 0,0,0,0,0,0,0,0 },
		{ 0,0,0,0,0,0,0,0 },
		{ 0,0,0,0,0,0,0,0 },
		{ 1,1,1,1,1,1,2,2 }
	}
end

function this.draw()
	----DRAW TILES
	do
	    local c, l
	    for l = 1, this.MAP_HEIGHT do
	      	for c = 1, this.MAP_WIDTH do
	        	local id = this.grid[l][c]
	        	local texQuad = this.tileTextures[id]
	        	if texQuad ~= nil then
	            	local x = (c - 1) * this.TILE_WIDTH
	            	local y = (l - 1) * this.TILE_HEIGHT
	            	love.graphics.draw(texQuad, x, y)
	       		end
	      	end
	    end
	end
	----
end

return this
