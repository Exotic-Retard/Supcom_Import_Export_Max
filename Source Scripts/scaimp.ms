--sca importer
--fileIn "help.ms" 

struct SCA_Frame
(
	position_array=#(),		--arrays holding relative position and rotation data
	rotation_array=#(),		--
	frame_time,			--float
	frame_flags,		--unsignedlong
	bones,				--number of bones in the frame
	
	fn LoadFromStream bstream num_bones=
	(
		--read frame header
		frame_time = ReadFloat bstream
		frame_flags = ReadLong bstream #unsigned
		bones = num_bones
		for i = 1 to num_bones do
		(
			local x = ReadFloat bstream
			local y = ReadFloat bstream
			local z = ReadFloat bstream
			Position = [x,y,z]
			local w = ReadFloat bstream
			local x = ReadFloat bstream
			local y = ReadFloat bstream
			local z = ReadFloat bstream
			Rotation = Quat x y z w
			append position_array Position
			append rotation_array Rotation
		)
	),
	fn DebugOut frame bonenames=
	(
		format "\nFrame: %\tTime: %\tFlags: %\n\n" frame frame_time frame_flags
		for i = 1 to bones do
		(
			format "\t%: %\t Pos: %\t Rot:%\n" i bonenames[i] position_array[i] rotation_array[i]
		)
	)
)
struct SCA_Header
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

	fn LoadFromStream bstream=
	(
		fourcc 				= ReadFixedString bstream 4 true
		version				= ReadLong bstream #unsigned
		numFrames			= ReadLong bstream #unsigned
		duration			= ReadFloat bstream
		numBones			= ReadLong bstream #unsigned
		boneNameOffset		= ReadLong bstream #unsigned
		boneLinkOffset		= ReadLong bstream #unsigned
		firstFrameOffset	= ReadLong bstream #unsigned
		frameSize			= ReadLong bstream #unsigned
	),
	fn IsValid=
	(
		if fourcc != "ANIM" then return false
		if version != 5 then
		(
			ShowError "Incorrect version! Found " + version + " but should be 5"
			return false
		)
		true
	),
		
	fn DebugOut=
	(
		format "SCA_Header\n----------\n"
		format "Marker: %, version: %\n" fourcc version
		format "Frames: %, Duration: %, Bones:\n" numFrames duration numBones
		format "bnOffset: %, blOffset: %, ffOffset: %, Framesize: %\n" boneNameOffset \
		boneLinkOffset firstFrameOffset frameSize
		ok
	)
)	
	
