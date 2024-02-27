local Talk = {
	disabled = false,
	talks = {
		[1] = {
			speaker = '???',
			content = 'Help! Help!',
			answers = {}
		},
		[2] = {
			speaker = '???',
			content = 'Hello? Is anyone here? Help!!!',
			answers = {}
		},
		[3] = {
			speaker = '???',
			content = 'Um..um, thank you! You just saved THE BLOCK MASTER!',
			answers = {}
		},
		[4] = {
			speaker = '???',
			content = 'What? You don\'t know me? I am Blocki. THE! BLOCK! MASTER!!!',
			answers = {}
		},
		[5] = {
			content = 'Oh, you are new here. I forgive you... for this time.',
			answers = {}
		},
		[6] = {
			content = 'Ah, hurry up! There is important thing in the house!',
			answers = {}
		},
		[7] = {
			content = 'Come on, follow me, you can help.',
			answers = {}
		},
		[8] = {
			content = 'Look! This workbench allows people to create objects from blocks! IT WILL SAVE OUR WORLD!',
			answers = {}
		},
		[9] = {
			content = 'Yes, our world, the Blockverse, has no creations for a long time. The workbench can bring creations back to our world!',
			answers = {}
		},
		[10] = {
			content = 'But, just a little accident...',
			answers = {}
		},
		[11] = {
			content = 'It\'s broken... What should I do...',
			answers = {}
		},
		[12] = {
			content = 'Wow! What did you do? You fixed it?!!',
			answers = {}
		},
		[13] = {
			content = 'Maybe you can use it? Could you fix the TV too? You can do it on the workbench.',
			answers = {}
		},
		[14] = {
			content = 'Amazing! Who holy are you?',
			answers = {'Newcomer', 'THE BLOCK MASTER'}
		},
		[15] = {
			content = 'I haven\'t watched TV in a long time, let\'s put it into room!',
			answers = {}
		},
		[16] = {
			content = 'Look at that! It\'s a TV of Creations, you can find great creations in it!',
			answers = {}
		},
		[17] = {
			content = 'Almost forgot! You might need these.',
			answers = {}
		},
		[18] = {
			speaker = '',
			content = '',
			answers = {}
		},
		[19] = {
			speaker = '',
			content = 'You obtain 50 coins!',
			answers = {}
		},
		[20] = {
			content = 'Come on, I can\'t wait to see them in the room!',
			answers = {}
		},
		[21] = {
			content = 'Amazing! Look at the room! It\'s great,isn\'t it?',
			answers = {}
		},
		[22] = {
			content = 'May be you are THE ONE.',
			answers = {}
		},
		[23] = {
			content = 'I made a choice! I give you this island now, you gotta make it a dream land!',
			answers = {'Ah?…OK?', 'Great!'}
		},
		[24] = {
			content = 'HAHA! I knewn it!',
			answers = {}
		},
		[25] = {
			content = 'This is your island now, give it a cool name!',
			answers = {}
		},
		[26] = {
			content = 'xxx, great name!',
			answers = {}
		},
		[27] = {
			content = 'Come on, you have more to see.',
			answers = {}
		},
		[28] = {
			content = 'A lot of new faces have come in recently, you can visit their islands too.',
			answers = {}
		},
		[29] = {
			content = 'There is a bus stop, you can visit other islands from it.',
			answers = {}
		},
		[30] = {
			content = 'These themed rooms are really cool, aren\'t they? Which theme do you like most?',
			answers = {'Fashion', 'Sweet', 'Childish'}
		},
		[31] = {
			content = 'I knew it! It\'s my favourite theme too!',
			answers = {}
		},
		[32] = {
			content = 'Here you are, this is my treasure, a good creation of xxx theme.',
			answers = {}
		},
		[33] = {
			content = 'Can\'t wait to see the xxx themed room you made. Try to put more assets of xxx theme in the room, and no other assets of different themes.',
			answers = {}
		},
		[34] = {
			content = 'Oh, two more things I forgot to tell you.',
			answers = {}
		},
		[35] = {
			content = 'This is the decoration bucket. If you don\'t think the room is big enough, you can expand it here!',
			answers = {}
		},
		[36] = {
			content = 'This is mailbox. You may need to check it.',
			answers = {}
		},
		[37] = {
			content = 'Okay, that\'s all! Let\'s see your work on the island! I\'m so looking forward to it!',
			answers = {}
		},
		[38] = {
			content = 'Hey, here\'s a cool thing for you to see.',
			answers = {}
		},
		[39] = {
			content = 'In Blockverse, everyone can transform into a variety of appearances, we call it \'avatar\'.',
			answers = {}
		},
		[40] = {
			content = 'You can build your own avatar in the workshop, and people who are as great as you should be able to make coolest avatars!',
			answers = {}
		},
		[41] = {
			content = 'WOW! Great work! I want an avatar like this too!',
			answers = {}
		},
		[42] = {
			content = 'Go to workshop, you can wear your avatar now!',
			answers = {}
		},
		[43] = {
			content = 'HAHA! Look at you! You look amazing! Can\'t wait for others to see it too!',
			answers = {}
		},
		[44] = {
			content = 'Just in time, Griffin Park is open and you can go meet other people, they are friendly and fun too!',
			answers = {}
		},
		[101] = {
			content = 'Congratulations! You did great job! It\'s so right to give you this island! You are a real Block Master!',
			answers = {}
		},
		[102] = {
			content = 'Can\'t wait to see the xxx themed room you made. Try to put more assets of xxx theme in the room, and no other assets of different themes.',
			answers = {''}
		},
		[103] = {
			content = 'I have some broken creations here, can you help me fix it?',
			answers = {'Yes', 'Maybe next time'}
		},
		[104] = {
			content = 'Nice work! You might need this.',
			answers = {}
		}
	},
	answerFuncs = {},
	timer = _Timer.new(),
}

