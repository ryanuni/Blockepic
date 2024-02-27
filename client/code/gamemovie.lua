_dofile('cfg_theme_tasks.lua')
local defaultthemed = _G.cfg_theme_tasks[1].tag
local obj = Global.getNotObtainThemeObject(defaultthemed)
local defaultthemedobjectachievement = obj and obj.achievements and obj.achievements[1] or ''
local Container = _require('Container')

local gmm = _require('GameMovieManager')
Global.gmm = gmm

local moviedata = {
	{name = 'signup', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'idle', delay = 0, duration = 1},
		{type = 'event', name = 'moviescreenin', delay = 200, duration = 1},
		{type = 'event', name = 'setlessgravity', delay = 200, duration = 1},
		{type = 'event', name = 'animastatedisable', delay = 200, duration = 1},
		{type = 'event', name = 'floorbreak', delay = 400, duration = 1},
		{type = 'event', name = 'stopBGM', delay = 400, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'beforefall', delay = 400, duration = 1480},
		{type = 'sound', op = 'play', res = 'anima_fall01', delay = 400, duration = 1},
		{type = 'sound', op = 'play', res = 'anima_step02', delay = 430, duration = 1},
		{type = 'sound', op = 'play', res = 'anima_step02', delay = 900, duration = 1},
		{type = 'event', name = 'floornostand', delay = 2200, duration = 1},
		{type = 'event', name = 'floorhide', delay = 2500, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'struggle', delay = 2200, duration = 2000},
		{type = 'event', name = 'enablepostprocess', delay = 2500, duration = 1},
		{type = 'event', name = 'updatelocaltime', delay = 2500, duration = 1},
		{type = 'event', name = 'camerarecover', delay = 2600, duration = 500},
		{type = 'camera', lookIndex = -1, delay = 2600, duration = 500},
		{type = 'camera', followrole = true, delay = 3100, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'liedown', delay = 4100, duration = -1},
		{type = 'event', name = 'liedownsound', delay = 4100, duration = 1},
		{type = 'event', name = 'fogon', delay = 400, duration = 1},
		{type = 'event', name = 'fogfade', delay = 4100, duration = 1},
		{type = 'event', name = 'fogfade', delay = 4200, duration = 1},
		{type = 'event', name = 'fogfade', delay = 4300, duration = 1},
		{type = 'event', name = 'fogfade', delay = 4400, duration = 1},
		{type = 'event', name = 'fogfade', delay = 4500, duration = 1},
		{type = 'event', name = 'fogfade', delay = 4600, duration = 1},
		{type = 'event', name = 'fogfade', delay = 4700, duration = 1},
		{type = 'event', name = 'fogfade', delay = 4800, duration = 1},
		{type = 'event', name = 'fogfade', delay = 4900, duration = 1},
		{type = 'event', name = 'fogfade', delay = 5000, duration = 1},
		{type = 'event', name = 'fogfade', delay = 5100, duration = 1},
		{type = 'event', name = 'fogfade', delay = 5200, duration = 1},
		{type = 'event', name = 'fogfade', delay = 5300, duration = 1},
		{type = 'event', name = 'fogfade', delay = 5400, duration = 1},
		{type = 'event', name = 'fogfade', delay = 5500, duration = 1},
		{type = 'event', name = 'fogfade', delay = 5600, duration = 1},
		{type = 'event', name = 'fogfade', delay = 5700, duration = 1},
		{type = 'event', name = 'fogoff', delay = 5800, duration = 1},
		{type = 'event', name = 'vibrate', delay = 4100, duration = 1},
		{type = 'event', name = 'moviescreenout', delay = 4100, duration = 1},
		{type = 'event', name = 'showisland', delay = 4300, duration = 1},
		{type = 'event', name = 'setislandevent1', delay = 4300, duration = 1},
	}},
	{name = 'doislandevent1', actions = {
		{type = 'animation', holderIndex = -1, animaname = 'standup', delay = 0, duration = 1200},
		{type = 'animation', holderIndex = -1, animaname = 'lookaround', delay = 1500, duration = 4000},
		{type = 'animation', holderIndex = -1, animaname = 'idle', delay = 5500, duration = 1},
		{type = 'talk', talkid = 1, event = 1, delay = 5500, duration = 1},
	}},
	{name = 'talk1', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'event', name = 'enablecamera', delay = 0, duration = 1},
		{type = 'event', name = 'animastateable', delay = 0, duration = 1},
		{type = 'event', name = 'setnormalgravity', delay = 0, duration = 1},
		{type = 'event', name = 'moviescreenin', delay = 200, duration = 1},
		{type = 'camera', followrole = false, delay = 200, duration = 1},
		{type = 'camera', name = 'recordcamera', delay = 200, duration = 1},
		{type = 'camera', lookShape = 'Broken_bridge', curve = 'looknpc', delay = 200, duration = 1000},
		{type = 'camera', name = 'userecordcamera', curve = 'looknpc', delay = 2500, duration = 1000},
		{type = 'camera', followrole = true, delay = 3500, duration = 1},
		{type = 'event', name = 'moviescreenout', delay = 3500, duration = 1},
		{type = 'event', name = 'enableinput', delay = 3500, duration = 1},
		{type = 'event', name = 'recoverui', delay = 3500, duration = 1},
	}},
	{name = 'login', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'idle', delay = 0, duration = 1},
		{type = 'event', name = 'setlessgravity', delay = 200, duration = 1},
		{type = 'event', name = 'animastatedisable', delay = 200, duration = 1},
		{type = 'event', name = 'floorbreak', delay = 400, duration = 1},
		{type = 'event', name = 'fogon', delay = 400, duration = 1},
		{type = 'event', name = 'stopBGM', delay = 400, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'beforefall', delay = 400, duration = 1480},
		{type = 'sound', op = 'play', res = 'anima_fall01', delay = 400, duration = 2000},
		{type = 'sound', op = 'play', res = 'anima_step02', delay = 430, duration = 1},
		{type = 'sound', op = 'play', res = 'anima_step02', delay = 900, duration = 1},
		{type = 'event', name = 'floornostand', delay = 2200, duration = 1},
		{type = 'event', name = 'floorhide', delay = 2500, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'fall', delay = 2200, duration = 2000},
		{type = 'event', name = 'enablepostprocess', delay = 2500, duration = 1},
		{type = 'event', name = 'fogfade', delay = 2501, duration = 1},
		{type = 'event', name = 'fogfade', delay = 2550, duration = 1},
		{type = 'event', name = 'fogfade', delay = 2600, duration = 1},
		{type = 'event', name = 'fogfade', delay = 2700, duration = 1},
		{type = 'event', name = 'fogfade', delay = 2800, duration = 1},
		{type = 'event', name = 'fogfade', delay = 2900, duration = 1},
		{type = 'event', name = 'fogfade', delay = 3000, duration = 1},
		{type = 'event', name = 'fogfade', delay = 3100, duration = 1},
		{type = 'event', name = 'fogfade', delay = 3200, duration = 1},
		{type = 'event', name = 'fogfade', delay = 3300, duration = 1},
		{type = 'event', name = 'fogfade', delay = 3400, duration = 1},
		{type = 'event', name = 'fogfade', delay = 3500, duration = 1},
		{type = 'event', name = 'fogfade', delay = 3600, duration = 1},
		{type = 'event', name = 'fogfade', delay = 3700, duration = 1},
		{type = 'event', name = 'fogfade', delay = 3800, duration = 1},
		{type = 'event', name = 'fogfade', delay = 4000, duration = 1},
		{type = 'event', name = 'fogfade', delay = 4200, duration = 1},
		{type = 'event', name = 'updatelocaltime', delay = 2500, duration = 1},
		{type = 'event', name = 'camerarecover', delay = 2600, duration = 500},
		{type = 'camera', lookIndex = -1, delay = 2600, duration = 500},
		{type = 'camera', followrole = true, delay = 3100, duration = 1},
		{type = 'event', name = 'moveroletohouse', delay = 3100, duration = 1},
		{type = 'event', name = 'vibrate', delay = 4100, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'idle', delay = 4100, duration = 1},
		{type = 'event', name = 'fogoff', delay = 4300, duration = 1},
		{type = 'event', name = 'showisland', delay = 4300, duration = 1},
		{type = 'event', name = 'setislandevent2', delay = 4300, duration = 1},
	}},
	{name = 'doislandevent2', actions = {
		{type = 'event', name = 'animastateable', delay = 0, duration = 1},
		{type = 'event', name = 'enableinput', delay = 0, duration = 1},
		{type = 'event', name = 'enablecamera', delay = 0, duration = 1},
		{type = 'event', name = 'setnormalgravity', delay = 0, duration = 1},
		{type = 'event', name = 'recoverui', delay = 100, duration = 1},
	}},
	{name = 'repair_bridge', actions = {
		{type = 'event', name = 'bridgerepaired', delay = 0, duration = 1},
		{type = 'camera', followrole = false, delay = 0, duration = 1},
		{type = 'camera', lookShape = 'blocki', curve = 'looknpc', delay = 200, duration = 1000},
		{type = 'talk', talkid = 2, event = 0, delay = 1000, duration = 1},
		{type = 'camera', lookIndex = -1, delay = 3000, duration = 1000},
		{type = 'camera', followrole = true, delay = 4000, duration = 1},
	}},
	{name = 'helpblocki', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'event', name = 'removeclutter', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		--{type = 'camera', followrole = false, delay = 200, duration = 1},
		--{type = 'camera', lookShape = 'blocki', curve = 'looknpc', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'standup', delay = 500, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 1700, duration = 1},
		{type = 'talk', talkid = 3, event = 3, delay = 1700, duration = 1},
	}},
	{name = 'talk3', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'surprise', delay = 300, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 1550, duration = 1},
		{type = 'talk', talkid = 4, event = 4, delay = 1550, duration = 1},
	}},
	{name = 'talk4', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'think', delay = 300, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 2550, duration = 1},
		{type = 'talk', talkid = 5, event = 5, delay = 2550, duration = 1},
	}},
	{name = 'talk5', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'surprise', delay = 300, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 1550, duration = 1},
		{type = 'talk', talkid = 6, event = 6, delay = 1550, duration = 1},
	}},
	{name = 'talk6', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookShape = 'gardendoor', blocki = true, delay = 200, duration = 300},
		{type = 'event', name = 'blockiwalktodoor', delay = 500, duration = 1000},
		{type = 'event', name = 'dooropening', delay = 1500, duration = 1},
		{type = 'event', name = 'blockiwalkintodoor', delay = 2000, duration = 1000},
		{type = 'face', lookShape = 'gardendoor', blocki = true, delay = 3100, duration = 100},
		{type = 'talk', talkid = 7, event = 7, delay = 2500, duration = 1},
		--{type = 'camera', lookIndex = -1, delay = 3000, duration = 300},
		--{type = 'camera', followrole = true, delay = 3300, duration = 1},
	}},
	{name = 'talk7', actions = {
		{type = 'event', name = 'enableinput', delay = 0, duration = 1},
		{type = 'event', name = 'recoverui', delay = 0, duration = 1},
	}},
	{name = 'gointohouse', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookShape = 'work', blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 1000, duration = 300},
		--{type = 'camera', followrole = false, delay = 500, duration = 1},
		--{type = 'camera', lookShape = 'blocki', curve = 'looknpc', delay = 500, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 500, duration = 1},
		{type = 'talk', talkid = 8, event = 8, delay = 500, duration = 1},
	}},
	{name = 'talk8', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 500, duration = 1},
		{type = 'talk', talkid = 9, event = 9, delay = 500, duration = 1},
	}},
	{name = 'talk9', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 500, duration = 1},
		{type = 'talk', talkid = 10, event = 10, delay = 500, duration = 1},
	}},
	{name = 'talk10', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'speechless', delay = 500, duration = 1},
		{type = 'talk', talkid = 11, event = 11, delay = 500, duration = 1},
	}},
	{name = 'talk11', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 100, duration = 1},
		{type = 'wait', lookShapes = {'work'}, delay = 100, duration = 1000},
		{type = 'event', name = 'enableinput', delay = 1200, duration = 1},
		{type = 'event', name = 'recoverui', delay = 1200, duration = 1},
		--{type = 'camera', lookIndex = -1, delay = 1200, duration = 300},
		--{type = 'camera', followrole = true, delay = 1500, duration = 1},
	}},
	{name = 'repair_work', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookShape = 'work', blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		--{type = 'camera', followrole = false, delay = 500, duration = 1},
		--{type = 'camera', lookShape = 'blocki', curve = 'looknpc', delay = 500, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'surprise', delay = 500, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 1750, duration = 1},
		{type = 'talk', talkid = 12, event = 12, delay = 1750, duration = 1},
	}},
	{name = 'talk12', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 500, duration = 1},
		{type = 'talk', talkid = 13, event = 13, delay = 500, duration = 1},
	}},
	{name = 'talk13', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 100, duration = 1},
		{type = 'wait', lookShapes = {'work'}, delay = 100, duration = 1000},
		{type = 'event', name = 'enableinput', delay = 1200, duration = 1},
		{type = 'event', name = 'recoverui', delay = 1200, duration = 1},
		--{type = 'camera', lookIndex = -1, delay = 1200, duration = 300},
		--{type = 'camera', followrole = true, delay = 1500, duration = 1},
		-- 
	}},
	{name = 'repair_TV', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		----{type = 'camera', followrole = false, delay = 500, duration = 1},
		--{type = 'camera', lookShape = 'blocki', curve = 'looknpc', delay = 500, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 500, duration = 1},
		{type = 'talk', talkid = 14, event = 14, delay = 500, duration = 1},
	}},
	{name = 'talk14', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'nod', delay = 500, duration = 1},
		{type = 'talk', talkid = 15, event = 15, delay = 500, duration = 1},
	}},
	{name = 'talk15', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 100, duration = 1},
		{type = 'wait', lookShapes = {'work'}, delay = 100, duration = 1000},
		{type = 'event', name = 'enableinput', delay = 1200, duration = 1},
		{type = 'event', name = 'recoverui', delay = 1200, duration = 1},
		--{type = 'camera', lookIndex = -1, delay = 1200, duration = 300},
		--{type = 'camera', followrole = true, delay = 1500, duration = 1},
		-- 
	}},
	{name = 'decoroomTV', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		--{type = 'camera', followrole = false, delay = 500, duration = 1},
		--{type = 'camera', lookShape = 'blocki', curve = 'looknpc', delay = 500, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 500, duration = 1},
		{type = 'talk', talkid = 16, event = 16, delay = 500, duration = 1},
	}},
	{name = 'talk16', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'remember', delay = 500, duration = 1},
		{type = 'talk', talkid = 17, event = 17, delay = 500, duration = 1},
	}},
	{name = 'talk17', actions = {
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'give', delay = 500, duration = 1},
		{type = 'talk', talkid = 18, event = 18, delay = 500, duration = 1},
	}},
	{name = 'talk18', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'event', name = 'give500coin', delay = 100, duration = 1},
		{type = 'event', name = 'turntofront', delay = 200, duration = 200},
		{type = 'event', name = 'get500coin', delay = 500, duration = 1},
		{type = 'event', name = 'showfristbuy', delay = 700, duration = 1000},
		{type = 'sound', op = 'play', res = 'anima_get01', delay = 700, duration = 1000},
		{type = 'talk', talkid = 19, event = 19, delay = 2000, duration = 1},
		{type = 'event', name = 'syncobjecttitle', delay = 2000, duration = 1},
	}},
	{name = 'talk19', actions = {
		{type = 'event', name = 'hidefristbuy', delay = 100, duration = 1},
		{type = 'event', name = 'hideui', delay = 2000, duration = 1},
		{type = 'event', name = 'disableinput', delay = 2100, duration = 1},
		{type = 'wait', lookShapes = {'TV'}, delay = 2100, duration = 1000},
		{type = 'event', name = 'enableinput', delay = 3200, duration = 1},
		{type = 'event', name = 'recoverui', delay = 3200, duration = 1},
	}},
	{name = 'fristbuyitem', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'event', name = 'turntofront', delay = 200, duration = 200},
		{type = 'event', name = 'showfristbuy', delay = 700, duration = 1000},
		{type = 'sound', op = 'play', res = 'anima_get01', delay = 700, duration = 1000},
		{type = 'talk', talkid = 19, event = 192, delay = 2000, duration = 1},
		{type = 'event', name = 'syncobjecttitle', delay = 2000, duration = 1},
	}},
	{name = 'fristbuyfinish', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'event', name = 'hidefristbuy', delay = 100, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		--{type = 'camera', followrole = false, delay = 500, duration = 1},
		--{type = 'camera', lookShape = 'blocki', curve = 'looknpc', delay = 500, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'laugh2', delay = 500, duration = 1},
		{type = 'talk', talkid = 20, event = 20, delay = 500, duration = 1},
	}},
	{name = 'talk20', actions = {
		{type = 'wait', lookShapes = {'work'}, delay = 100, duration = 1000},
		{type = 'event', name = 'enableinput', delay = 1200, duration = 1},
		{type = 'event', name = 'recoverui', delay = 1200, duration = 1},
		-- 
	}},
	{name = 'decobuyitem', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		--{type = 'camera', followrole = false, delay = 500, duration = 1},
		--{type = 'camera', lookShape = 'blocki', curve = 'looknpc', delay = 500, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'laugh2', delay = 500, duration = 1},
		{type = 'talk', talkid = 21, event = 21, delay = 500, duration = 1},
	}},
	{name = 'talk21', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'think', delay = 500, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 2750, duration = 1},
		{type = 'talk', talkid = 22, event = 22, delay = 2750, duration = 1},
	}},
	{name = 'talk22', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 500, duration = 1},
		{type = 'talk', talkid = 23, event = 23, delay = 500, duration = 1},
	}},
	{name = 'talk23', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderIndex = -1, animaname = 'speechless', delay = 500, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'nod', delay = 2200, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'nod', delay = 2200, duration = 1},
		{type = 'talk', talkid = 24, event = 24, delay = 2200, duration = 1},
	}},
	{name = 'talk232', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderIndex = -1, animaname = 'nod', delay = 500, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'nod', delay = 500, duration = 1},
		{type = 'talk', talkid = 24, event = 24, delay = 500, duration = 1},
	}},
	{name = 'talk24', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'nod', delay = 500, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 2900, duration = 1},
		{type = 'talk', talkid = 25, event = 25, delay = 2900, duration = 1},
	}},
	{name = 'talk25', actions = {
		{type = 'event', name = 'showislandname', delay = 400, duration = 1},
	}},
	{name = 'changeislandname', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		--{type = 'camera', followrole = false, delay = 500, duration = 1},
		--{type = 'camera', lookShape = 'blocki', curve = 'looknpc', delay = 500, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'nod', delay = 500, duration = 1},
		{type = 'talk', talkid = 26, event = 26, delay = 500, duration = 1},
		{type = 'event', name = 'syncscenetitle', delay = 500, duration = 1},
	}},
	{name = 'talk26', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'nod', delay = 500, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 2900, duration = 1},
		{type = 'talk', talkid = 27, event = 27, delay = 2900, duration = 1},
	}},
	{name = 'talk27', actions = {
		{type = 'face', lookShape = 'gardendoor', blocki = true, delay = 200, duration = 300},
		{type = 'event', name = 'blockiwalkout1', delay = 500, duration = 2500},
		{type = 'event', name = 'blockiwalkout2', delay = 3500, duration = 500},
		{type = 'event', name = 'enableinput', delay = 3500, duration = 1},
		{type = 'event', name = 'recoverui', delay = 3500, duration = 1},
	}},
	{name = 'goouthouse', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'camera', followrole = false, delay = 200, duration = 1},
		{type = 'camera', lookShape = 'blocki', curve = 'looknpc', delay = 200, duration = 500},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'remember', delay = 500, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 2200, duration = 1},
		{type = 'camera', lookIndex = -1, curve = 'looknpc', delay = 2200, duration = 500},
		{type = 'camera', followrole = true, delay = 2700, duration = 1},
		{type = 'talk', talkid = 28, event = 28, delay = 2200, duration = 1},
	}},
	{name = 'talk28', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookShape = 'busstop', blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 1000, duration = 1},
		{type = 'talk', talkid = 29, event = 29, delay = 1000, duration = 1},
	}},
	{name = 'talk29', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 100, duration = 1},
		{type = 'wait', lookShapes = {'busstop'}, delay = 100, duration = 1000},
		{type = 'event', name = 'enableinput', delay = 1200, duration = 1},
		{type = 'event', name = 'recoverui', delay = 1200, duration = 1},
	}},
	{name = 'fristbrowserroom', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'nod', delay = 500, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 2900, duration = 1},
		{type = 'talk', talkid = 30, event = 30, delay = 2900, duration = 1},
	}},
	{name = 'talk30', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'laugh2', delay = 500, duration = 2700},
		{type = 'talk', talkid = 31, event = 31, delay = 500, duration = 1},
	}},
	{name = 'talk31', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'nod', delay = 500, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 2900, duration = 1},
		{type = 'talk', talkid = 32, event = 32, delay = 2900, duration = 1},
		{type = 'event', name = 'syncthemetitle1', delay = 2900, duration = 1},
	}},
	{name = 'talk32', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'give', delay = 500, duration = 1},
		{type = 'event', name = 'givethemeobject', delay = 2000, duration = 1},
	}},
	{name = 'aftergetthemeobject', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 100, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 100, duration = 300},
		{type = 'talk', talkid = 33, event = 33, delay = 100, duration = 1},
		{type = 'event', name = 'syncthemetitle2', delay = 100, duration = 1},
	}},
	{name = 'talk33', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'event', name = 'hidefristbuy', delay = 100, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'remember', delay = 500, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 2200, duration = 1},
		{type = 'talk', talkid = 34, event = 34, delay = 2200, duration = 1},
	}},
	{name = 'talk34', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookShape = 'paintbucket', blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 1000, duration = 1},
		{type = 'talk', talkid = 35, event = 35, delay = 1000, duration = 1},
	}},
	{name = 'talk35', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'wait', lookShapes = {'paintbucket'}, delay = 100, duration = 1000},
		{type = 'face', lookShape = 'bulletin', blocki = true, delay = 1200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 1200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 2000, duration = 1},
		{type = 'talk', talkid = 36, event = 36, delay = 2000, duration = 1},
	}},
	{name = 'talk36', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 100, duration = 1},
		{type = 'wait', lookShapes = {'bulletin'}, delay = 100, duration = 1000},
		{type = 'event', name = 'enableinput', delay = 1200, duration = 1},
		{type = 'event', name = 'recoverui', delay = 1200, duration = 1},
	}},
	{name = 'checkmailfinish', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'laugh2', delay = 500, duration = 1},
		{type = 'talk', talkid = 37, event = 37, delay = 500, duration = 1},
	}},
	{name = 'talk37', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'remember', delay = 500, duration = 1},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 2200, duration = 1},
		{type = 'talk', talkid = 38, event = 38, delay = 2200, duration = 1},
	}},
	{name = 'talk38', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'nod', delay = 500, duration = 2400},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 2900, duration = 1},
		{type = 'talk', talkid = 39, event = 39, delay = 2900, duration = 1},
	}},
	{name = 'talk39', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 1000, duration = 1},
		{type = 'talk', talkid = 40, event = 40, delay = 1000, duration = 1},
	}},
	{name = 'talk40', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 100, duration = 1},
		{type = 'wait', lookShapes = {'lego_AvatarDoor'}, delay = 100, duration = 1000},
		{type = 'event', name = 'enableinput', delay = 1200, duration = 1},
		{type = 'event', name = 'recoverui', delay = 1200, duration = 1},
	}},
	{name = 'buildavatar', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'laugh2', delay = 500, duration = 1},
		{type = 'talk', talkid = 41, event = 41, delay = 500, duration = 1},
	}},
	{name = 'talk41', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 1000, duration = 1},
		{type = 'talk', talkid = 42, event = 42, delay = 1000, duration = 1},
	}},
	{name = 'talk42', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 100, duration = 1},
		{type = 'wait', lookShapes = {'lego_AvatarDoor'}, delay = 100, duration = 1000},
		{type = 'event', name = 'enableinput', delay = 1200, duration = 1},
		{type = 'event', name = 'recoverui', delay = 1200, duration = 1},
	}},
	{name = 'wearavatar', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'laugh2', delay = 500, duration = 1},
		{type = 'talk', talkid = 43, event = 43, delay = 500, duration = 1},
	}},
	{name = 'talk43', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'face', lookIndex = -1, blocki = true, delay = 200, duration = 300},
		{type = 'face', lookShape = 'blocki', delay = 200, duration = 300},
		{type = 'animation', holderShape = 'blocki', animaname = 'talktoself', delay = 1000, duration = 1},
		{type = 'talk', talkid = 44, event = 44, delay = 1000, duration = 1},
	}},
	{name = 'talk44', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 100, duration = 1},
		{type = 'wait', lookShapes = {'lego_ParkDoor'}, delay = 100, duration = 1000},
		{type = 'event', name = 'enableinput', delay = 1200, duration = 1},
		{type = 'event', name = 'recoverui', delay = 1200, duration = 1},
	}},
	{name = 'getNewObject', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'event', name = 'turntofront', delay = 200, duration = 200},
		{type = 'event', name = 'showfristbuy', delay = 700, duration = 1000},
		{type = 'sound', op = 'play', res = 'anima_get01', delay = 700, duration = 1000},
		{type = 'talk', talkid = 19, event = 191, delay = 1000, duration = 1},
		{type = 'event', name = 'syncobjecttitle', delay = 1000, duration = 1},
	}},
	{name = 'getNewObjectFinish', actions = {
		{type = 'event', name = 'hidefristbuy', delay = 100, duration = 1},
		{type = 'event', name = 'continuetalkaftergetnewobject', delay = 200, duration = 1},
	}},
	{name = 'showinputui', actions = {
		{type = 'event', name = 'enableinput', delay = 0, duration = 1},
		{type = 'event', name = 'recoverui', delay = 0, duration = 1},
	}},
	{name = 'lookstonetablet', actions = {
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'event', name = 'enablecamera', delay = 0, duration = 1},
		{type = 'event', name = 'moviescreenin', delay = 200, duration = 1},
		{type = 'camera', followrole = false, delay = 200, duration = 1},
		{type = 'camera', name = 'recordcamera', delay = 200, duration = 1},
		{type = 'camera', lookShape = 'Stonetablet', curve = 'looknpc', delay = 200, duration = 1000},
		{type = 'camera', name = 'userecordcamera', curve = 'looknpc', delay = 2500, duration = 1000},
		{type = 'camera', followrole = true, delay = 3500, duration = 1},
		{type = 'event', name = 'moviescreenout', delay = 3500, duration = 1},
		{type = 'event', name = 'enableinput', delay = 3500, duration = 1},
		{type = 'event', name = 'recoverui', delay = 3500, duration = 1},
	}},
}

