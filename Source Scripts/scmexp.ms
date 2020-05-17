--scm mesh exporter v2
struct e_SCM_Tris
(
	triindex, --3 unsigned shorts 
	fn WriteTris bstream=
	(
		WriteShort bstream ( triindex[1] - 1 ) #unsigned 
		WriteShort bstream ( triindex[2] - 1 ) #unsigned
		WriteShort bstream ( triindex[3] - 1 ) #unsigned
	)		
)
--vertex struct
struct e_SCM_Vert
(
	Position, --float vector(x,y,z) position relative to the local origion of the mesh
	Normal, -- float vector(x,y,z)
	Tangent, -- float vector(x,y,z)
	Binormal, -- float vector(x,y,z)
	uv1, --floatvector(u,v)
	uv2, --floatvector(u,v)
	boneindex, -- array of 4 chars - verts can be weighted to up to 4 bones. Supcom only expects boneindex[0] (non organic models)
	newindex, -- index to mesh vert for getting the bone
	oldindex, -- index to see if a vert has the same pos
	SmoothGroup, -- smooth group - currently the first group which isnt 0

	fn WriteVert bstream=
	(
		--position
		WriteFloat bstream Position[1]
		WriteFloat bstream Position[2]
		WriteFloat bstream Position[3]
		--normal
		WriteFloat bstream Normal[1]
		WriteFloat bstream Normal[2]
		WriteFloat bstream Normal[3]
		--tangent
		WriteFloat bstream Tangent[1]
		WriteFloat bstream Tangent[2]
		WriteFloat bstream Tangent[3]
		--binormal
		WriteFloat bstream Binormal[1]
		WriteFloat bstream Binormal[2]
		WriteFloat bstream Binormal[3]
		--uv1
		WriteFloat bstream uv1[1]
		WriteFloat bstream ( 1 - uv1[2] )
		--uv2
		WriteFloat bstream uv2[1]
		WriteFloat bstream ( 1 - uv2[2] )
		--boneindex
		WriteByte bstream boneindex #unsigned
		WriteByte bstream 0 #unsigned
		WriteByte bstream 0 #unsigned
		WriteByte bstream 0 #unsigned
	),
	fn DebugOut=
	(
		--format "Position: %\n" Position
		--format "Normal: % Tangent: % Binormal: %\n" Normal Tangent Binormal
		--format "UV1: % UV2: %\n" uv1 uv2
		format "Boneindex: %\n" boneindex
	)	
)
--bone struct
struct e_SCM_Bone
(
	RestPoseInverse1, 	--4x4 Matrix with row major
	RestPoseInverse2,	--row2 
	RestPoseInverse3,	--row3
	RestPoseInverse4,	--row4
	Position,				--vector(x,z,y) pos relative to parent bone
	Rotation,				--quaternion(w,x,y,z) rot relative to parent bone
	nameoffset,				--long
	parentboneindex,		--long
	reserved0,				--long				
	reserved1,				--long
	name,					--name
		
	fn WriteBone bstream=
	(
		--Rest Pose Inverse
		WriteFloat bstream RestPoseInverse1[1] 
		WriteFloat bstream RestPoseInverse2[1] 
		WriteFloat bstream RestPoseInverse3[1] 
		WriteFloat bstream 0.0 
		
		WriteFloat bstream RestPoseInverse1[2] 
		WriteFloat bstream RestPoseInverse2[2] 
		WriteFloat bstream RestPoseInverse3[2] 
		WriteFloat bstream 0.0
		
		WriteFloat bstream RestPoseInverse1[3] 
		WriteFloat bstream RestPoseInverse2[3] 
		WriteFloat bstream RestPoseInverse3[3] 
		WriteFloat bstream 0.0 
		
		WriteFloat bstream RestPoseInverse4[1] 
		WriteFloat bstream RestPoseInverse4[2] 
		WriteFloat bstream RestPoseInverse4[3] 
		WriteFloat bstream 1.0 

		WriteFloat bstream Position[1] 
		WriteFloat bstream Position[2] 
		WriteFloat bstream Position[3] 
		
		WriteFloat bstream Rotation.w 
		WriteFloat bstream Rotation.x 
		WriteFloat bstream Rotation.y 
		WriteFloat bstream Rotation.z 

		WriteLong bstream nameoffset #unsigned
		WriteLong bstream parentboneindex #unsigned
		
		WriteLong bstream 0 #unsigned
		WriteLong bstream 0 #unsigned
	),
	fn debugOut number debugfile=
	(
		if parentboneindex == -1 then
		(
			format "Bone: % - 1 (Root)\nRestPoseInverse" name to:debugfile
		)
		else
		(
			format "Bone: % - %\nRestPoseInverse"name number to:debugfile
		)
		--format "Bone: %\nRestPoseInverse"name to:debugfile
		format "%, %, %, %\n" RestPoseInverse1 RestPoseInverse2 RestPoseInverse3 RestPoseInverse4 to:debugfile
		format "Position: %\n" Position to:debugfile
		format "Rotation: %\n" Rotation to:debugfile
		format "nameoffset: %\n" nameoffset to:debugfile
		if parentboneindex == -1 then
		(
			format "Parent: Root\n\n" to:debugfile
		)
		else
		(
			format "Parent: %\n\n" ( parentboneindex + 1 ) to:debugfile
		)
	)
)
struct e_SCM_Header
(
	boneoffset,
	wbonecount,	
	vertoffset,
	evertoffset, --omitted in supcom1.0, leave as 0
	vertcount,
	indexoffset, 
	indexcount,
	infooffset, 
	infocount, 
	totalbones,
	
	fn WriteHeader bstream=
	(
		--fourcc "MODL"
		WriteByte bstream 77
		WriteByte bstream 79
		WriteByte bstream 68
		WriteByte bstream 76
		--version number
		WriteLong bstream 5 #unsigned\
		--bonedata offset
		WriteLong bstream boneoffset #unsigned\
		--weighted bone count
		WriteLong bstream wbonecount #unsigned\
		
		--vertex offset
		WriteLong bstream vertoffset #unsigned\
		--extrat vertex offset, always 0
		WriteLong bstream 0 #unsigned\
		--vertex count
		WriteLong bstream vertcount #unsigned\			
		--indexcount
		WriteLong bstream indexoffset #unsigned\
		
		--indexcount
		WriteLong bstream indexcount #unsigned\
		--info offset			
		WriteLong bstream infooffset #unsigned\
		--info count
		WriteLong bstream infocount #unsigned\
		--totalbones			
		WriteLong bstream totalbones #unsigned\
		
		--pad
		for i = 1 to 12 do WriteByte bstream 197
		WriteByte bstream 78
		WriteByte bstream 65
		WriteByte bstream 77
		WriteByte bstream 69
	),
	fn DebugOut=
	(
		format "SCM_Header\n----------\n"
		--format "Marker: %, version: %\n" fourcc version
		format "Weighted bones: %, Total bones: %\n" wbonecount totalbones
		format "Vertex count: %, Trianlge count: %\n" vertcount ( indexcount / 3 )
		format "bOffset: %, vOffset: %, tOffset: %, iOffset %\n" boneoffset vertoffset indexoffset infooffset
		ok
	)
)
struct SCM_Export
(
	bstream,		--bitsream
	bonelist=#(), 	--array of bone structs
	bonenames=#(), 	--array of bone names
	--wbones=#(),
	vertlist=#(),	--array of vert structs
	trislist=#(),	--array of tris structs
	nodes=#(), 		--sorted array that holds all the nodes.
	meshes=#(),		--array that hold the meshes of nodes
	debugfile,		
	
	--debug options
	debug_bone = 0,
	debug_vert = 0,
	debug_tris = 0,
	
	
	--out_file = createfile out_name
	--format "%,%\n" num_verts num_faces to:debugfile
	
	fn Open filename=
	(
		bstream = fopen filename "wb"
		
		--debugfile_name = ((GetDir #export)+"/testmesh.dat")
		format "Debugoptions: %, % ,%\n" debug_bone debug_vert debug_tris
		if debug_bone == 1 or debug_vert == 1 or debug_tris == 1 then
		(
			debugfilepath = getfilenamepath filename
			debugfilefile = getfilenamefile filename
			tempstring = debugfilepath + debugfilefile + "_debug.txt"
			
			debugfile = createfile tempstring
		)

		ok
	),
	
    --max returns the smooth groups as an integer(!) and comverting it to a bit array apparently requires this bullshit?
    fn getFaceSmoothGroupB obj face =
    (
        local sgroup_val=getFaceSmoothGroup obj face
        local sg_bitarray=#{}
        if sgroup_val < 0 do
        (
            sg_bitarray[32]=true
            sgroup_val -= 2^31
        )
        for i = 1 to 31 do
        (
            sg_bitarray[i]= (mod sgroup_val 2 > .5)
            sgroup_val /= 2
        )
        return sg_bitarray
    ),
    
	fn CompareSmoothGroups MeshObject Face1 Face2=
	(
		local SMGList = getFaceSmoothGroupB MeshObject Face1
		local SGListCompare = getFaceSmoothGroupB MeshObject Face2
		local SmoothGroupsUnique = true
		for i in SMGList while SmoothGroupsUnique do
		(
			if ((SGListCompare[i] == 1) and (SMGList[i] == 1)) then --if theyre both part of the same group then they are smoothed together.
			(
				SmoothGroupsUnique = false
			)
		)
		return SmoothGroupsUnique
	),
	
	fn GetFirstSmoothGroup MeshObject Face1 =
	(
		--find the first smoothing group that is active, defaults to 0 which is also a valid option in this case.
		local SmoothGroupFound = 0
		local SMGList = getFaceSmoothGroupB MeshObject Face1
		for i in SMGList while SmoothGroupFound == 0 do
		(
			if (SMGList[i] == 1) then
			(
				SmoothGroupFound = i
			)
		)
		return SmoothGroupFound
	),
	
	fn streamClose=
	(
		fclose bstream
		ok
	),
	fn exportModel=
	(
		--Check if anything is selected.
		selection = getCurrentSelection()
		if selection.count == 0 then
		(
			messageBox "No object selected" title:"error"
			return false
		)
		if selection.count > 1 then
		(
			messageBox "Multiple objects selected, please select only 1 object" title:"error"
			return false
		)
		-----------------------------------------------------------
		
		--Check if we have selected a/the parent object.
		if selection[1].parent != undefined then
		(
			messageBox "Selected object is not a root object" title:"error"
			return false	
		)
		--collect and sort (parents first) all the nodes into an array. 
		local pA=#() -- parent array to hold parent nodes
		local nA=#() -- node array
		local tA=#() -- temp array to hold the list of children nodes from the nodes in pA
		local dA=#() -- dummy array. dummy objects should be treated as reference bones and come last in the bonelist
		--put parent node in parent array
		append pA selection[1]

		while pA.count > 0 do
		(
			/*
			--Append all nodes in pA into nA
			for i = 1 to pA.count do
			(
				append nA pA[i]
			)
			*/
			--Go through each node in pA and:
			for i = 1 to pA.count do
			(
				--Append nodes in pA into nA
				append nA pA[i]
			
				--append children of each node in pA into tA
				--get children of node pA[i]
				local children = pA[i].children
				--put all children in tA
				for j = 1 to children.count do
				(
					append tA children[j]
				)
			)
			--clear pA
			pA=#()
			--copy tA into pA
			for k = 1 to tA.count do
			(
				--Before putting a node into the pA array for the next cycle check if its a dummy or not
				if ( classof tA[k] ) == Dummy then
				(
					append dA tA[k]
				)
				else 
				(
					append pA tA[k]
				)
			)
			--clear tA
			tA=#()
		)
		nodes = nA 

		--create header struct
		header = e_SCM_header()

		header.wbonecount = nodes.count
		--copy dummy bones into nodelist
		for i = 1 to dA.count do
		(
			append nodes dA[i]
		)
		header.totalbones = nodes.count
		--format "Nodelist: \n % \n" nodes
		----------------------------------------------------------- 
		--create NAME and SKEL data
		boneoffset = 64
		totalbones = header.totalbones
		
		local exportbone = e_SCM_Bone()
		for i = 1 to totalbones do
		(
			node = nodes[i]

			bonename = node.name
			append bonenames bonename
			exportbone.name = bonename
			
			exportbone.nameoffset = boneoffset
			boneoffset += (bonename.count + 1)
			
			transform = node.transform
			parent = node.parent 
			if parent == undefined then
			(
				--local parentindex = -1
				exportbone.parentboneindex = -1
				exportbone.position = transform.row4
				exportbone.rotation = quat 0 0 0 1
			)
			else
			(
				exportbone.parentboneindex = ( findItem bonenames parent.name ) - 1
				--relative position and rotation
				exportbone.position = ( in coordsys parent node.pos )
				exportbone.rotation = ( in coordsys parent node.rotation ) 
			)
			Transform.row1 = normalize Transform.row1
			Transform.row2 = normalize Transform.row2
			Transform.row3 = normalize Transform.row3

			iTransform = inverse transform
			exportbone.RestPoseInverse1 = ( normalize [ iTransform.row1[1], iTransform.row2[1], iTransform.row3[1]] )
			exportbone.RestPoseInverse2 = ( normalize [ iTransform.row1[2], iTransform.row2[2], iTransform.row3[2]] )
			exportbone.RestPoseInverse3 = ( normalize [ iTransform.row1[3], iTransform.row2[3], iTransform.row3[3]] )
			exportbone.RestPoseInverse4 = iTransform.row4
			
			append bonelist (copy exportbone)
			if debug_bone == 1 then exportbone.debugout i debugfile
		)
		-----------------------------------------------------------
		--Calculate the padding after the bonename and bonedata block so that the next fourcc is 16byte aligned
		--calculate bonename padding
		bonepadding = 16 - (mod boneoffset 16)
		if bonepadding < 4 then	bonepadding += 16
		boneoffset += bonepadding
		bonepadding -= 4
		header.boneoffset = boneoffset
	
		--calculate bonedata padding
		--a single bone entry is 108 bytes. 27*4
		vertexoffset = boneoffset + ( totalbones * 108 )
		bonedatapadding = 16 - ( mod vertexoffset 16 )
		if bonedatapadding < 4 then
		(
			bonedatapadding += 16
		)
		vertexoffset +=bonedatapadding
		bonedatapadding -= 4
		header.vertoffset = vertexoffset
		-----------------------------------------------------------
		
		--Go through each node in node array, convert it to a mesh and split it along the uv seams
		for nNode = 1 to header.wbonecount do 
		(
			progressStart ("Mesh:" + nodes[nNode].name )
			progressUpdate(0)

			local mesh = snapshotasmesh nodes[nNode]
			
			--build tvfaces in case the model doesn't have any
			--todo: check if model doesn't have tvfaces before rebuilding
			--BuildTVFaces mesh
			--for i = 1 to mesh.numfaces do (setTVFace mesh i (getFace mesh i))

			--temp vert and tris arrays so we don't have to sort through the entire list, only the current mesh list
			local m_vertlist=#() 
			local m_trislist=#()
			if debug_vert == 1 or debug_tris == 1 then
			(
				format "\n\tMesh: % - %\n\n" nNode bonenames[nNode] to:debugfile
			)
			for nFace = 1 to mesh.numFaces do
			(
				
				--update progressbar every 10 faces
				if ( mod nFace 10 ) == 0 do progressUpdate( 100.0 * nFace / mesh.numFaces )

				-- Reference to current face vertex & texture coordinate
				vTri = getFace mesh nFace
				tTri = getTVFace mesh nFace
				
				--save the smooth group of to the vertices
				local FaceSmoothGroup = GetFirstSmoothGroup mesh nFace
				-- Resulting face of the process
				local outFace = Point3 0 0 0
				-- For each face index...
				for i = 1 to 3 do
				(
					--format "Index: %\n" i
					-- Vert struct that will be appended to m_vertlist if it isn't a duplicate in pos and tpos
					-- if pos is the same but different tpos still create a new vert.
					local outVert = e_scm_vert()
					-- Reference to the MAX vertex coordinate
					local inVert = getVert mesh vTri[i]
					-- Reference to the MAX texture coordinate
					local inTVert = getTVert mesh tTri[i]
					inTVert = Point2 inTVert.x inTVert.y
				
					--get vertex normals
					--get faces sharing this vert				
					local vertFaces = meshOp.getFacesUsingVert mesh vTri[i]
					
					local FacesSkipped = 0
					
					--init normals
					local tNormal = [0,0,0]
					local tangent = [0,0,0]
					local binormal = [0,0,0]
					--go through each face and find its normal, tangent and binormal 
					for j in vertFaces do
					(
						local SkipThisFace = CompareSmoothGroups mesh nFace j
						
						--skip any faces that arent using the same smoothing group
						if (SkipThisFace == true) then
						(
							FacesSkipped += 1
						)
						else
						(
							--face normal
							tNormal += getFaceNormal mesh j
							--tangent and binormal vectors
							P1 = getVert mesh vTri[1]
							P2 = getVert mesh vTri[2]
							P3 = getVert mesh vTri[3]
							
							UV1 = getTVert mesh tTri[1]
							UV1 = Point2 UV1.x UV1.y
							UV2 = getTVert mesh tTri[2]
							UV2 = Point2 UV2.x UV2.y
							UV3 = getTVert mesh tTri[3]
							UV3 = Point2 UV3.x UV3.y
						
							Edge1 = P2 - P1
							Edge2 = P3 - P1
						
							Edge1uv = UV2 - UV1
							Edge2uv = UV3 - UV1
						
							cp = ( Edge1uv[2] * Edge2uv[1] ) - ( Edge1uv[1] * Edge2uv[2] )
							if ( cp != 0.0 ) then
							(
								mul = 1.0 / cp
								tangent += (( Edge1 * -Edge2uv[2] + Edge2 * Edge1uv[2]) * mul )
								binormal += (( Edge1 * -Edge2uv[1] + Edge2 * Edge1uv[1]) * mul )
							)
						)
					)
					--find average of the normals, tangents and binormals
					local NumberUsedFaces = vertFaces.count - FacesSkipped
					local tNormal = normalize (tNormal / NumberUsedFaces )
					local tangent = normalize (tangent / NumberUsedFaces )
					local binormal = normalize (binormal / NumberUsedFaces )
					--set normal, tangent and binormal of the vertex
					outVert.Normal = tNormal
					outVert.Binormal = binormal
					outVert.Tangent = tangent
				
					--format " inVert: % \n inTVert: %\n" invert intvert
		
					-- Now we have to see if the current vertex already exists in the final list of vertices
					-- Looping in a loop like this is what makes the script slow. Someone (you) should refactor this away.
					local indexMatch = 0
					for v in m_vertlist do
					(
						-- If newindex is undefined that means that no vert with the same pos and tpos was found: create one
						-- Oldindex is used since multiple same-pos-different-tpos verts might be found.
						-- We only need to know the first one.
					
						-- Increment index match of the current vertex counter
						indexMatch += 1
		
						-- Did we found the first match of the current vertex?
						-- Found a vertex with the same position but a different tvert position.
						if (v.position == inVert) and (outVert.oldindex == undefined) do
						(
							-- Yes!. So store its value.
							-- We're gonna make use of this later for weight calculation!
							--format "   Same vert, different tvert: %\n" indexMatch
							outVert.oldindex = indexMatch
						)
		
						-- Did we found a vertex equal in vertex & texture coordinates and should be smoothed?
						if (v.position == inVert) and (v.uv1 == inTVert) and (v.SmoothGroup == FaceSmoothGroup) do
						(
							-- Yes. So we assign the index of the located vertex
							--format "   Same vert, same tvert: %\n" indexMatch
							outVert.newIndex = v.newIndex
						)
					)
					-- Time for weight calculation --
					-- If the vertex already exists means we don't need to add a new weight.
					-- We have to use the located vertex weight instead
					if outVert.oldIndex != undefined then
					(
						-- Vert already has an oldindex
						-- Assign boneindex from the oldindex to the new index
						outVert.boneindex = m_vertlist[outVert.oldIndex].boneindex
					)
					else
					(	
						-- Don't need to do weight calculation, just get current bone number.
						outVert.boneindex = (nNode - 1 )
					)
	
					-- Was the current vertex found in the vertlist?
					if outVert.newIndex == undefined then
					(
						-- No match found were pos and tpos were the same, so create a new vertex
						outVert.position = inVert
						outVert.uv1 = inTVert
						outVert.uv2 = inTVert
						outVert.newIndex = m_vertlist.count + 1
						outVert.SmoothGroup == FaceSmoothGroup --save the current faces smooth group (0 for none)
		
						-- Add the new vertex to the list of m_vertices
						append m_vertlist outVert
						if debug_vert == 1 do format "VERT: % - %\n" m_vertlist.count outVert.position to:debugfile
						--outVert.debugOut()
						-- Index for this vertex
						outFace[i] = m_vertlist.count
					)
					else
					(
						-- The vertex already exists so the only thing we have to do is add its index
						outFace[i] = outVert.newIndex
					)
				)
				-- Add the new face to the list of faces
				exportface = e_scm_tris()
				exportface.triindex = outFace
				append m_trislist exportface

				--"TRIS: % - %\n" m_trislist.count outFace
			)
			--copy m_vertlist and m_trislist into the main list
			--first get count of current number of vertices in main vertlist
			--we need to offset the face index by this number
			local vcount = vertlist.count
			if vcount == undefined then vcount = 0
			--format "\n" vcount
			--cycle through all verts in m_vertlist and add them to the main vertlist
			for m_vcount = 1 to m_vertlist.count do
			(
				append vertlist m_vertlist[m_vcount]
			)
			--cycle through all the tris in m_trislist, offset them add them to the main trislist
			for m_tcount = 1 to m_trislist.count do
			(
				--offset the items in m_trislist[m_tcount]
				m_trislist[m_tcount].triindex += vcount
				append trislist m_trislist[m_tcount]
				if debug_tris == 1 do format  "TRIS: % - %\n" m_tcount m_trislist[m_tcount].triindex to:debugfile
			)
			--format "Vertlist: % Trislist: %\n" vertlist.count trislist.count
			--format "\n"
			progressEnd()
		)
		-----------------------------------------------------------
		--Calculate the padding after the vert/trislist/info so that the next fourcc is 16byte aligned
		--calculate vertexdata padding
		--a single vertex entry is 68 bytes. 17*4
		indexoffset = vertexoffset + ( vertlist.count * 68 )
		--modulo = mod indexoffset 16
		vertdatapadding = 16 - ( mod indexoffset 16 )
		if vertdatapadding < 4 then
		(
			vertdatapadding += 16
		)
		indexoffset = ( indexoffset + vertdatapadding )
		vertdatapadding -= 4
		header.indexoffset = indexoffset
		--calculate index padding
		--a single index entry is 6 bytes. 3*2
		infooffset = indexoffset + ( trislist.count * 6 )
		--modulo = mod infooffset 16
		indexpadding = 16 - ( mod infooffset 16 )
		if indexpadding < 4 then
		(
			indexpadding += 16
		)
		infooffset = ( infooffset + indexpadding )
		indexpadding -= 4
		header.infooffset = infooffset
		--progressStart ("Creating Vertex Data")
		--info count
		--fixed string: "Exported with scmtool www.janvanderweg.com"
		header.infocount = 43	
		header.vertcount = vertlist.count
		header.indexcount = ( trislist.count * 3 )

		/*
		-------------------------------------------
		Write scm file
		-------------------------------------------
		*/
		
		progressStart "Writing scm file"
		progressUpdate(0)
		--write header
		header.writeheader bstream
		--write bonelist
		for i = 1 to totalbones do
		(
			Writestring bstream bonenames[i]
		)
		--write padding
		for i = 1 to bonepadding do WriteByte bstream 197
		WriteByte bstream 83
		WriteByte bstream 75
		WriteByte bstream 69
		WriteByte bstream 76
		--write bones
		for i = 1 to totalbones do 
		(
			--bonelist[i].debugout()
			bonelist[i].writebone bstream
		)
		--write padding
		for i = 1 to bonedatapadding do WriteByte bstream 197
		WriteByte bstream 86
		WriteByte bstream 84
		WriteByte bstream 88
		WriteByte bstream 76
		--write verts
		for i = 1 to vertlist.count do
		(
			--vertlist[i].debugout()
			vertlist[i].writevert bstream
			if ( mod i 10 ) == 0 do progressUpdate( 100.0 * i/vertlist.count )
		)
		--write padding
		for i = 1 to vertdatapadding do WriteByte bstream 197
		WriteByte bstream 84
		WriteByte bstream 82
		WriteByte bstream 73
		WriteByte bstream 83
		--write trislist
		for i = 1 to trislist.count do
		(
			trislist[i].writetris bstream
			if ( mod i 10 ) == 0 do progressUpdate( 100.0 * i/trislist.count )
		)
		--write padding
		for i = 1 to indexpadding do WriteByte bstream 197
		WriteByte bstream 73
		WriteByte bstream 78
		WriteByte bstream 70
		WriteByte bstream 79
		--write info
		WriteString bstream "Exported with scmTool www.janvanderweg.com"
		progressEnd()
		if debug_bone == 1 or debug_vert == 1 or debug_tris == 1 then
		(
			close debugfile
		)
		gc()
	)
)