/*
========================================
   ** SupCom MaxTool - Jan Van Der Weg **
          http://www.janvanderweg.com/pro-supcom.php - old site
          https://github.com/Exotic-Retard/Supcom_Import_Export_Max currently maintained Github Repo.

	Many thanks to:
		Chris Cookson for his scripts, they taught me a lot!
		der_ton from doom3world, without his scripts correct bone creation would have taken a lot longer!
		GH33DA for explaining what the transform matrixes (matrices?) are!
		Jonathan "BeRSeRKeR" Garcia, for his splitting code!
		
	SupCom Maxtool:
	v1.2
    --[e]Exotic_Retard - added support for smoothgroups, and SCM exported with blender supcom exporter 5.0+
	v1.1b
	--Fixed possible bug with exporting animations
	--Added animation debug dump file
	v1.1
	--Fixed bone transform generation. It isn't required to reset the Xform of all objects.
	--Debug txt file now exports to the same directory as the scm. Filename is scmfilename_debug.txt
	--The use of controllers (IK, etc) should work now.
	v1.0
	--Importer can now export animation files.
		-- in the time configuration dialog set fps, start and end time
	--Fixed frame counting bug in sca import	
	v0.9a
	--Importer now imports the same way as you would export
	--Can now apply animation files.
		--Applying sca files should work 100% but there might still be a few bugs
	--Added options to dump the model data (bones,verts,tris) into 'c:\scm_debug.txt'
	v0.9
	-New export script. Uses max object instead of bones.
	-Objects are treated as a seperate bone
	-Dummy objects are treated as reference bones
		-Don't link objects to a dummy object. Objects that are linked to dummies are ignored.
	-Check the example max file (requires max9)
	========================================
*/
fileIn "scmimp.ms" -- mesh importer
fileIn "scmexp.ms" -- mesh exporter

fileIn "scaimp.ms" -- animation importer
fileIn "scaexp.ms" -- animation exporter

utility SCMTool "SupCom MaxTool" silentErrors:false
(
	--Rollout
	group "About:"
	(
		bitmap the_bmp fileName:"supcom.bmp" 
		label Label1 "SupCom MaxTool v1.2"
		label Label2 "https://github.com/Exotic-Retard/Supcom_Import_Export_Max"
	)
	
	group "Import:"
	(
		button importSCM "Import .SCM" tooltip:"Import a Supreme Commander An RTS From Chris Taylor model... ^_^"
		button applySCA "Apply .SCA" tooltip:"Load and apply animations from an .sca file... ^_^"
	)
	group "Export:"
	(
		label labeldebug "Debug options:"
		checkbox exportdebugbone "Bonedata" tooltip:"Dump bonedata to a text file"
		checkbox exportdebugvert "Vertdata" tooltip:"Dump vertdata to a text file"
		checkbox exportdebugtris "Trisdata" tooltip:"Dump trisdata to a text file"		
		button exportSCM "Export .SCM" tooltip:"Export a Supreme Commander An RTS From Chris Taylor model... ^_^"

		checkbox exportdebuganim "Animdata" tooltip:"Dump animdata to a text file"		
		button exportSCA "Export .SCA" tooltip:"Export a Supreme Commander An RTS From Chris Taylor animation... ^_^"
	)
	-- Utilities --
	fn DoesFileReallyExist filename=
	(
		local temp = fopen filename "rb"
		if temp != undefined then
		(
			fclose temp
			true
		)
		else
		(
			false
		)
	)
	
	--UI Stuff
	on importSCM pressed do
	(
		inipath = scriptsPath + "scmtool.ini"
		filename = getINISetting inipath "settings" "importscm"
	    scmFilename = getOpenFileName caption:"Select SCM file" \
					filename:filename \
					types:"SupCom SCM (*.scm)|*.scm|All Files (*.*)|*.*|"

		if scmFilename != undefined then
		(
			if DoesFileReallyExist scmFilename then
			(
				setINISetting inipath "settings" "importscm" scmFilename

				set coordsys world

				local loader = SCM_Loader()
				loader.Open scmFilename
				loader.LoadModel()
				loader.Close()

				max views redraw
			)
		)
	)
	on applySCA pressed do
	(
		inipath = scriptsPath + "scmtool.ini"
		filename = getINISetting inipath "settings" "importsca"
		scaFilename = getOpenFileName caption:"Select SCA file" \
					filename:filename \
					types:"SupCom SCA (*.sca)|*.sca|All Files (*.*)|*.*|"
		
		if scaFilename != undefined then
		(
			if DoesFileReallyExist scaFilename then
			(
				
				local loader = SCA_Loader()
				loader.Open scaFilename
				loader.ImportAnims()
				loader.Close()
				setINISetting inipath "settings" "importsca" scaFilename
				--format "OK\n"
				max views redraw
			)
		)
	)

	on exportSCM pressed do
	(
	
		inipath = scriptsPath + "scmtool.ini"
		filename = getINISetting inipath "settings" "exportscm"
	    scmFilename = getSaveFileName caption:"Select SCM file" \
					filename:filename \
					types:"SupCom SCM (*.scm)|*.scm|All Files (*.*)|*.*|"

		if scmFilename != undefined then
		(
			setINISetting inipath "settings" "exportscm" scmFilename
			set coordsys world
			
			
			local exporter = SCM_Export()
			--debug options
			if exportdebugbone.tristate == 1 then exporter.debug_bone = 1
			if exportdebugvert.tristate == 1 then exporter.debug_vert = 1
			if exportdebugtris.tristate == 1 then exporter.debug_tris = 1

			exporter.Open scmFilename
			exporter.exportModel()
			exporter.streamClose()
				
			max views redraw
			
		)
	)
	on exportSCM2 pressed do
	(
	
		inipath = scriptsPath + "scmtool.ini"
		filename = getINISetting inipath "settings" "exportscm"
	    scmFilename = getSaveFileName caption:"Select SCM file" \
					filename:filename \
					types:"SupCom SCM (*.scm)|*.scm|All Files (*.*)|*.*|"

		if scmFilename != undefined then
		(
			setINISetting inipath "settings" "exportscm" scmFilename
			set coordsys world
			
			
			local exporter = SCM_Export2()
			--debug options
			if exportdebugbone.tristate == 1 then exporter.debug_bone = 1
			if exportdebugvert.tristate == 1 then exporter.debug_vert = 1
			if exportdebugtris.tristate == 1 then exporter.debug_tris = 1

			exporter.Open scmFilename
			exporter.exportModel()
			exporter.streamClose()
				
			max views redraw
			
		)
	)

	on exportSCA pressed do
	(
		inipath = scriptsPath + "scmtool.ini"
		filename = getINISetting inipath "settings" "exportsca"
	    scaFilename = getSaveFileName caption:"Select SCA file" \
					filename:filename \
					types:"SupCom SCA (*.sca)|*.sca|All Files (*.*)|*.*|"
		if scaFilename != undefined then
		(
			setINISetting inipath "settings" "exportsca" scaFilename
			set coordsys world
						
			local exporter = e_SCA_Export()
			if exportdebuganim.tristate == 1 then exporter.debug_anim = 1

			exporter.Open scaFilename
			exporter.ExportAnims()
			exporter.streamClose()
				
			max views redraw
			
		)
	)
)
