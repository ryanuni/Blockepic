local objectOPfunctions = {
	['play'] = {title = 'Play', icon = '', func = function()
		Global.LevelManager:findDataAndGo('checkpoint.sen', '#Platformer')

		Global.Achievement:ask('lobby_unlock')
		Global.Achievement:ask('shop_unlock')
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return not Version:isDemo() and not Global.Achievement:check('lobby_unlock')
	end},
	['leavelobby'] = {title = 'Back to island', icon = 'icon_gohome_2.png', func = function()
		Global.entry:back()
	end},
	['create'] = {title = 'Create', icon = '', func = function()
		Global.LevelManager:showCreateModeUI()
	end},
	['checkpoint'] = {title = 'Play Platformer', icon = '', func = function()
		if Version:isDemo() then
			Global.LevelManager:findDataAndGo('checkpoint.sen', '#Platformer')
		else
			Global.LevelManager:showList(nil, '#Platformer')
		end
	end},
	['tetris'] = {title = 'Play Tetris', icon = '', func = function()
		Global.LevelManager:showList(nil, '#Tetris')
	end},
	['buildbrick'] = {title = 'Build Bricks', icon = 'icon_build_2.png', func = function()
		Global.entry:goBuildBrick()
	end,
	disablefunc = function()
		return _sys.os ~= 'win32' and _sys.os ~= 'mac'
	end,
	visiblefunc = function()
		if _sys:getFileName(Global.sen.name, false, false) == 'house2' then return true end
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('goouthouse')
	end},
	['myobjects'] = {title = 'My Works', icon = 'icon_showobj_3.png', func = function()
		Global.ObjectBag:showObjects(true, 'browsermine')
	end,
	visiblefunc = function()
		if _sys:getFileName(Global.sen.name, false, false) == 'house2' then return true end
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('goouthouse')
	end,
	disablefunc = function()
		return #Global.GetObjects('browsermine') == 0
	end},
	['buildscene'] = {title = 'Build Dungeon', icon = 'icon_build_2.png', func = function()
		--Global.entry:goBuildScene()
		Global.LvTemplate:show()
	end,
	disablefunc = function()
		return _sys.os ~= 'win32' and _sys.os ~= 'mac'
	end,
	visiblefunc = function()
		if _sys:getFileName(Global.sen.name, false, false) == 'house2' then return true end
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('goouthouse')
	end},
	['myscenes'] = {title = 'My Works', icon = 'icon_showobj_3.png', func = function()
		Global.ObjectBag:showObjects(true, 'browserminescene')
	end,
	visiblefunc = function()
		if _sys:getFileName(Global.sen.name, false, false) == 'house2' then return true end
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('goouthouse')
	end,
	disablefunc = function()
		return #Global.GetObjects('browserminescene') == 0
	end},
	['myblueprint'] = {title = 'Repair Asset', icon = 'icon_repair_1.png', func = function()
		Global.Blueprint:downloadMyBluePrints(nil, function()
			--Global.brickui:show('blueprint')
			Global.ObjectBag:showObjects(true, 'myblueprint')
		end)
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		local bps = Global.Blueprint:getMyBluePrints()
		return next(bps) and Global.Achievement:check('guidetalkfinish')
	end},
	-- ['templateobjects'] = {title = 'Templates', icon = 'templates.png', func = function()
		-- Global.ObjectBag:showObjects(true, 'browsertemplate')
	-- end},
	['mycollects'] = {title = 'My Favorite', icon = 'collection.png', sound = 'ui_inte06', volume = 1.0, func = function()
		Global.ObjectBag:showObjects(true, 'browsercollect')
	end,
	disablefunc = function()
		return #Global.GetObjects('browsercollect') == 0
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('fristbuyitem')
	end},
	['showbulletinboard'] = {title = 'Check Mailbox', icon = 'icon_bulletin_2.png', sound = 'ui_inte09', volume = 1.0, func = function()
		Global.Bulletin:show(true)
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('talk36')
	end},
	['showobjects'] = {title = 'Show Creations', icon = 'icon_showobj_2.png', func = function()
		Global.RegisterRemoteCbOnce('onChangeObjectRecommand', 'goBrowser', function()
			local objs = Global.getObjectRecommands()
			Global.entry:goBrowser(objs, 1, true, 'object', 'browser')
			return true
		end)

		RPC('GetRecommandObjects')
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('talk16')
	end},
	['share'] = {title = 'Share House', icon = 'icon_share_2.png', func = function()
		Global.SwitchControl:set_freeze_on()
		local ShareURL = "https://game.blockepic.com/share/"
		local myhouse = Global.getMyHouse()
		if Global.ObjectManager:check_isLocal(myhouse) then
			Global.ObjectManager:upload(myhouse)
			Notice(Global.TEXT.NOTICE_HOUSE_SHARE_ERROR)
			return
		end
		local houseid = myhouse.id
		local version = 'sharehome_' .. Featurelist.sharehome
		local browsertype = "ShowHouse"
		local name = Global.Login:getName()
		name = string.gsub(name, " ", "")

		local uploadurl = "https://game.blockepic.com/upload/"
		local curtime = _now(0.001)
		local picname1 = 'share_' .. name .. '_' .. curtime .. '_1.bmp'
		local picname2 = 'share_' .. name .. '_' .. curtime .. '_2.bmp'
		local url1 = uploadurl .. picname1
		local url2 = uploadurl .. picname2

		-- 初始化摄像机
		local cameras = {}
		for _, v in ipairs(Global.CaptureCameras) do
			local camera = _Camera.new()
			camera.eye = v.eye
			camera.look = v.look
			camera.up = v.up
			camera.fov = v.fov
			table.insert(cameras, camera)
		end

		local content = string.format("%s?browsertype=%s&house=%d&version=%s&name=%s&time=%s", ShareURL, browsertype, houseid, version, name, curtime)
		print('content', content)
		local callback1 = function(name, md5)
			-- print('callback1', name, md5)
			Global.FileSystem:uploadTmpFile(url1, name)

			local callback2 = function(name, md5)
				-- print('callback2', name, md5)
				Global.FileSystem:uploadTmpFile(url2, name, function(res)
					if res then
						Global.Social:share(nil, content)
					else
						Notice(Global.TEXT.NOTICE_SHARE_ERROR)
					end
					Global.SwitchControl:set_freeze_off()
				end)
				Global.CaptureManager:useJPG(false)
			end
			Global.BuildHouse:capture(909, 520, cameras[2], callback2)
		end

		Global.CaptureManager:useJPG(true)
		Global.BuildHouse:capture(953, 532, cameras[1], callback1)
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('checkmailfinish')
	end},
	['buildroom'] = {title = 'Deco Room', icon = 'icon_deco_2.png', func = function()
		Global.entry:goBuildHouse()
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('repair_TV')
	end},
	['buildroom1'] = {title = 'Deco Room', icon = 'icon_deco_2.png', func = function()
		Global.entry:goBuildHouse()
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('repair_TV')
	end},
	['playmusic'] = {renderfunc = function(index, item)
		local music = Global.AudioPlayer.curSource
		if music and music.time and music.name then
			item.normalitem.visible = false
			item.musicitem.visible = true
			local function syncState()
				local state = music:getState()
				item.musicitem.play.visible = false
				item.musicitem.stop.visible = false
				item.musicitem.download.visible = false
				item.musicitem.downloading.visible = false
				if state == music.class.SOURCE_STATE.init then
					item.musicitem.download.visible = true
				elseif state == music.class.SOURCE_STATE.preparing then
					item.musicitem.downloading.visible = false
					music.onProgress = function(progress)
						item.musicitem.downloading.bar.currentValue = progress * 100
					end
				elseif state == music.class.SOURCE_STATE.prepared then
					item.musicitem.play.visible = true
				elseif state == music.class.SOURCE_STATE.playing then
					item.musicitem.stop.visible = true
				end
			end
			syncState()

			item.musicitem.play.click = function()
				Global.AudioPlayer:playCurrent()
				RPC('UpdateMyMusicPlaying', {Playing = true})
			end
			item.musicitem.stop.click = function()
				Global.AudioPlayer:stop()
				RPC('UpdateMyMusicPlaying', {Playing = false})
			end
			item.musicitem.download.click = function()
				music:prepare()
			end
			music.onStateChange = syncState

			item.musicitem.confirm.click = function()
				Global.MusicLibrary:show(true, 'MyMusic')
			end

			item.musicitem.time.text = string.ftoTimeFormat(music.time)
			item.musicitem.name.text = music.name
		else
			item.musicitem.visible = false
			item.normalitem.visible = true
			item.normalitem.title.text = 'Select Music'
			item.normalitem.c._icon = 'img://icon_music_2.png'
			item.normalitem._sound = Global.SoundList['ui_selectmusic']
			item.normalitem._soundVolumeScale = 1.0
			item.normalitem.click = function()
				Global.MusicLibrary:show(true, 'MyMusic')
			end
		end
	end,
	visiblefunc = function()
		if _sys:getFileName(Global.sen.name, false, false) == 'house2' then return true end
		if Global.House:isInMyHouse() == false then return false end
		return true
	end},
	['goparkour'] = {title = 'Parkour', icon = 'icon_level_1.png', sound = 'ui_inte08', volume = 1.0, func = function()
		Global.LevelManager:findDataAndGo('checkpoint.sen', '#Platformer')
	end},
	['buildavatar'] = {title = 'Build Bard', icon = 'icon_build_2.png', func = function()
		--Global.entry:goBuildAnima(nil, nil, 'newbard')
		Global.BardTemplate:show()
	end,
	disablefunc = function()
		return _sys.os ~= 'win32' and _sys.os ~= 'mac'
	end,
	visiblefunc = function()
		if _sys:getFileName(Global.sen.name, false, false) == 'house2' then return true end
		if Global.House:isInMyHouse() == false then return false end
		if Global.Achievement:check('talk40') and Global.Achievement:check('buildavatar') == false then return true end
		if Global.Achievement:check('talk42') and Global.Achievement:check('wearavatar') then return true end
		return false
	end},
	['dressup'] = {title = 'Dress Up', icon = 'icon_dressup_2.png', func = function()
		Global.entry:goAvatarRoom()
	end,
	visiblefunc = function()
		if _sys:getFileName(Global.sen.name, false, false) == 'house2' then return true end
		if Global.House:isInMyHouse() == false then return false end

		return Global.Achievement:check('talk42')
	end},
	['mydress'] = {title = 'My Works', icon = 'icon_showobj_3.png', func = function()
		--Global.brickui:show('mywork')

		Global.ObjectBag:showObjects(true, 'browserminedress')
	end,
	visiblefunc = function()
		if _sys:getFileName(Global.sen.name, false, false) == 'house2' then return true end
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('talk42')
	end,
	disablefunc = function()
		return #Global.GetObjects('browserminedress') == 0
	end},
	['openfame'] = {title = 'Open', icon = 'npc2.png', func = function()
		--Global.brickui:show('mywork')
		Global.fameUI:show(true)
	end,
	visiblefunc = function()
		return Global.fameUI:visible()
	end},
	['connectwallet'] = {title = 'Connect Wallet', icon = 'nft.png', func = function()
		-- connect wallet
		print('connect wallet')

		Global.Wallet:connectByWallet()
		Global.ui.interact:refresh()
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('talk42')
	end},
	['mintnft1'] = {title = 'Mint Dancer', icon = 'nft.png', func = function()
		-- Mint Dancer
		print('Mint Dancer')
		Global.ObjectManager:tmp_mint("dancer")
		if Global.Wallet:isConnect() then
			Global.Wallet:mint(1)
		end

		Global.ui.interact:refresh()
		Notice("You obtain a Dancer avatar!")
	end,
	disablefunc = function()
		-- local walletconnected = 
		if _sys:isMobile() then
			return not Global.Wallet:isConnect()
		end
		return Global.ObjectManager:tmp_check_nft("dancer") ~= nil
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('talk42')
	end},
	['mintnft2'] = {title = 'Mint Inventor', icon = 'nft.png', func = function()
		-- Mint Inventor
		print('Mint Inventor')
		Global.ObjectManager:tmp_mint("inventor")
		if Global.Wallet:isConnect() then
			Global.Wallet:mint(2)
		end
		Global.ui.interact:refresh()
		Notice("You obtain an Inventor avatar!")
	end,
	disablefunc = function()
		if _sys:isMobile() then
			return not Global.Wallet:isConnect()
		end
		return Global.ObjectManager:tmp_check_nft("inventor") ~= nil
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('talk42')
	end},
	['buildrepair'] = {title = 'Build Repair', icon = 'icon_repair_2.png', func = function()
		Global.entry:goBuildRepair()
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return true
	end},
	['repair'] = {title = 'repair', icon = 'icon_repair_1.png', func = function()
		Global.entry:goRepair('repair_TV')
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return true
	end},
	['repairbridge'] = {title = 'repair', icon = 'icon_repair_1.png', func = function()
		Global.entry:goRepair('repair_bridge')
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.sen:getBlockByShape('Broken_bridge').node.visible
	end},
	['repairwork'] = {title = 'Repair', icon = 'icon_repair_1.png', func = function()
		Global.entry:goRepair('repair_work')
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('talk11') and Global.Achievement:check('repair_work') == false
	end},
	['repairTV'] = {title = 'Repair TV', icon = 'icon_repair_1.png', func = function()
		Global.entry:goRepair('repair_TV')
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('talk13') and Global.Achievement:check('repair_TV') == false
	end},
	['help'] = {title = 'Remove Clutter', icon = 'icon_talk_1.png', func = function()
		Global.Achievement:register('helpblocki', function()
			Global.gmm:startMovie('helpblocki')
			Global.gmm:syncGuideStep()
			Global.gmm:disableBlockiTalk()
		end)
		Global.Achievement:ask('helpblocki')
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.Achievement:check('helpblocki') == false
	end},
	['talk'] = {title = 'Talk', icon = 'icon_talk_2.png', func = function()
		local step = Global.gmm:getCurStep()
		assert(step, 'no step!!!!')
		print('talk', step.name)
		Global.gmm:disableBlockiTalk()
		Global.gmm:startMovie(step.name)
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		if Global.Achievement:check('helpblocki') == false then return false end
		if Global.gmm.blockitalkdisable then return false end

		local step = Global.gmm:getCurStep()
		if step then
			print(step.name, step.canbegin)
			return step.canbegin
		end

		return false
	end},
	['themeroom'] = {title = 'Theme Room', icon = 'icon_talk_2.png', volume = 0, func = function()
		Global.DailyTasks:getHouseThemedTask(function(resule, data)
			if data.level == nil then
				Global.Talk:show(101)
				return
			end

			-- print('getHouseThemedTask', result, table.ftoString(data))
			Global.Talk:show(102)
			if data.level == 1 then
				Global.Talk:setContent('Can\'t wait to see the ' .. data.theme .. ' themed room you made. Try to put more assets of ' .. data.theme .. ' theme in the room, and no other assets of different themes.')
			else
				local desc = ''
				for i = 1, data.level do
					desc = desc .. genHtmlImg('star.png', 48, 48)
				end
				Global.Talk:setContent('I want to see a cooler ' .. data.theme .. ' themed room, at least ' .. desc .. ', can you do that?')
			end

			local myhouse = Global.getMyHouse()
			local tag, level
			if myhouse and myhouse.housetag and myhouse.housetag ~= '' then
				tag = Global.totag(myhouse.housetag)
				level = Global.tolevel(myhouse.housetag)
			end
			if tag and level and tag == '#' .. data.theme and level >= data.level then
				Global.Talk:setAnswerFunctions({function()
					Global.Talk:show(104)
					Global.Talk:setAnswerFunctions({function()
						Global.DailyTasks:doneHouseThemedTask(data)
					end})
				end})
				Global.Talk:setAnswers({'I made it!'})
			else
				Global.Talk:setAnswerFunctions()
				Global.Talk:setAnswers({'OK, I\'m on it.'})
			end
			-- print(myhouse.housetag, tag, level)
		end)
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end

		if Global.Achievement:check('guidetalkfinish') then return true end
		return false
	end},
	['introduce'] = {title = 'Introduce', icon = 'icon_talk_1.png', func = function()
		Global.Introduce:show('brief')
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end

		if Global.Achievement:check('guidetalkfinish') then return true end
		return false
	end},
	['autorepairportal'] = {title = 'Auto Repair', icon = 'icon_repair_2.png', func = function()
		Global.PortalFixTask:addSubProgress()
		Global.FameTask:doTask('Fix_Portal')
		Global.ui.interact:refresh()
	end,
	disablefunc = function()
		--print(' Global.ObjectManager:getAstronautAvatarCount()', Global.ObjectManager:getAstronautAvatarCount())
		return not ((Global.OpenAutoRepair or Global.ObjectManager:getAstronautAvatarCount() >= 5)
			and (Global.PortalFixTask.subprogress or 0) < 100)
		-- return true
	end},
	['famerank'] = {title = 'Fame Rank', icon = 'fame.png', func = function()
		Global.Leaderboard_fame:camera_focus(true)
		-- print('famerank')
	end},
	['brawlrank'] = {title = 'Brawl Rank', icon = 'lookin_2.png', func = function()
		Global.Leaderboard_brawl:updateUI('normal')
		Global.Leaderboard_brawl:camera_focus(true)
		-- print('brawlrank')
	end},
	['brawlgamenightrank'] = {title = 'Game Night Rank', icon = 'lookin_2.png', func = function()
		Global.Leaderboard_brawl:updateUI('event')
		Global.Leaderboard_brawl:camera_focus(true)
		-- print('brawlrank')
	end},
	['neveruprank_single'] = {title = 'Single Rank', icon = 'lookin_2.png', func = function()
		Global.Leaderboard_neverup:updateUI('single')
		Global.Leaderboard_neverup:camera_focus(true)
		-- print('neveruprank_single')
	end},
	['neverupsingle_gamenight'] = {title = 'Game Night Rank', icon = 'lookin_2.png', func = function()
		Global.Leaderboard_neverup:updateUI('event')
		Global.Leaderboard_neverup:camera_focus(true)
		-- print('brawlrank')
	end},
	-- ['neveruprank_multi'] = {title = 'Match Rank', icon = 'lookin_2.png', func = function()
	-- 	Global.Leaderboard_neverup:updateUI('multi')
	-- 	Global.Leaderboard_neverup:camera_focus(true)
	-- 	-- print('neveruprank_multi')
	-- end},
	['joinbrawlgamenight'] = {icon = 'brawl_2.png', func = function()
		local info = Global.GameEvent:get('blockbrawl')
		if info.event == nil then return end
		if info.state == 0 then
			Global.ui.interact:refresh()
			return
		end

		Global.BlockBrawlEntry:camera_focus(true)
		-- print('joinbrawl')
		Global.Room_New:Join({count = 4, game = 'puzzle_brawl', eventid = info.event.id}, {
			waiting_update = function(current, total)
				-- print('waiting_update', current, total, debug.traceback())
				Global.BlockBrawlEntry:updateMatchUI(current, total)
			end,
			waiting_leave = function()
				-- print('waiting_leave', debug.traceback())
				Global.BlockBrawlEntry:updateMatchUI()
			end,
			prepare = function(players, randomseed, data)
				-- print('prepare', debug.traceback())
				Global.Timer:add('goblockbrawl', 3000, function()
					Global.BlockBrawlEntry:updateMatchUI()
					Global.entry:goBlockBrawl(players, randomseed, data.countdown_second)
				end)
			end,
			start = function()
				-- print('start', debug.traceback())
				Global.BlockBrawlEntry:prepare_to_start(function()
					Global.BlockBrawl:initGame()
				end)
			end,
			do_op = function(data)
				-- print('do_op', data, debug.traceback())
				Global.BlockBrawl:doOperation(data)
			end,
			finish = function(data)
				local rank = data.rank
				-- print('finish', dump(rank), debug.traceback())

				if not rank[1].score then -- fake data
					rank = {
						{name = 'test', score = 100},
						{name = 'test', score = 80},
						{name = 'test', score = 900},
						{name = 'test', score = -10}
					}
				end
				Global.BlockBrawl:showFinish(rank)
			end
		})
	end,
	disablefunc = function()
		local info = Global.GameEvent:get('blockbrawl')
		if info.state ~= 1 then return true end

		return info.event.num - info.num <= 0
	end,
	visiblefunc = function()
		local info = Global.GameEvent:get('blockbrawl')
		return info.state == 1
	end,
	getTitle = function()
		local info = Global.GameEvent:get('blockbrawl')
		if info.num == nil then return '' end

		local total = info.event.num
		local left = info.num
		return 'Game Night ' .. tonumber(total - left) .. '/' .. total
	end},
	['joinbrawl'] = {title = 'Join Brawl', icon = 'brawl_2.png', func = function()
		Global.BlockBrawlEntry:camera_focus(true)
		-- print('joinbrawl')
		Global.Room_New:Join({count = 4, game = 'puzzle_brawl'}, {
			waiting_update = function(current, total)
				-- print('waiting_update', current, total, debug.traceback())
				Global.BlockBrawlEntry:updateMatchUI(current, total)
			end,
			waiting_leave = function()
				-- print('waiting_leave', debug.traceback())
				Global.BlockBrawlEntry:updateMatchUI()
			end,
			prepare = function(players, randomseed, data)
				-- print('prepare', debug.traceback())
				Global.Timer:add('goblockbrawl', 3000, function()
					Global.BlockBrawlEntry:updateMatchUI()
					Global.entry:goBlockBrawl(players, randomseed, data.countdown_second)
				end)
			end,
			start = function()
				-- print('start', debug.traceback())
				Global.BlockBrawlEntry:prepare_to_start(function()
					Global.BlockBrawl:initGame()
				end)
			end,
			do_op = function(data)
				-- print('do_op', data, debug.traceback())
				Global.BlockBrawl:doOperation(data)
			end,
			finish = function(data)
				local rank = data.rank
				-- print('finish', dump(rank), debug.traceback())

				if not rank[1].score then -- fake data
					rank = {
						{name = 'test', score = 100},
						{name = 'test', score = 80},
						{name = 'test', score = 900},
						{name = 'test', score = -10}
					}
				end
				Global.BlockBrawl:showFinish(rank)
			end
		})
	end},
	['brawl2'] = {title = 'brawl2', icon = 'icon_repair_2.png', func = function()
		-- Global.BrawlRank:camera_focus(true)
		print('brawl2')
		Global.Room_New:Leave()
	end},
	never_browse = {
		title = 'Show Dungeons',
		icon = 'brawl_2.png',
		sound = 'ui_inte06',
		func = function()
			local objs = {}
			local obj = Global.GameInfo:get_object('neverup')
			table.insert(objs, obj)
			obj = Global.GameInfo:get_object('neverdown')
			table.insert(objs, obj)
			Global.entry:goBrowser(objs, 1, true, 'scene', 'browser')
		end,
	},
	never_random = {
		title = 'Random',
		icon = 'brawl_2.png',
		sound = 'ui_inte06',
		func = function()
			local obj = Global.ObjectManager:getObject('never_random')
			Global.entry:goBrowser({obj}, 1, true, 'scene_random', 'browser')
		end,
	},
	never_favourite = {
		title = 'My Favorite',
		icon = 'collection.png',
		sound = 'ui_inte06',
		volume = 1.0,
		func = function()
			Global.entry:goBrowser(Global.GetObjects('never_game'), 1, true, 'scene', 'browser')
		end,
		disablefunc = function()
			return #Global.GetObjects('never_game') == 0
		end,
	},
	music_browse = {
		title = 'Show Dungeon',
		icon = 'brawl_2.png',
		sound = 'ui_inte06',
		func = function()
			Global.RegisterRemoteCbOnce('onChangeObjectRecommand', 'goBrowser', function()
				local objs = Global.getObjectRecommands()
				Global.entry:goBrowser(objs, 1, true, 'scene_music', 'browser')
				return true
			end)

			RPC('GetSceneList')
		end,
	},
	music_random = {
		title = 'Random',
		icon = 'brawl_2.png',
		sound = 'ui_inte06',
		func = function()
			local obj = Global.ObjectManager:getObject('music_random')
			Global.entry:goBrowser({obj}, 1, true, 'scene_random', 'browser')
		end,
	},
	music_favourite = {
		title = 'My Favorite',
		icon = 'collection.png',
		sound = 'ui_inte06',
		volume = 1.0,
		func = function()
			Global.entry:goBrowser(Global.GetObjects('music_scene'), 1, true, 'scene_music', 'browser')
		end,
		disablefunc = function()
			return #Global.GetObjects('music_scene') == 0
		end,
	},
	
	['browse_scene'] = {title = 'Show Dungeons', icon = 'brawl_2.png', func = function()
		Global.RegisterRemoteCbOnce('onChangeObjectRecommand', 'goBrowser', function()
			local objs = Global.getObjectRecommands()
			Global.entry:goBrowser(objs, 1, true, 'scene', 'browser')
			return true
		end)

		RPC('GetSceneList')
	end,
	visiblefunc = function()
		return true
	end},
	['collects_scene'] = {title = 'My Favorite', icon = 'collection.png', sound = 'ui_inte06', volume = 1.0, func = function()
		Global.ObjectBag:showObjects(true, 'browsercollectscene')
	end,
	disablefunc = function()
		return #Global.GetObjects('browsercollectscene') == 0
	end},
	['obtainfame'] = {title = 'Obtain Fame', icon = 'fame.png', volume = 0, func = function()
		-- TODO:
		Global.ObtainFame:obtainFame()
		--Global.FameTask:obtainFameEarn()
		Global.ui.interact:refresh()
	end,
	disablefunc = function()
		local n = Global.ObtainFame:getFameCount()
		return n == 0
	end,
	visiblefunc = function()
		return true
	end},
	['repairportal'] = {title = 'Repair', icon = 'icon_repair_1.png', volume = 0, func = function()
		local level = math.random(1, 5)
		if not Global.repairPortalKeys then
			Global.repairPortalKeys = {}
		end
		local rl = Global.randomNewRepairLevel(level, Global.repairPortalKeys)
		--local rl = Global.getRepairLevel(level)
		if rl then
			Global.entry:goRepair(rl.file)
		end
	end,
	visiblefunc = function()
		return true
	end},
	['repairthings'] = {title = 'Repair Things', icon = 'icon_repair_1.png', volume = 0, func = function()
		Global.DailyTasks:getFixTask(function(result, data)
			local rl = Global.getRepairLevel(data.level)
			if rl then
				Global.Talk:show(103)
				Global.Talk:setAnswerFunctions({function()
					Global.entry:goRepair(rl.file, data.level)
				end,
				function()
				end})
			end
		end)
	end,
	disablefunc = function(u)
		Global.DailyTasks:getFixTask(function(result, data)
			if u and data.level then
				u.disabled = Global.getRepairLevel(data.level) == nil
			end
		end)
		return true
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end

		if Global.Achievement:check('guidetalkfinish') then return true end
		return false
	end},
	['changeislandname'] = {title = 'Rename Island', icon = 'icon_deco_1.png', volume = 0, func = function()
		Global.Island.onEditName = function()
			if Global.House:isInMyHouse() then
				local home = Global.getMyHouse()
				if home then
					Global.House:changeBoardImage(home)
				end
			end
		end
		Global.Island:editName()
	end,
	visiblefunc = function()
		if Global.House:isInMyHouse() == false then return false end
		return Global.getMyHouse().name ~= 'housedefault'
	end},
	['mario1'] = {title = 'Mario 1', icon = 'brawl_2.png', volume = 0, func = function()
		Global.MarioEntry:camera_focus(true)
		Global.Room_New:Join({count = 2, game = 'platform_jump', data1 = '7J9G3T3WF.dungeon'}, {
			waiting_update = function(current, total)
				-- print('waiting_update', current, total, debug.traceback())
				Global.MarioEntry:updateMatchUI(current, total)
			end,
			waiting_leave = function()
				-- print('waiting_leave', debug.traceback())
				Global.MarioEntry:updateMatchUI()
			end,
			prepare = function(players, randomseed, data)
				-- print('prepare', debug.traceback())
				Global.Timer:add('gomario', 3000, function()
					Global.MarioEntry:updateMatchUI()
					if randomseed then
						math.randomseed(randomseed)
					end
					Global.entry:goMario(data.data1, players, 'multiple')
				end)
			end,
			start = function()
				-- print('start', debug.traceback())
				Global.Mario:prepare_to_start()
			end,
			do_op = function(data)
				-- print('do_op', data, debug.traceback())
				Global.Mario:doOperation(data)
			end,
			finish = function(rank)
				-- print('finish', dump(rank), debug.traceback())
				Global.Mario:showFinish(rank)
			end
		})
	end},
	['mario2'] = {title = 'Mario 2', icon = 'brawl_2.png', volume = 0, func = function()
		Global.MarioEntry:camera_focus(true)
		Global.Room_New:Join({count = 2, game = 'platform_jump', data1 = '8X80Y3LQF.dungeon'}, {
			waiting_update = function(current, total)
				-- print('waiting_update', current, total, debug.traceback())
				Global.MarioEntry:updateMatchUI(current, total)
			end,
			waiting_leave = function()
				-- print('waiting_leave', debug.traceback())
				Global.MarioEntry:updateMatchUI()
			end,
			prepare = function(players, randomseed, data)
				-- print('prepare', debug.traceback())
				Global.Timer:add('gomario', 3000, function()
					Global.MarioEntry:updateMatchUI()
					if randomseed then
						math.randomseed(randomseed)
					end
					Global.entry:goMario(data.data1, players, 'multiple')
				end)
			end,
			start = function()
				-- print('start', debug.traceback())
				Global.Mario:prepare_to_start()
			end,
			do_op = function(data)
				-- print('do_op', data, debug.traceback())
				Global.Mario:doOperation(data)
			end,
			finish = function(rank)
				-- print('finish', dump(rank), debug.traceback())
				Global.Mario:showFinish(rank)
			end
		})
	end},
	['mario3'] = {title = 'Mario 3', icon = 'brawl_2.png', volume = 0, func = function()
		Global.MarioEntry:camera_focus(true)
		Global.Room_New:Join({count = 2, game = 'platform_jump', data1 = 'XYNNWND4G.dungeon'}, {
			waiting_update = function(current, total)
				-- print('waiting_update', current, total, debug.traceback())
				Global.MarioEntry:updateMatchUI(current, total)
			end,
			waiting_leave = function()
				-- print('waiting_leave', debug.traceback())
				Global.MarioEntry:updateMatchUI()
			end,
			prepare = function(players, randomseed, data)
				-- print('prepare', debug.traceback())
				Global.Timer:add('gomario', 3000, function()
					Global.MarioEntry:updateMatchUI()
					if randomseed then
						math.randomseed(randomseed)
					end
					Global.entry:goMario(data.data1, players, 'multiple')
				end)
			end,
			start = function()
				-- print('start', debug.traceback())
				Global.Mario:prepare_to_start()
			end,
			do_op = function(data)
				-- print('do_op', data, debug.traceback())
				Global.Mario:doOperation(data)
			end,
			finish = function(rank)
				-- print('finish', dump(rank), debug.traceback())
				Global.Mario:showFinish(rank)
			end
		})
	end},
	['mario4'] = {title = 'Mario 4', icon = 'brawl_2.png', volume = 0, func = function()
		Global.MarioEntry:camera_focus(true)
		Global.Room_New:Join({count = 3, game = 'platform_jump', data1 = 'V8Q532KFG.dungeon'}, {
			waiting_update = function(current, total)
				-- print('waiting_update', current, total, debug.traceback())
				Global.MarioEntry:updateMatchUI(current, total)
			end,
			waiting_leave = function()
				-- print('waiting_leave', debug.traceback())
				Global.MarioEntry:updateMatchUI()
			end,
			prepare = function(players, randomseed, data)
				-- print('prepare', debug.traceback())
				Global.Timer:add('gomario', 3000, function()
					Global.MarioEntry:updateMatchUI()
					if randomseed then
						math.randomseed(randomseed)
					end
					Global.entry:goMario(data.data1, players, 'multiple')
				end)
			end,
			start = function()
				-- print('start', debug.traceback())
				Global.Mario:prepare_to_start()
			end,
			do_op = function(data)
				-- print('do_op', data, debug.traceback())
				Global.Mario:doOperation(data)
			end,
			finish = function(rank)
				-- print('finish', dump(rank), debug.traceback())
				Global.Mario:showFinish(rank)
			end
		})
	end},
	['mario5'] = {title = 'Mario 5', icon = 'brawl_2.png', volume = 0, func = function()
		Global.entry:goMario('NF1W0WQMG.dungeon')
		Global.ui.back.visible = false
	end},
	['mario6'] = {title = 'Mario 6', icon = 'brawl_2.png', volume = 0, func = function()
		Global.entry:goMario('RQJ4X7TMF.dungeon')
		Global.ui.back.visible = false
	end},
	['mario7'] = {title = 'Mario 7', icon = 'brawl_2.png', volume = 0, func = function()
		Global.entry:goMario('JMJCL1M0H.dungeon')
		Global.ui.back.visible = false
	end},
	['mario8'] = {title = 'Mario 8', icon = 'brawl_2.png', volume = 0, func = function()
		Global.entry:goMario('WQY7D45JF.dungeon')
		Global.ui.back.visible = false
	end},
	['mario9'] = {title = 'Mario 9', icon = 'brawl_2.png', volume = 0, func = function()
		Global.entry:goMario('J99WQHGXG.dungeon')
		Global.ui.back.visible = false
	end},
	['gogos'] = {title = 'GO MUSEUM', icon = 'icon_golobby_2.png', volume = 0, func = function()
		Global.entry:goHome3()
	end},
}

