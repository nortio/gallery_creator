import htmlgen
import os
import osproc
import std/strformat
import std/logging 
import std/json
import std/sequtils
import std/times
import std/algorithm
import std/times

const internalStyle = """
body {
  margin: auto;
  padding: 0px;
  font-family: sans-serif;
  max-width: 768px;
}
body > * {
  margin: 10px 10px
}
img {
  width: 100%;
  padding: 0px;
  margin: 0px;
}
.comment {
  color: gray;
  font-size: small;
  font-style: italic;
  margin-right: auto;
}
.download {
  display: block;
}
.info {
  display: flex;
  align-items: center;
  justify-content: end;
  gap: 8px;
  flex-wrap: wrap;
}
"""

type
  Image = object
    filename: string
    comment: string
    lastmodification: Time

proc getOptimizedImageName(originalImagePath: string): string =
  let imageTuple = splitFile(originalImagePath)
  let imageName = imageTuple.name & ".webp"
  return imageName

proc optimizeImage(originalImagePath: string, outputDirectory: string) =
  let imageName = getOptimizedImageName(originalImagePath)
  let imageOutPath = outputDirectory & "/" & imageName
  # convert 1.JPG -quality 50 -strip 1-converted-webp.webp
  # per jpeg -quality 70 (cli uguale)
  let command = &"convert \"{originalImagePath}\" -quality 50 -strip \"{imageOutPath}\""
  var res = execCmd(command)
  debug(&"Command: {command} | Return: {res}")

proc getList(outputFolder: string): seq[Image] =
  let jsonFile = normalizePathEnd(outputFolder & "/" & "list.json")
  try:
    let contents = readFile(jsonFile)
    debug(&"Parsing existing json: {jsonFile}")
    let jsonNode = parseJson(contents)
    let list = jsonNode.to(seq[Image])
    return list
  except IOError:
    return @[]
  except JsonParsingError:
    var err = getCurrentExceptionMsg()
    error(err)
    raise

proc comparison(x, y: Image): int = 
  cmp(x.lastmodification, y.lastmodification)

#[
  Generate html page with a list of image paths (these need to be absolute)
]#
proc generatePage*(images: seq[string], title: string, imgOutput: string, generatePageOnly: bool, outputFolder: string): string =
  var imageList: string
  if generatePageOnly:
    info("Skipping image optimization...")
  
  var list = getList(outputFolder)

  for index, image in images:
    let imageName = getOptimizedImageName(image)

    if not generatePageOnly:
      let imageOutPath = imgOutput & "/" & imageName
      if not fileExists(imageOutPath):
        optimizeImage(image, imgOutput)
      stdout.write &"[GENERATING] Processed {index} images out of {images.len()}\r"
      stdout.flushFile()

    let found = list.filter(proc(x: Image): bool = x.filename == imageName)
    if found.len() == 0:
      let mTime = image.getLastModificationTime()

      let im = Image(
        filename: imageName,
        comment: "",
        lastmodification: mTime
      )
      list.add(im)

  let listFile = normalizePathEnd(outputFolder & "/" & "list.json")
  list.sort(comparison)
  writeFile(listFile, $(%*list))

  for image in list:
    let filename = "img/" & image.filename
    let imageDate = image.lastmodification.format("dd-MM-YYYY hh:mm")
    var comment = ""
    if image.comment.len() > 0:
      comment = `div`(class="comment", image.comment)
    imageList.add(
      img(src=filename, alt=title, loading="lazy") &
      `div`(
        class="info",
        comment &
        `div`(
          class="info",
          time(class="comment", imageDate) &
          a(href=filename, class="download", download=image.filename, "Download")
        )
      )
    )

  var body = html(
    head(
      meta(charset="UTF-8"),
      meta(name="viewport", content="width=device-width, initial-scale=1.0"),
      title(
        title
      ),
      style(
        internalStyle
      )
    ),
    body(
      h1(title),
      imageList
    )
  )

  return body


