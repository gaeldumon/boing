local this = {}

this.SCREEN_WIDTH = love.graphics.getWidth()
this.SCREEN_HEIGHT = love.graphics.getHeight()
this.current_screen = 'menu'

this.color = {}
this.color.white = {0,0,0}
this.color.black = {1,1,1}
this.color.red = {1,0,0}
this.color.green = {0,1,0}
this.color.blue = {0,0,1}
this.color.brown = {102/255, 51/255, 0}

function math.rsign() return love.math.random(2) == 2 and 1 or -1 end

function this.collide(pobj1, pobj2)
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

function this.bounce(pobj, pgravity, psurface, pmaxy--[[150]], --[[2.5]]pforcefactor, --[[700]]pforceloss, psound, dt)
	pobj.vy = (pgravity - pobj.force) * dt
	pobj.y = pobj.y + pobj.vy

	if pobj.y >= psurface - pobj.h then
		pobj.force = pgravity * pforcefactor
		psound:play()
	end

	if pobj.y <= this.SCREEN_HEIGHT - pobj.h and pobj.y >= pmaxy then
		pobj.force = pobj.force - pforceloss * dt
	end
end

function this.change_screen(pnew_screen, pdelay)
	local timer = 0
	if ptimer <= pdelay then
		ptimer = ptimer + (10*dt)
	else
		def.current_screen = pnew_screen
	end
end

function this.load_imgs(pdir, ptable, pnumber)
	local i
	for i = 1, pnumber do
		ptable[i] = love.graphics.newImage(pdir .. tostring(i) .. '.png')
	end
end

function this.kill_sprites(ptable)
	local n
	for n, sprite in ipairs(ptable) do
		if sprite.kill == false then
			sprite.kill = true
		end
	end
end

function this.purge_sprites(ptable)
	local n
	for n, sprite in ipairs(ptable) do
		if sprite.kill == true then
			table.remove(ptable, n)
		end
	end
end

function this.draw_sprites(ptable, pscale)
	local n
	for n, sprite in ipairs(ptable) do
		love.graphics.draw(sprite.img, sprite.x, sprite.y, 0, pscale, pscale, sprite.w/2, sprite.h/2)
	end
end

return this