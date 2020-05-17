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




--this struct stores data for each mesh while we work on it
struct Split_Mesh
(
	split_vertlist=#(),
	split_trilist=#(),
	split_texturelist=#(),
	vertexidmap=#()
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
    
    
    
    --called with: CreateMesh BoneID MeshData
	fn CreateMesh BoneID MeshData=
	(
        local mesh_name = bonenames[BoneID]
        --get transform matrix from bone
        transform = bonelist[BoneID].transform
        rot = ( bonelist[BoneID].transform as quat )
        --create a new mesh object
        new_mesh = mesh pivot:transform.row4 vertices:MeshData.split_vertlist faces:MeshData.split_trilist tverts:MeshData.split_texturelist name:mesh_name
        --rotate the pivot only
        RotatePivotOnly new_mesh rot
        append nodes new_mesh

        --fix uv coordinates
        if MeshData.split_vertlist.count != 0 then
        (
            BuildTVFaces new_mesh
            for i = 1 to new_mesh.numfaces do (setTVFace new_mesh i (getFace new_mesh i))
        )
        --rebuild the mesh object
        update new_mesh
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
		local tokens = filterString ( ReadFixedString bstream ( header.boneoffset - 64 ) false ) "\tÅ" --this is cursed because it looks for a specific character, which is a very shaky assumption. SCM can accept any padding character.
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
		

        --
        --for each bone in the bone list
        --make an empty table to store the vert lists, texture lists and face lists, and id map
        --
        --
        --
        --for each face in the face list
        --look up the bone id of the first vertex in the list and use that as the id
        --
        --for each vertex in the face
        --if the vertex id is in the map then do nothing else
        --store vertex in the vertex list
        --store uv in the uv list
        --store vertex id in the id map
        --
        --store the face with the vertex ids set to the id mapping
        --
        --id map:
        --512:1
        --513:2
        --516:3
        --511:4
        --514:5
        --517:6
        --
        --
        --
        --for each bone in the bone list
        --create the mesh using the stored arrays
        --
        
        
        --create a list of split meshes, one for each bone
        local ordered_meshlist=#()
        local boneMeshData = Split_Mesh()
        for i = 1 to bonelist.count do
        (
            --create a mesh data container for each split mesh, and then fill it in.
            append ordered_meshlist (deepCopy boneMeshData)
        )
        
        
        -- fill in data for our split meshes
        for i = 1 to trislist.count do
        (
            local triindex = trislist[i].triindex
            
            
            --look up the bone id for one of our vertices and assume that its the same for the rest
            --this isnt actually true - SCM supports different bones sharing the same faces
            --however because we are splitting bones, MAX wont support this so we have to just break it.
            --use the blender SCM importer if you want this functionality, i guess.
            local BoneID = vertlist[triindex[1]].boneindex + 1
            
            --note: the +1 there is to translate from a 0 index to a 1 index.
            
            --use the bone id to determine which mesh to add data to
            local OurMesh = ordered_meshlist[BoneID]
            
            local remappedTrilist = #()
            --loop through the vertices in our mesh, and fill in their data
            for j = 1 to 3 do
            (
                local vertexID = triindex[j]
                if OurMesh.vertexidmap[vertexID] == undefined then
                (
                    append OurMesh.split_vertlist vertlist[vertexID].position
                    append OurMesh.split_texturelist vertlist[vertexID].uv1
                
                    OurMesh.vertexidmap[vertexID] = OurMesh.split_vertlist.count
                )
                append remappedTrilist OurMesh.vertexidmap[vertexID]
            )
            
            --convert array to a vector and then store it in the list, since apparently the mesh needs tris as vectors. whatever.
            append OurMesh.split_trilist [remappedTrilist[1], remappedTrilist[2], remappedTrilist[3]]
            
        )
        
        --create a mesh for each entry in the list. if the mesh is empty create a dummy node instead
        for i = 1 to header.totalbones do
        (
            if ordered_meshlist[i].split_vertlist.count > 0 then
            (
                CreateMesh i ordered_meshlist[i]
            )
			else
			(
                --create dummy objects for reference points
                transmatrix = ( inverse bonelist[i].RestPoseInverse )
                
                newdummy = dummy name:bonenames[i] transform:transmatrix
                newdummy.boxsize = [0.1,0.1,0.1]
                --newdummy.pos = transmatrix.row4
                append nodes newdummy
			)
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