for i, v in ipairs(moviedata) do
	gmm:createMovie(v)
end

local newmoviedata = {
	{name = 'newsignup', actions = {
		{type = 'event', name = 'showgramophone', delay = 0, duration = 1},
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'idle', delay = 0, duration = 1},
		{type = 'event', name = 'moviescreenin', delay = 200, duration = 1},
		{type = 'event', name = 'setlessgravity', delay = 200, duration = 1},
		{type = 'event', name = 'animastatedisable', delay = 200, duration = 1},
		{type = 'event', name = 'floorbreak', delay = 400, duration = 1},
		{type = 'event', name = 'stopBGM', delay = 400, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'beforefall', delay = 400, duration = 1480},
		{type = 'sound', op = 'play', res = 'anima_fall01', delay = 400, duration = 1},
		{type = 'sound', op = 'play', res = 'anima_step02', delay = 430, duration = 1},
		{type = 'sound', op = 'play', res = 'anima_step02', delay = 900, duration = 1},
		{type = 'event', name = 'floornostand', delay = 2200, duration = 1},
		{type = 'event', name = 'floorhide', delay = 2500, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'struggle', delay = 2200, duration = 2000},
		{type = 'event', name = 'enablepostprocess', delay = 2500, duration = 1},
		{type = 'event', name = 'updatelocaltime', delay = 2600, duration = 1},
		{type = 'event', name = 'camerarecover', delay = 2600, duration = 500},
		{type = 'camera', lookIndex = -1, delay = 2600, duration = 500},
		{type = 'camera', followrole = true, delay = 3100, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'liedown', delay = 4100, duration = -1},
		{type = 'event', name = 'liedownsound', delay = 4100, duration = 1},
		{type = 'event', name = 'vibrate', delay = 4100, duration = 1},
		{type = 'event', name = 'moviescreenout', delay = 4100, duration = 1},
		{type = 'event', name = 'showemptyisland', delay = 4300, duration = 1},
		{type = 'event', name = 'setislandevent3', delay = 4300, duration = 1},
	}},
	{name = 'doislandevent3', actions = {
		{type = 'animation', holderIndex = -1, animaname = 'standup', delay = 0, duration = 1200},
		{type = 'animation', holderIndex = -1, animaname = 'idle', delay = 1300, duration = 1},
		{type = 'event', name = 'animastateable', delay = 0, duration = 1},
		{type = 'event', name = 'enableinput', delay = 1300, duration = 1},
		{type = 'event', name = 'enablecamera', delay = 1300, duration = 1},
		{type = 'event', name = 'setnormalgravity', delay = 1300, duration = 1},
		{type = 'event', name = 'recoverui', delay = 1300, duration = 1},
		{type = 'event', name = 'showinputtip', delay = 1400, duration = 1},
	}},
	{name = 'newlogin', actions = {
		{type = 'event', name = 'showgramophone', delay = 0, duration = 1},
		{type = 'event', name = 'hideui', delay = 0, duration = 1},
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'idle', delay = 0, duration = 1},
		{type = 'event', name = 'setlessgravity', delay = 200, duration = 1},
		{type = 'event', name = 'animastatedisable', delay = 200, duration = 1},
		{type = 'event', name = 'floorbreak', delay = 400, duration = 1},
		{type = 'event', name = 'stopBGM', delay = 400, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'beforefall', delay = 400, duration = 1480},
		{type = 'sound', op = 'play', res = 'anima_fall01', delay = 400, duration = 2000},
		{type = 'sound', op = 'play', res = 'anima_step02', delay = 430, duration = 1},
		{type = 'sound', op = 'play', res = 'anima_step02', delay = 900, duration = 1},
		{type = 'event', name = 'floornostand', delay = 2200, duration = 1},
		{type = 'event', name = 'floorhide', delay = 2500, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'fall', delay = 2200, duration = 2000},
		{type = 'event', name = 'playgramophone', delay = 2200, duration = 1},
		{type = 'event', name = 'enablepostprocess', delay = 2500, duration = 1},
		{type = 'event', name = 'updatelocaltime', delay = 2600, duration = 1},
		{type = 'event', name = 'camerarecover', delay = 2600, duration = 500},
		{type = 'camera', lookIndex = -1, delay = 2600, duration = 500},
		{type = 'camera', followrole = true, delay = 3100, duration = 1},
		{type = 'event', name = 'vibrate', delay = 4100, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'idle', delay = 4100, duration = 1},
		{type = 'event', name = 'animastateable', delay = 4300, duration = 1},
		{type = 'event', name = 'enableinput', delay = 4300, duration = 1},
		{type = 'event', name = 'enablecamera', delay = 4300, duration = 1},
		{type = 'event', name = 'setnormalgravity', delay = 4300, duration = 1},
		{type = 'event', name = 'recoverui', delay = 4400, duration = 1},
	}},
	{name = 'hugpipeanddown', actions = {
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'animation', holderIndex = -1, animaname = 'mlahugpipe', delay = 0, duration = 1},
		{type = 'event', name = 'mlaflagdown', delay = 0, duration = 1},
		{type = 'event', name = 'mladown', delay = 0, duration = 1000},
		{type = 'event', name = 'mlaturn', delay = 1000, duration = 1000},
		{type = 'event', name = 'mlaruntocastle', delay = 1500, duration = 1000},
		{type = 'event', name = 'enableinput', delay = 4000, duration = 1},
		{type = 'event', name = 'mlarecover', delay = 4000, duration = 1},
	}},
	{name = 'mariostart', actions = {
		{type = 'event', name = 'disableinput', delay = 0, duration = 1},
		{type = 'event', name = 'mlaruntocastle', delay = 0, duration = 1500},
		{type = 'event', name = 'mlarunlowspeed', delay = 0, duration = 1},
		{type = 'event', name = 'moviescreenstayend', delay = 100, duration = 1},
		{type = 'event', name = 'enableinput', delay = 1300, duration = 1},
		{type = 'event', name = 'mlarecover', delay = 1300, duration = 1},
	}},
}

