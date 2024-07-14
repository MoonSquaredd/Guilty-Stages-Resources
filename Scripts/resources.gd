extends Node2D

var stageNames = {
	"AD. 2172 (+R)" = "bg_fr.cmp",
	"AD. 2172 (Slash)" = "bg_sfr.cmp",
	"Babylon (+R)" = "bg_in.cmp",
	"Babylon (Reload)" = "bg_rin.cmp",
	"Babylon (Slash)" = "bg_sin.cmp",
	"Castle (+R)" = "bg_sy.cmp",
	"Castle (Reload)" = "bg_rsy.cmp",
	"Castle (Slash)" = "bg_ssy.cmp",
	"China (+R)" = "bg_jm.cmp",
	"China (Reload)" = "bg_rjm.cmp",
	"China (Slash)" = "bg_sjm.cmp",
	"Colony (+R)" = "bg_bk.cmp",
	"Colony (Reload)" = "bg_rbk.cmp",
	"Colony (Slash)" = "bg_sbk.cmp",
	"Frasco (+R)" = "bg_ab.cmp",
	"Frasco (Slash)" = "bg_sab.cmp",
	"Grave (+R)" = "bg_kr.cmp",
	"Grave (Reload)" = "bg_rkr.cmp",
	"Grove (+R)" = "bg_dz.cmp",
	"Grove (Reload)" = "bg_rdz.cmp",
	"Grove (Slash)" = "bg_sdz.cmp",
	"Heaven (+R)" = "bg_js.cmp",
	"Hell (+R)" = "bg_ts.cmp",
	"Hell (Reload)" = "bg_rts.cmp",
	"Hell (Slash)" = "bg_sts.cmp",
	"London (+R)" = "bg_ax.cmp",
	"London (Reload)" = "bg_rax.cmp",
	"London (Slash)" = "bg_sax.cmp",
	"May Ship (+R)" = "bg_my.cmp",
	"May Ship (AC)" = "bg_my.cmp",
	"May Ship (Reload)" = "bg_rmy.cmp",
	"May Ship (Slash)" = "bg_smy.cmp",
	"Nirvana (Reload)" = "bg_rve.cmp",
	"Nirvana (Slash)" = "bg_sve.cmp",
	"Paris (+R)" = "bg_sl.cmp",
	"Paris (Reload)" = "bg_rsl.cmp",
	"Paris (Slash)" = "bg_ssl.cmp",
	"Phantom City (+R)" = "bg_zp.cmp",
	"Phantom City (Reload)" = "bg_rzp.cmp",
	"Phantom City (Slash)" = "bg_szp.cmp",
	"Russia (Reload)" = "bg_rml.cmp",
	"Russia (Slash)" = "bg_sml.cmp",
	"Unknown (+R)" = "bg_ex.cmp",
	"Unknown (Reload)" = "bg_rex.cmp",
	"Unknown (Slash)" = "bg_sex.cmp",
	"Verdant (+R)" = "bg_yy.cmp",
	"Verdant (Reload)" = "bg_ryy.cmp",
	"Verdant (Slash)" = "bg_syy.cmp",
	"Zepp (+R)" = "bg_po.cmp",
	"Zepp (Reload)" = "bg_rpo.cmp",
	"Zepp (Slash)" = "bg_spo.cmp",
}

var stageFolder = ""
var outputFolder = ""
var selectedStage = null

func getTileInfo(file: FileAccess, tile):
	file.seek(tile+4)
	var bpp = file.get_16()
	var width = file.get_16()
	var height = file.get_16()
	var paletteSize = (16**(bpp/4))
	var raw = tile + 16 + (paletteSize*4)
	var rawSize = width * height
	return {"bpp" = bpp, "width" = width, "height" = height, "paletteSize" = paletteSize, "raw" = raw, "rawSize" = rawSize}

func getTiles(file: FileAccess):
	file.seek(0)
	var tiles = []
	var offsetToTiles = file.get_32()
	file.seek(offsetToTiles+4)
	
	while not file.eof_reached():
		var current = file.get_32()
		
		if current == 0xFFFFFFFF:
			break
		else:
			tiles.append(current + offsetToTiles)
	
	return tiles

func getSprites(file: FileAccess):
	file.seek(4)
	var objects = []
	var sprites = []
	
	while not file.eof_reached():
		var object = file.get_32()
		
		if object == 0xFFFFFFFF:
			break
		else:
			objects.append(object)
	
	if objects.size() <= 1:
		return ["no objects"]
	
	for i in range(objects.size() - 1):
		var offsetToObject = objects[i]
		file.seek(offsetToObject+4)
		var offsetToSprites = file.get_32()
		file.seek(offsetToSprites + offsetToObject)
		
		while not file.eof_reached():
			var current = file.get_32()
		
			if current == 0xFFFFFFFF:
				break
			else:
				sprites.append(current + offsetToObject + offsetToSprites)
	
	return sprites

