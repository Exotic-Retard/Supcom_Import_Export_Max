========================================
   ** SCM IMPORTER - Jan Van Der Weg **
          www.janvanderweg.com

	Many thanks to:
		Chris Cookson for his scripts, they taught me a lot!
		der_ton from doom3world, without his scripts correct bone creation would have taken a lot longer!
		GH33DA for explaining what the transform matrixes (matrices?) are!
		Jonathan "BeRSeRKeR" Garcia, for his splitting code!

	SupCom Maxtool:
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


Installation:
Extract the zip contents to your 3dsmax scripts directory. (C:\Program Files\Autodesk\3ds Max 9\Scripts)

Usage:
After extracting the files load max and goto the utility toolbar. (Hammer tab)
Click on the MAXScript button, select run script and point to the scmtool.mzp file. 
Select SupCom MaxTool from the Utilities dropdown box.

Exporting:
-Supcom uses an Y-up coordinate system. 3dsmax uses a Z-up system. Create your model accordingly.

Setting up a model:
-Every moving part should be a seperate object.
-Manually set the object pivot, the pivot is treated as the bone origin and orientation.
-Use dummy objects (helpers tab) as reference points.

Misc:
-help help help helppppppp this is still a untested beta.
-The script might be slow for larger models. Be patient.
	





