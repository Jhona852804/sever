-- Geolocation.lua
Event = Lib.Media.Events.Event
Display = Lib.Media.Display
BitmapData = Display.BitmapData
Bitmap = Display.Bitmap
Geom = Lib.Media.Geom
stage = Display.stage
Camera = Lib.Media.Camera
Geolocation = Lib.Media.Sensors.Geolocation
Text = Lib.Media.Text
stage = Lib.Media.Display.stage

-- Main.lua

rot = 270 -- 0,90,270,180
osn = Lib.Media.System.systemName()
bitmap = nil

function setBmpSize()
  if osn == "android" or osn == "ios" then
  	o = stage.getOrientation()
	  if o == 1 then
		rot = 90
      elseif o == 3 then
		rot = 0 
      elseif o == 4 then
		rot = 180
      else
        rot = 270 
      end
  end

  if bitmap ~= nil then
    local sw = stage.stageWidth
    local sh = stage.stageHeight
    local w = bitmap.bitmapData.width
    local h = bitmap.bitmapData.height
    if rot==90 or rot==270 then
	    w = bitmap.bitmapData.height
        h = bitmap.bitmapData.width
    end
    local bmpW = sw
    local bmpH = sh
    if w*sh > h*sw then
	    bmpH = h*sw/w
    else
        bmpW = w*sh/h
    end

    print('Stage : '..sw..' '..sh)
    print('Camera: '..bmpW..' '..bmpH)
    bitmap.rotation = rot
    bitmap.width = bmpW
    bitmap.height = bmpH

	if rot == 0 then
		bitmap.x = (sw-bmpW)*0.5
		bitmap.y = (sh-bmpH)*0.5
	elseif rot == 90 then
        bitmap.x = sw - (sw-bmpW)*0.5
        bitmap.y = (sh-bmpH)*0.5
	elseif rot == 270 then
        bitmap.x = (sw-bmpW)*0.5
		bitmap.y = sh - (sh-bmpH)*0.5
	elseif rot == 180 then
        bitmap.x = sw - (sw-bmpW)*0.5
        bitmap.y = sh - (sh-bmpH)*0.5
    end
  end
end

function onFrame(e)
  print("onFrame! "..camera.width.."x"..camera.height)
  if camera ~= nil then
    camera.removeEventListener(Event.VIDEO_FRAME,onFrame,false)
    bitmap = Bitmap.new( camera.bitmapData, nil, true )
    stage.addChild(bitmap)
    setBmpSize()
  end
end

print("Camera devices:")
names = Camera.names
if names ~= nil and #names > 0 then
  for i = 1, #names do
    camera = Camera.getCamera(names[i]) 
    print("camera: "..camera.name.." ["..camera.width.."x"..camera.height.."] position: "..camera.position)
    camera.destroy()--not all devicess can open multiple cameras, destroy previously created before you can get next camera info
  end

  camera = Camera.getCamera(1) --get default camera 
  if camera ~= nil then
    print("Found default camera: "..camera.name.." ["..camera.width.."x"..camera.height.."] position: "..camera.position)
    camera.addEventListener(Event.VIDEO_FRAME,onFrame,false,0,false)
    stage.addEventListener(Event.RESIZE, function(e) setBmpSize() end, false, 0, false)
    camera.activate()
  end
else
  print("not found")
end

local fmt = Text.TextFormat.new('_sans', 15, 0x660000, nil, nil, nil)
local text = Text.TextField.new()
text.defaultTextFormat = fmt
text.autoSize = Text.TextFieldAutoSize.LEFT
text.x = 10
text.y = 10
text.width = 200
text.wordWrap = true
stage.addChild(text)

local geo = Geolocation.new()
local isSupported = Geolocation.isSupported

function updateHandler(e)
	text.text = 
		"\ntimestamp: "..e.timestamp..
		"\naltitude: "..e.altitude..
		"\nlatitude: "..e.latitude..
		"\nlongitude: "..e.longitude..
		"\nhorizontalAccuracy: "..e.horizontalAccuracy..
		"\nverticalAccuracy: "..e.verticalAccuracy..
		"\nspeed: "..e.speed..
		"\nheading: "..e.heading..
        (e.provider and "\nprovider: "..e.provider or "")
end

function statusHandler(e)
    Lib.Sys.trace(e)
	if geo.muted then
    	geo.removeEventListener(Lib.Media.Events.GeolocationEvent.UPDATE, updateHandler, false)
    else
    	geo.addEventListener(Lib.Media.Events.GeolocationEvent.UPDATE, updateHandler, false, 0 ,false)
	end
end

if (isSupported) then
	print("Geolocation feature supported")
    geo.locationAlwaysUsePermission = true --for iOS, declared before request permission
    print(Geolocation.permissionStatus)
    geo.requestPermission() -- required on mobile devices 
    geo.addEventListener(Lib.Media.Events.GeolocationEvent.UPDATE, updateHandler, false, 0 ,false)
    geo.addEventListener(Lib.Media.Events.StatusEvent.STATUS, statusHandler, false, 0 ,false)
else
	print("Geolocation feature not supported")
end
