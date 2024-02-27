local dt = {
	OnGetHouseThemedTask,
	OnDoneHouseThemedTask,
	OnGetFixTask,
	OnDoneFixTask,
}
Global.DailyTasks = dt

dt.getHouseThemedTask = function(self, callback)
	self.OnGetHouseThemedTask = callback

	RPC('GetHouseThemedTask', {})
end
dt.changeHouseThemedTask = function(self, theme)
	RPC('ChangeHouseThemedTask', {Theme = theme})
end
dt.doneHouseThemedTask = function(self, task, callback)
	self.OnDoneHouseThemedTask = callback
	RPC('DoneHouseThemedTask', {Task = task})
end

dt.getFixTask = function(self, callback)
	self.OnGetFixTask = callback

	RPC('GetFixTask', {})
end
dt.doneFixTask = function(self, level, callback)
	self.OnDoneFixTask = callback
	RPC('DoneFixTask', {Level = level})
end

-------------------------------------------
define.GetHouseThemedTaskInfo{Result = false, Info = {}}
when{}
function GetHouseThemedTaskInfo(Result, Info)
	if dt.OnGetHouseThemedTask then
		dt.OnGetHouseThemedTask(Result, Info.res)
	end
end

define.GetFixTaskInfo{Result = false, Info = {}}
when{}
function GetFixTaskInfo(Result, Info)
	if dt.OnGetFixTask then
		dt.OnGetFixTask(Result, Info.res)
	end
end

define.DoneHouseThemedTaskInfo{Result = false, Info = {}}
when{}
function DoneHouseThemedTaskInfo(Result, Info)
	if dt.OnDoneHouseThemedTask then
		dt.OnDoneHouseThemedTask(Result, Info.Achievement, Info.Activeness)
	end
end

define.DoneFixTaskInfo{Result = false, Info = {}}
when{}
function DoneFixTaskInfo(Result, Info)
	if dt.OnDoneFixTask then
		dt.OnDoneFixTask(Result, Info.Achievement, Info.Activeness)
	end
end