for i, v in ipairs(newmoviedata) do
	gmm:createMovie(v)
end

local g = Global.Role.gravity_get()

gmm.onEvent = function(name, duration)
	if not Version:isAlpha1() then return end
	print('onEvent', name, duration)
	if name == 'floorbreak' then
		Global.Role.gravity_set(g / 6)
		local node = Global.sen:getNode('sign_in_02')
		if node then
			if node.mesh.skeleton == nil then
				node.mesh:attachSkeleton('sign_in_02.skl')
			end
			if node.playinganima then
				node.playinganima:stop()
			end
			local anima = node.mesh.skeleton:addAnima('sign_in_02_posui.san')
			anima.loop = false
			anima:play()
		end
	elseif name == 'showgramophone' then
		local block = Global.sen:getBlockByShape('gramophone')
		if block then
			-- local visible = not _sys:getGlobal('PCRelease') or Global.ObjectManager:hasAstronautAvatar()
			local visible = true
			block:setVisible(visible, visible)
		end
	elseif name == 'playgramophone' then
		local block = Global.sen:getBlockByShape('gramophone')
		if block and block.node.visible then
			Global.AudioPlayer:stop()
			local music = Global.Login:getMusic()
			if music then
				local audio = Global.AudioPlayer:createAudio(music.name, music)
				if audio then
					Global.AudioPlayer:setCurrent(audio)
					if Global.Login:getMusicPlaying() then
						Global.AudioPlayer:playCurrent()
					end
				end
			end
			local vec = Container:get(_Vector3)
			block:getTransform():getTranslation(vec)
			Global.AudioPlayer:setLocation(vec)
			Container:returnBack(vec)
		end
	elseif name == 'showfamegift' then
		Global.FameTask:getFameGift()
	elseif name == 'floornostand' then
		local block = Global.sen:getBlockByShape('rolestand')
		block:switchVisible(false, false)
	elseif name == 'moveroletohouse' then
		if Global.Achievement:check('helpblocki') then
			local vec = Container:get(_Vector3)
			Global.role:getPosition(vec)
			vec:set(vec.x - 35, vec.y + 20, vec.z)
			Global.role:setPosition(vec)
			Container:returnBack(vec)
		end
	elseif name == 'floorshow' then
		local node1 = Global.sen:getNode('sign_in_01')
		if node1 then
			node1.visible = true
		end
		local node2 = Global.sen:getNode('sign_in_02')
		if node2 then
			node2.visible = true
		end
		local node3 = Global.sen:getNode('sign_in_03')
		if node3 then
			node3.visible = true
		end
	elseif name == 'floorhide' then
		local node1 = Global.sen:getNode('sign_in_01')
		if node1 then
			node1.visible = false
		end
		local node2 = Global.sen:getNode('sign_in_02')
		if node2 then
			node2.visible = false
		end
		local node3 = Global.sen:getNode('sign_in_03')
		if node3 then
			node3.visible = false
		end
	elseif name == 'showmode1' then
		local node1 = Global.sen:getNode('sign_in_01')
		if node1 then
			if node1.mesh.skeleton == nil then
				node1.mesh:attachSkeleton('sign_in_01.skl')
			end
			local anima = node1.mesh.skeleton:addAnima('sign_in_01_kaichang01.san')
			anima.loop = false
			anima:onStop(function()
				local idleanima = node1.mesh.skeleton:addAnima('sign_in_01_idle.san')
				idleanima.loop = true
				idleanima:play()
				node1.playinganima = nil
			end)
			anima:play()
			node1.playinganima = anima
		end
		local node2 = Global.sen:getNode('sign_in_02')
		if node2 then
			if node2.mesh.skeleton == nil then
				node2.mesh:attachSkeleton('sign_in_02.skl')
			end
			local anima = node2.mesh.skeleton:addAnima('sign_in_02_idle_qian.san')
			anima.loop = true
			anima:play()
			node2.playinganima = anima
		end
	elseif name == 'showmode2' then
		local node1 = Global.sen:getNode('sign_in_01')
		if node1 then
			if node1.mesh.skeleton == nil then
				node1.mesh:attachSkeleton('sign_in_01.skl')
			end
			if node1.playinganima then
				node1.playinganima:stop()
			end
			local anima = node1.mesh.skeleton:addAnima('sign_in_01_zhuanchang01.san')
			anima.loop = false
			anima:onStop(function()
				local idleanima = node1.mesh.skeleton:addAnima('sign_in_01_idle_hou.san')
				idleanima.loop = true
				idleanima:play()
			end)
			anima:play()
		end
		local node2 = Global.sen:getNode('sign_in_02')
		if node2 then
			if node2.mesh.skeleton == nil then
				node2.mesh:attachSkeleton('sign_in_02.skl')
			end
			if node2.playinganima then
				node2.playinganima:stop()
			end
			local anima = node2.mesh.skeleton:addAnima('sign_in_02_zhuanchang01.san')
			anima.loop = false
			anima:onStop(function()
				local idleanima = node2.mesh.skeleton:addAnima('sign_in_02_idle_hou.san')
				idleanima.loop = true
				idleanima:play()
				node2.playinganima = nil
			end)
			anima:play()
			node2.playinganima = anima
		end
	elseif name == 'showinputtip' then
		DownTip('WSAD/↑↓←→ to move, SPACE to jump.', 30000)
	elseif name == 'showhotkeytip' then
		DownTip('Hold TAB to show shortcuts.', 30000)
	elseif name == 'fogon' then
		Global.TimeOfDayManager.enableFog = false

		local fog = Global.sen.graData:getFog(1)
		fog.type = _Fog.TypeLinear
		fog.color = 0xff4080c0
		fog.far = 10
		fog.near = 5
		_rd.bgColor = fog.color
	elseif name == 'fogfade' then
		Global.TimeOfDayManager.enableFog = false
		local fog = Global.sen.graData:getFog(1)
		fog.far = fog.far + duration
		fog.near = fog.near + duration
	elseif name == 'fogoff' then
		Global.TimeOfDayManager.enableFog = true
		local fog = Global.sen.graData:getFog(1)
		fog.type = 0
		fog.far = 2000
		fog.near = 200
	elseif name == 'animastatedisable' then
		Global.role.animaState.able = false
	elseif name == 'animastateable' then
		Global.role.animaState.able = true
	elseif name == 'setlessgravity' then
		Global.Role.gravity_set(g / 6)
	elseif name == 'setnormalgravity' then
		Global.Role.gravity_set(g)
	elseif name == 'disablecamera' then
		Global.SwitchControl:set_cameracontrol_off()
	elseif name == 'enablecamera' then
		Global.SwitchControl:set_cameracontrol_on()
	elseif name == 'disableinput' then
		Global.SwitchControl:set_input_off()
		_app:setupCallback()
		if Global.sen.setting.oldspecialtype == nil then
			Global.sen.setting.oldspecialtype = Global.sen.setting.specialtype
		end
		Global.sen.setting.specialtype = ''
		TEMP_SETUP_PARKOUR_UI()
		Global.CoinUI:show(false)
		Global.ProfileUI:show(false)
	elseif name == 'enableinput' then
		Global.SwitchControl:set_input_on()
		Global.CoinUI:show(true)
		Global.ProfileUI:show(true)
		Global.sen.setting.specialtype = Global.sen.setting.oldspecialtype
		TEMP_SETUP_PARKOUR_UI()
		if Global.sen.setting.specialtype == 'parkour' then
			_app:setupCallback(TEMP_GAME_CALLBACK_PARKOUR)
		elseif Global.sen.setting.specialtype == 'homeparkour' then
			_app:setupCallback(TEMP_GAME_CALLBACK_HOMEPARKOUR)
		end
		Global.SwitchControl:set_input_on()
	elseif name == 'liedownsound' then
		-- Global.Sound:play('anima_fall01')
		local pfx = Global.role.mb.mesh.pfxPlayer:play('yanchen_001.pfx')
		pfx.transform:mulScalingLeft(2, 2, 2)

		_rd.camera:shake(0.1, 0.2, 500, _Camera.Quadratic)
	elseif name == 'camerarecover' then
		local vec = Container:get(_Vector3)
		local camera = Global.CameraControl:get()
		-- camera:scale(5.2, duration)
		-- camera:moveDirH(1.57 - camera:getDirH(), duration)
		-- camera:moveDirV(0.523 - camera:getDirV(), duration)
		camera:scale(9.2, duration)
		camera:moveDirH(2.515 - camera:getDirH(), duration)
		camera:moveDirV(0.228 - camera:getDirV(), duration)
		vec:set(camera.camera.look)
		vec.z = vec.z - 3
		camera:moveLook(vec, duration)
		camera.camera.fov = 45
		Container:returnBack(vec)
	elseif name == 'stopBGM' then
		Global.Sound:stop()
		Global.Sound:play('bgm_ambient_indoor')
		-- Global.Sound:play('bgm_ambient1')
		-- Global.Sound:play('bgm_ambient2')
		-- Global.Sound:play('bgm_ambient3')
	elseif name == 'loginbegin' then
		local posmat = Global.sen.graData:getMarker('cha01')
		local vec = Container:get(_Vector3)
		local vec1 = Container:get(_Vector3)
		posmat:getTranslation(vec)
		-- vec.x = 4.9352 
		-- vec.y = -14.9247
		-- 3.7918 y:-10.8778
		-- Global.role:setPosition(_Vector3.new(4.9352,-14.9247, vec.z + Global.role.size.z / 2))
		Global.role:setPosition(_Vector3.new(vec.x, vec.y, vec.z + Global.role.size.z / 2))
		local block = Global.sen:getBlockByShape('rolestand')
		block:getTransform():getTranslation(vec1)
		block:move(vec.x - vec1.x, vec.y - vec1.y, vec.z - vec1.z - 0.1)
		block:switchVisible(false, true)
		Container:returnBack(vec, vec1)
		local camera = Global.CameraControl:get()
		camera:followTarget()
		-- camera:setEyeLook(_Vector3.new(-0.13 + 11.14, 4.9-4.1, 16.5), _Vector3.new(-0.13 + 11.14, 5.2-4.1, 16.5))
		camera:setEyeLook(_Vector3.new(-0.13, 4.9, 16.5), _Vector3.new(-0.13, 5.2, 16.5))
		camera:update()
		camera.camera.fov = 35
		Global.LoginUI:moveToLoginInCamera()
	elseif name == 'moviescreenin' then
		Global.ScreenEffect:setDisabled(true)
		Global.ScreenEffect:movieCurtainIn()
	elseif name == 'moviescreenout' then
		Global.ScreenEffect:movieCurtainOut()
	elseif name == 'moviescreenstayend' then
		Global.ScreenEffect:setDisabled(true)
		Global.ScreenEffect:movieCurtainStayEnd()
	elseif name == 'randomexpress' then
		local animas = {'laugh', 'angry'}
		Global.role:playAnima(animas[math.random(1, #animas)], false, function()
			if Global.role then
				Global.role:playAnima('idle')
			end
		end)
	elseif name == 'loginanima' then
		Global.role:playAnima('jump3', false, function()
			if Global.role then
				Global.role:playAnima('idle')
			end
		end)
	elseif name == 'doorclosed' then
		local door = Global.sen:getBlockByShape('gardendoor')
		assert(door, 'no door')
		door:switchVisible(true, true)

		local meshs = {}
		door.node.mesh:getSubMeshs(meshs)
		if meshs[1].skeleton == nil then
			meshs[1]:attachSkeleton('obj_men_01.skl')
		end
		local anima1 = meshs[1].skeleton:addAnima('obj_men_01_idle.san')
		anima1.loop = true
		anima1:play()
		if meshs[2].skeleton == nil then
			meshs[2]:attachSkeleton('obj_men_02.skl')
		end
		local anima2 = meshs[2].skeleton:addAnima('obj_men_02_idle.san')
		anima2.loop = true
		anima2:play()
	elseif name == 'dooropen' then
		local door = Global.sen:getBlockByShape('gardendoor')
		assert(door, 'no door')
		door:switchVisible(true, false)

		local meshs = {}
		door.node.mesh:getSubMeshs(meshs)
		if meshs[1].skeleton == nil then
			meshs[1]:attachSkeleton('obj_men_01.skl')
		end
		local anima1 = meshs[1].skeleton:addAnima('obj_men_01_n_idle.san')
		anima1.loop = true
		anima1:play()

		if meshs[2].skeleton == nil then
			meshs[2]:attachSkeleton('obj_men_02.skl')
		end
		local anima2 = meshs[2].skeleton:addAnima('obj_men_02_n_idle.san')
		anima2.loop = true
		anima2:play()
	elseif name == 'dooropening' then
		local door = Global.sen:getBlockByShape('gardendoor')
		assert(door, 'no door')
		local meshs = {}
		door.node.mesh:getSubMeshs(meshs)
		if meshs[1].skeleton == nil then
			meshs[1]:attachSkeleton('obj_men_01.skl')
		end
		local anima1 = meshs[1].skeleton:addAnima('obj_men_01_n_open.san')
		anima1.loop = false
		anima1:play()
		Global.Sound:play('opendoor')

		if meshs[2].skeleton == nil then
			meshs[2]:attachSkeleton('obj_men_02.skl')
		end
		local anima2 = meshs[2].skeleton:addAnima('obj_men_02_n_open.san')
		anima2.loop = false
		anima2:onStop(function()
			local a1 = meshs[1].skeleton:addAnima('obj_men_01_n_idle.san')
			a1.loop = true
			a1:play()

			local a2 = meshs[2].skeleton:addAnima('obj_men_02_n_idle.san')
			a2.loop = true
			a2:play()
			door:switchVisible(true, false)
		end)
		anima2:play()
	elseif name == 'turntofront' then
		if Global.role then
			local dir = Container:get(_Vector3)
			dir:set(0, -1, 0)
			Global.role:updateFace(dir, duration)
			Container:returnBack(dir)
		end
	elseif name == 'showfristbuy' then
		if gmm.newgetobject then
			Global.role:playAnima('lift')

			local timer = _Timer.new()
			timer:start('pauselift', 1000, function()
				Global.role:pauseAnima()
				timer:stop()
			end)

			local name = gmm.newgetobject.picfile and gmm.newgetobject.picfile.name or (tostring(gmm.newgetobject.name) .. '-display.bmp')
			gmm.newgetobjectpic = _Image.new(name)
			local pfx = Global.role.mb.mesh.pfxPlayer:play('huoquwupin_001.pfx')
			pfx.transform:mulTranslationRight(0, 0, 4.8)
			pfx.transform:mulScalingLeft(1.5, 1.5, 1.5)
			if gmm.ongetobject then
				gmm:ongetobject()
			end
		end
	elseif name == 'hidefristbuy' then
		Global.role:playAnima('idle')
		gmm.newgetobjectpic = nil
		gmm.newgetobject = nil
		gmm.isfristbuy = false
	elseif name == 'vibrate' then
		_sys:vibrate(30)
	elseif name == 'disablepostprocess' then
		if _rd.postProcess then _rd.postProcess.enable = false end
		_sys.enableOldShadow = false
		_rd.enableShadowProjection = false
	elseif name == 'enablepostprocess' then
		if _rd.postProcess then _rd.postProcess.enable = true end
		_rd.enableShadowProjection = false
		_sys.enableOldShadow = true
	elseif name == 'lightrecover' then
		Global.TimeOfDayManager:cancel()
	elseif name == 'locklocaltime' then
		Global.TimeOfDayManager.enableInOutHouse = false
		Global.TimeOfDayManager:setCurrentTime(15)
	elseif name == 'updatelocaltime' then
		Global.TimeOfDayManager.enableInOutHouse = true
		local curtime = _sys.currentTime
		local time = curtime.hour + curtime.minute / 60
		Global.TimeOfDayManager:setCurrentTime(time)
	elseif name == 'showisland' then
		local name = (Global.sen and Global.sen.title and Global.sen.title ~= '') and Global.sen.title or 'An unknown island in the Blockverse'
		Global.Island:show(name)
	elseif name == 'showemptyisland' then
		Global.Island:show('')
	elseif name == 'hideui' then
		Global.UI:switchUIVisible(false)
	elseif name == 'recoverui' then
		Global.UI:switchUIVisible(true)
	elseif name == 'setislandevent1' then
		Global.Island:registerExit(function()
			gmm:startMovie('doislandevent1')
		end)
	elseif name == 'setislandevent2' then
		Global.Island:registerExit(function()
			gmm:startMovie('doislandevent2')
		end)
		Global.UI:switchUIVisible(true)
	elseif name == 'setislandevent3' then
		Global.Island:registerExit(function()
			gmm:startMovie('doislandevent3')
		end)
	elseif name == 'settalkevent0' then
		Global.Talk:setAnswerFunctions({function()
			gmm.onEvent('enableinput')
			gmm.onEvent('recoverui')
		end})
	elseif name == 'settalkevent1' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk1')
		end})
	elseif name == 'bridgerepaired' then
		local bb = Global.sen:getBlockByShape('Broken_bridge')
		bb:switchVisible(false, false)
		local gb = Global.sen:getBlockByShape('Good_bridge')
		gb:switchVisible(true, true)
		local group = Global.sen:getGroup(13)
		for i, v in ipairs(group.blocks) do
			v:setVisible(false, false)
		end
	elseif name == 'removeclutter' then
		-- ART TODO.碎木头消失
		-- print('dsahidashodsah')
		local fence = Global.sen:getBlockByShape('blocki_fence')
		fence:changeTransparency(0, 1)
		fence:enablePhysic(false)
	elseif name == 'blockistandup' then
		local blocki = Global.sen:getBlockByShape('blocki')
		blocki:applyAnim('standup', false, nil, true)
		local anima = blocki:playAnim('standup')
		anima:onStop(function()
			blocki:applyAnim('idle', true, nil, false)
			blocki:playAnim('idle')
		end)
	elseif name == 'settalkevent3' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk3')
			Global.Achievement:ask('talk3')
		end})
	elseif name == 'settalkevent4' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk4')
			Global.Achievement:ask('talk4')
		end})
	elseif name == 'settalkevent5' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk5')
			Global.Achievement:ask('talk5')
		end})
	elseif name == 'settalkevent6' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk6')
			Global.Achievement:ask('talk6')
		end})
	elseif name == 'settalkevent7' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk7')
			Global.Achievement:checkorask('talk7', function()
				gmm:syncGuideStep()
				Global.ui.interact:refresh()
			end)
		end})
	elseif name == 'settalkevent8' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk8')
			Global.Achievement:ask('talk8')
		end})
	elseif name == 'settalkevent9' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk9')
			Global.Achievement:ask('talk9')
		end})
	elseif name == 'settalkevent10' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk10')
			Global.Achievement:ask('talk10')
		end})
	elseif name == 'settalkevent11' then
		Global.Talk:setAnswerFunctions({function()
			Global.Achievement:checkorask('talk11', function()
				gmm:startMovie('talk11')
				gmm:syncGuideStep()
				Global.ui.interact:refresh()
			end)
		end})
	elseif name == 'settalkevent12' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk12')
			Global.Achievement:ask('talk12')
		end})
	elseif name == 'settalkevent13' then
		Global.Talk:setAnswerFunctions({function()
			Global.Achievement:checkorask('talk13', function()
				gmm:startMovie('talk13')
				gmm:syncGuideStep()
				Global.ui.interact:refresh()
			end)
		end})
	elseif name == 'settalkevent14' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk14')
			Global.Achievement:ask('talk14')
		end,
		function()
			gmm:startMovie('talk14')
			Global.Achievement:ask('talk14')
		end})
	elseif name == 'settalkevent15' then
		Global.Talk:setAnswerFunctions({function()
			Global.Achievement:checkorask('talk15', function()
				gmm:startMovie('talk15')
				gmm:syncGuideStep()
				Global.ui.interact:refresh()
			end)
		end})
	elseif name == 'settalkevent16' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk16')
			Global.Achievement:ask('talk16')
		end})
	elseif name == 'settalkevent17' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk17')
			Global.Achievement:ask('talk17')
		end})
	elseif name == 'settalkevent18' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk18')
			Global.Achievement:ask('talk18')
		end})
	elseif name == 'settalkevent19' then
		Global.Talk:setAnswerFunctions({function()
			gmm:clearObtainObject()
			gmm:startMovie('talk19')
			Global.Achievement:ask('talk19')
		end})
	elseif name == 'settalkevent191' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('getNewObjectFinish')
		end})
	elseif name == 'settalkevent192' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('fristbuyfinish')
		end})
	elseif name == 'give500coin' then
		gmm.newgetobject = {picfile = {name = 'coin.png'}, title = genHtmlImg('coin1.png', 48, 48) .. '500'}
	elseif name == 'syncobjecttitle' then
		Global.Talk:setContent('You obtain ' .. (gmm.newgetobject.title or '') .. '!')
	elseif name == 'syncscenetitle' then
		Global.Talk:setContent(Global.sen.title .. ', great name!')
	elseif name == 'syncthemetitle1' then
		local theme = ''
		for i, v in ipairs(_G.cfg_theme_tasks) do
			if Global.Achievement:check(v.tag .. 'themed') then
				theme = v.tag
				break
			end
		end
		Global.Talk:setContent('Here you are, this is my treasure, a good creation of ' .. theme .. ' theme.')
	elseif name == 'syncthemetitle2' then
		local theme = ''
		for i, v in ipairs(_G.cfg_theme_tasks) do
			if Global.Achievement:check(v.tag .. 'themed') then
				theme = v.tag
				break
			end
		end
		Global.Talk:setContent('Can\'t wait to see the ' .. theme .. ' themed room you made. Try to put more assets of ' .. theme .. ' theme in the room, and no other assets of different themes.')
	elseif name == 'get500coin' then
		Global.Achievement:checkorask('fristgetcoin', function()
			Global.CoinUI:show(true)
			Global.Login:updateActiveness(500)
		end)
	elseif name == 'settalkevent20' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk20')
			Global.Achievement:ask('talk20')
		end})
	elseif name == 'settalkevent21' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk21')
			Global.Achievement:ask('talk21')
		end})
	elseif name == 'settalkevent22' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk22')
			Global.Achievement:ask('talk22')
		end})
	elseif name == 'settalkevent23' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk23')
			Global.Achievement:ask('talk23')
		end,
		function()
			gmm:startMovie('talk232')
			Global.Achievement:ask('talk23')
		end})
	elseif name == 'settalkevent24' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk24')
			Global.Achievement:ask('talk24')
		end})
	elseif name == 'settalkevent25' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk25')
			Global.Achievement:ask('talk25')
		end})
	elseif name == 'settalkevent26' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk26')
			Global.Achievement:ask('talk26')
		end})
	elseif name == 'settalkevent27' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk27')
			Global.Achievement:ask('talk27')
		end})
	elseif name == 'settalkevent28' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk28')
			Global.Achievement:ask('talk28')
		end})
	elseif name == 'settalkevent29' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk29')
			Global.Achievement:ask('talk29')
		end})
	elseif name == 'settalkevent30' then
		local answers = {cfg_theme_tasks[1].tag, cfg_theme_tasks[2].tag, cfg_theme_tasks[3].tag}
		Global.Talk:setAnswers(answers)
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk30')
			Global.Achievement:ask('talk30')
			Global.Achievement:ask(answers[1] .. 'themed')
			Global.DailyTasks:changeHouseThemedTask(answers[1])
		end,
		function()
			gmm:startMovie('talk30')
			Global.Achievement:ask('talk30')
			Global.Achievement:ask(answers[2] .. 'themed')
			Global.DailyTasks:changeHouseThemedTask(answers[2])
		end,
		function()
			gmm:startMovie('talk30')
			Global.Achievement:ask('talk30')
			Global.Achievement:ask(answers[3] .. 'themed')
			Global.DailyTasks:changeHouseThemedTask(answers[3])
		end})
	elseif name == 'settalkevent31' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk31')
			Global.Achievement:ask('talk31')
		end})
	elseif name == 'settalkevent32' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk32')
			Global.Achievement:ask('talk32')
		end})
	elseif name == 'settalkevent33' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk33')
			Global.Achievement:ask('talk33')
		end})
	elseif name == 'settalkevent34' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk34')
			Global.Achievement:ask('talk34')
		end})
	elseif name == 'settalkevent35' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk35')
			Global.Achievement:ask('talk35')
		end})
	elseif name == 'settalkevent36' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk36')
			Global.Achievement:ask('talk36')
		end})
	elseif name == 'settalkevent37' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk37')
			Global.Achievement:ask('talk37')
		end})
	elseif name == 'settalkevent38' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk38')
			Global.Achievement:ask('talk38')
		end})
	elseif name == 'settalkevent39' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk39')
			Global.Achievement:ask('talk39')
		end})
	elseif name == 'settalkevent40' then
		Global.Talk:setAnswerFunctions({function()
			Global.Achievement:checkorask('talk40', function()
				gmm:startMovie('talk40')
				gmm:syncGuideStep()
				Global.ui.interact:refresh()
			end)
		end})
	elseif name == 'settalkevent41' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk41')
			Global.Achievement:ask('talk41')
		end})
	elseif name == 'settalkevent42' then
		Global.Talk:setAnswerFunctions({function()
			Global.Achievement:checkorask('talk42', function()
				gmm:startMovie('talk42')
				gmm:syncGuideStep()
				Global.ui.interact:refresh()
			end)
		end})
	elseif name == 'settalkevent43' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk43')
			Global.Achievement:ask('talk43')
		end})
	elseif name == 'settalkevent44' then
		Global.Talk:setAnswerFunctions({function()
			gmm:startMovie('talk44')
			Global.Achievement:ask('talk44')
			Global.Achievement:ask('guidetalkfinish')
		end})
	elseif name == 'showislandname' then
		Global.Island.onEditName = function()
			if Global.House:isInMyHouse() then
				local home = Global.getMyHouse()
				if home then
					Global.House:changeBoardImage(home)
				end
			end
			gmm:askGuideStepChangeIslandName()
		end
		Global.Island:editName()
	elseif name == 'givethemeobject' then
		local obj = nil
		for i, v in ipairs(_G.cfg_theme_tasks) do
			if Global.Achievement:check(v.tag .. 'themed') then
				obj = Global.getNotObtainThemeObject(v.tag)
				break
			end
		end
		if obj and obj.achievements then
			local achievement = obj.achievements[1]
			Global.Achievement:register(achievement, function()
				gmm:playNewObjectMovie(obj)
				gmm.continuetalkfunc = function()
					gmm:startMovie('aftergetthemeobject')
					gmm.continuetalkfunc = nil
				end
			end)
			Global.Achievement:ask(achievement)
		end
	elseif name == 'blockiwalktodoor' then
		local blocki = Global.sen:getBlockByShape('blocki')
		blocki:applyAnim('run', true, nil, true)
		blocki:playAnim('run')
		blocki:enablePhysic(false)
		blocki.node.transform:mulTranslationRight(0, 5, 0, duration)

		local timer = _Timer.new()
		timer:start('blockiwalk', duration, function()
			local blocki = Global.sen:getBlockByShape('blocki')
			blocki:enablePhysic(true)
			blocki:stopAnim()
			blocki:applyAnim('idle', true, nil, false)
			blocki:playAnim('idle')
			timer:stop('blockiwalk')
		end)
	elseif name == 'blockiwalkintodoor' then
		local blocki = Global.sen:getBlockByShape('blocki')
		blocki:enablePhysic(false)
		blocki:applyAnim('run', true, nil, true)
		blocki:playAnim('run')
		local vec = Container:get(_Vector3)
		blocki.node.transform:getTranslation(vec)
		blocki.node.transform:mulTranslationRight(-vec.x, -vec.y, -vec.z, duration)
		Container:returnBack(vec)

		local timer = _Timer.new()
		timer:start('blockiwalk', duration, function()
			blocki:enablePhysic(true)
			blocki:stopAnim()
			blocki:applyAnim('idle', true, nil, false)
			blocki:playAnim('idle')
			timer:stop('blockiwalk')
		end)
	elseif name == 'blockiwalkout1' then
		local blocki = Global.sen:getBlockByShape('blocki')
		blocki:enablePhysic(false)
		blocki:applyAnim('run', true, nil, true)
		blocki:playAnim('run')
		blocki.node.transform:mulTranslationRight(0, -8, 0, duration)

		local timer = _Timer.new()
		timer:start('blockiwalk', duration, function()
			local blocki = Global.sen:getBlockByShape('blocki')
			blocki:enablePhysic(true)
			blocki:stopAnim()
			blocki:applyAnim('idle', true, nil, false)
			blocki:playAnim('idle')
			timer:stop('blockiwalk')
		end)
	elseif name == 'blockiwalkout2' then
		local blocki = Global.sen:getBlockByShape('blocki')
		blocki:enablePhysic(false)
		blocki:applyAnim('run', true, nil, true)
		blocki:playAnim('run')
		blocki.node.transform:mulTranslationRight(1.7, 0, 0, duration)

		local timer = _Timer.new()
		timer:start('blockiwalk', duration, function()
			local blocki = Global.sen:getBlockByShape('blocki')
			blocki:enablePhysic(true)
			blocki:stopAnim()
			blocki:applyAnim('idle', true, nil, false)
			blocki:playAnim('idle')
			timer:stop('blockiwalk')
			Global.Achievement:checkorask('blockigoout', function()
				gmm:syncGuideStep()
			end)
		end)
	elseif name == 'continuetalkaftergetnewobject' then
		if gmm.continuetalkfunc then
			gmm.continuetalkfunc()
		else
			gmm:startMovie('showinputui')
		end
	elseif name == 'mlaflagdown' then
		Global.Role.gravity_set(0)
		Global.role.logic.vz = 0
		Global.role.logic.vxy = 0
		Global.role.animaState.able = false
		local flag1 = Global.sen:getBlockByShape('mario_flag1')
		flag1:setVisible(true, false)
		local flag2 = Global.sen:getBlockByShape('mario_flag2')
		flag2:setVisible(true, false)
		flag2.node.transform:mulTranslationRight(0, 0, -6.3, 1000)
		local position = Global.role.cct.position
		position:set(position.x, position.y + 0.3, position.z)
		Global.dungeon:stopBGM()
		Global.SoundManager:play('mario_flagdown.mp3')
	elseif name == 'mladown' then
		local vec = Container:get(_Vector3)
		Global.role:getPosition(vec)
		Global.role.logic.vz = -vec.z / 1000
		Container:returnBack(vec)
	elseif name == 'mlaturn' then
		local vec = Container:get(_Vector3)
		vec:set(0, -1, 0)
		Global.role:updateFace(vec)
		local position = Global.role.cct.position
		position:set(position.x, position.y + 0.3, position.z)
		Container:returnBack(vec)
		Global.SoundManager:play('mario_win.mp3')
	elseif name == 'mlaruntocastle' then
		local vec = Container:get(_Vector3)
		vec:set(0, 1, 0)
		Global.role:updateFace(vec)
		Container:returnBack(vec)
		Global.role.animaState.able = true
		Global.SwitchControl:set_input_off()
		Global.InputManager:setKeys({RIGHT = true})
		Container:returnBack(vec)
	elseif name == 'mlarecover' then
		Global.SwitchControl:set_input_on()
		Global.InputManager:setKeys({})
		Global.role.animaState.able = false
		Global.Role.gravity_set(g)
		Global.role.animaState.able = true
		if _G.OLDRUN_MAX then
			_G.RUN_MAX = _G.OLDRUN_MAX
			_G.OLDRUN_MAX = nil
		end
	elseif name == 'mlarunlowspeed' then
		_G.OLDRUN_MAX = _G.RUN_MAX
		_G.RUN_MAX = 0.0038
	end
