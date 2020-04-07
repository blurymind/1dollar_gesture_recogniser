extends Control

## todo- turn this into an addon for godot, so it is easier to reuse in other projects
signal shapeDetected 
export var inputMapAction = ""
var pressed = false
var guestures = preload("recognizer.gd").new()
var draw = []
var position = Vector2()
var scriptPath = self.get_script().get_path().get_base_dir()
onready var gestureJsonFilePath = scriptPath + "\\recordedGestures.json"
export var maxInk = 0.7  ## set this to the max line length the user can draw
export var replenishInkSpeed = 11.5 # set to 0 in order to disable replenishing ink altogether
export var inkLossRate = 1 # set to 0 in order to disable tracking ink altogether
onready var curInk = maxInk

var mouseCursorIconPath = scriptPath+"\\pencil.png"
export var recording = true
export var particleEffect = true
export var particleColor = Color(1,1,1,1)

var particleNode = null
var particleMaterial = null

func _ready():
	var drawInputEvent = InputEventKey.new() ## set the action to trigger this behavior
	if inputMapAction == "":## make left mouse button the default trigger action
		drawInputEvent.set_scancode(BUTTON_LEFT)
		InputMap.add_action("m_btn")
		InputMap.action_add_event("m_btn", drawInputEvent)
		print("set left mouse to m_btn action")
		inputMapAction = "m_btn"

	if particleEffect: ## set fancy particle effect if user wanted it
		particleNode = Particles2D.new()
		particleMaterial = ParticlesMaterial.new()
		particleNode.set_name("drawParticle")
		particleNode.set_position(Vector2(50,50))
		particleNode.set_amount(32)
		particleNode.set_lifetime(1)
		particleNode.set_use_local_coordinates(false)
		particleNode.set_emitting(false)
		particleMaterial.set_color(particleColor)
		particleMaterial.initial_velocity = 0.0
		particleMaterial.linear_accel = 0
		particleMaterial.scale = 20
		particleMaterial.set_gravity(Vector3(0, 200, 0))
		particleNode.process_material = particleMaterial
		add_child(particleNode)
	connect("mouse_entered",self,"_on_mouse_enter")
	connect("mouse_exited",self,"_on_mouse_exit")
	loadSavedGesturesFromJson(gestureJsonFilePath)
	
	if recording: ## add debug dev gui if in dev mode
		var debugGui = preload("debugGui.tscn").instance()
		add_child(debugGui)
		debugGui.set_position(Vector2(get_global_position().x,get_size().y))
		get_node("gui/addGuester").connect("pressed",self,"_on_addGuester_pressed")
		get_node("gui/saveGesturesToJson").connect("pressed",self,"saveGesturesToJsonFile")
		get_node("gui/status").set_text(str("Loaded ",guestures.Unistrokes.size()," gestures from json library"))
		get_tree().set_debug_collisions_hint(true)
	set_process_input(true)
	if inkLossRate> 0:
		set_process(true)
	update()

################### replenish ink process #####################
func _process(delta):
	if Input.is_action_pressed(inputMapAction) == false and pressed == false:######  releasing  ########################
		if curInk <= maxInk:
			if replenishInkSpeed != 0:curInk += replenishInkSpeed * delta /10
		else:curInk = maxInk
	elif curInk > 0: ###### pressing  ########################################################
		curInk -= inkLossRate * delta## run out of ink when drawing
	if curInk < maxInk: update()
	if curInk < 0:
		curInk = 0

var maximumRecPoints = 1000
var minimumRecPoints = 4
func _input(event):	
	if canDraw:
		if (event.is_action_pressed(inputMapAction)): ## pressed###############################################
			draw = []
			pressed = event.pressed
			position.x = get_viewport().get_mouse_position().x
			position.y = get_viewport().get_mouse_position().y
			if particleEffect and (draw.size() < maximumRecPoints):
				particleNode.set_emitting(true)
				particleNode.set_position(position)
		if (event is InputEventMouseMotion && pressed): ## while pressed#################################
			if (draw.size() < maximumRecPoints):
				if curInk > 0:
					position.x = get_viewport().get_mouse_position().x
					position.y = get_viewport().get_mouse_position().y
					draw.append(position)
					if particleEffect:
						particleNode.set_position(position)
					if draw.size() % 2:update() ## dont update so often
					if inkLossRate ==0:curInk-=0.01
			else:recogniseDrawnGesture()
			
			if curInk <= 0: ## recognise gesture even if user runs outa ink
				recogniseDrawnGesture()
		if (event.is_action_released(inputMapAction)): ## released ################################################
			pressed = event.pressed
			if (draw.size() > minimumRecPoints) and (draw.size() < maximumRecPoints):
				recogniseDrawnGesture()
		if particleEffect and (curInk <= 0):particleNode.set_emitting(false)

