/*
[INFO]

NAME = VISCO_View by Grid
VERSION = 1.6.1
AUTHOR = Vasiliy Lukyanenko
DEV = VISCO
HELP = 

[INSTALL]

MACRO=ViewByGrid
CAT=VISCOCG
TEXT=View By Grid
ICON=#("ViewByGrid",1)

[ICONS]

\\visco.local\data\Instal_Sync\scripts\scripts\icons\ViewByGrid\ViewByGrid_16i.bmp=
\\visco.local\data\Instal_Sync\scripts\scripts\icons\ViewByGrid\ViewByGrid_16a.bmp=
\\visco.local\data\Instal_Sync\scripts\scripts\icons\ViewByGrid\ViewByGrid_24a.bmp=
\\visco.local\data\Instal_Sync\scripts\scripts\icons\ViewByGrid\ViewByGrid_24i.bmp=

[1.0.0]

* First release =

[1.3.0]

- BugFix: Crash 3Ds Max 2012=

[1.5.0]

+ Added: Support hot keys (T,L,F,B)=
+ Added: Button Select Grid=

[1.5.1]

* Adopt for new Scripts Launcher =

[1.6.0]

* Script window can resize=
+ Added: Remember window position=
+ Added: Remember window size=

[1.6.1]

+Added: Button Up and Down for sort grid list=
-Removed: Buttons Update and Select Grid=
+Added: Context menu with items^ Update and Select Grid=


[ABOUT]

Script helps to work with grid object views in =
comfortable way. When script window is=
open you can use default hot keys (T,L,F,B, etc.)=
to switch between  front, top,left, bottom...=
and other views of the grid object.=
Use buttons Up and Down for arrange list.=
Use context menu items for update list and select grid.=

[SCRIPT]
*/

fn getScriptInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	
	r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" collect i
	
	return #(n, a, v, o, r, c, h)
)

fn parseToLine m = 
(
	if(m.count == 0) do return ""
	
	l = ""				
	for i in m do l += i + "\n"
	return l
)

try(closeRolloutFloater rViewByGrid) catch()
global rViewByGrid = newRolloutFloater "View by Grid" 200 300
global ViewByGrid
global windowHeight = 300
global iWindowPos = [0.0, 0.0]
global rcRightClick