end

gmm.playNewObjectMovie = function(self, object)
	gmm.continuetalkfunc = nil
	gmm.newgetobject = object
	gmm:startMovie('getNewObject')
end

gmm.onStartMovie = function()
	Global.EntryEditAnima:clearLook()
end

gmm.onStopMovie = function()
	Global.EntryEditAnima:clearLook()
end

gmm.newgetobjectiscoin = function()
	return gmm.newgetobject and gmm.newgetobject.picfile and gmm.newgetobject.picfile.name == 'coin.png'
end

gmm.onRender = function(e)
	if gmm.newgetobjectpic then
		local vec = Container:get(_Vector3)
		local point = Container:get(_Vector2)
		Global.role:getPosition(vec)
		_rd:projectPoint(vec.x, vec.y, vec.z + 1.8, point)
		local w = gmm.newgetobjectpic.w
		local h = gmm.newgetobjectpic.h
		local size = math.max(256 / w, 256 / h)
		w = w * size
		h = h * size
		gmm.newgetobjectpic:drawImage(point.x - w / 2, point.y - h / 2, point.x + w / 2, point.y + h / 2)
		Container:returnBack(vec, point)
	end
	if gmm.newgetobjectiscoin() then
		if Global.CoinUI:isShow() == false then
			Global.CoinUI:show(true)
		end
	end
