-- KHM Importer for 3DS Max
-- Door Kickers 2 model format importer
-- Version 1.0

clearListener()  -- Clear the listener window

-- ===== CONSTANTS =====
global KHM_VERSION = 101
global KHM_MAX_OBJECT_NAME = 48
global KHM_MAX_BONE_INFLUENCES = 4
global KHM_MAX_BONES = 64

-- ===== DATA STRUCTURES =====

struct KHM_ObjectBase
(
	szName = "",
	uiId = 0,
	uiParentId = -1,
	matLocal = matrix3 1,
	matGlobal = matrix3 1,
	node = undefined
)

struct KHM_CollisionShape
(
	collisionType = 0,  -- 0=Sphere, 1=Box, 2=Capsule, 3=ConvexMesh, 4=Mesh, 5=Plane
	transform = matrix3 1,
	radius = 0.0,
	extents = [0, 0, 0],
	halfHeight = 0.0
)

struct KHM_ObjectMesh
(
	-- Base object properties
	szName = "",
	uiId = 0,
	uiParentId = -1,
	matLocal = matrix3 1,
	matGlobal = matrix3 1,

	-- Geometry
	numVertices = 0,
	pVertices = #(),
	pNormals = #(),
	pColors = #(),
	numTxCoordMaps = 0,
	pTexCoords = #(),

	-- Skin data
	pSkinWeights = #(),
	pSkinBoneIndices = #(),

	-- Indices
	numIndices = 0,
	pIndices = #(),
	pFaceNormals = #(),

	-- Collision
	numCollisions = 0,
	pCollisions = #(),

	-- Bounds
	minBound = [0, 0, 0],
	maxBound = [0, 0, 0],
	volume = 0.0
)

struct KHM_Animation
(
	numNodes = 0,
	startTimeS = 0.0,
	endTimeS = 0.0,
	numNodeFrames = 0,
	frameDurationMs = 0.0,
	pNodeAnimations = #(),
	pNodeTransforms = #()
)

struct KHM_ModelDefinition
(
	pMesh = undefined,
	numHelpers = 0,
	lHelpers = #(),
	numBones = 0,
	lBones = #(),
	pAnimation = undefined
)

-- ===== MAIN IMPORTER STRUCT =====