-- 5月版本仅展示需要的引导
local objectOPintroduce = {
	themeroom = {image = 'introduce_themeroom.png', text = 'Check the process of your task: themed room.'},
	buildavatar = {image = 'introduce_buildavatar.png', text = 'Build bard.'},
	buildbrick = {image = 'introduce_buildbrick.png', text = 'Build bricks.'},
	--buildscene = {image = 'introduce_buildbrick.png', text = 'Build scenes.'},
	buildroom = {image = 'introduce_buildroom.png', text = 'Decorate your room.'},
	buildroom1 = {image = 'introduce_buildroom.png', text = 'Decorate your room.'},
	dressup = {image = 'introduce_dressup.png', text = 'Put on your bards.'},
	mydress = {image = 'introduce_myobjects.png', text = 'View built works.'},
	--myscenes = {image = 'introduce_myobjects.png', text = 'View built works.'},
	expandroom = {image = 'introduce_expandroom.png', text = 'Expand your room space.'},
	introduce = {image = 'introduce_introduce.png', text = 'Check a brief introduction of Blockepic.'},
	myblueprint = {image = 'introduce_myblueprint.png', text = 'Repair things.'},
	mycollects = {image = 'introduce_mycollects.png', text = 'View your favorite creations.'},
	myobjects = {image = 'introduce_myobjects.png', text = 'View built works.'},
	repairthings = {image = 'introduce_repairthings.png', text = 'Repair things.'},
	repairportal = {image = 'introduce_repairportal.png', text = '', full = true},
	-- obtainfame = {image = 'introduce_myobjects.png', text = 'Obtain Fame.'},
	share = {image = 'introduce_share.png', text = 'Share your room with other users.'},
	showbulletinboard = {image = 'introduce_showbulletinboard.png', text = 'View received emails.'},
	showcollecthouses = {image = 'introduce_showcollecthouses.png', text = 'View your favorite rooms.'},
	showhouses = {image = 'introduce_showhouses.png', text = 'View rooms built by other users.'},
	showobjects = {image = 'introduce_showobjects.png', text = 'View creations built by other users.'},
	obtainfame = {image = 'introduce_fame.png', text = 'Obtain fame.'},
	playmusic = {image = 'introduce_music.png', text = 'Select music.'},
}

