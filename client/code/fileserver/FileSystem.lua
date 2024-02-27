--[[
	文件管理
	files
		会记录到save文件
		结构(array)
			每个元素
			{
				filename
				md5
				state(存了没用)
					做辅助标记，默认LOCAL
					UPDATED 和服务器同步过
			}

		所有文件在【加载】时，要走一遍【下载】的逻辑
			第一次访问：直接下载
			本地创建上传：上传完之后走下载
		下载的检查
			1.查一下记录的file能否和md5对应，若对应，只做本地下载（改文件名，如果需要）的处理
			2.不对应，说明需要走网络下载
				1.下载成功
					1.md5一致，结束
					2.md5不一致，标记
				2.下载失败

]]

_require('ExtendString')
local STATE = {
	LOCAL = 0,
	UPLOADED = 1,
	UPDATED = 2,
	DOWNLOADING = 3,
}
local UPLOAD_STATE = {
	NORMAL = 0,
	ERROR = 1,
}
local FileSystem = {downs = {}, ups = {}, tasks = {}}
FileSystem.files = Global.SaveManager:Register('filesystem')
FileSystem.init = function(self)
	for i, f in ipairs(self.files) do
		f.state = STATE.LOCAL
	end
end
FileSystem.clearCache = function(self, deep)
	if deep then
		for i, f in ipairs(self.files) do
			_sys:delFile(_sys:getSaveFileName(f.filename))
		end
	end

	for i in next, self.files do
		self.files[i] = nil
	end
	Global.SaveManager:Save(true)
end
FileSystem.dump = function(self)
	print('===== files =====')
	dump(self.files)
	print('===== tasks =====')
	dump(self.tasks)
end
Global.FileSystem = FileSystem
FileSystem.new = function()
	local o = {}
	setmetatable(o, {__index = FileSystem})

	o.loader = _Loader.new()

	return o
end
FileSystem.downloadFile = function(self, url, filename, onprogress, onfinish)
	if onprogress then
		self.loader:onProgress(onprogress)
	end

	if onfinish then
		self.loader:onFinish(onfinish)
	end

	filename = _sys:getSaveFileName(filename)

	self.loader:loadHttp(url, filename)
end
FileSystem.stop = function(self)
	self.loader:stop()
end
----------------------------------------------------------------
-- {
-- 	name = 'xxxx',
-- 	md5 = 'xxx',
-- 	url = 'xxxx'
-- }
FileSystem.downloadData = function(self, d, onprogress, onfinish)
	self:downloadDatas({d}, onprogress, onfinish)
end
FileSystem.downloadDatas = function(self, ds, onprogress, onfinish)
	local index = ''
	local datas = {}
--	print('[FileSystem.downloadDatas] ======', datas, debug.traceback())
	for i, data in ipairs(ds) do
		datas[i] = {
			name = data.name,
			md5 = data.md5,
			url = data.url,
		}
	end

	local file_changed = true
	for i, data in ipairs(datas) do
		local f = self:new_upload_getByMd5(data.md5)
		if f then
			-- print('[FileSystem.downloadDatas] Record exist', data.name, f.state)
			if self:atom_checkFile(f) then
				-- 检查一致
				-- print('[FileSystem.downloadDatas] atom_checkFile, true')
				self:new_downloadLocal(data.md5, data.name)
				file_changed = false
			else
				data.downloadrecord = f
				f.filename = data.name
				index = index .. data.name
			end
		else
			f = self:new_fileRecord(data.name, data.md5, STATE.LOCAL)
			if self:atom_checkFile(f) then
				-- 恰好一样
			else
				-- 直接download
--				print('[FileSystem.downloadDatas] Download', data.name, data.md5, data.url)
				data.downloadrecord = f
				index = index .. data.name
			end
		end
	end

	if index == '' then
		if onfinish then
			onfinish(true, file_changed)
			return true
		end
	end

	local l = self.downs[index]
	if l then
		table.insert(l.onFinishs, onfinish)
		return
	end

	l = _Loader.new()
	l.onFinishs = {}
	l:onProgress(onprogress)
	l:onFinish(function()
		local success = true
		for i, data in ipairs(datas) do
			local f = data.downloadrecord
			if f then
				if self:atom_checkFile(f) then
				else
					if self:atom_isFileValid(f) then
						print('[FileSystem] download incorrect md5', f.md5, data.url, debug.traceback())
					else
						print('[FileSystem] Websystem error', f.md5, data.url, debug.traceback())
					end
					success = false

					_sys:delFile(_sys:getSaveFileName(f.filename))
				end
			end
		end
		self:new_task_update()
		for i, f in ipairs(l.onFinishs) do
			f(success, file_changed)
		end
		self.downs[index] = nil
	end)
	for i, data in ipairs(datas) do
		if data.downloadrecord then