func retrievePalettes():
	var tileList = []
	var spriteList = []
	var stageFileName = stageNames[selectedStage]
	
	var file = FileAccess.open(stageFolder + "/" + stageFileName, FileAccess.READ)
	if not file:
		return 1
	tileList = getTiles(file)
	spriteList = getSprites(file)
	
	var extrasFile = FileAccess.open(outputFolder + "/" + selectedStage + " resources/" + stageFileName.erase(stageFileName.length() - 4, 4) + "E.txt", FileAccess.WRITE)
	extrasFile.store_string(";GameName=" + selectedStage + "\n")
	extrasFile.store_string(";ColorFormat=RGBA8887 \n\n")
	
	for i in range(tileList.size()):
		file.seek(tileList[i]+4)
		var bpp = file.get_8()
		var paletteSize = (16**(bpp/4))
		var paletteStart = tileList[i] + 16
		var paletteEnd = paletteStart + paletteSize*4
		var off = 0
		file.seek(paletteEnd-4)
		var lastColor = file.get_32()
		if lastColor == 0:
			off = 4
		extrasFile.store_string("Tile " + str(i+1) + "\n")
		extrasFile.store_string("0x%X \n" % [paletteStart-off])
		extrasFile.store_string("0x%X \n\n" % [paletteEnd-off])
	
	if spriteList != ["no objects"]:
		for i in range(spriteList.size()):
			file.seek(spriteList[i]+4)
			var bpp = file.get_8()
			var paletteSize = (16**(bpp/4))
			var paletteStart = spriteList[i] + 16
			var paletteEnd = paletteStart + paletteSize*4
			var off = 0
			file.seek(paletteEnd-4)
			var lastColor = file.get_32()
			if lastColor == 0:
				off = 4
			extrasFile.store_string("Sprite " + str(i+1) + "\n")
			extrasFile.store_string("0x%X \n" % [paletteStart-off])
			extrasFile.store_string("0x%X \n\n" % [paletteEnd-off])
	
	extrasFile.close()
	file.close()
	return 0

func createPreviews():
	var tileList = []
	var spriteList = []
	var stageFileName = stageNames[selectedStage]
	
	var file = FileAccess.open(stageFolder + "/" + stageFileName, FileAccess.READ)
	if not file:
		return 1
	tileList = getTiles(file)
	spriteList = getSprites(file)
	
	for i in range(tileList.size()):
		file.seek(tileList[i]+4)
		var bpp = file.get_16()
		var width = file.get_16()
		var height = file.get_16()
		var paletteSize = (16**(bpp/4))
		
		if bpp == 4:
			width /= 2
		
		file.seek(tileList[i]+12+(paletteSize*4))
		var lastColor = file.get_32()
		
		var preview = FileAccess.open(outputFolder + "/" + selectedStage + " resources/previews/Tile_" + str(i+1) + "-W-" + str(width) + "-H-" + str(height) + ".raw", FileAccess.WRITE)
		for j in range(height):
			for k in range(width):
				var byte = file.get_8()
				if bpp == 8:
					if byte%32 > 7 and byte%32 < 23:
						if byte%32 < 16:
							byte += 8
						else:
							byte -= 8
				if lastColor == 0:
					byte += 1
				preview.store_8(byte)
		preview.close()
	
	if spriteList != ["no objects"]:
		for i in range(spriteList.size()):
			file.seek(spriteList[i]+4)
			var bpp = file.get_16()
			var width = file.get_16()
			var height = file.get_16()
			var paletteSize = (16**(bpp/4))
			file.seek(spriteList[i]+12+(paletteSize*4))
			var lastColor = file.get_32()
			
			var preview = FileAccess.open(outputFolder + "/" + selectedStage + " resources/previews/Sprite_" + str(i+1) + "-W-" + str(width) + "-H-" + str(height) + ".raw", FileAccess.WRITE)
			for j in range(height):
				for k in range(width):
					var byte = file.get_8()
					if bpp == 8:
						if byte%32 > 7 and byte%32 < 23:
							if byte%32 < 16:
								byte += 8
							else:
								byte -= 8
					if lastColor == 0:
						byte += 1
					preview.store_8(byte)
			preview.close()
	
	file.close()
	return 0