end

_app:registerUpdate(gmm)

gmm.guidesteps = {
	{name = 'repair_bridge', canbegin = true},
	{name = 'helpblocki', canbegin = true},
	{name = 'talk3', canbegin = true},
	{name = 'talk4', canbegin = true},
	{name = 'talk5', canbegin = true},
	{name = 'talk6', canbegin = true},
	{name = 'talk7', canbegin = false},
	{name = 'gointohouse', canbegin = true},
	{name = 'talk8', canbegin = true},
	{name = 'talk9', canbegin = true},
	{name = 'talk10', canbegin = true},
	{name = 'talk11', canbegin = false},
	{name = 'repair_work', canbegin = true},
	{name = 'talk12', canbegin = true},
	{name = 'talk13', canbegin = false},
	{name = 'repair_TV', canbegin = true},
	{name = 'talk14', canbegin = true},
	{name = 'talk15', canbegin = false},
	{name = 'decoroomTV', canbegin = true},
	{name = 'talk16', canbegin = true},
	{name = 'talk17', canbegin = true},
	{name = 'talk18', canbegin = true},
	{name = 'talk19', canbegin = false},
	{name = 'fristgetcoin', ignore = true},
	{name = 'fristbuyitem', canbegin = false},
	{name = 'talk20', canbegin = false},
	{name = 'decobuyitem', canbegin = true},
	{name = 'talk21', canbegin = true},
	{name = 'talk22', canbegin = true},
	{name = 'talk23', canbegin = true},
	{name = 'talk24', canbegin = true},
	{name = 'talk25', canbegin = true},
	{name = 'changeislandname', canbegin = true},
	{name = 'talk26', canbegin = true},
	{name = 'talk27', canbegin = true},
	{name = 'blockigoout', ignore = true},
	{name = 'goouthouse', canbegin = true},
	{name = 'talk28', canbegin = true},
	{name = 'talk29', canbegin = false},
	{name = 'fristbrowserroom', canbegin = true},
	{name = 'talk30', canbegin = true},
	{name = defaultthemed .. 'themed', ignore = true},
	{name = defaultthemedobjectachievement, ignore = true},
	{name = 'talk31', canbegin = true},
	{name = 'talk32', canbegin = true},
	{name = 'talk33', canbegin = true},
	{name = 'talk34', canbegin = true},
	{name = 'talk35', canbegin = true},
	{name = 'talk36', canbegin = false},
	{name = 'checkmailfinish', canbegin = true},
	{name = 'talk37', canbegin = true},
	{name = 'talk38', canbegin = true},
	{name = 'talk39', canbegin = true},
	{name = 'talk40', canbegin = false},
	{name = 'buildavatar', canbegin = true},
	{name = 'talk41', canbegin = true},
	{name = 'talk42', canbegin = false},
	{name = 'wearavatar', canbegin = true},
	{name = 'talk43', canbegin = true},
	{name = 'talk44', canbegin = false},

	{name = 'guidetalkfinish', canbegin = true},
}
gmm.SkipGuide = function(self)
	Global.Achievement:register('guidetalkfinish', function()
		gmm:syncGuideStep()
		Global.sen.pfxPlayer:stop('tanhao.pfx', true)
		Global.CoinUI:show(true)
		Global.ui.interact:refresh()
	end)
	for i, a in ipairs(self.guidesteps) do
		Global.Achievement:ask(a.name)
	end