-- The main SCM loader object
struct SCA_Loader
(
	bstream,	--bitsream
	header,		--file header

	boneNames=#(),	--Array of bonenames
	boneLinks=#(),	--Array of bonelinks
	frames=#(), --Array holding frame structs
	
	-- Fix for where sca bone names aren't named correctly,
	-- or the amount of bones in the scm and sca differs
	--nodes=#(), --Array holding sorted nodes 
	
	rootPos,
	rootQuat,
	fn Open filename=
	(
		g_modelFilename = filename
		g_modelName = getFilenameFile filename
		g_modelPath = getFileNamePath filename
		bstream = fopen filename "rb"
		ok
	),
	
	fn Close=
	(
		fclose bstream
		ok
	),
	fn ImportAnims=
	(
		-- Load SCA_Header
		fseek bstream 0 #seek_set
		
		header = SCA_Header()
		header.LoadFromStream bstream
		--header.DebugOut()
		
		if not header.IsValid() then
		(
			format "Invalid header, aborting.\n"
			return false;
		)
		-- Load bone names
		--format "Loading bone names\n"
		fseek bstream 64 #seek_set
		bonestring = ReadFixedString bstream ( header.boneLinkOffset - 64 ) false
		tokens = filterString bonestring "\t≈"
		--copy all tokens except the last one into bonenames array. Last token is fourcc LINK.
		for i = 1 to ( tokens.count - 1 )do	append boneNames tokens[i]
		
		--format "Loading bone links\n"
		for i = 1 to header.numBones do
		(
			temp = ReadLong bstream #unsigned
			boneLinks[i] = ( temp + 1)
		)
		--for i = 1 to header.numBones do format "Bone: %, %, parent: %\n" i boneNames[i] boneLinks[i]
		
		--check if current scene (import from scm) is compatible
		--check if bone names exist in scene
		for i = 1 to header.numBones do 
		(
			node = getNodeByName boneNames[i]
			--hacky fix for lod models.
			lodnode = getNodeByName ( "lod1_" + boneNames[i] )
			--format "Bone: %\n" bonenames[i]
			
			if node == undefined do
			(
				if lodnode == undefined do
				(
					messageBox ( "Current scene not compatible. Bone in sca: '" + bonenames[i] +"' not found in scene." )  title:"error"
					format "i: %\n" i
					format "bonename: %\n" boneNames[i]
					format "node: %\n" ( getNodeByName boneNames[i] )
					return false
				)
			)
		)
		--Collect the nodes
		--if selection[1].parent != undefined then
		--(
		--	messageBox "Selected object is not a root object" title:"error"
		--	return false	
		--)
		
		--nodes = CollectSortedNodes selection[1]
		
		--ROOT DELTA
		temp = ReadFixedString bstream 4 false
		
		rootPos=#(ReadFloat bstream, ReadFloat bstream, ReadFloat bstream)
		w= ReadFloat bstream
		x= ReadFloat bstream
		y= ReadFloat bstream
		z= ReadFloat bstream
		rootQuat = quat x y z w
		--format "Root delta, pos: % quat: %\n" rootPos rootQuat
		--format "Loading Frames \n"
		
		--local curFrame = SCA_Frame()
		for i = 1 to header.numFrames do
		(
			local curFrame = SCA_Frame()
			curFrame.LoadFromStream bstream header.numBones
			--curFrame.DebugOut i boneNames
			--format "%\n" curFrame
			append frames (copy curFrame)
			--format "%\n p: %\n q: %\n" i frames[i].posArray frames[i].quatArray
		)
		--Animate the bones wheee \o/
		
		animate on
		(
			progressStart ("Loading frames")
			--try
			--(
				for curFrame = 0 to ( header.numFrames - 1 ) do
				(
					--format "Frame: %\n" curFrame
					at time curFrame
					(
						--format "\nFrame: %\n" curFrame
						fpos=frames[curFrame+1].position_array
						fquat=frames[curFrame+1].rotation_array
						--Position
						for i = 1 to header.numBones do
						(
							--format "ANIMATING FRAME: %\n" i
							--format "%\n" ( frames[curFrame].debugout(i) )
							--Calculate new bone position and rotation
							--get node							
							--hacky fix for lod models.
							--if getNodeByName[i] == undefined then
							--(
							--	node = getNodeByName ( "lod1_" + boneNames[i] )
							--)
							--else
							--(
								node = getNodeByName boneNames[i]
							--)
							parent = node.parent
							
							--format "\tBone: % - % parent: %\n" i boneNames[i] parent	
							if parent == undefined then
							(
								node.pos = fpos[i]
								node.rotation = fquat[i]
							)
							else
							(
								in coordsys parent node.pos = fpos[i]
								in coordsys parent node.rotation = fquat[i]
							)
							--exportbone.position = ( in coordsys parent node.pos )
							--exportbone.rotation = ( in coordsys parent node.rotation ) 
							--in coordsys parent rotate selection (EulerAngles 0 0 90)
						)
					)
						
					-- Don't update too often (pointless to update more than 100 times anyway)
					if (mod curFrame 3) == 0 then
					(
						progressUpdate (100.0 * curFrame / header.numFrames)
					)
						
					-- Allow the user to cancel if they get bored or panic
					if getProgressCancel() then
					(
						progressEnd()
						return undefined
					)
				)
			--)
			--catch
			--(
				-- Always call this otherwise gmax kind of locks up
				progressEnd()
				--throw
			--)
			--progressEnd()
		)
		
		
	)
)