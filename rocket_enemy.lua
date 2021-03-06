local G = love.graphics

RocketEnemy = Enemy:new {
	shield = 1,
	score = 150,
	img = G.newImage("media/rocket.png"),
	model = { -16, 16, -4, -20, 4, -20, 16, 16 }
}
genQuads(RocketEnemy, 16)
function RocketEnemy:init(rand, x, y, wall)
	self:super(rand, x, y)
	self.vx = 0
	self.vy = 0
	self.nx = 0
	self.ny = 0
	self.rocketSound = nil
	if wall == "up"		then self.ny =1  end
	if wall == "down"	then self.ny =-1  end
	if wall == "left"	then self.nx =1  end
	if wall == "right"	then self.nx =-1  end
	self.ang = math.atan2(-self.nx, -self.ny)
	transform(self)
	self.active = false
end
function RocketEnemy:hit(x)
	Enemy.hit(self, x)
	if self.rocketSound then self.rocketSound:stop() end
end
function RocketEnemy:subUpdate()
	self.y = self.y + game.walls.speed

	if not self.active and game.player.alive then
		transform(self)
		local dx = game.player.x - self.x
		local dy = game.player.y - self.y
		local dot = self.nx * dx + self.ny * dy
		if dot > 0 then
			local cross = self.nx * dy - self.ny * dx
			if math.abs(cross) < 50 then
				self.active = true
				self.rocketSound = playRocketSound()
			end
		end
	end
	if self.active then
		if self.tick % 4 == 0 then
			local sm = SmokeParticle(self.x - self.nx * 16, self.y - self.ny * 16)
			sm.dx = 0
			sm.dy = 0
			sm.ttl = 8
		end
		self.vx = self.vx + self.nx * 0.1
		self.vy = self.vy + self.ny * 0.1
		self.x = self.x + self.vx
		self.y = self.y + self.vy
		transform(self)
		local d, n, w = game.walls:checkCollision(self.trans_model)
		if d > 0 then
		    self:hit(self.shield)
	    end
	end
end

local rocketSoundData = love.sound.newSoundData("media/rocket.ogg")
function playRocketSound()
	local source = love.audio.newSource(rocketSoundData)
	love.audio.play(source)
	return source
end