end
gmm.getCurStep = function(self)
	if Global.Achievement:check('guidetalkfinish') then return end

	local steps = {}
	for i, v in ipairs(gmm.guidesteps) do
		if v.ignore ~= true then
			table.insert(steps, v)
		end
	end
	for i = #steps, 2, -1 do
		local step = steps[i]
		local laststep = steps[i - 1]
		if Global.Achievement:check(step.name) == false and Global.Achievement:check(laststep.name) then
			return laststep
		end
	end
end

local setBlockGuideVisible = function(name, visible)
	local block = Global.sen:getBlockByShape(name)
	if block then
		block:showGuide(visible)
	else
		print(name .. ' is not in the scene!')
	end
end

gmm.syncGuideStep = function(self)
	if _sys:getFileName(Global.sen.resname) ~= 'house1.sen' or Global.GameState:isState('Game') then return end

	local arepair_bridge = Global.Achievement:check('repair_bridge')
	setBlockGuideVisible('Broken_bridge', arepair_bridge == false)
	if arepair_bridge then
		self.onEvent('bridgerepaired')
	end

	local blocki = Global.sen:getBlockByShape('blocki')
	blocki:stopAnim()
	blocki:applyAnim('idle', true, nil, false)
	blocki:playAnim('idle')
	if Global.Achievement:check('helpblocki') == false then
		blocki.node.transform:mulRotationZLeft(math.pi / 4)
		blocki:stopAnim()
		blocki:applyAnim('liedown', true, nil, true)
		blocki:playAnim('liedown')

		local fence = Global.sen:getBlockByShape('blocki_fence') -- 压在blocki身上的大石头
		if fence then
			fence.node.visible = true
			fence:enablePhysic(true)
		end
	elseif Global.Achievement:check('talk3') then -- 移除压在blocki身上的大石头
		local fence = Global.sen:getBlockByShape('blocki_fence')
		if fence then
			fence.node.visible = false
			fence:enablePhysic(false)
		end
	end

	if Global.Achievement:check('talk7') then
		self.onEvent('dooropen')
		local vec = Container:get(_Vector3)
		blocki.node.transform:getTranslation(vec)
		blocki.node.transform:mulTranslationRight(-vec.x, -vec.y, -vec.z)
		Container:returnBack(vec)

		if Global.Achievement:check('gointohouse') == false then
			local house = Global.sen:getBlockByShape('mini_house')
			assert(house, 'no mini_house')
			house:registerPress(function()
				gmm:askGuideStepGoIntoHouse()
				house:registerPress()
			end)
		end
	end

	setBlockGuideVisible('work', false)
	if (Global.Achievement:check('talk11') and Global.Achievement:check('repair_work') == false) or
		(Global.Achievement:check('talk13') and Global.Achievement:check('repair_TV') == false) or
		(Global.Achievement:check('talk15') and Global.Achievement:check('decoroomTV') == false) or
		(Global.Achievement:check('talk20') and Global.Achievement:check('decobuyitem') == false) then
		setBlockGuideVisible('work', true)
	end

	setBlockGuideVisible('TV', false)
	if Global.Achievement:check('talk19') and Global.Achievement:check('fristbuyitem') == false then
		setBlockGuideVisible('TV', true)
	end

	setBlockGuideVisible('busstop', false)
	if Global.Achievement:check('talk29') and Global.Achievement:check('fristbrowserroom') == false then
		setBlockGuideVisible('busstop', true)
	end

	setBlockGuideVisible('bulletin', false)
	if Global.Achievement:check('talk36') and Global.Achievement:check('checkmailfinish') == false then
		setBlockGuideVisible('bulletin', true)
	end

	setBlockGuideVisible('lego_AvatarDoor', false)
	if (Global.Achievement:check('talk40') and Global.Achievement:check('buildavatar') == false) or
		(Global.Achievement:check('talk42') and Global.Achievement:check('wearavatar') == false) then
		setBlockGuideVisible('lego_AvatarDoor', true)
	end

	setBlockGuideVisible('lego_ParkDoor', false)
	if Global.Achievement:check('talk44') and Global.Achievement:check('first_gohome') == false then
		setBlockGuideVisible('lego_ParkDoor', true)
	end

	setBlockGuideVisible('blocki', false)
	if Global.Achievement:check('guidetalkfinish') == false and self.blockitalkdisable ~= true then
		local step = Global.gmm:getCurStep()
		if step then
			setBlockGuideVisible('blocki', step.canbegin)
		else
			setBlockGuideVisible('blocki', true)
		end
	end

	if Global.Achievement:check('blockigoout') or Global.Achievement:check('talk28') then
		self.onEvent('dooropen')
		local vec = Container:get(_Vector3)
		blocki.node.transform:getTranslation(vec)
		blocki.node.transform:mulTranslationRight(1.7 - vec.x, -8 - vec.y, -vec.z)
		Container:returnBack(vec)
	end

	if Global.Achievement:check('blockigoout') then
		if Global.Achievement:check('goouthouse') == false then
			local floor = Global.sen:getBlockByShape('Island_floor')
			assert(floor, 'no floor')
			floor:registerPress(function()
				gmm:disableBlockiTalk()
				gmm:askGuideStepGoOutHouse()
				floor:registerPress()
			end)
		end
	end

	if gmm.repairlevel then
		Global.DailyTasks:doneFixTask(gmm.repairlevel)
		gmm.repairlevel = nil
		RPC("GetBlueprints", {})
	end

	if Global.Achievement:check('checkmailfinish') then
		Global.Bulletin:updateGuide()
	end

	self:syncBlockiVisible()
