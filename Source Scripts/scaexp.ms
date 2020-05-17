--sca exporter
struct e_SCA_Frame
(
	position_array=#(),		--arrays holding relative position and rotation data
	rotation_array=#(),		--
	frame_time,			--float
	frame_flags,		--unsignedlong
	bones,				--number of bones in the frame
	--framesize,			-- = 4 * (( 7 * numbones ) + 2)
	
	fn WriteFrame bstream=
	(
		--write frame header
		WriteFloat bstream frame_time
		--no flags defined yet
		--WriteLong bstream frame_flags #unsigned
		WriteLong bstream 0 #unsigned
		
		for i = 1 to bones do
		(
			Position = position_array[i]
			WriteFloat bstream Position[1]
			WriteFloat bstream Position[2]
			WriteFloat bstream Position[3]
			
			Rotation = rotation_array[i]
			WriteFloat bstream Rotation.w 
			WriteFloat bstream Rotation.x 
			WriteFloat bstream Rotation.y 
			WriteFloat bstream Rotation.z 
		)
	),
	fn DebugOut frame bonenames fstream=
	(
		format "\nFrame: %\tTime: %\tFlags: %\n\n" frame frame_time frame_flags to:fstream
		for i = 1 to bones do
		(
			format "\t%: %\t Pos: %\t Rot:%\n" i bonenames[i] position_array[i] rotation_array[i] to:fstream
		)
	)
)
struct e_SCA_Header
(
	fourcc,			--"ANIM"
	version,		--"5"
	numFrames,
	duration,		--duration in seconds. fps: (numFrames-1)/duration
	numBones,
	boneNameOffset,
	boneLinkOffset,
	firstFrameOffset,
	frameSize,

	fn WriteHeader bstream=
	(
		--FOURCC 'ANIM'
		WriteByte bstream 65
		WriteByte bstream 78
		WriteByte bstream 73
		WriteByte bstream 77
		--version "5"
		WriteLong bstream 5 #unsigned
		WriteLong bstream numFrames #unsigned
		WriteFloat bstream duration 
		WriteLong bstream numBones #unsigned
		WriteLong bstream boneNameOffset #unsigned
		WriteLong bstream boneLinkOffset #unsigned
		WriteLong bstream firstFrameOffset #unsigned
		WriteLong bstream frameSize #unsigned

		--pad
		WriteByte bstream 197
		WriteByte bstream 119
		WriteByte bstream 119
		WriteByte bstream 119
		WriteByte bstream 46
		WriteByte bstream 106
		WriteByte bstream 97
		WriteByte bstream 110
		WriteByte bstream 118
		WriteByte bstream 97
		WriteByte bstream 110
		WriteByte bstream 100
		WriteByte bstream 101
		WriteByte bstream 114
		WriteByte bstream 119
		WriteByte bstream 101
		WriteByte bstream 103
		WriteByte bstream 46
		WriteByte bstream 99
		WriteByte bstream 111
		WriteByte bstream 109
        WriteByte bstream 197
		WriteByte bstream 197
		WriteByte bstream 197


		--for i = 1 to 24 do WriteByte bstream 197
	
		
		WriteByte bstream 78
		WriteByte bstream 65
		WriteByte bstream 77
		WriteByte bstream 69
	),
	fn DebugOut fstream=
	(
		format "SCA_Header\n----------\n" to:fstream
		format "Marker: %, version: %\n" fourcc version to:fstream
		format "Frames: %, Duration: %, Bones: %\n" numFrames duration numBones to:fstream
		format "boneNameOffset: %, boneLinkOffset: %\nFirstFrameOffset: %, Framesize: %\n" boneNameOffset \ 
		boneLinkOffset firstFrameOffset frameSize to:fstream
		ok
	)
)	
	
