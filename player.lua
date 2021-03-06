local G = love.graphics


Player = Object:new {
	img = G.newImage("media/player.png"),
	model = { -16, 16, -16, 0, -4, -12, 4, -12, 16, 0, 16, 16 }
}
genQuads(Player, 16)
function Player:init()
	self.trans_model = {}
end
function Player:reset()
	self.shield = 3
	self.x = 0
	self.y = 350
	self.alive = true
	self.invincible = 0
	self.score = 0

	self.tick = 0
	self.shoot_delay = 0
	self.blast = 0
	self.blast_x = 0
	self.blast_y = 0
	self.flash = 0
end
function Player:hit(d, n, w, e)
	-- FIXME
--	if 1 then return end

	-- collision
	if d then
		self.x = self.x + n[1] * d
		self.y = self.y + n[2] * d

		-- instand death
		if self.y > 284 and (not e or e.alive) then
			self.invincible = 0
			self.shield = 0
		end

		self.blast_x = n[1] * 7
		self.blast_y = n[2] * 7
		self.blast = 15
		transform(self)
		for i = 1, 10 do
			ExplosionSparkParticle(w[1], w[2])
		end
	end
	-- damage
	if self.invincible == 0 then
		self.invincible = 100
		self.flash = 5
		self.shield = self.shield - 1
		if self.shield <= 0 then
			self.alive = false
			makeExplosion(self.x, self.y)
		end
	end
end
function Player:update(input)
	if not self.alive then return end

	self.tick = self.tick + 1
	if self.flash > 0 then self.flash = self.flash - 1 end
	self.blast_x = self.blast_x * 0.85
	self.blast_y = self.blast_y * 0.85

	local speed = 3
	if self.shoot_delay > 0 or input.shoot then
		speed = speed * 0.5
	end
	if self.blast > 0 then
		self.blast = self.blast - 1
		speed = 0
	end

	if self.tick < 60 then
		self.y = self.y - 3
	else
		self.x = self.x + self.blast_x + input.dx * speed
		self.y = self.y + self.blast_y + input.dy * speed
		if self.x > 384 then self.x = 384 end
		if self.x <-384 then self.x =-384 end
		if self.y > 284 then self.y = 284 end
		if self.y <-284 then self.y =-284 end
	end

	transform(self)

	local d, n, w = game.walls:checkCollision(self.trans_model)
	if d > 0 then
		n[1] = -n[1]
		n[2] = -n[2]
		self:hit(d, n, w)
	end

	-- shoot
	if input.shoot and self.shoot_delay == 0 then
		self.shoot_delay = 10
		Laser(self.x, self.y - 4,   0)
		Laser(self.x, self.y - 4, -45)
		Laser(self.x, self.y - 4,  45)
		playLaserSound()
	end
	if self.shoot_delay > 0 then
		self.shoot_delay = self.shoot_delay - 1
	end


	-- collision with enemies
	for _, e in ipairs(Enemy.list) do
		local d, n, w = polygonCollision(self.trans_model, e.trans_model)
		if d > 0 then
			e:hit(1)
			self:hit(d, n, w, e)
		end
	end


	if self.invincible > 0 then
		self.invincible = self.invincible - 1
	end

end
function Player:draw()
	if not self.alive then return end

	if self.invincible % 8 >= 4 then return end

	if self.flash > 0 then G.setShader(flash_shader) end

	G.setColor(255, 255, 255)
	G.draw(
		self.img,
		self.quads[1 + math.floor(self.tick / 8 % 2)],
		self.x, self.y, 0, 4, 4, 8, 8)

	if self.flash > 0 then G.setShader() end

--	G.polygon("line", self.trans_model)
end




Laser = Object:new {
	list = {},
	img = G.newImage("media/laser.png"),
	model = { -2, -10, 2, -10, 2, 10, -2, 10 }
}
function Laser:init(x, y, dir)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	self.dir = dir
	self.trans_model = {}
end
function Laser:update()
	for i = 1, 4 do
		if self.dir == 0 then
			self.y = self.y - 4
		end
		if self.dir == -45 then
			self.y = self.y - 2
			self.x = self.x - 2
		end
		if self.dir ==  45 then
			self.y = self.y - 2
			self.x = self.x + 2
		end
		if self.y < -300 then return "kill" end
		transform(self)

		local d, n, w = game.walls:checkCollision(self.trans_model)
		if d > 0 then
			for i = 1, 10 do
				LaserParticle(w[1], w[2])
			end
			playLaserMissSound()
			return "kill"
		end

		for _, e in ipairs(Enemy.list) do
			local d, n, w = polygonCollision(self.trans_model, e.trans_model)
			if d > 0 then
				e:hit(1)
				for i = 1, 10 do
					LaserParticle(w[1], w[2])
				end
				return "kill"
			end

		end
	end
end
function Laser:draw()
	G.setColor(255, 255, 255)
	G.draw(self.img, self.x, self.y, 0, 4, 4, 1.5, 3)
--	G.polygon("line", self.trans_model)
end

local laserSoundData = love.sound.newSoundData("media/laser.ogg")
function playLaserSound()
	local source = love.audio.newSource(laserSoundData)
	love.audio.play(source)
end

local laserMissSoundData = love.sound.newSoundData("media/laser-miss.ogg")
function playLaserMissSound()
	local source = love.audio.newSource(laserMissSoundData)
	love.audio.play(source)
end