end

gmm.checkGuideStep = function(self, onlycheck)
	if onlycheck ~= true and (_sys:getFileName(Global.sen.resname) ~= 'house1.sen' or Global.GameState:isState('Game')) then return end

	local checksuccess = false
	if checksuccess == false and Global.Achievement:check('repair_bridge') == false then
		if gmm.repairbridgedone then
			if onlycheck then return true end
			Global.Achievement:register('repair_bridge', function()
				self:startMovie('repair_bridge')
				self:syncGuideStep()
				Global.ui.interact:refresh()
			end)
			Global.Achievement:ask('repair_bridge')
			checksuccess = true
		end
	end

	if checksuccess == false and Global.Achievement:check('repair_work') == false then
		if gmm.repairworkdone then
			if onlycheck then return true end
			Global.Achievement:register('repair_work', function()
				self:startMovie('repair_work')
				self:disableBlockiTalk()
				self:syncGuideStep()
				Global.ui.interact:refresh()
			end)
			Global.Achievement:ask('repair_work')
			checksuccess = true
		end
	end

	if checksuccess == false and Global.Achievement:check('repair_TV') == false then
		if gmm.repairTVdone then
			if onlycheck then return true end
			Global.Achievement:register('repair_TV', function()
				self:startMovie('repair_TV')
				self:disableBlockiTalk()
				self:syncGuideStep()
				Global.ui.interact:refresh()
			end)
			Global.Achievement:ask('repair_TV')
			checksuccess = true
		end
	end

	if checksuccess == false and Global.Achievement:check('decoroomTV') == false then
		local block = Global.sen:getBlockByShape('TV')
		if block then
			if onlycheck then return true end
			Global.Achievement:register('decoroomTV', function()
				self:startMovie('decoroomTV')
				self:disableBlockiTalk()
				self:syncGuideStep()
				Global.ui.interact:refresh()
			end)
			Global.Achievement:ask('decoroomTV')
			checksuccess = true
		end
	end

	if checksuccess == false and Global.Achievement:check('fristbuyitem') and self.newgetobject and self.isfristbuy then
		if onlycheck then return true end
		self:startMovie('fristbuyitem')
		self:disableBlockiTalk()
		self:syncGuideStep()
		checksuccess = true
	end

	if checksuccess == false and Global.Achievement:check('decobuyitem') == false then
		local buyworkinscene = false
		for i, v in ipairs(Global.getPurchasedObjects()) do
			if v.state == 2 and Global.sen:getBlockByShape(v.name) then
				buyworkinscene = true
				break
			end
		end
		for i, v in ipairs(Global.GetUnlockObjects()) do
			if Global.sen:getBlockByShape(v.name) then
				buyworkinscene = true
				break
			end
		end
		if buyworkinscene then
			if onlycheck then return true end
			Global.Achievement:register('decobuyitem', function()
				self:startMovie('decobuyitem')
				self:disableBlockiTalk()
				self:syncGuideStep()
				Global.ui.interact:refresh()
			end)
			Global.Achievement:ask('decobuyitem')
			checksuccess = true
		end
	end

	if checksuccess == false and Global.Achievement:check('fristbrowserroom') == false then
		if gmm.browserroomdone then
			if onlycheck then return true end
			Global.Achievement:register('fristbrowserroom', function()
				self:startMovie('fristbrowserroom')
				self:disableBlockiTalk()
				self:syncGuideStep()
				Global.ui.interact:refresh()
			end)
			Global.Achievement:ask('fristbrowserroom')
			gmm.browserroomdone = nil
			checksuccess = true
		end
	end

	if checksuccess == false and Global.Achievement:check('buildavatar') == false then
		if gmm.buildavatardone then
			if onlycheck then return true end
			Global.Achievement:register('buildavatar', function()
				self:startMovie('buildavatar')
				self:disableBlockiTalk()
				self:syncGuideStep()
				Global.ui.interact:refresh()
			end)
			Global.Achievement:ask('buildavatar')
			gmm.buildavatardone = nil
			checksuccess = true
		end
	end

	if checksuccess == false and Global.Achievement:check('wearavatar') == false then
		if gmm.wearavatardone then
			if onlycheck then return true end
			Global.Achievement:register('wearavatar', function()
				self:startMovie('wearavatar')
				self:disableBlockiTalk()
				self:syncGuideStep()
				Global.ui.interact:refresh()
			end)
			Global.Achievement:ask('wearavatar')
			gmm.wearavatardone = nil
			checksuccess = true
		end
	end