-- The main SCA exporter object
struct e_SCA_Export
(
	bstream,	--bitstream
	header,		--file header

	boneNames=#(),	--Array of bonenames
	boneLinks=#(),	--Array of bonelinks
	framestruct=#(), --Array holding frame structs
	LinkList=#(),	--Array of bone links
	
	rootPos,
	rootQuat,
	
	debugfile,	
	debug_anim = 0,

	fn Open filename=
	(
		bstream = fopen filename "wb"
		
		
		
		if debug_anim == 1 then
		(
		    debugfilepath = getfilenamepath filename
			debugfilefile = getfilenamefile filename
			tempstring = debugfilepath + debugfilefile + "_debug_SCA.txt"
			
			debugfile = createfile tempstring
		)
		ok
	),
	
	fn streamClose=
	(
		fclose bstream
		ok
	),
	fn ExportAnims=
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
		--sca: dummies should be exported, forget about them
		--local dA=#() -- dummy array. dummy objects should be treated as reference bones and come last in the bonelist
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
					--:welp: dummy found 
					--append dA tA[k]
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
		
		--header struct
		header = e_SCA_Header()
		
		--calculate the anim duration
		--fps = ( num_frames - 1) / duration
		--duration = ( num_frames - 1 ) / fps
		fps = framerate
		frames = animationRange
		num_frames = frames.end - frames.start + 1
		num_frames = num_frames.frame as integer
		header.numFrames = num_frames

		duration = ( num_frames - 1.0 ) / fps
		header.duration = duration

		num_bones = nodes.count
		header.numBones = num_bones
		--framesize = 4 * (( 7 * numbones ) + 2)
		header.frameSize = 4 * (( 7 * num_bones ) + 2)
		header.boneNameOffset = 64
		--header.boneLinkOffset
		--header.firstFrameOffset
		--starts at 64 but make it 68 to bake in the NAME fourcc
		local bonelinkoffset = 64
		for i = 1 to num_bones do
		(
			node = nodes[i]
			bonename = node.name
			append bonenames bonename
			
			--format "Bone: %, b: %" bonename bonelinkoffset
			bonelinkoffset += (bonename.count + 1)
			--format "a: %\n" bonelinkoffset
			parent = node.parent 
			if parent == undefined then
			(
				append linklist  -1
			)
			else
			(
				append linklist (( findItem bonenames parent.name ) - 1)
			)
		)
		--link bytes = 4 * num_bones
		LinkOffset = bonelinkoffset 
		LinkPadding = 16 - (mod LinkOffset 16)
		if LinkPadding < 4 then LinkPadding += 16 
		LinkOffset += LinkPadding
		LinkPadding -= 4
		
		header.boneLinkOffset = LinkOffset
		
		FirstFrameOffset = LinkOffset + ( 4 * num_bones )		
		FirstFramePadding = 16 - (mod FirstFrameOffset 16)
		if FirstFramePadding < 4 then FirstFramePadding += 16
		FirstFrameOffset += FirstFramepadding
		FirstFramepadding -= 4
		header.FirstFrameOffset = FirstFrameOffset

		if debug_anim == 1 do header.debugout debugfile
		local frame = e_SCA_Frame()
		local time = 0
		local dTime = duration / ( num_frames - 1 )
		--Animate the bones wheee \o/
		
		for curFrame = 0 to ( num_Frames - 1 ) do
		(
			at time curFrame
			(
				--format "\nFrame: %\n" curFrame
				fpos=#()
				fquat=#()
				--Position
				for i = 1 to num_bones do
				(
					node = nodes[i]
					parent = node.parent
					
					if parent == undefined then
					(
						--parent bone
						--append fpos node.pos 
						--append fquat node.rotation
						--format "\tPos: % \tRotation: %\n" node.pos node.rotation
						
						--new way:
						matRelative = Matrix3 1
						matRelative = node.transform * matRelative
						
						append fpos matRelative.pos
						append fquat ( inverse matRelative.rotation )
						--format "Position: %\n" matRelative.pos

					)
					else
					(
						--Old way
						--append fpos ( in coordsys parent node.pos )
						--append fquat ( in coordsys parent node.rotation )
						--format "\tPos: % \tRotation: %\n" fpos[i] fquat[i]
						--New way, should work with IK chains etc:
						/*
						matRelative = Matrix3 1
						if $.parent != undefined do
						(
							matRelative = $.parent.transform
							--matRelative = toRightHanded matRelative
							matRelative = inverse matRelative
						)
						matRelative = $.transform * matRelative
						--matRelative = toRightHanded matRelative
						matRelative.pos
						matRelative.rotationpart
						*/
						
						matRelative = parent.transform
						matRelative = inverse matRelative

						matRelative = node.transform * matRelative

						append fpos matRelative.pos
						append fquat ( inverse matRelative.rotation )
						--format "Position: %\n" matRelative.pos

						--matRelative.pos
						--matRelative.rotationpart
					)
				)
				--set frame stuff
				frame.position_array = fpos
				frame.rotation_array = fquat
				frame.frame_time = time
				frame.frame_flags = 0
				frame.bones = num_bones
				time += dTime
				append framestruct (copy frame)
				--format "frame: %\n" i
				--for j = 1 to framestruct.count do
				--(
					if debug_anim == 1 do frame.debugout curFrame bonenames debugfile
				--)
			)
		)
		
		
		/*
		-------------------------------------------
		Write sca file
		-------------------------------------------
		*/
		
		--write header
		header.WriteHeader bstream
		--write bonelist
		for i = 1 to num_bones do
		(
			Writestring bstream bonenames[i]
		)
		for i = 1 to LinkPadding do WriteByte bstream 197
		--write fourcc 'LINK'
		WriteByte bstream 76
		WriteByte bstream 73
		WriteByte bstream 78
		WriteByte bstream 75
		--write link list
		for i = 1 to num_bones do
		(
			WriteLong bstream linklist[i] #unsigned
		)
		--write padding
		for i = 1 to FirstFramePadding do WriteByte bstream 197
		--write fourcc 'DATA'
		WriteByte bstream 68
		WriteByte bstream 65
		WriteByte bstream 84
		WriteByte bstream 65
		--write root pos and delta
		for i = 1 to 3 do WriteFloat bstream 0
		WriteFloat bstream 1.0
		for i = 1 to 3 do WriteFloat bstream 0
		--write frames
		for i = 1 to framestruct.count do
		(
			--framestruct[i].debugout i bonenames
			framestruct[i].WriteFrame bstream
		)
        if debug_anim == 1 then
		(
			close debugfile
		)

		gc()
	)
)