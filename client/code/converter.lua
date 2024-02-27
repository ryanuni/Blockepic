local converter = {}

Global.Converter = converter

-- mesh_str
-- "POSITION" : 0, "NORMAL" : 1
-- "indices" : 1
local GLTF_mesh_str = [[
"meshes" : [
  {
    "name" : "%s",
    "primitives" : [
        {
            "attributes" : {
              %s
            },
            "indices" : %d
        }
    ]
  }
],
]]

-- buffer_str
-- vb in base64
-- ib in base64
local GLTF_buffer_str = [[
"buffers" : [
  {
    "uri" : "data:application/octet-stream;base64,%s",
    "byteLength" : %d
  },
  {
    "uri" : "data:application/octet-stream;base64,%s",
    "byteLength" : %d
  }
],
]]

-- bufferViews_str
-- position buffer view :34963
-- normal buffer view bytestride
-- index buffer view : 34962
local GLTF_bufferView_str = [[
  {
    "buffer" : %d,
    "byteOffset" : %d,
    "byteStride" : %d,
    "byteLength" : %d,
    "target" : %d
  }
]]

local GLTF_bufferViews_str = [[
  "bufferViews" : [
    %s
  ],
]]

-- accessors_str
-- position buffer accessors 
-- normal buffer accessors bytestride
-- index buffer accessors
-- "componentType" : float:5126,word:5123
local GLTF_accessor_str = [[
  {
    "bufferView" : %d,
    "byteOffset" : %d,
    "componentType" : %d,
    "count" : %d,
    "type" : "%s"
  }
]]

local GLTF_accessors_str = [[
"accessors" : [
  %s
]
]]

local GLTF_str = [[
{
  "asset" : {
    "version" : "2.0"
  },
  "scene": 0,
  "scenes" : [
    {
      "nodes" : [ 0 ]
    }
  ], 
  "nodes" : [
    {
      "mesh" : 0
    }
  ],
  %s
  %s
  %s
  %s
}
]]

local GLTF = {
    scene = 0,
    scenes = {},
    nodes = {},
    meshes = {},
    buffers = {},
    bufferViews = {},
    accessors = {},
    asset = {},
}

GLTF.convert = function(mesh)
    local vb = mesh:getVertexBuffer(_Mesh.OriBuffer)
    local ib = mesh:getIndexBuffer(_Mesh.OriBuffer)
    local format = mesh.vertexFormat
    local vertexCount = mesh:getVertexCount()
    local faceCount = mesh:getFaceCount()
    local VB_URI = string.enbase64(vb)
    local IB_URI = string.enbase64(ib)
    print(VB_URI)
    print(IB_URI)
    print(format, vertexCount, faceCount)

    local _floatSize = 4
    local vertexStride = 3 * _floatSize
    local mesh_attr_str = '"POSITION" : 0'

    local n = 1
    if _and(format, _Mesh.Normal) ~= 0 then 
      mesh_attr_str = mesh_attr_str .. (',"NORMAL" : %d'):format(n)
      vertexStride = vertexStride + 3 * _floatSize 
      n = n + 1 
    end
    
    if _and(format, _Mesh.Diffuse) ~= 0 then 
      mesh_attr_str = mesh_attr_str .. (',"COLOR" :  %d'):format(n)
      vertexStride = vertexStride + 1 * _floatSize 
      n = n + 1 
    end

    if _and(format, _Mesh.Texcoord1) ~= 0 then 
      mesh_attr_str = mesh_attr_str .. (',"TEXCOORD" :  %d'):format(n)  
      vertexStride = vertexStride + 2 * _floatSize 
      n = n + 1 
    end

    local mesh_str = GLTF_mesh_str:format(mesh.resname, mesh_attr_str, n)

    local VB_length = vertexCount * vertexStride 
    local IB_length = faceCount * 3 * 2 -- word length : 2 

    local buff_str = GLTF_buffer_str:format(VB_URI, VB_length, IB_URI, IB_length)
    
    local bufferView_str = GLTF_bufferView_str:format(0, 0, vertexStride, VB_length, 34963)
    local accessor_str = GLTF_accessor_str:format(0, 0, 5126, vertexCount, "VEC3")
    n = 1
    local vertexOffset = 3 * _floatSize
    if _and(format, _Mesh.Normal) ~= 0 then 
      bufferView_str = bufferView_str .. ',' .. GLTF_bufferView_str:format(0, vertexOffset, vertexStride, VB_length, 34963)
      accessor_str = accessor_str .. ',' .. GLTF_accessor_str:format(n, 0, 5126, vertexCount, "VEC3")
      vertexOffset = vertexOffset + 3 * _floatSize
      n = n + 1 
    end
    
    if _and(format, _Mesh.Diffuse) ~= 0 then 
      bufferView_str = bufferView_str .. ',' .. GLTF_bufferView_str:format(0, vertexOffset, vertexStride, VB_length, 34963)
      accessor_str = accessor_str .. ',' .. GLTF_accessor_str:format(n, 0, 5126, vertexCount, "UINT")
      vertexOffset = vertexOffset + 1 * _floatSize
      n = n + 1 
    end

    if _and(format, _Mesh.Texcoord1) ~= 0 then 
      bufferView_str = bufferView_str .. ',' .. GLTF_bufferView_str:format(0, vertexOffset, vertexStride, VB_length, 34963)
      accessor_str = accessor_str .. ',' .. GLTF_accessor_str:format(n, 0, 5126, vertexCount, "VEC2")
      vertexOffset = vertexOffset + 2 * _floatSize
      n = n + 1 
    end

    bufferView_str = bufferView_str .. ',' .. GLTF_bufferView_str:format(1, 0, 0, IB_length, 34962)
    accessor_str = accessor_str .. ',' .. GLTF_accessor_str:format(n, 0, 5123, faceCount * 3, "SCALAR")

    return GLTF_str:format( mesh_str, buff_str, GLTF_bufferViews_str:format(bufferView_str), GLTF_accessors_str:format(accessor_str))
end

converter.save = function(mesh, name)
  local str = GLTF.convert(mesh)
  local file = _File.new()
  file:create(name, 'utf8')
  file:write(str)
  file:close()
end