rollout ViewByGrid "View by Grid" width:150 height:170
(
	listBox lbxGridList "Select Grid:" 
	
	groupbox grpSort "Sort" pos:[5, (lbxGridList.height + 25)] width: (ViewByGrid.width - 10) height: 50
		
	button btnUp "Up" across: 2 width: (ViewByGrid.width  / 2.5) pos:[15, (lbxGridList.height + 43)]
	button btnDown "Down" width: (ViewByGrid.width / 2.5) pos:[100, (lbxGridList.height + 43)]
	timer tmrZoom "" active: false interval: 1
	
	--button btnUpdate "Update" across: 2 width: (ViewByGrid.width  / 2.5) pos:[15, (lbxGridList.height + 80)]
	--button btnSelectGrid "Select Grid" width: (ViewByGrid.width / 2.5) pos:[100, (lbxGridList.height + 80)]

	global GridList = #()
	global GridName = #()
	local callbackGrid = undefined
	
	
	
	fn useSettings k p w =
	(	
		d = getFilenamePath  (getThisScriptFilename())
		n = filenameFromPath (getThisScriptFilename())			
		settingsFile = d + @"ini\" + (sysInfo.username) + "_" + n + ".ini"
				
		szUser = sysInfo.computername
		case w of
		(
			0:
			(
				s = getINISetting settingsFile szUser k
				case p of
				(
					"int": return s as integer
					"float": return s as float
					"bool": if s == "true" then true else false
					default: return s
				)
			)
			default: return setINISetting settingsFile szUser k (p as string)
		)
	)
	
	fn saveWindowPos =
	(
		useSettings "x"  iWindowPos[1] 1
		useSettings "y"  iWindowPos[2] 1		
	)
		
	fn getGridList =
	(		
		lbxGridList.items = #()
		
		GridList = #()
		GridName= #()
		
		
		append GridName "[ Default ]"
		append GridList undefined
				
		g = for i in objects where classOf i == Grid collect i
			
		
		GridListToSort = #()
		GridListNoSort = #()
		z = #()
		
		for i in g do
		(
			o = getUserProp i "order"
		
			if(o != undefined) then 
			(
				append GridListToSort i
				append z o								
			)
			else
			(
				append GridListNoSort i
			)	
		)
			
		sort z

		for i in z do
		(
			for ii in GridListToSort do
			(
				o = (getUserProp ii "order")
				
				if(findItem GridList ii != 0) do continue
				
				if(o == i) do
				(
					append GridList ii
				)
			)	
		)
		
		join GridList GridListNoSort		
		join GridName (for i in GridList where i != undefined collect i.name)
				
						
		lbxGridList.items = GridName
	)

	
	fn updateGridList ev nd = 
	(
		
		if(ev == #deleted) do return getGridList()
		
		for i in nd where i != undefined do 
		(
			o = (GetAnimByHandle i)
			
			if(classOf o == grid) do 
			(
				getGridList()
				exit
			)
		)
	)
	
	fn setGrid s =
	(		
		if(s < 1) do return false
				
		try
		(
			activeGrid = GridList[s]
			lbxGridList.selection = s
			
			viewport.setType #view_iso_user
			toolMode.coordsys #grid
			if s == 1 do toolMode.coordsys #view
			
			getGridList()
		)
		catch()
	)
	
	fn findGrid g =
	(
		p = -1
		for i in 1 to GridName.count do
		(			
			if(matchPattern GridName[i] pattern: g == true) do 
			(
				p = i
				exit
			)
		)
		
		return p
	)
		
	
	fn getActiveGrid =
	(
		g = activeGrid
		if(g != undefined) do
		(
			for i in 1 to GridName.count do
			(			
				if(matchPattern GridName[i] pattern: g.name == true) do 
				(
					setGrid i
					exit
				)
			)
		)
	)
	
	fn viewHotkey =
	(
		if(activeGrid == undefined) do return false
		v = viewport.getType()
		
		gridTM = inverse activeGrid.transform		
				
		n = case v of
		(
			#view_front : rotatex gridTM -90
			#view_bottom : rotatex gridTM 180
			#view_right: (rotatex gridTM -90; rotatey gridTM -90)
			#view_left  : (rotatex gridTM -90; rotatey gridTM 90)
			#view_back : (rotatex gridTM 90; rotatez gridTM 180)
			#view_top  : gridTM
			default: undefined
		)	
		
		if(n != undefined) do
		(
			viewport.setType #view_iso_user			
			viewport.setTM gridTM		
			toolMode.coordsys #grid					
			ForceCompleteRedraw()
			
			tmrZoom.active = false			
			tmrZoom.active = true			
		)
	)

	fn setWindowSize y load: false =
	(
		o = (ViewByGrid.height - lbxGridList.height)
	
		if(load) do y += o
		
		h = y - o
		
		if(y < windowHeight) do return rViewByGrid.size.y = windowHeight
	
		lbxGridList.height = h - o
			
		ViewByGrid.height = h
		rViewByGrid.size.y = y
	
	
		grpSort.pos.y = h - o + 25
		btnUp.pos.y = h - o + 43
		btnDown.pos.y = h - o + 43
		--btnUpdate.pos.y = h - o + 80
		--btnSelectGrid.pos.y = h - o + 80
	)
	
	fn sortGrid id sortTo: #up =
	(
		if(id == undefined or id < 2) do return false
		
		idOrder = id
		
		case sortTo of
		(
			#up:  idOrder -= 1
			#down: idOrder += 1
		)
		
		if(idOrder > GridList.count or idOrder < 2) do return false
		
		for i in 1 to GridList.count where GridList[i] != undefined do setUserProp GridList[i] "order" i
			
		for i in 1 to GridList.count where GridList[i] != undefined do
		(	
			o = getUserProp GridList[i] "order"
			if(o != undefined and o == idOrder) then
			(
				setUserProp GridList[i] "order" id
			)
		)
		
		setUserProp GridList[id] "order" idOrder
		
		getGridList()
		getActiveGrid()
		
		lbxGridList.selection = idOrder
	)	
	
	-- Without timer 3dMax 2012 will crash!
	on tmrZoom tick do
	(
		max zoomext sel 	
		max zoomext sel 	
		max zoomext sel 	
		tmrZoom.active = false
	)

	
	on ViewByGrid open  do
	(
		getGridList()
		getActiveGrid()
		
		x = (useSettings "x" "float" 0) as float
		y = (useSettings "y" "float" 0) as float

		try(rViewByGrid.pos = [x, y]) catch()
		
		h = (useSettings "h" "float" 0) as float
		
			
		if(h != 0) do setWindowSize h load: true
		

		callbackGrid = NodeEventCallback mouseUp:true delay:1000 deleted:updateGridList added:updateGridList nameChanged:updateGridList	wireColorChanged:updateGridList	selectionChanged:updateGridList
		
		rcmenu rcRightClick
		(
			menuItem mItem1 "Update" 
			menuItem mItem2 "Select Grid" 
			
			on rcRightClick open do 
			(
				
			)
			
			on mItem1 picked do 
			(
				getGridList()
				getActiveGrid()
			)	
			
			on mItem2 picked do try(select activeGrid)catch()
		)
		
		RegisterRedrawViewsCallback viewHotkey		
		callbacks.addScript #spacemodeChange "if(activeGrid != undefined and getRefCoordSys() == #hybrid) then toolMode.coordsys #grid else if (activeGrid == undefined and getRefCoordSys() == #object) then toolMode.coordsys #view" id:#fwdManipulate persistent:false	
	)

	on ViewByGrid rolledUp x do
	(
	)
	
	on ViewByGrid moved p do
	(
		iWindowPos = p
	)
	
	on ViewByGrid resized s do
	(				
		setWindowSize s[2]
	)
	
	on ViewByGrid close  do
	(
		saveWindowPos()
		
		callbackGrid = undefined
		gc light:true
		
		useSettings "h" ViewByGrid.height 1
		
		unRegisterRedrawViewsCallback viewHotkey	
		callbacks.removescripts id:#fwdManipulate
	)
	
	on lbxGridList selected s do
	(
		setGrid s
		
		getGridList()
		getActiveGrid()
	)
	
	on lbxGridList rightClick x do
	(
		popUpMenu  rcRightClick
	)
	
	on lbxGridList doubleClicked x do
	(
		try(select activeGrid)catch()
	)
	
	on btnUpdate pressed do
	(
		getGridList()
		getActiveGrid()
	)
		
	on btnSelectGrid pressed do
	(
		try(select activeGrid)catch()
	)
	
	on btnUp pressed do
	(
		id = lbxGridList.selection
		
		sortGrid id sortTo: #up
	)
	
	on btnDown pressed do
	(
		id = lbxGridList.selection
		
		sortGrid id sortTo: #down
	)
)

rollout rAbout "About" 
(	
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	button btnHelp "Help" enabled: false
	
	fn getHelp run: false =
	(
		s = getThisScriptFilename()
		i = getScriptInfo s
		szHelp = (getFilenamePath s) + i[7]
		if(i[7] != "" and doesFileExist szHelp) do btnHelp.enabled = true
			
		if(run) do ShellLaunch szHelp ""
	)
	
	on btnHelp pressed do getHelp run: true
				
	on rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
		
		getHelp()
	)
)

addRollout ViewByGrid rViewByGrid rolledUp:false 
addRollout rAbout rViewByGrid rolledUp:true 
