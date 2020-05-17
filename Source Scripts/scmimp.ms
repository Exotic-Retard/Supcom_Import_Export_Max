--mesh importer
fileIn "help.ms"
--triangle struct
struct SCM_Tris
(
	triindex, --3 unsigned shorts 
	
	fn LoadFromStream bstream=
	(
		local x = Readshort bstream #unsigned
		local y = Readshort bstream #unsigned
		local z = Readshort bstream #unsigned
		triindex = [x+1, y+1, z+1]
	)
)
--vertex struct
struct SCM_Vert
(
	Position, --float vector(x,y,z) position relative to the local origion of the mesh
	--Tangent Space
	Normal, -- float vector(x,y,z)
	Tangent, -- float vector(x,y,z)
	Binormal, -- float vector(x,y,z)
	--supports two sets of uv coordinates (awesome!)
	uv1, --floatvector(u,v)
	uv2, --floatvector(u,v)
	boneindex, -- array of 4 chars - verts can be weighted to up to 4 bones. Supcom only expects boneindex[0] (non organic models)

	fn LoadFromStream bstream=
	(
			local x = ReadFloat bstream
			local y = ReadFloat bstream
			local z = ReadFloat bstream
			Position = [x, y, z]
			local x = ReadFloat bstream
			local y = ReadFloat bstream
			local z = ReadFloat bstream
			Normal = [x, y ,z]
			local x = ReadFloat bstream
			local y = ReadFloat bstream
			local z = ReadFloat bstream
			Tangent = [x, y, z]
			local x = ReadFloat bstream
			local y = ReadFloat bstream
			local z = ReadFloat bstream
			Binormal = [x, y, z]
			--hardcode the w component
			local u = ReadFloat bstream
			local v = ( 1 - ReadFloat bstream )
			uv1 = [u, v, 0]
			--hardcode the w component
			local u = ReadFloat bstream
			local v = ( 1 - ReadFloat bstream )
			uv2 = [u, v, 0]
			local x = Readbyte bstream #unsigned
			local y = Readbyte bstream #unsigned -- last 3 bone indexes not used
			local z = Readbyte bstream #unsigned
			local w = Readbyte bstream #unsigned
			boneindex = x
			--boneindex = [x, y, z, w]
	),
	fn DebugOut=
	(
		format "%\n" Position
	)	
)
--bone struct
struct SCM_Bone
(
    RestPoseInverse, 	--4x4 Matrix with row major 
	Position,				--vector(x,z,y) pos relative to parent bone
	Rotation,				--quaternion(w,x,y,z) rot relative to parent bone
	nameoffset,				--long
	parentboneindex,		--long
	reserved0,				--long				
	reserved1,				--long
	--
	transform,				--transform matrix
			
	fn LoadFromStream bstream=
	(
		
		row1_point3 = point3 ( ReadFloat bstream ) ( ReadFloat bstream ) ( ReadFloat bstream )
		w = ReadFloat bstream
		row2_point3 = point3 ( ReadFloat bstream ) ( ReadFloat bstream ) ( ReadFloat bstream )
		w = ReadFloat bstream
		row3_point3 = point3 ( ReadFloat bstream ) ( ReadFloat bstream ) ( ReadFloat bstream )
		w = ReadFloat bstream
		row4_point3 = point3 ( ReadFloat bstream ) ( ReadFloat bstream ) ( ReadFloat bstream )
		w = ReadFloat bstream
		
		RestPoseInverse = matrix3 row1_point3 row2_point3 row3_point3 row4_point3
					
		x = ReadFloat bstream
		y = ReadFloat bstream
		z = ReadFloat bstream
		Position = [x, y, z]
		w = ReadFloat bstream
		x = ReadFloat bstream
		y = ReadFloat bstream
		z = ReadFloat bstream
		Rotation = Quat x y z w
		nameoffset = ReadLong bstream #unsigned
		parentboneindex = ( ReadLong bstream #unsigned + 1 )
		reserved0 = ReadLong bstream #unsigned
		reserved1 = ReadLong bstream #unsigned
		--transform matrix:
		transform = inverse restposeinverse
	),
	fn DebugOut=
	(
		--format "Restpose:\n"
		--format "%\n" ( inverse Restposeinverse )
		format "\tParent: %\n" parentboneindex
	)
		
)
struct SCM_Header
(
	fourcc,			-- "MODL"
	version,		-- "5"
	boneoffset,		
	wbone,			--numer of bones influencing verts
	vertoffset,
	evertoffset,	--not used in supcom1.0, omitted
	vertcount,		--vertex count
	indexoffset,		
	indexcount,		--tricount = indexcount/3
	infooffset,
	infocount,
	totalbones,		--total amount of bones (weighted bones and tags)
	tricount,

	fn LoadFromStream bstream=
	(
		fourcc 		= ReadFixedString bstream 4 true
		version 	= ReadLong bstream #unsigned
		boneoffset 	= ReadLong bstream #unsigned
		wbone 		= ReadLong bstream #unsigned
		vertoffset 	= ReadLong bstream #unsigned
		evertoffset = ReadLong bstream #unsigned
		vertcount 	= ReadLong bstream #unsigned
		indexoffset = ReadLong bstream #unsigned
		indexcount 	= ReadLong bstream #unsigned
		infooffset 	= ReadLong bstream #unsigned
		infocount 	= ReadLong bstream #unsigned
		totalbones 	= ReadLong bstream #unsigned
		tricount 	= ( indexcount / 3 )
	),
	fn IsValid=
	(
		if fourcc != "MODL" then return false
		if version != 5 then
		(
			ShowError "Incorrect version! Found " + version + " but should be 5"
			return false
		)
		true
	),
	
	fn DebugOut=
	(
		format "SCM_Header\n----------\n"
		format "Marker: %, version: %\n" fourcc version
		format "Weighted bones: %, Total bones: %\n" wbone totalbones
		format "Vertex count: %, Trianlge count: %\n" vertcount ( indexcount / 3 )
		format "bOffset: %, vOffset: %, tOffset: %, iOffset %\n" boneoffset vertoffset indexoffset infooffset
		ok
	)
)	
struct SCM_Loader
(
	bstream,	--bitsream
	header,		--file header
	bonelist=#(), --array of bone structs
	bonenames=#(), --array of bone names
	vertlist=#(), --array of vert structs
	trislist=#(), --array of tris structs
	vertweight=#(), --array that holds which bone is linked to which vert
	whichbone=#(), --array that holds the bone numbers
	nodes=#(),
		
	fn RotatePivotOnly obj rotation= 
	(
		local rotValInv=inverse rotation
		animate off in coordsys local obj.rotation*=RotValInv
		obj.objectoffsetrot*=RotValInv
		obj.objectoffsetpos*=RotValInv
	),

	fn Open filename=
	(
		bstream = fopen filename "rb"
		ok
	),
	
	fn Close=
	(
		fclose bstream
		ok
	),
	fn LoadModel=
	(
		--Load the contents of the scm file
		-- Load SCM_Header
		fseek bstream 0 #seek_set
		header = SCM_Header()
		header.LoadFromStream bstream
			
		if not header.IsValid() then
		(
			format "Invalid header, aborting.\n"
			return false;
		)
		-- Load bonenames
		fseek bstream 64 #seek_set
		local tokens = filterString ( ReadFixedString bstream ( header.boneoffset - 64 ) false ) "\tÅ"
		--copy all tokens except the last one into bonenames array. Last token is fourcc SKEL.
		for i = 1 to ( tokens.count - 1 ) do
		(
			append bonenames tokens[i]
		)
		--load bones
		fseek bstream header.boneoffset #seek_set
		local bone = SCM_Bone()
		for i = 1 to bonenames.count do
		(
			--format "Bone: % - %\n" i bonenames[i]
			bone.LoadFromStream bstream
			append bonelist (copy bone)
			--bone.debugout()
		)
		--load verts
		fseek bstream header.vertoffset #seek_set
		local vert = SCM_vert()
		for i = 1 to header.vertcount do
		(
			vert.LoadFromStream bstream
			append vertlist (copy vert)
			bone = ( vert.boneindex + 1 )
			append whichbone bone
		)
		--load trislist
		fseek bstream header.indexoffset #seek_set
		local tris = SCM_Tris()
		for i = 1 to header.tricount do
		(
			tris.LoadFromStream bstream
			append trislist (copy tris)
		)
		------------------------------------------------------
		--Create the mesh objects
		------------------------------------------------------
		--sort the verts and tris into seperate per mesh lists
		local nMesh = 1 --current mesh we are working on
		local nTris = 1 --tris counter
		local mesh_vertlist=#()
		local mesh_trislist=#()
		local old_vertCount = 0
		
		for nVert = 1 to header.vertcount do
		(
			--get vertex details
			local boneindex = ( vertlist[nVert].boneindex + 1 )
			
			--if new mesh or last vert, find trislist for this mesh
			if boneindex != nMesh or nVert == header.vertcount then
			(
				-- if vert is last vert
				if nVert == header.vertcount do
				(
					--format "Vertex: %\n" nVert
					append mesh_vertlist vertlist[nVert]
					nVert +=1 
			 		--append mesh_vertlist vertlist[nVert]
				)
				--boneindex > nMesh, new mesh found
				--format "Start of new mesh found, create mesh from 'old' data\n"
				--format "Verts: %\n" mesh_vertlist.count
				--format "vertlist: %\n" mesh_vertlist
				--format "Verts: %\n" mesh_vertlist.count
				--append vert_markers nVert
				--find corresponding trislist
				local end = 0
				while end == 0 do
				(
					--check the vert indexes in the trislist entry and check if it references
					--any vertices not belonging to the current mesh
					
					--get triindex from tris
					if trislist[nTris] != undefined then
					(
						local triindex = trislist[nTris].triindex
						--format "checking triindex: %\n" triindex

						--find if any entry in triindex doesn't belong to this mesh
						for i = 1 to 3 do
						(
							if triindex[i] >= nVert do
							(
								--found an entry >= nVert, this tris belongs to the next mesh
								end = 1 --stop the search
							)
						)
						if end == 1 then
						(
							-- we have found a hit
							-- don't increment and don't append... do nothing!
							--format "hit found, stopping"
						)
						else
						(
							--not hit found, increment nTris and append tris to mesh_trislist
							--format "\tNo hit adding to list\n"
							append mesh_trislist trislist[nTris]
							nTris +=1
						)
					)
					--else, undefined? no more tris to search, something went wrong
					else
					(
						--last tris stop search
						end = 1
					)
				)
				
				--format "Tris: %\n" mesh_trislist.count
				--format "trislist: %\n" mesh_trislist
				
				--------------------------------------
				--create mesh from 'old' vert and tris data
				--create arrays to pass to the mesh constructor
				local vert_array=#() -- array that will hold the vertex information
				local face_array=#() -- array that will hold the triangle list information
				local tvert_array=#() -- array that will hold vertex texture coordinates
				local mesh_name = bonenames[nMesh]
				--format "Mesh: %\n" nMesh
				-- build vert array
				
				for i = 1 to mesh_vertlist.count do
				(
					append vert_array mesh_vertlist[i].position
					append tvert_array mesh_vertlist[i].uv1
					
				)
				-- build triangle list
				for i = 1 to mesh_trislist.count do
				(
					local currentface = mesh_trislist[i].triindex
					for j = 1 to 3 do
					(
						currentface[j] -= old_vertCount
					)
					append face_array currentface
				)
				--format "vert array: %\n" vert_array
				--format "face array: %\n" face_array
				--get transform matrix from bone
				transform = bonelist[nMesh].transform
				rot = ( bonelist[nMesh].transform as quat )
				--create a new mesh object
				new_mesh = mesh pivot:transform.row4 vertices:vert_array faces:face_array tverts:tvert_array name:mesh_name
				--rotate the pivot only
				RotatePivotOnly new_mesh rot
				append nodes new_mesh
				old_vertCount += new_mesh.numverts

				--fix tverts
				--UEF t3 Battleship fix
				if mesh_vertlist.count != 0 do
				(
				--end uef t3 bs fix
					BuildTVFaces new_mesh
					for i = 1 to new_mesh.numfaces do (setTVFace new_mesh i (getFace new_mesh i))
				)
				--rebuild the mesh object
				update new_mesh
				--------------------------------------
				--reset 
				mesh_vertlist=#()
				mesh_trislist=#()
				--increment nMesh so we can start looking for the next mesh				
				nMesh +=1
				--add vert to the new empty mesh_vertlist
				--format "Vertex: %\n" nVert
				append mesh_vertlist vertlist[nVert]

				--format "\n"
			)
			else
			(
				--format "Vertex: %\n" nVert
				--still on the same mesh
				--append vert to mesh_vertlist
				append mesh_vertlist vertlist[nVert]
			)
		)
		--create dummy objects for reference points
		for i = ( header.wbone + 1 ) to header.totalbones do
		(
			transmatrix = ( inverse bonelist[i].RestPoseInverse )
			
			newdummy = dummy name:bonenames[i] transform:transmatrix
			newdummy.boxsize = [0.1,0.1,0.1]
			--newdummy.pos = transmatrix.row4
			append nodes newdummy
		)
		--link bones
		for i = 1 to header.totalbones do
		(
			--get bone parent
			local parent = bonelist[i].parentboneindex
			--local parentname = bonenames[i]
			
			if parent == 0 then
			(
				--root bone, don't attach it to anything.
			)
			else
			(
				--format "Linking % to % \n" nodes[i].name nodes[parent].name
				--format "Linking: % to % (% to %)\n" nodes[i] nodes[parent] i parent
				--format "Linking: % to % (% to %)\n" nodes[i].name nodes[parent].name i parent

				attachObjects nodes[parent] nodes[i] move:false
				--node1 = getNodeByName bonenames[i]
				--node2 = getNodeByName bonenames[parent]
				--attachObjects node2 node1 move:false
			)
		)
		gc()
	)
)