end

gmm.syncBlockiVisible = function(self)
	local blocki = Global.sen:getBlockByShape('blocki')
	if blocki then
		if Global.House:isInMyHouse() then
			local binside = blocki:isInsideHouse()
			local rinside = Global.role:isInsideHouse()
			local visible = binside == rinside
			blocki:setVisible(visible, visible)
		else
			blocki:setVisible(false, false)
		end
	end
end

gmm.askGuideStepFristBuy = function(self, object, achievement)
	if Global.Achievement:check('fristbuyitem') == false then
		if achievement ~= '' then
			Global.Achievement:register(achievement, function() end)
		end
		Global.Achievement:register('fristbuyitem', function()
			Global.EntryEditAnima.edit_mode = false
			Global.entry:back() -- 一定是回到自己家
			self.newgetobject = object
			if object.title == nil or object.title == '' then
				object.title = _sys:getFileName(object.name, false, false)
			end
			self.isfristbuy = true
		end)
	end
end

gmm.askGuideStepGoIntoHouse = function(self)
	if Global.Achievement:check('gointohouse') == false then
		Global.Achievement:register('gointohouse', function()
			self:startMovie('gointohouse')
			self:syncGuideStep()
			Global.ui.interact:refresh()
		end)
		Global.Achievement:ask('gointohouse')
	end
end

gmm.askGuideStepGoOutHouse = function(self)
	if Global.Achievement:check('goouthouse') == false then
		Global.Achievement:register('goouthouse', function()
			self:startMovie('goouthouse')
			self:syncGuideStep()
		end)
		Global.Achievement:ask('goouthouse')
	end
end

gmm.askGuideStepChangeIslandName = function(self)
	if Global.Achievement:check('changeislandname') == false then
		Global.Achievement:register('changeislandname', function()
			self:startMovie('changeislandname')
			self:syncGuideStep()
		end)
		Global.Achievement:ask('changeislandname')
	end
end

gmm.askGuideStepCheckMail = function(self)
	if Global.Achievement:check('checkmailfinish') == false then
		Global.Achievement:register('checkmailfinish', function()
			self:startMovie('checkmailfinish')
			self:syncGuideStep()
		end)
		Global.Achievement:ask('checkmailfinish')
	end
end

gmm.disableBlockiTalk = function(self)
	self.blockitalkdisable = true
	setBlockGuideVisible('blocki', false)
	Global.ui.interact:refresh()
end

gmm.addObtainCoin = function(self, num)
	local coinimg = genHtmlImg('coin1.png', 48, 48)
	if self.obtaincoin == nil then
		self.obtaincoin = {picfile = {name = 'coin.png'}, title = coinimg .. num, num = num}
	else
		self.obtaincoin.num = self.obtaincoin.num + num
		self.obtaincoin.title = coinimg .. self.obtaincoin.num
	end
end

gmm.clearObtainCoin = function(self)
	self.obtaincoin = nil
end

gmm.addObtainObject = function(self, object)
	self.obtainobjects = self.obtainobjects or {}
	table.insert(self.obtainobjects, object)
end

gmm.clearObtainObject = function(self)
	dump(self.obtaincoin)
	dump(self.obtainobjects)
	self.obtaincoin = nil
	self.obtainobjects = nil
end

gmm.hasObtainObjects = function(self)
	if self.obtaincoin then return true end
	return self.obtainobjects and #self.obtainobjects > 0 or false
end

gmm.isPlayingObtainMovie = function(self)
	return self.curIndex ~= nil
end

gmm.playObtainMovie = function(self)
	if self.obtaincoin then
		self.obtainobjects = self.obtainobjects or {}
		table.insert(self.obtainobjects, 1, self.obtaincoin)
		self.obtaincoin = nil
	end
	assert(self.obtainobjects and #self.obtainobjects > 0, 'no obtain object!!')
	self.curIndex = 1
	self.continuetalkfunc = function()
		self.curIndex = self.curIndex + 1
		if self.curIndex <= #self.obtainobjects then
			self.newgetobject = self.obtainobjects[self.curIndex]
			self:startMovie('getNewObject')
		else
			self:startMovie('showinputui')
			if self.onObtainMovieFinish then
				self.onObtainMovieFinish()
				self.onObtainMovieFinish = nil
			end
			self.curIndex = nil
			self.obtainobjects = nil
			self.obtaincoin = nil
			self.ongetobject = nil
		end
	end
	self.newgetobject = self.obtainobjects[self.curIndex]
	self:startMovie('getNewObject')
	self.ongetobject = function()
		if self.newgetobject and self.newgetobject.num then
			Global.CoinUI:flush()
		end
	end
end