local ia = {}
local ui = Global.ui
ia.init = function(self)
	self.ui = ui.interaction
	self.main = ui.interaction.main
	self.open = ui.interaction.open
	self.objects = {}
	self.currentObject = nil

	self.ui.onSizeChange = function()
		self:resize()
	end
end
ia:init()
ia.refresh = function(self)
	local os = self.objects
	self.objects = {}
	for i = #os, 1, -1 do
		local v = os[i]
		self:addObject(v.obj, v.info)
	end
	self:sync(true)
end
ia.autoopen = function(self)
	if self.open.visible then
		self.open.click()
	end
end
ia.attach = function(self, obj, info)
	self:delObject(obj)
	self:addObject(obj, info)
	self:sync()
end

ia.addObject = function(self, obj, info)
	local funcdata = {}
	funcdata.add = true
	funcdata.sound = info.sound
	funcdata.volume = info.volume
	for i, v in ipairs(info.data) do
		local d = objectOPfunctions[v]
		if d and (d.visiblefunc == nil or d.visiblefunc()) then
			d.key = v
			table.insert(funcdata, d)
		end
		if v == 'play' then
			local d = objectOPfunctions['lobby']
			if d and (d.visiblefunc == nil or d.visiblefunc()) then
				d.key = 'lobby'
				table.insert(funcdata, d)
			end
		end
		if v == 'hide' then
			funcdata.add = false
		end
	end
	if funcdata.add then
		table.insert(self.objects, 1, {obj = obj, funcdata = funcdata, info = info})
	end
