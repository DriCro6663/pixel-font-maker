# import module
fs        = require 'fs'
getPixels = require "get-pixels"
builder   = require 'xmlbuilder'

# read img-font.json from ./font-img
imgPath     = '../font-img' # font image folder path (need to .json)
outputPath  = '../font-svg' # output font svg folder path
searchExt   = '.json'      # extract extension
settingList = undefined    # main: settingList = loadFiles(imgPath, searchExt)
#setting    = undefined    # main: setting = settingList[i]

# font setting
font_width = 1024
font_height = 1024
pixel_width = 8
pixel_height = 8

# load font-img folder setting.json
loadFiles = (dirpath, ext) -> 
  fs.readdir(dirpath, (err, files) ->
    if (err) 
      console.error(err)
      return
  )
  files = fs.readdirSync(dirpath)
  # extract extension file
  files = files.filter((file) ->
    fs.statSync("#{dirpath}/#{file}").isFile() and ///#{ext}$///.test(dirpath+'/'+file)
  )
  # add dir path
  files = files.map((file) -> 
    require("#{dirpath}/#{file}")
  )

class PixelImage
  constructor: (@pixels, @width, @height) ->
  
  getPixel: (x, y)->
    offset = x * 4 + y * 4 * @width
    @pixels[offset] << 16 | @pixels[offset + 1] << 8 | @pixels[offset + 2]
  
  getSubPixels: (x, y, width, height)->
    @getPixel x + x2, y + y2 for x2 in [0..(width - 1)] for y2 in [0..(height - 1)]

createSvg = (paths, setting)->
  svg = builder.create 'svg', {encoding: 'UTF-8', standalone: true}
  svg.att(
    version: '1.1',
    xmlns  : 'http://www.w3.org/2000/svg', 
    width  : "#{font_width}", height: "#{font_height}", 
    viewBox: "0 0 #{font_width} #{font_height}"
  )
  font = svg
    .ele('def')
      .ele 'font', {id: setting.name, 'horiz-adv-x': "#{font_width}"}
  font.ele 'font-face', {
    'units-per-em': "#{font_height}", 'ascent':"#{font_height}", 'descent': '0',
    'bbox':"0 0 #{font_width} #{font_height}"
  }
  font.ele 'missing-glyph', {'horiz-adv-x': "#{font_width}"}
  font.ele 'glyph', {'unicode': '&#x20;', 'd':'', 'horiz-adv-x': "#{font_width / 2}"}
  for code, path of paths
    font.ele 'glyph', {
      'unicode': "&#x#{code.charCodeAt(0).toString(16)};",
      'd':path
    }
  svg.end(pretty: true, indent: '  ', newline: '\n').replace(/&amp;/g, '&')

pixelsToPath = (pixels, setting)->
  # 重複するパスを取り除きながらパスのリストをつくる
  paths = {}
  for y in [0..(pixels.length - 1)]
    for x in [0..(pixels[y].length - 1)]
      if pixels[y][x] == 0
        if paths["#{x+1},#{y}L"]?
          delete paths["#{x+1},#{y}L"]
        else
          paths["#{x},#{y}R"] = {x:x, y:y, path:"R", used:false}
        
        if paths["#{x+1},#{y+1}D"]?
          delete paths["#{x+1},#{y+1}D"]
        else
          paths["#{x+1},#{y}U"] = {x:x+1, y:y, path:"U", used:false}
        
        if paths["#{x},#{y+1}R"]
          delete paths["#{x},#{y+1}R"]
        else
          paths["#{x+1},#{y+1}L"] = {x:x+1, y:y+1, path:"L", used:false}
        
        if paths["#{x},#{y}U"]
          delete paths["#{x},#{y}U"]
        else
          paths["#{x},#{y+1}D"] = {x:x, y:y+1, path:"D", used:false}
  
  # unusedなパスを順番にたどり、パス文字列を作る
  pathStr = []
  for _, path of paths
    if !path.used
      current = path
      x = path.x
      y = path.y
      pathStr.push "M#{path.x * font_width / pixel_width} #{(pixel_height-path.y) * font_height / pixel_height}"
      
      while !current.used
        current.used = true
        pathStr.push current.path
        switch current.path
          when 'U'
            y++
            current = paths["#{x},#{y}U"]||paths["#{x},#{y}R"]||paths["#{x},#{y}D"]||paths["#{x},#{y}L"]
          when 'D'
            y--
            current = paths["#{x},#{y}D"]||paths["#{x},#{y}L"]||paths["#{x},#{y}U"]||paths["#{x},#{y}R"]
          when 'R'
            x++
            current = paths["#{x},#{y}R"]||paths["#{x},#{y}D"]||paths["#{x},#{y}L"]||paths["#{x},#{y}U"]
          when 'L'
            x--
            current = paths["#{x},#{y}L"]||paths["#{x},#{y}U"]||paths["#{x},#{y}R"]||paths["#{x},#{y}D"]

  # 連続する同じ方向のパスの簡略化を行う
  pathStr
    .join('')
    .replace(/R+/g, (match)-> "h#{match.length * font_width / pixel_width}")
    .replace(/L+/g, (match)-> "h-#{match.length * font_width / pixel_width}")
    .replace(/U+/g, (match)-> "v-#{match.length * font_height / pixel_height}")
    .replace(/D+/g, (match)-> "v#{match.length * font_height / pixel_height}")
    .replace(/[vh]-?\d+$/, 'z')

IsFullWidth = (char, map) ->
  if !map.length # target null
    result = false
  else
    result = map.includes(char); # half:false, full: true

SetFontSetting = (width=null, height=null) ->
  if width != null
    font_width = width * 100
    pixel_width = width
  if height != null
    font_height = height * 100
    pixel_height = height

ConvertImg2Svg = (setting, imgpath=imgPath, svgpath=outputPath) ->
  getPixels( "#{imgpath}/#{setting.img}", (err, pixels)->
    throw "Bad image path" if err
    
    img = new PixelImage( pixels.data, pixels.shape[0], pixels.shape[1] )
    ja_map = setting.ja_map.flat()
    
    paths = {}
    for y in [0..(setting.map.length - 1)]
      for x in [0..(setting.map[y].length - 1)]
        # full-width
        if IsFullWidth(setting.map[y][x], ja_map)
          SetFontSetting(setting.ja_width, setting.ja_height)
          paths[setting.map[y].charAt(x)] = pixelsToPath( 
            img.getSubPixels( x * setting.ja_width, y * setting.ja_height, setting.ja_width, setting.ja_height ), 
            setting
          )
        # half-width
        else
          SetFontSetting(setting.width, setting.height)
          paths[setting.map[y].charAt(x)] = pixelsToPath( 
            img.getSubPixels( x * setting.width, y * setting.height, setting.width, setting.height ), 
            setting
          )
    
    SetFontSetting(setting.width, setting.height)
    fs.writeFileSync( 
      "#{svgpath}/#{setting.name}.svg", createSvg( paths, setting )
    )
  )

main = ->
  settingList = loadFiles(imgPath, searchExt)
  
  for setting in settingList
    ConvertImg2Svg(setting)
  
  console.log 'Convert done ...'

main()
