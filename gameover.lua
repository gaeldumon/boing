local game = require('game')
local def = require('define')

local this = {}

this.stars = {}

function this.makeBounce(pSprite, pGravity, pSurface, --[[2.5]]pForceFactor, --[[700]]pForceLoss, pSound, dt)
	pSprite.vy = (pGravity - pSprite.force) * dt
	pSprite.y = pSprite.y + pSprite.vy

	if pSprite.y >= def.SCREEN_HEIGHT - pSprite.h*3 - pSurface then
		pSprite.force = pGravity * pForceFactor
		if pSound ~= nil then pSound:play() end
	end

	if pSprite.y <= def.SCREEN_HEIGHT - pSprite.h and pSprite.y >= 150 then
		pSprite.force = pSprite.force - pForceLoss * dt
	end
end

function this.createStar()
	local star = {}
	star.img = love.graphics.newImage('images/target.png')
	star.w = star.img:getWidth()
	star.h = star.img:getHeight()
	star.x = love.math.random(def.SCREEN_WIDTH/2.80, def.SCREEN_WIDTH/1.80)
	star.y = 0
	star.vy = 0
	star.vx = 0
	star.force = 0
	star.speed = 4
	table.insert(this.stars, star)
	return star
end

this.shit = true

function this.load()
	this.bg = love.graphics.newImage('images/score-screen.png')
	this.star = {}
end

function this.update(dt)
	if this.shit == true then
		local n
		for n=1, game.player_score do
			this.createStar()
		end
		this.shit = false
	end

	for n, star in ipairs(this.stars) do
		if star ~= nil then this.makeBounce(star, 400, 0, 2.5, 700, nil, dt) end
	end
end

function this.draw()
	love.graphics.draw(this.bg)
	love.graphics.setColor(0.5,0.5,0.5)
	love.graphics.print(tostring(game.player_score), def.SCREEN_WIDTH/2.1, def.SCREEN_HEIGHT/3, 0, 3, 3)
	love.graphics.setColor(1,1,1)

	local n
	for n, star in ipairs(this.stars) do
		love.graphics.draw(star.img, star.x, star.y, 0, 3, 3)
	end
end

function this.keypressed(key)
	if key == 'space' then
		game.load()
		def.current_screen = 'game'
	end
end

return this