local ui = Global.UI:new('Talk.bytes', 'screen')
ui.visible = false

Global.Talk = Talk

Talk.setAnswerFunctions = function(self, funcs)
	self.answerFuncs = funcs or {}
end

Talk.onChoose = function(self, index)
	local func = self.answerFuncs[index]
	self.answerFuncs = {}
	if func then
		func()
	end
end

Talk.setSpeaker = function(self, speaker)
	ui.speaker.text = speaker
end

Talk.setDisabled = function(self, disabled)
	self.disabled = disabled
	ui.next.visible = disabled == false
end

Talk.setContent = function(self, content)
	self.content = content
	ui.content.text = ''
	ui.contentbg.visible = content ~= ''
	self:fillContent()
end

Talk.fillContent = function(self)
	ui.bg.visible = true
	self.timer:stop()
	local count = string.fwordLength(self.content, true)
	local index = 0
	self.timer:start('fill', 10, function()
		index = index + 1
		if count > 0 then
			ui.content.text = string.sub(self.content, 1, string.fgetLenByWordLength(self.content, index, true))
		end
		if index >= count then
			self.timer:stop('fill')
			self:showNext()
		end
	end)
end
Talk.skipFillContent = function(self)
	ui.content.text = self.content
	self.timer:stop('fill')
	self:showNext()
end

Talk.showNext = function(self)
	if ui.answers.itemNum > 0 then
		ui.answers.visible = true
		ui.bg.visible = false
	else
		ui.next.visible = true
		ui.bg.visible = true
	end
end

Talk.setAnswers = function(self, answers)
	ui.answers.onRenderItem = function(index, item)
		local answser = answers[index]
		item.title.text = answser
		item.click = function()
			if self.disabled then return end

			self:exit()
			self:onChoose(index)
		end
	end
	ui.answers.itemNum = #answers
	ui.answers.visible = false
	ui.next.visible = false
	self:fillContent()
end

Talk.show = function(self, talkid)
	self.tick = os.now()
	Global.UI:pushAndHide('normal')
	ui.visible = true
	ui._y = 200
	Global.UI.mmanager:addMovment(ui, {x = ui._x, y = 0}, 500)
	ui:gotoAndPlay('show')
	Global.UI.vmanager:addVisible(ui, true, 200)
	if self.fristShow ~= true then
		Global.Sound:play('ui_selectmusic')
		self.fristShow = true
	else
		Global.Sound:play('ui_hint04')
	end
	local talk = self.talks[talkid]
	self:setSpeaker(talk.speaker or 'blocki')
	self:setContent(talk.content or '')
	ui.speakerbg.visible = true
	if ui.speaker.text == '' or self.content == '' then
		ui.speakerbg.visible = false
	end
	self:setAnswers(talk.answers or {})
	ui.bg.click = function()
		if self.disabled or (os.now() - self.tick < 500) then return end

		if ui.content.text ~= self.content then
			self:skipFillContent()
			return
		end

		self:exit()
		self:onChoose(1)
	end
end

Talk.exit = function(self)
	Global.UI:popAndShow('normal')
	ui._y = 0
	Global.UI.mmanager:addMovment(ui, {x = ui._x, y = 200}, 200)
	ui:gotoAndPlay('hide')
	Global.UI.vmanager:addVisible(ui, false, 200)
	ui.bg.visible = false
end
