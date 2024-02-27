Global.CONSTPICKFLAG = {
	NONE = 0,
	NORMALBLOCK = 1,
	SELECTBLOCK = 2,
	ROLE = 4,
	TERRAIN = 8,
	GROUPSELECT = 16,
	WALL = 32,
	DUMMY = 64,
	KNOT = 128,
	BONE = 256,
	JOINT = 512,
	SELECTWALL = 1024,
	PHYSICALBLOCK = 2048,

	-- 特殊标记，pick部分物件时可临时设置此标记，注意pick完后要改回原值
	SWEEPTEST = 4096,

	-- 单向门
	BLOCK_QUERY = 8192,
}