--			print('[FileSystem] Download file =============', data.url, data.name, data.md5)
			l:loadHttp(data.url, _sys:getSaveFileName(data.name))
		end
	end
	table.insert(l.onFinishs, onfinish)
	self.downs[index] = l
end
----------------------------------------------------------------------
FileSystem.new_fileExist = function(self, md5)
	local f = self:new_upload_getByMd5(md5)
	if f then
		return self:atom_checkFile(f)
	end
end
FileSystem.new_downloadLocal = function(self, md5, filename)
	local f = self:new_upload_getByMd5(md5)
	if f.filename ~= filename then
		_sys:moveFile(_sys:getSaveFileName(f.filename), _sys:getSaveFileName(filename))
--		print('[FileSystem.new_downloadLocal]', f.filename, filename, debug.traceback())
		f.filename = filename
	end
	self:new_task_update()
end
FileSystem.new_fileRecord = function(self, filename, md5, state)
	local f = self:new_upload_getByMd5(md5)
	-- print('[FileSystem.new_fileRecord]', filename, md5, state)
	assert(f == nil, 'fileRecord duplicated:' .. filename)

	f = {
		filename = filename,
		md5 = md5,
		state = state,
		upload_state = UPLOAD_STATE.NORMAL
	}
	table.insert(self.files, f)

	self:new_update()

	return f
end
----------------------------------------------------------------
FileSystem.atom_checkFile = function(self, f)
	--print('checkfile', f.filename, _sys:md5(_File.getString(f.filename)), f.md5)
	return _sys:md5(_File.getString(f.filename)) == f.md5
end
FileSystem.atom_isFileValid = function(self, f)
	local content = _File.getString(f.filename)
	if not content then return false end

	if content:find('<html>') then
		return false
	end

	return true
end
FileSystem.atom_newName = function(self, ext)
	return Global.Login:getAid() .. '_' .. _now(0.001) .. '_' .. _tick() .. '.' .. ext
end
FileSystem.atom_newData = function(self, ext, data)
	local filename = self:atom_newName(ext)
	_File.writeString(filename, data, 'utf-8')

	return self:atom_newFile(filename)
end
FileSystem.atom_newFile = function(self, filename)
	local md5 = _sys:md5(_File.getString(filename))
	local f = self:new_upload_getByMd5(md5)
	if f then
		print('[FileSystem.atom_newFile] delete', filename, f.filename)
		if filename ~= f.filename then
			_sys:delFile(_sys:getSaveFileName(filename))
		end
		return f.filename, md5
	end
	self:new_fileRecord(filename, md5, STATE.LOCAL)

	return filename, md5
end
FileSystem.atom_newPic = function(self, tempid, config, callback)
	self:atom_newName('bmp')
	Global.CaptureManager:addTask(tempid, config, callback)

	-- return self:atom_newFile(filename)
end
FileSystem.new_update = function(self)
--	print('[FileSystem.new_update]', debug.traceback())
	Global.SaveManager:Save()
	self:new_task_update()
end
local tid = 0
FileSystem.new_task_new = function(self, files, callback)
	self.tasks[tid] = {
		files = table.clone(files),
		callback = callback,
	}

	tid = tid + 1

	for i, f in ipairs(files) do
		self:new_uploadOne(f)
	end
end
FileSystem.new_task_update = function(self)
	local finish, success
	for k, t in next, self.tasks do
		print('[FileSystem.new_task_update] task', k)
		finish = true
		success = true
		for i, filename in ipairs(t.files) do
			local f = self:new_upload_getByName(filename)
			-- print('[FileSystem.new_task_update]', f, filename, f and f.state, f and f.upload_state)
			if not f then
				print('[FileSystem.new_task_update] file not exist, treat as downloaded local')
			elseif f.upload_state == UPLOAD_STATE.NORMAL and f.state == STATE.LOCAL then
				finish = false
				break
			elseif f.upload_state == UPLOAD_STATE.ERROR then
				success = false
			end
		end

		-- print('[new_task_update]', success)
		if finish then
			self.tasks[k] = nil
			if t.callback then
				t.callback(success)
			end
		end
	end