func recogniseDrawnGesture():
	if particleEffect: ## particle effect is optional
		particleNode.set_position(position)
		particleNode.set_emitting(false)
	
	if (draw.size() > maximumRecPoints): return ##prevent crashes
	if (draw.size() == 0): return ##prevent crashes
	var recognisedGesture = guestures.recognize(draw)
	var inkLeft = curInk
	emit_signal("shapeDetected",recognisedGesture,inkLeft)
	get_node("gui/status").set_text(str(recognisedGesture," --ink left:",inkLeft)+str(" --draw: ",draw.size()," --gesture lib: ",guestures.Unistrokes.size()))

	drawColShapePolygon(draw)
	if inkLossRate  == 0:
		curInk = maxInk
	update()
	if not recording:
		draw = []

var savedGestures = []
var data = {}
func _on_addGuester_pressed():
	if (draw.size() > minimumRecPoints) and (draw.size() < maximumRecPoints):
		var new_guester = preload("unistroke.gd").new(get_node("gui/guester_name").get_text(), draw)
		guestures.Unistrokes.append(new_guester)	
		## store to array that will be written to the json file
		savedGestures.append([get_node("gui/guester_name").get_text(),var2str(draw)])
		if recording:
			print("we have ",savedGestures.size()," gestures so far")
			get_node("gui/status").set_text(str("ADDED draw: ",draw.size()," uni: ",guestures.Unistrokes.size()," to ram"))
		draw = []

func saveGesturesToJsonFile():
	data = {}
	var file = File.new()
	file.open(gestureJsonFilePath, File.WRITE)
	data["gestures"] = savedGestures
	file.store_line(JSON.print(data))
	file.close()
	if recording:print("saved ",savedGestures.size()," gestures")

var loadedGestures = []
func loadSavedGesturesFromJson(path):
	if recording:print("loading gestures from:",path)
	var file = File.new()
	file.open(gestureJsonFilePath, File.READ)
	var rawString = file.get_as_text()
	if rawString.length() == 0:return #nothing loaded, thus skip
	data = JSON.parse(rawString).result
	
	for gesture in data["gestures"]:
		var cleanedGesture = []
		for vectorval in str2var(gesture[1]):
			cleanedGesture.append(vectorval)
		var cleanedGestureData = []
		cleanedGestureData.append(str(gesture[0]))
		cleanedGestureData.append(cleanedGesture)
		loadedGestures.append(cleanedGestureData)
		savedGestures.append(gesture)

	for load_guester in loadedGestures:
		var new_guester = preload("unistroke.gd").new(load_guester[0], load_guester[1])
		guestures.Unistrokes.append(new_guester)
	if recording:print ("Loaded ",loadedGestures.size()," gestures!")

## can we draw or not - the mouse needs to be inside the area
var canDraw = false
func _on_mouse_enter():
	canDraw = true
	Input.set_custom_mouse_cursor(load(mouseCursorIconPath))
func _on_mouse_exit():
	canDraw = false
	Input.set_custom_mouse_cursor(null)

########### draw ###################################################################################
export var lineThickness = 2
export var lineColor = Color(255, 0, 0,1)
export var inkHealthBarWidth = 100

func _draw():
	var lineIndex = 0
	if draw.size() <= 0: return

	if lineThickness != 0:
		for line in draw:
			if lineIndex > 0 : ##draw freehand line
				draw_line(draw[lineIndex-1], draw[lineIndex], Color(lineColor.r,lineColor.g,lineColor.b,curInk), lineThickness)
			lineIndex +=1

	if inkLossRate> 0 and inkHealthBarWidth != 0:
		if curInk > 0 and inkHealthBarWidth > 0 :## indicate how much ink is left
			draw_rect(Rect2(10,10,curInk*inkHealthBarWidth,20),lineColor)

### draw a colision shape from the array ###
export var createColisions = true
export var maxDrawnColShapes = 3
func drawColShapePolygon(vector2arr):
	if curInk > 0 and createColisions:
		var colShapePol = CollisionPolygon2D.new()
		colShapePol.set_polygon(vector2arr)
		colShapePol.add_to_group(str("drawnShape:",guestures.recognize(draw))) ##will be useful later on for colisions
		colShapePol.add_to_group("drawnShapes") ## use to keep track of all
		add_child(colShapePol)
	### limit how many maximum drawn shapes can exist ### you can destroy them on collision elsewhere
	if maxDrawnColShapes > 0:##if set to 0, it is disabled
		if get_tree().get_nodes_in_group("drawnShapes").size() > maxDrawnColShapes:
			get_tree().get_nodes_in_group("drawnShapes")[0].queue_free()## remove the oldest
