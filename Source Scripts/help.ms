-- Read a string of fixedLen chars
fn ReadFixedString bstream fixedLen junk=
(
	local str = ""
	for i = 1 to fixedLen do
	(
		local ch = ReadByte bstream #unsigned
		--format "Read string: %\n" ch
		if junk == true then
		(
			if ch == 0 then
			(
				str += bit.intAsChar ch
				-- Ignore junk
				SkipBytes bstream (fixedLen - i)
				exit
			)
			else 
			(
				str += bit.intAsChar ch
			)
		)
		--str += bit.intAsChar ch
		else if junk == false then
		(
			if ch == 0 then 
			(
				--replace with a tab "\t"
				str += "\t"
				)
			else
			(
				str += bit.intAsChar ch
			)
		)
	)
	str
)
fn CollectSortedNodes selNode=
(
	--Check if we have selected a/the parent object.
	if selNode.parent != undefined then
	(
		messageBox "Selected object is not a root object" title:"error"
		return false	
	)

	local pA=#() -- parent array to hold parent nodes
	local nA=#() -- node array
	local tA=#() -- temp array to hold the list of children nodes from the nodes in pA
	local dA=#() -- dummy array. dummy objects should be treated as reference bones and come last in the bonelist
	--put parent node in parent array
	append pA selNode

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
	return nA
)