end
FileSystem.new_uploadFiles = function(self, files, callback)
	self:new_task_new(files, callback)
	self:new_task_update()
end
-- filename -> url -> upload -> fid
FileSystem.new_upload_getByMd5 = function(self, md5)
	for i, v in ipairs(self.files) do
		if v.md5 == md5 then
			return v
		end
	end
end
FileSystem.new_upload_getByName = function(self, filename)
	for i, v in ipairs(self.files) do
		if v.filename == filename then
			return v
		end
	end
end
FileSystem.new_uploadOne = function(self, filename)
	-- print('[FileSystem.new_uploadOne]', filename)
	local f = self:new_upload_getByName(filename)
	if not f then
		print('[FileSystem.new_uploadOne] File record not found', filename)
		self:atom_newFile(filename)
		f = self:new_upload_getByName(filename)
	end

	-- print('[FileSystem.new_uploadOne] f.state', f.filename, f.state)
	if f.state == STATE.LOCAL then
		f.upload_state = UPLOAD_STATE.NORMAL
		RPC('File_Upload', {Type = _sys:getExtention(filename), Md5 = f.md5})
	end
end
FileSystem.new_upload_upload = function(self, url, md5)
	-- md5 -> filename
	local f = self:new_upload_getByMd5(md5)
	-- filename -> upload to url
	local strs = string.split(url, '/')
	-- print('[FileSystem.new_upload_upload]', url, md5, table.ftoString(f), strs[#strs])
	_sys:httpPostUpload(url, _sys:getSaveFileName(f.filename), strs[#strs], function(rescode)
		local success = rescode == 200
		-- if rescode == 200 then
		-- 	Notice('httpPostUpload success')
		-- elseif rescode > 700 then
		-- 	Notice('httpPostUpload error file not exist')
		-- elseif rescode > 600 then
		-- 	Notice('httpPostUpload error net error')
		-- elseif rescode > 400 then
		-- 	Notice('httpPostUpload error post param error')
		-- end
		self:new_upload_onFinish(md5, success)
		if not success then
			f.upload_state = UPLOAD_STATE.ERROR
			print('[FileSystem.new_upload_upload] failed', f.filename, f.upload_state, rescode)
			self:new_task_update()
		end
	end)
end
FileSystem.uploadTmpFile = function(self, url, filename, callback)
	-- md5 -> filename
	if not _sys:fileExist(filename) then
		if callback then
			callback(false)
		end
		return
	end
	-- filename -> upload to url
	local strs = string.split(url, '/')
	_sys:httpPostUpload(url, _sys:getSaveFileName(filename), strs[#strs], function(rescode)
		local success = rescode == 200
		if rescode == 200 then
			print('[uploadTmpFile] httpPostUpload success')
		elseif rescode > 700 then
			print('[uploadTmpFile] httpPostUpload error file not exist')
		elseif rescode > 600 then
			print('[uploadTmpFile] httpPostUpload error net error')
		elseif rescode > 400 then
			print('[uploadTmpFile] httpPostUpload error post param error')
		end
		if callback then
			callback(success)
		end
	end)
end
FileSystem.new_upload_onFinish = function(self, md5, success)
	RPC('File_Upload_Finish', {Md5 = md5, Success = success})
end
FileSystem.new_upload_getFid = function(self, fid, md5)
--	print('[FileSystem.new_upload_getFid]', fid, md5)
	local f = self:new_upload_getByMd5(md5)
	f.fid = fid
	f.state = STATE.UPLOADED
	self:new_update()
end

define.File_GetUrl{Url = '', Md5 = ''}
when{}
function File_GetUrl(Url, Md5)
	-- print('[File_GetUrl]', Url, Md5)
	FileSystem:new_upload_upload(Url, Md5)
end
define.File_GetFid{Fid = -1, Md5 = ''}
when{}
function File_GetFid(Fid, Md5)
	-- print('[File_GetFid]', Fid, Md5)
	FileSystem:new_upload_getFid(Fid, Md5)
end
define.File_Uploading{Md5 = ''}
when{}
function File_Uploading()
	-- print('[File_Uploading]')
	FileSystem:new_task_update()
end

FileSystem:init()