end

ia.delObject = function(self, obj)
	for i, v in ipairs(self.objects) do
		if v.obj.data.shape == obj.data.shape then
			table.remove(self.objects, i)
			break
		end
	end
end

ia.sync = function(self, refresh)
	local fristobj = nil
	for i, v in ipairs(self.objects) do
		if #v.funcdata > 0 then
			fristobj = v
			break
		end
	end
	if fristobj then
		if self.currentObject ~= fristobj.obj or refresh then
			self:show(fristobj.obj, fristobj.funcdata)
		end
	else
		self:hide()
	end
end

ia.resize = function(self)
	local n = self.main.list.itemNum
	self.main.list._height = 204 * n
	if _app:isScreenH() then -- 1 column
		self.main._y = self.ui._height - 60 - self.main.list._height
		-- self.open._y = self.ui._height - 300
	else
		self.main._y = self.ui._height - 660 - self.main.list._height
		-- self.open._y = self.ui._height - 840
	end
end

ia.show = function(self, obj, funcdata)
	self.currentObject = obj
	self.ui:gotoAndPlay('show')
	self.open.visible = true
	if self.main.visible then
		self.main:gotoAndPlay('hideitem')
	end
	local oi = Global.ObjectIcons[obj.data.shape .. '_1'] or (obj.name and Global.ObjectIcons[obj.name .. '_1'])
	if oi then
		self.open.icon._icon = 'img://' .. oi
	else
		self.open.icon._icon = 'ui://22xbi68luovr33oo9'
	end

	Global.Sound:play('ui_inte01')

	self.open.click = function()
		Global.Sound:play(funcdata.sound)
		_sys:vibrate(30)
		self.open.visible = false
		self.main.list.onRenderItem = function(index, item)
			local fdata = funcdata[index]
			item._soundVolumeScale = 0.0
			if fdata.renderfunc then
				fdata.renderfunc(index, item)
			else
				item.musicitem.visible = false
				item.normalitem.visible = true
				item.normalitem.title.text = fdata.title or fdata:getTitle()
				item.normalitem.c._icon = fdata.icon == '' and fdata.icon or 'img://' .. fdata.icon
				local sound = fdata.sound or 'ui_default'
				item.normalitem._sound = Global.SoundList[sound]
				item.normalitem._soundVolumeScale = fdata.volume or 1.0
				item.normalitem.click = function()
					fdata.func(item.normalitem)
				end
				item.disabled = false
				if fdata.disablefunc then
					item.disabled = fdata.disablefunc(item)
				end
			end
		end
		self.main.list.itemNum = #funcdata

		self:resize()

		self.main:gotoAndPlay('showitem')

		Global.AddHotKeyFunc(_System.KeyESC, function()
			return self.main.visible
		end, function()
			self:sync(true)
			-- self.main:gotoAndPlay('hideitem')
		end)

		ui.introduceguide.click = function()
			ui.introduceguide.visible = false
			self:showIntroduce(funcdata)
		end

		ui.funcintroduce.fg.click = function()
			self:hideIntroduce()
		end

		local needintroduce = false
		for i, v in ipairs(funcdata) do
			print(v.key, objectOPintroduce[v.key])
			if objectOPintroduce[v.key] then
				needintroduce = true
				break
			end
		end

		if needintroduce then
			local achievement = 'introduce' .. funcdata[1].key
			if Global.Achievement:check(achievement) then
				ui.introduceguide.visible = true
			else
				self:showIntroduce(funcdata)
				Global.Achievement:ask(achievement)
			end
		end
	end
	ui.introduceguide.visible = false
	Global.EmojiChat.syncSkillVisible()