struct KHMImporter
(
	-- File handle
	fileStream = undefined,

	-- ===== BINARY I/O FUNCTIONS =====

	fn ReadUChar =
	(
		ReadByte fileStream #unsigned
	),

	fn ReadUShort =
	(
		ReadShort fileStream #unsigned
	),

	fn ReadUInt =
	(
		ReadLong fileStream #unsigned
	),

	fn ReadInt =
	(
		ReadLong fileStream #signed
	),

	fn ReadFloat =
	(
		::ReadFloat fileStream
	),

	fn ReadVector2 =
	(
		local u = ReadFloat()
		local v = ReadFloat()
		[u, v]
	),

	fn ReadVector3 =
	(
		local x = ReadFloat()
		local y = ReadFloat()
		local z = ReadFloat()
		[x, y, z]
	),

	-- KHM uses coordinate swizzling: (x, y, z) -> (x, -z, y)
	fn ReadSwizzledVector3 =
	(
		local x = ReadFloat()
		local y = ReadFloat()
		local z = ReadFloat()
		[x, -z, y]
	),

	fn ReadVector4 =
	(
		local x = ReadFloat()
		local y = ReadFloat()
		local z = ReadFloat()
		local w = ReadFloat()
		[x, y, z, w]
	),

	-- Quaternion with swizzling: (x, y, z, w) -> (w, x, -z, y)
	fn ReadQuaternion =
	(
		local x = ReadFloat()
		local y = ReadFloat()
		local z = ReadFloat()
		local w = ReadFloat()
		-- Max uses [w, x, y, z] order for quaternions
		quat w x (-z) y
	),

	-- Read 4x4 matrix with coordinate conversion
	fn ReadMatrix =
	(
		-- Read 16 floats (row-major format from file)
		local floats = #()
		for i = 1 to 16 do
			append floats (ReadFloat())

		-- Extract components from 4x4 matrix
		-- In row-major: [m00 m01 m02 m03] [m10 m11 m12 m13] [m20 m21 m22 m23] [m30 m31 m32 m33]
		-- Translation is in the 4th column: floats[4], floats[8], floats[12]
		local xAxis = [floats[1], floats[2], floats[3]]
		local yAxis = [floats[5], floats[6], floats[7]]
		local zAxis = [floats[9], floats[10], floats[11]]
		local trans = [floats[4], floats[8], floats[12]]

		-- Apply coordinate swizzling: (x, y, z) -> (x, -z, y)
		local newXAxis = [xAxis.x, -xAxis.z, xAxis.y]
		local newYAxis = [yAxis.x, -yAxis.z, yAxis.y]
		local newZAxis = [zAxis.x, -zAxis.z, zAxis.y]
		local newTrans = [trans.x, -trans.z, trans.y]

		-- Build matrix from swizzled components
		local result = matrix3 newXAxis newYAxis newZAxis newTrans

		result
	),

	fn ReadObjectName =
	(
		local nameStr = ""
		for i = 1 to KHM_MAX_OBJECT_NAME do
		(
			local ch = ReadByte fileStream #unsigned
			if ch != 0 then
				nameStr += bit.intAsChar ch
		)
		nameStr
	),

	fn ReadSBoneIndices =
	(
		local indices = #()
		for i = 1 to KHM_MAX_BONE_INFLUENCES do
			append indices (ReadUChar())
		indices
	),

	-- ===== READING FUNCTIONS =====

	fn ReadHeader =
	(
		-- Read magic number - read as individual bytes
		local b1 = ReadByte fileStream #unsigned
		local b2 = ReadByte fileStream #unsigned
		local b3 = ReadByte fileStream #unsigned
		local b4 = ReadByte fileStream #unsigned

		-- Check for KHM header (K=75, H=72, M=77, null=0)
		if b1 != 75 or b2 != 72 or b3 != 77 or b4 != 0 then
		(
			format "ERROR: Invalid KHM file - wrong magic number\n"
			format "  Expected: K(75) H(72) M(77) 0(0)\n"
			format "  Got: %(%) %(%) %(%) %(%)\n" (bit.intAsChar b1) b1 (bit.intAsChar b2) b2 (bit.intAsChar b3) b3 (bit.intAsChar b4) b4
			return false
		)

		-- Read version
		local version = ReadUInt()
		if version != KHM_VERSION then
		(
			format "ERROR: Wrong KHM version. Expected %, got %\n" KHM_VERSION version
			return false
		)

		format "KHM file header valid (version %)\n" version
		true
	),

	fn ReadBones pModelDef =
	(
		local count = ReadUChar()
		format "Reading % bones...\n" count

		if count == 0 then
			return true

		pModelDef.numBones = count
		pModelDef.lBones = #()

		for i = 1 to count do
		(
			local bone = KHM_ObjectBase()
			bone.szName = ReadObjectName()
			bone.uiId = ReadInt()
			bone.uiParentId = ReadInt()
			bone.matLocal = ReadMatrix()
			bone.matGlobal = ReadMatrix()

			append pModelDef.lBones bone
			format "  Bone: % (ID: %, Parent: %)\n" bone.szName bone.uiId bone.uiParentId
		)

		true
	),

	fn ReadHelpers pModelDef =
	(
		local count = ReadUChar()
		format "Reading % helpers...\n" count

		if count == 0 then
			return true

		pModelDef.numHelpers = count
		pModelDef.lHelpers = #()

		for i = 1 to count do
		(
			local helper = KHM_ObjectBase()
			helper.szName = ReadObjectName()
			helper.uiId = ReadInt()
			helper.uiParentId = ReadInt()
			helper.matLocal = ReadMatrix()
			helper.matGlobal = ReadMatrix()
			append pModelDef.lHelpers helper
			format "  Helper: % (ID: %, Parent: %)\n" helper.szName helper.uiId helper.uiParentId
		)

		true
	),

	fn ReadSkin pMesh =
	(
		local hasSkin = ReadUChar()
		format "  Has skin: %\n" hasSkin

		if hasSkin == 0 then
			return true

		-- Read skin weights
		pMesh.pSkinWeights = #()
		for i = 1 to pMesh.numVertices do
			append pMesh.pSkinWeights (ReadVector4())

		-- Read bone indices
		pMesh.pSkinBoneIndices = #()
		for i = 1 to pMesh.numVertices do
			append pMesh.pSkinBoneIndices (ReadSBoneIndices())

		true
	),

	fn ReadCollisionData pMesh =
	(
		pMesh.numCollisions = ReadInt()
		format "  Reading % collisions...\n" pMesh.numCollisions

		if pMesh.numCollisions == 0 then
			return true

		pMesh.pCollisions = #()

		for i = 1 to pMesh.numCollisions do
		(
			local col = KHM_CollisionShape()
			col.collisionType = ReadUInt()
			col.transform = ReadMatrix()

			case col.collisionType of
			(
				0: -- SPHERE
				(
					col.radius = ReadFloat()
					format "    Collision %: Sphere (radius: %)\n" i col.radius
				)
				1: -- BOX
				(
					local x = ReadFloat()
					local y = ReadFloat()
					local z = ReadFloat()
					col.extents = [x, -z, y]  -- Apply swizzling
					format "    Collision %: Box (extents: %)\n" i col.extents
				)
				2: -- CAPSULE
				(
					col.radius = ReadFloat()
					col.halfHeight = ReadFloat()
					format "    Collision %: Capsule (radius: %, halfHeight: %)\n" i col.radius col.halfHeight
				)
				3: -- CONVEX_MESH
				(
					format "    Collision %: Convex Mesh (not fully implemented)\n" i
					-- Skip convex mesh data for now
					local numPolys = ReadInt()
					-- Skip polygon data
					for p = 1 to numPolys do
					(
						ReadVector3()
						ReadFloat()
						ReadUShort()
						ReadUShort()
					)
					local numIndices = ReadInt()
					for p = 1 to numIndices do
						ReadUShort()
					local numVertices = ReadInt()
					for p = 1 to numVertices do
						ReadVector3()
				)
				default:
				(
					format "    WARNING: Unknown collision type %\n" col.collisionType
				)
			)

			append pMesh.pCollisions col
		)

		true
	),

	fn ReadGeometry pMesh =
	(
		format "  Reading geometry...\n"

		-- Read vertices
		pMesh.numVertices = ReadInt()
		format "    Vertices: %\n" pMesh.numVertices
		pMesh.pVertices = #()
		for i = 1 to pMesh.numVertices do
			append pMesh.pVertices (ReadSwizzledVector3())

		-- Read normals
		pMesh.pNormals = #()
		for i = 1 to pMesh.numVertices do
			append pMesh.pNormals (ReadSwizzledVector3())

		-- Read indices
		pMesh.numIndices = ReadInt()
		format "    Indices: % (% triangles)\n" pMesh.numIndices (pMesh.numIndices / 3)
		pMesh.pIndices = #()
		for i = 1 to pMesh.numIndices do
			append pMesh.pIndices (ReadUShort() + 1)  -- +1 because Max is 1-based

		-- Read face normals
		local numFaces = pMesh.numIndices / 3
		pMesh.pFaceNormals = #()
		for i = 1 to numFaces do
			append pMesh.pFaceNormals (ReadSwizzledVector3())

		-- Read vertex colors (optional)
		local hasVertColors = ReadUChar()
		if hasVertColors == 1 then
		(
			format "    Has vertex colors\n"
			pMesh.pColors = #()
			for i = 1 to pMesh.numVertices do
			(
				local r = (ReadUChar() as float) / 255.0
				local g = (ReadUChar() as float) / 255.0
				local b = (ReadUChar() as float) / 255.0
				local a = (ReadUChar() as float) / 255.0
				append pMesh.pColors (color (r * 255) (g * 255) (b * 255) (a * 255))
			)
		)

		-- Read texture coordinates
		pMesh.numTxCoordMaps = ReadUInt()
		format "    UV maps: %\n" pMesh.numTxCoordMaps
		pMesh.pTexCoords = #()

		for mapIdx = 1 to pMesh.numTxCoordMaps do
		(
			for vtxIdx = 1 to pMesh.numVertices do
			(
				local u = ReadFloat()
				local v = 1.0 - ReadFloat()  -- Flip V coordinate
				append pMesh.pTexCoords [u, v, 0]
			)
		)

		-- Read skin data
		ReadSkin pMesh

		-- Read collision data
		ReadCollisionData pMesh

		-- Read bounding box
		pMesh.minBound = ReadVector3()
		pMesh.maxBound = ReadVector3()
		format "    Bounds: % to %\n" pMesh.minBound pMesh.maxBound

		true
	),

	fn ReadMeshes pModelDef =
	(
		local count = ReadUChar()
		format "Reading % meshes...\n" count

		if count == 0 then
			return true

		pModelDef.pMesh = KHM_ObjectMesh()
		local pMesh = pModelDef.pMesh

		pMesh.szName = ReadObjectName()
		pMesh.uiId = ReadInt()
		pMesh.uiParentId = ReadInt()
		pMesh.matLocal = ReadMatrix()
		pMesh.matGlobal = ReadMatrix()

		format "  Mesh: % (ID: %, Parent: %)\n" pMesh.szName pMesh.uiId pMesh.uiParentId

		ReadGeometry pMesh

		true
	),

	fn ReadAnimation pModelDef =
	(
		local count = ReadUChar()
		format "Reading animation (count: %)...\n" count

		if count == 0 then
			return true

		format "  WARNING: Animation import not yet implemented\n"
		-- TODO: Implement animation reading

		true
	),

	fn ReadAnimationMask pModelDef =
	(
		local count = ReadUChar()
		format "Reading animation mask (count: %)...\n" count

		if count == 0 then
			return true

		format "  WARNING: Animation mask import not yet implemented\n"
		-- TODO: Implement animation mask reading

		true
	),

	-- ===== SCENE CREATION =====

	fn CreateBones pModelDef =
	(
		if pModelDef.numBones == 0 then
			return #()

		format "Creating bones...\n"

		local boneNodes = #()
		local idToNode = #()

		-- Create all bones first
		for i = 1 to pModelDef.lBones.count do
		(
			local boneData = pModelDef.lBones[i]
			local boneObj = BoneSys.createBone boneData.matGlobal.position \
			                                     (boneData.matGlobal.position + [0.01, 0, 0]) \
			                                     (boneData.matGlobal.position + [0, 0, 0.01])
			boneObj.name = boneData.szName
			boneObj.transform = boneData.matGlobal
			boneObj.width = 0.01
			boneObj.height = 0.01
			boneObj.showLinks = true

			boneData.node = boneObj
			append boneNodes boneObj

			-- Store in ID lookup
			while idToNode.count <= boneData.uiId do
				append idToNode undefined
			idToNode[boneData.uiId + 1] = boneObj
		)

		-- Parent bones
		for i = 1 to pModelDef.lBones.count do
		(
			local boneData = pModelDef.lBones[i]
			if boneData.uiParentId != -1 and boneData.uiParentId != 4294967295 then
			(
				if boneData.uiParentId + 1 <= idToNode.count and idToNode[boneData.uiParentId + 1] != undefined then
					boneData.node.parent = idToNode[boneData.uiParentId + 1]
			)
		)

		boneNodes
	),

	fn CreateHelpers pModelDef idToNode =
	(
		if pModelDef.numHelpers == 0 then
			return #()

		format "Creating helpers...\n"

		local helperNodes = #()

		for i = 1 to pModelDef.lHelpers.count do
		(
			local helperData = pModelDef.lHelpers[i]
			local helperObj = Point name:helperData.szName \
			                        pos:helperData.matGlobal.position \
			                        size:0.5 \
			                        cross:true \
			                        box:false
			helperObj.transform = helperData.matGlobal

			helperData.node = helperObj
			append helperNodes helperObj

			-- Store in ID lookup
			while idToNode.count <= helperData.uiId do
				append idToNode undefined
			idToNode[helperData.uiId + 1] = helperObj

			-- Parent if needed
			if helperData.uiParentId != -1 and helperData.uiParentId != 4294967295 then
			(
				if helperData.uiParentId + 1 <= idToNode.count and idToNode[helperData.uiParentId + 1] != undefined then
					helperObj.parent = idToNode[helperData.uiParentId + 1]
			)
		)

		helperNodes
	),

	fn CreateMesh pModelDef idToNode =
	(
		if pModelDef.pMesh == undefined then
			return undefined

		format "Creating mesh...\n"

		local pMesh = pModelDef.pMesh

		-- Build face array
		local faces = #()
		for i = 1 to pMesh.numIndices by 3 do
		(
			append faces [pMesh.pIndices[i], pMesh.pIndices[i+1], pMesh.pIndices[i+2]]
		)

		-- Create mesh
		local meshObj = mesh name:pMesh.szName \
		                     vertices:pMesh.pVertices \
		                     faces:faces

		-- Set normals
		for i = 1 to pMesh.pNormals.count do
		(
			setNormal meshObj i pMesh.pNormals[i]
		)

		-- Set UVs
		if pMesh.pTexCoords.count > 0 then
		(
			meshop.setNumMaps meshObj 2 keep:true
			meshop.setMapSupport meshObj 1 true
			buildTVFaces meshObj

			for i = 1 to pMesh.pTexCoords.count do
			(
				meshop.setMapVert meshObj 1 i pMesh.pTexCoords[i]
			)

			-- Copy face indices to TV faces
			for i = 1 to faces.count do
			(
				meshop.setMapFace meshObj 1 i faces[i]
			)
		)

		-- Set vertex colors
		if pMesh.pColors.count > 0 then
		(
			meshop.setNumCPVVerts meshObj pMesh.pColors.count
			for i = 1 to pMesh.pColors.count do
			(
				meshop.setVertColor meshObj 0 i pMesh.pColors[i]
			)
		)

		-- Apply transform with coordinate correction
		-- Apply an additional -90 degree rotation around X axis to correct orientation
		local rotationCorrection = rotateXMatrix -90
		meshObj.transform = pMesh.matGlobal * rotationCorrection

		-- Store in ID lookup
		while idToNode.count <= pMesh.uiId do
			append idToNode undefined
		idToNode[pMesh.uiId + 1] = meshObj

		-- Apply skin modifier if we have bones and skin data
		if pModelDef.numBones > 0 and pMesh.pSkinWeights.count > 0 then
		(
			format "  Applying skin weights...\n"

			-- Collect all bone nodes
			local boneNodes = #()
			for i = 1 to pModelDef.lBones.count do
			(
				if pModelDef.lBones[i].node != undefined then
					append boneNodes pModelDef.lBones[i].node
			)

			if boneNodes.count > 0 then
			(
				-- Ensure mesh is updated and finalized
				update meshObj

				-- Convert to Editable Mesh
				convertToMesh meshObj

				-- Force another update after conversion
				update meshObj

				-- Verify mesh has vertices
				format "  Mesh object has % vertices\n" meshObj.numverts

				-- Add skin modifier
				local skinMod = Skin()
				addModifier meshObj skinMod

				-- Update the modifier stack
				update meshObj

				-- Add all bones to skin modifier and create index mapping
				-- Maps bone index (from file) to skin modifier bone index
				local boneIndexToSkinIndex = #()
				for i = 1 to pModelDef.lBones.count do
				(
					append boneIndexToSkinIndex 0  -- Initialize with 0 (invalid)
				)

				for i = 1 to pModelDef.lBones.count do
				(
					if pModelDef.lBones[i].node != undefined then
					(
						skinOps.addBone skinMod pModelDef.lBones[i].node 1
						-- Get the actual index in the skin modifier (should be sequential)
						local actualBoneCount = skinOps.GetNumberBones skinMod
						boneIndexToSkinIndex[i] = actualBoneCount
					)
				)

				local totalSkinBones = skinOps.GetNumberBones skinMod
				format "  Added % bones to skin modifier\n" totalSkinBones

				-- Set vertex weights (use mesh vertex count, not skin vertex count)
				format "  Applying weights to % vertices\n" pMesh.numVertices
				for vertIdx = 1 to pMesh.numVertices do
				(
					local weights = pMesh.pSkinWeights[vertIdx]
					local boneIndices = pMesh.pSkinBoneIndices[vertIdx]

					-- Build arrays of bone indices and weights (only non-zero weights)
					local weightArray = #()
					local boneArray = #()

					if weights.x > 0.0001 and boneIndices[1] >= 0 and boneIndices[1] < pModelDef.lBones.count then
					(
						local skinIdx = boneIndexToSkinIndex[boneIndices[1] + 1]
						if skinIdx > 0 and skinIdx <= totalSkinBones then
						(
							append boneArray skinIdx
							append weightArray weights.x
						)
					)
					if weights.y > 0.0001 and boneIndices[2] >= 0 and boneIndices[2] < pModelDef.lBones.count then
					(
						local skinIdx = boneIndexToSkinIndex[boneIndices[2] + 1]
						if skinIdx > 0 and skinIdx <= totalSkinBones then
						(
							append boneArray skinIdx
							append weightArray weights.y
						)
					)
					if weights.z > 0.0001 and boneIndices[3] >= 0 and boneIndices[3] < pModelDef.lBones.count then
					(
						local skinIdx = boneIndexToSkinIndex[boneIndices[3] + 1]
						if skinIdx > 0 and skinIdx <= totalSkinBones then
						(
							append boneArray skinIdx
							append weightArray weights.z
						)
					)
					if weights.w > 0.0001 and boneIndices[4] >= 0 and boneIndices[4] < pModelDef.lBones.count then
					(
						local skinIdx = boneIndexToSkinIndex[boneIndices[4] + 1]
						if skinIdx > 0 and skinIdx <= totalSkinBones then
						(
							append boneArray skinIdx
							append weightArray weights.w
						)
					)

					-- Apply weights to this vertex
					if weightArray.count > 0 then
					(
						skinOps.ReplaceVertexWeights skinMod vertIdx boneArray weightArray
					)
				)

				format "  Skin weights applied successfully\n"
			)
			else
			(
				format "  WARNING: No bone nodes found for skinning\n"
			)
  		)

		meshObj
	),

	fn CreateCollisions pModelDef meshObj =
	(
		if pModelDef.pMesh == undefined then
			return #()

		local pMesh = pModelDef.pMesh
		if pMesh.numCollisions == 0 then
			return #()

		format "Creating collision objects...\n"

		local collisionObjs = #()

		for i = 1 to pMesh.pCollisions.count do
		(
			local col = pMesh.pCollisions[i]
			local colObj = undefined

			-- Apply same rotation correction as mesh
			local rotationCorrection = rotateXMatrix -90

			case col.collisionType of
			(
				0: -- SPHERE
				(
					colObj = Sphere radius:col.radius segments:16 \
					               name:("COL_SPHERE_" + i as string) \
					               wirecolor:yellow
					colObj.transform = col.transform * rotationCorrection
				)
				1: -- BOX
				(
					colObj = Box length:(col.extents.x * 2) width:(col.extents.y * 2) height:(col.extents.z * 2) \
					            name:("COL_BOX_" + i as string) \
					            wirecolor:yellow
					colObj.transform = col.transform * rotationCorrection
				)
				2: -- CAPSULE
				(
					colObj = Cylinder radius:col.radius height:(col.halfHeight * 2 + col.radius * 2) \
					                  name:("COL_CAPSULE_" + i as string) \
					                  wirecolor:yellow
					colObj.transform = col.transform * rotationCorrection
				)
			)

			if colObj != undefined then
			(
				colObj.parent = meshObj
				append collisionObjs colObj
			)
		)

		collisionObjs
	),

	-- ===== MAIN IMPORT FUNCTION =====

	fn ImportKHM filename =
	(
		format "\n========================================\n"
		format "Importing KHM file: %\n" filename
		format "========================================\n\n"

		-- Open file
		fileStream = fopen filename "rb"
		if fileStream == undefined then
		(
			format "ERROR: Could not open file: %\n" filename
			return false
		)

		-- Read header
		if not ReadHeader() then
		(
			fclose fileStream
			return false
		)

		-- Create model definition
		local pModelDef = KHM_ModelDefinition()

		-- Read all sections
		ReadBones pModelDef
		ReadHelpers pModelDef
		ReadMeshes pModelDef
		ReadAnimation pModelDef
		ReadAnimationMask pModelDef

		-- Close file
		fclose fileStream
		fileStream = undefined

		format "\n========================================\n"
		format "File reading complete. Creating scene objects...\n"
		format "========================================\n\n"

		-- Create scene objects
		local idToNode = #()
		local boneNodes = CreateBones pModelDef
		local helperNodes = CreateHelpers pModelDef idToNode
		local meshObj = CreateMesh pModelDef idToNode
		local collisionObjs = CreateCollisions pModelDef meshObj

		format "\n========================================\n"
		format "Import complete!\n"
		format "  Bones: %\n" boneNodes.count
		format "  Helpers: %\n" helperNodes.count
		format "  Mesh: %\n" (if meshObj != undefined then meshObj.name else "None")
		format "  Collisions: %\n" collisionObjs.count
		format "========================================\n\n"

		true
	)
)

-- ===== PLUGIN INTERFACE =====
-- ===== RUN SCRIPT TO IMPORT =====
-- When this script is run via Scripting > Run Script, it opens a file dialog

format "\n===========================================\n"
format "KHM Importer for 3DS Max\n"
format "===========================================\n\n"

filename = getOpenFileName caption:"Select KHM file to import" \
                            types:"KHM Files (*.khm)|*.khm|All Files (*.*)|*.*"

if filename != undefined then
(
	format "Importing: %\n" filename
	importer = KHMImporter()
	importer.ImportKHM filename
)
else
(
	format "Import cancelled by user.\n"
)
