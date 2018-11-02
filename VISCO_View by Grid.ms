/*
[INFO]

NAME = VISCO_View by Grid
VERSION = 1.8.1
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
+ Added: Context menu with items^ Update and Select Grid=

[1.7.0]

* Changed: Improved UI=
+ Added: Create Grid button with options=
+ Added: Context Menu: Rename Active Grid=
+ Added: Context Menu: Remove Active Grid=
+ Added: Context Menu: Sort Up=
+ Added: Context Menu: Sort Down=
- Removed: Buttons Sort Up and Sort Down=

[1.7.1]

* Changed: Removed horizontal grid option and added rotate by 90 option=

[1.8.0] 
- BugFix: Rename grid from context menu=
- BugFix: Create line when grid activated for views=

[1.8.1] 
* Changed: Rethought window resizing system=
+ Added: Context menu item Grid List Size=

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

fn dbg a = (
	clearListener()
	print "---------------"
	print a 
	print "---------------"
)

try(closeRolloutFloater rViewByGrid) catch()
clearListener()
global CreateGrid
global _WINDOW_HEIGHT = 220
global _LBX_LINE_SIZE = 13
global _OFFSET_ROLLOUTS = 95
global iWindowPos = [0.0, 0.0]
global rcRightClick
global _LBX_SIZES = #(8, 15, 30, 50)
global _LBX_HEIGHT = _LBX_SIZES[1]


global rViewByGrid = newRolloutFloater "View by Grid" 200 _WINDOW_HEIGHT
global ViewByGrid

	
rollout ViewByGrid "View by Grid" width:150 height: 0
(
	listBox lbxGridList "" offset: [-15, -2] width: 190 height:  1
	/*groupbox grpSort "Sort" pos:[5, (lbxGridList.height + 5)] width: (ViewByGrid.width - 10) height: 50
		
	button btnUp "Up" across: 2 width: (ViewByGrid.width  / 2.5) pos:[15, (lbxGridList.height + 24)]
	button btnDown "Down" width: (ViewByGrid.width / 2.5) pos:[100, (lbxGridList.height + 24)]*/
	timer tmrZoom "" active: false interval: 10
	
	--button btnUpdate "Update" across: 2 width: (ViewByGrid.width  / 2.5) pos:[15, (lbxGridList.height + 80)]
	--button btnSelectGrid "Select Grid" width: (ViewByGrid.width / 2.5) pos:[100, (lbxGridList.height + 80)]

	global GridList = #()
	global GridName = #()
	local callbackGrid = undefined
	
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
					return f
					exit
				)
			)
		)
		
		return undefined
	)
	global allowZoom = false
	
	fn viewHotkey f:#none=
	(
		if(activeGrid == undefined) do return false
			
		v = viewport.getType()
		if(f != #none) do v = f
		
		if(allowZoom) do (
			max zoomext sel	
		)
		
		case v of
		(
			#view_top  : actionMan.executeAction 0 "40315"  -- Views: Grid Top
			#view_front :  actionMan.executeAction 0 "40316"  -- Views: Grid Front
			#view_back: actionMan.executeAction 0 "40317"  -- Views: Grid Back
			#view_bottom : actionMan.executeAction 0 "40318"  -- Views: Grid Bottom
			#view_left : actionMan.executeAction 0 "40319"  -- Views: Grid Left
			#view_right: actionMan.executeAction 0 "40320"  -- Views: Grid Right				
			default: return allowZoom = false	
		)
			
		toolMode.coordsys #grid	
		disableSceneRedraw()
		enableSceneRedraw()
		ForceCompleteRedraw()
	
		allowZoom = true
		
		tmrZoom.active = false			
		tmrZoom.active = true	
	)

	fn setWindowSize size: -1 reload: false =
	(	
		if(size != -1) do useSettings "hh" size 1
		
		h = useSettings "hh" "int" 0
			
		if(h  != 0 and h != _LBX_SIZES[1]) do (
			_LBX_HEIGHT = h
			_WINDOW_HEIGHT = _WINDOW_HEIGHT + ((_LBX_HEIGHT - _LBX_SIZES[1]) * _LBX_LINE_SIZE)										
		)
		
		lbxGridList.height = _LBX_HEIGHT * _LBX_LINE_SIZE
		ViewByGrid.height = lbxGridList.height + 10
		rViewByGrid.size.y = _WINDOW_HEIGHT
		
		if(reload) do fileIn (getThisScriptFileName())			
	)
	
	fn getSelectedGrid = (
		id = lbxGridList.selection
		if(id == 0) do return undefined
		
		n = lbxGridList.selected 				
		i = findGrid n
		if(i != -1) do return 	GridList[i]
		return undefined
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
		/*
		actionMan.executeAction 0 "310" 
		actionMan.executeAction 0 "310" 
		actionMan.executeAction 0 "310" */
		
		ForceCompleteRedraw()
		ForceCompleteRedraw()
		ForceCompleteRedraw()
		ForceCompleteRedraw()
		
		tmrZoom.active = false
	)

	
	on ViewByGrid open  do
	(
		getGridList()
		getActiveGrid()
		
		x = (useSettings "x" "float" 0) as float
		y = (useSettings "y" "float" 0) as float

		try(rViewByGrid.pos = [x, y]) catch()
		
		setWindowSize()
		
		callbackGrid = NodeEventCallback mouseUp:true delay:1000 deleted:updateGridList added:updateGridList nameChanged:updateGridList	wireColorChanged:updateGridList	selectionChanged:updateGridList
				
		rcmenu rcRightClick
		(
			menuItem mTop "Top" 
			menuItem mBottom "Bottom" 
			menuItem mFront "Front" 
			menuItem mBack "Back" 
			menuItem mLeft "Left" 
			menuItem mRight "Right" 
			separator sep00
			menuItem mItem1 "Update List" 
			menuItem mItem2 "Select Grid" 
			separator sep0
			menuItem mRename "Rename Active Grid" enabled: false
			separator sep1
			subMenu "Grid List Size" (
				menuItem mSize1 "Small"
				menuItem mSize2 "Medium"
				menuItem mSize3 "Large"
				menuItem mSize4 "Super Large"
			)
			separator sep5
			menuItem mUp "Sort Up" 
			menuItem mDown "Sort Down" 
			separator sep2
			menuItem mRemove "Remove Grid" enabled: false
			
			fn setView type = (
				ViewByGrid.viewHotkey f:type 
				ViewByGrid.viewHotkey f:type 
			)
			
			fn newSize type = (
				s = _LBX_SIZES[type]
				setWindowSize size: s reload: true
			)
			
			on mSize1 picked do newSize 1
			on mSize2 picked do newSize 2
			on mSize3 picked do newSize 3
			on mSize4 picked do newSize 4
			
			on rcRightClick open do 
			(
				g = getSelectedGrid()
				
				if(g != undefined) do (
					mRemove.text = "Remove Active Grid: " + g.name
					mRename.text = "Rename Active Grid: " + g.name
					mRemove.enabled = true
					mRename.enabled = true
				)
			)
			
			on mRename picked do (

				g = getSelectedGrid()
				
				if(g != undefined) do (
					n = CreateGrid.modalGridName()					
					if(n.count > 1) do g.name = n
					getGridList()
				)				
			)
			
			on mRemove picked do (
				g = getSelectedGrid()
			
				if(g != undefined) do (
					q = queryBox ("Do you really want to delete " + g.name + " ?") title: "Confirm?"
					
					if(q) do delete g
				)
			)
			
			on mItem1 picked do 
			(
				getGridList()
				getActiveGrid()
			)	
			
			on mUp picked do 
			(
				id = lbxGridList.selection		
				ViewByGrid.sortGrid id sortTo: #up
			)	
			
			on mDown picked do 
			(
				id = lbxGridList.selection		
				ViewByGrid.sortGrid id sortTo: #down
			)	
			
			on mTop picked do (
				ViewByGrid.viewHotkey f:#view_top 
				ViewByGrid.viewHotkey f:#view_top 
			)
			on mBottom picked do setView #view_bottom
			on mFront picked do setView #view_front 
			on mBack picked do setView #view_back
			on mLeft picked do setView #view_left
			on mRight picked do setView #view_right
			
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
		--setWindowSize s[2]
	)
	
	on ViewByGrid close  do
	(
		saveWindowPos()
		
		callbackGrid = undefined
		gc light:true
		
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

rollout CreateGrid "" (
	button btnCreateGrid "Create Grid" width: 170	
	checkbox cbxActivate "Activate grid after creation"
	checkbox cbxHorizontalGrid "Rotate grid by 90deg" checked: true
	
	fn modalGridName = (
		global _GRID_NAME = ""
		try(destroyDialog rSetGridName) catch()
		
		rollout rSetGridName "Grid Name" (
			group "Enter grid name:" (
				edittext edtGridName ""
			)
			
			button btnOk "Ok" align: #left width: 70 height: 26 offset: [0, 10]
			
			on rSetGridName open do (
				setFocus edtGridName
			)
			
			on btnOk pressed do (
				_GRID_NAME = edtGridName.text
				try(destroyDialog rSetGridName) catch()
			)
			
			on edtGridName entered t do (
				if(t == "") do return false
				_GRID_NAME = edtGridName.text
				try(destroyDialog rSetGridName) catch()
			)
		)
		
		createDialog rSetGridName 220 100 modal: true
		try(destroyDialog rSetGridName) catch()
		
		return _GRID_NAME
	)
	
	on CreateGrid open do (
				
	)
	
	on btnCreateGrid pressed do (
		itemsCnt = ViewByGrid.lbxGridList.items.count
		
		oldAutoGrid = maxOps.autoGrid 
		maxOps.autoGrid = true
				
		startObjectCreation Grid returnNewNodes: true
		maxOps.autoGrid  = oldAutoGrid		
		
		
		if(classOf selection[1] == Grid) do (
			
			g = selection[1]
			
			if(cbxHorizontalGrid.checked) do (
				pos = g.pos
				rot = g.rotation as eulerAngles 
					print rot
				r = -1
				if(rot.x >=0) do r = 1
				
				ntm = preRotateX g.transform -((rot.x + (90 - rot.x)))
				g.transform = ntm				
					
				g.pos = pos
			)	
			
			n = modalGridName()
			if(n.count > 1) do g.name = n
		)

		if(cbxActivate.checked) do (
			if(itemsCnt < ViewByGrid.lbxGridList.items.count) do (
				s = ViewByGrid.lbxGridList.items.count
				ViewByGrid.setGrid s	
			)	
		)
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

addRollout ViewByGrid rViewByGrid rolledUp:false border: false category: 1
addRollout CreateGrid rViewByGrid rolledUp:false border: false category: 2
addRollout rAbout rViewByGrid rolledUp:true category: 100