end

ia.hide = function(self)
	self.ui:gotoAndPlay('hide')
	self.open.visible = false
	if self.main.visible then
		self.main:gotoAndPlay('hideitem')
	end
	self.currentObject = nil
	self:hideIntroduce()
	ui.introduceguide.visible = false
	Global.EmojiChat.syncSkillVisible()
end

ia.clear = function(self)
	self:hide()
	self.objects = {}
end

ia.print = function(self)
	print('------------------------------')
	for i, v in ipairs(self.objects) do
		print(i, v.obj.data.shape, #v.funcdata)
	end
	print('++++++++++++++++++++++++++++++')
end

ia.hideIntroduce = function(self)
	ui.introduceguide.visible = true
	ui.funcintroduce.visible = false
	ui.funcintroducebg.visible = false
end

ia.showIntroduce = function(self, funcdata)
	local num = #funcdata
	assert(num <= 4, 'Count of functions can not larger than 4')
	ui.introduceguide.visible = false
	ui.funcintroducebg.visible = true
	ui.funcintroduce.visible = true

	local loadervisible = false
	local loadervimage = ''
	for i = 1, 4 do
		local d = funcdata[num - i + 1]
		local opintro = d and objectOPintroduce[d.key] or nil
		ui.funcintroduce['bg' .. i].visible = opintro ~= nil
		ui.funcintroduce['text' .. i].visible = opintro ~= nil
		ui.funcintroduce['loader' .. i].visible = opintro ~= nil
		if loadervisible == false and opintro ~= nil and opintro.full then
			loadervisible = true
			loadervimage = opintro.image
		end
		if opintro then
			ui.funcintroduce['text' .. i].text = opintro.text
			ui.funcintroduce['loader' .. i]._icon = opintro.image
		end
	end
	ui.funcintroduce['loader'].visible = loadervisible
	ui.funcintroduce['loader']._icon = loadervimage
end

return ia