func buildImage(file: FileAccess, resource, resourceType, i):
	file.seek(resource+4)
	var bpp = file.get_16()
	var width = file.get_16()
	var height = file.get_16()
	var paletteSize = (16**(bpp/4))
	
	if bpp == 4:
		width /= 2
	
	file.seek(resource+16)
	
	var palette = PackedColorArray()
	for j in range(paletteSize):
		var red = file.get_8()
		var green = file.get_8()
		var blue = file.get_8()
		var alpha = (file.get_8() - 1) * 2
		palette.append(Color8(red, green, blue, alpha))
		
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var byte = file.get_8()
			if bpp == 8:
				if byte%32 > 7 and byte%32 < 23:
					if byte%32 < 16:
						byte += 8
					else:
						byte -= 8
			image.set_pixel(x, y, palette[byte & (paletteSize-1)])
	image.save_png(outputFolder + "/" + selectedStage + " resources/pngs/" + resourceType + "_" + str(i+1) + ".png")

func createPNGs():
	var tileList = []
	var spriteList = []
	var stageFileName = stageNames[selectedStage]
	
	var file = FileAccess.open(stageFolder + "/" + stageFileName, FileAccess.READ)
	if not file:
		return 1
	tileList = getTiles(file)
	spriteList = getSprites(file)
	
	for i in range(tileList.size()):
		buildImage(file, tileList[i], "Tile", i)
	
	if spriteList != ["no objects"]:
		for i in range(spriteList.size()):
			buildImage(file, spriteList[i], "Sprite", i)
	
	file.close()

func _ready():
	for i in stageNames:
		$"MenuBar/Select Stage".add_item(i)

func _on_select_stage_id_pressed(id):
	var clicked = $"MenuBar/Select Stage".get_item_text(id)
	$selectedStage.text = "Selected Stage: " + clicked
	selectedStage = clicked
	print(selectedStage)

func _on_button_pressed():
	var inPath = str($StagesPath.text).replace("\\", "/")
	var outPath = str($OutputPath.text).replace("\\", "/")
	
	if not $Options/Palettes.button_pressed and not $Options/Previews.button_pressed and not $Options/PNGs.button_pressed:
		$Error.text = "Error: No option selected"
		$Timer.start()
		await $Timer.timeout
		$Error.text = ""
		return 1
	
	if not selectedStage:
		$Error.text = "Error: No stage selected"
		$Timer.start()
		await $Timer.timeout
		$Error.text = ""
		return 2
	
	if inPath == "" or outPath == "":
		$Error.text = "Error: No file path specified"
		$Timer.start()
		await $Timer.timeout
		$Error.text = ""
		return 3
	
	var gameFolder = DirAccess.dir_exists_absolute(inPath)
	if not gameFolder:
		$Error.text = "Error: Stage folder is not accessible"
		$Timer.start()
		await $Timer.timeout
		$Error.text = ""
		return 4
	
	var dst = DirAccess.dir_exists_absolute(outPath)
	if not dst:
		$Error.text = "Error: Output folder is not accessible"
		$Timer.start()
		await $Timer.timeout
		$Error.text = ""
		return 5
	
	if selectedStage == "May Ship (+R)":
		stageFolder = inPath + "/Resource/pr/ver_100/bg"
	else:
		stageFolder = inPath + "/Resource/bg"
	outputFolder = outPath
	DirAccess.make_dir_absolute(outputFolder + "/" + selectedStage + " resources")
	
	if get_node("Options/Palettes").button_pressed:
		var result = retrievePalettes()
		if result == 1:
			$Error.text = "Error: Could not find stage file"
			$Timer.start()
			await $Timer.timeout
			$Error.text = ""
			return 6
		$Success.text = "Successfully created extras file for " + selectedStage
		$Timer.start()
		await $Timer.timeout
		$Success.text = ""
	
	if get_node("Options/Previews").button_pressed:
		DirAccess.make_dir_absolute(outputFolder + "/" + selectedStage + " resources/previews")
		var result = createPreviews()
		if result == 1:
			$Error.text = "Error: Could not find stage file"
			$Timer.start()
			await $Timer.timeout
			$Error.text = ""
			return 6
		$Success.text = "Successfully created previews for " + selectedStage
		$Timer.start()
		await $Timer.timeout
		$Success.text = ""
	
	if get_node("Options/PNGs").button_pressed:
		DirAccess.make_dir_absolute(outputFolder + "/" + selectedStage + " resources/pngs")
		var result = createPNGs()
		if result == 1:
			$Error.text = "Error: Could not find stage file"
			$Timer.start()
			await $Timer.timeout
			$Error.text = ""
			return 6
		$Success.text = "Successfully created tiles PNGs for " + selectedStage
		$Timer.start()
		await $Timer.timeout
		$Success.text = ""
