local caconfig = {
	-- init camera
	['init'] = {
		['look'] = {
			['x'] = 20,
			['y'] = 20,
			['z'] = 0.8,
		}
	},
	-- ui_login camera
	['login'] = {
		['look'] = {
			['x'] = -92.18927001953125,
			['y'] = -1.1569628715515137,
			['z'] = 12.885293960571289,
		}
	},
	['home'] = {
		['look'] = {
			['x'] = 4.7,
			['y'] = 1.6,
			['z'] = 0.9,
		}
	}
}

local initrespawnpos = {
	[1] = {
		['pos'] = {
			['x'] = 0,
			['y'] = 0,
			['z'] = 0,
		},
		['dir'] = {
			['x'] = 0,
			['y'] = -1,
			['z'] = 0,
		}
	}
}

local curves = {
	['editFocus'] = {-- 快慢型
		['data'] = {
			[1] = {
				['x'] = 0,
				['y'] = 0,
			},
			[2] = {
				['x'] = 0.1,
				['y'] = 0.5,
			},
			[3] = {
				['x'] = 0.2,
				['y'] = 0.8,
			},
			[4] = {
				['x'] = 1,
				['y'] = 1,
			}
		},
		type = _Curve.Hermite
	},
	['camera_rotate'] = {-- 快慢型
		['data'] = {
			[1] = {
				['x'] = 0,
				['y'] = 0,
			},
			[2] = {
				['x'] = 0.5,
				['y'] = 0.7,
			},
			[3] = {
				['x'] = 1,
				['y'] = 1,
			},
		},
		type = _Curve.Hermite
	},
	-- focus camera curve
	['fcc'] = {-- 快慢型
		['data'] = {
			[1] = {
				['x'] = 0,
				['y'] = 0,
			},
			[2] = {
				['x'] = 0.1,
				['y'] = 0.5,
			},
			[3] = {
				['x'] = 1,
				['y'] = 1,
			}
		},
		['type'] = _Curve.Hermite
	},
	-- login camera rotation curve
	['lcc'] = {-- 快慢型
		['data'] = {
			[1] = {
				['x'] = 0,
				['y'] = 0,
			},
			[2] = {
				['x'] = 0.3,
				['y'] = 0.9,
			},
			[3] = {
				['x'] = 1,
				['y'] = 1,
			}
		},
		['type'] = _Curve.Hermite
	},
	['scc'] = {-- 快慢型
		['data'] = {
			[1] = {
				['x'] = 0,
				['y'] = 0,
			},
			[2] = {
				['x'] = 0.7,
				['y'] = 0.9,
			},
			[3] = {
				['x'] = 1,
				['y'] = 1,
			}
		},
		['type'] = _Curve.Hermite
	},
	['speedup'] = {-- 启动并加速
		['data'] = {
			[1] = {
				['x'] = 0,
				['y'] = 0,
			},
			[2] = {
				['x'] = 0.5,
				['y'] = 0.01,
			},
			[3] = {
				['x'] = 0.75,
				['y'] = 0.25,
			},
			[4] = {
				['x'] = 1,
				['y'] = 1,
			}
		},
		['type'] = _Curve.Hermite
	},
	['looknpc'] = {-- 慢快慢
		['data'] = {
			[1] = {
				['x'] = 0,
				['y'] = 0,
			},
			[2] = {
				['x'] = 0.3,
				['y'] = 0.1,
			},
			[3] = {
				['x'] = 0.7,
				['y'] = 0.9,
			},
			[4] = {
				['x'] = 1,
				['y'] = 1,
			}
		},
		['type'] = _Curve.Hermite
	},
	['fadeinout'] = {
		['data'] = {
			[1] = {
				['x'] = 0,
				['y'] = 0,
			},
			[2] = {
				['x'] = 0.2,
				['y'] = 1,
			},
			[3] = {
				['x'] = 0.8,
				['y'] = 1,
			},
			[4] = {
				['x'] = 1,
				['y'] = 0,
			}
		},
		['type'] = _Curve.Hermite
	},
	['fadeout'] = {
		['data'] = {
			[1] = {
				['x'] = 0,
				['y'] = 1,
			},
			[2] = {
				['x'] = 0.7,
				['y'] = 1,
			},
			[3] = {
				['x'] = 1,
				['y'] = 0,
			}
		},
		['type'] = _Curve.Hermite
	}
}

Global.caconfig = caconfig
Global.initrespawnpos = initrespawnpos
Global.Curves = {}
for k, v in pairs(curves) do
	local curve = _Curve.new()
	for _, p in ipairs(v.data) do
		curve:addPoint(_Vector2.new(p.x, p.y))
	end
	curve.type = v.type
	Global.Curves[k] = curve
end