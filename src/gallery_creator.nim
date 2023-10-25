# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import os
import std/parseopt
import std/strformat
import system
import std/logging
import std/strutils
import sugar
import html_gen

const NimblePkgVersion {.strdefine.} = ""

var outputDirectory: string = "output"
var title: string = "Image gallery"
var imageOutput: string = ""
var input: seq[string]
var allowedExtensions: seq[string] = @["jpg", "jpeg", "png", "webp"]
var generatePageOnly = false

let help = &"""
gallery_creator ({NimblePkgVersion})

Usage: gallery_creator [options] [input...]
  Input can be a folder or multiple files

Options:
  -h, --help                              Display this message
  -e=[ext,...], --extensions=[ext,...]    Allowed extensions
  -o, --output                            Output directory
  -p, --page-only                         Skip image optimization and output only html page
  -t, --title                             Gallery title
"""

when defined(release):
  setLogFilter(lvlInfo)

proc validateOptions(options: string) = 
  var parser = initOptParser(options, shortNoVal = {'p'}, longNoVal = @["page-only"])
  for kind, key, value in parser.getopt():
    debug(&"[{kind}] {key}: {value}")
    case kind 
    of cmdEnd: doAssert(false)
    of cmdArgument:
      input.add(key)
    of cmdShortOption, cmdLongOption:
      case key
      of "help", "h":
        echo help
        system.quit(0)
      of "extensions", "e":
        allowedExtensions = value.split(",")
        info(&"Overriding default allowed extensions! Allowed: {allowedExtensions}")
      of "output", "o":
        outputDirectory = normalizePathEnd(value.strip())
      of "page-only", "p":
        generatePageOnly = true
      of "title", "t":
        title = value.strip()
      else:
        echo help
        error(&"Unrecognized option: {key}")
        system.quit(1)
  if input.len() == 0:
    echo help
    error("You need to specify at least one file/folder!")
    system.quit(1)

proc main() =
  var consoleLogger = newConsoleLogger(fmtStr="[$levelname]: ")
  addHandler(consoleLogger)

  let options = os.commandLineParams()
  validateOptions(os.quoteShellCommand(options))

  if input.len() == 1:
    let rootDir = absolutePath(input[0])
    let isDir = dirExists(rootDir)
    if isDir:
      let files = collect:
        for file in walkDirRec(rootDir, relative = false):
          let fileTuple = splitFile(file)
          let extension = fileTuple.ext.strip(true, false, {'.'}).toLower()
          if allowedExtensions.contains(extension):
            absolutePath(file)
      debug(files.join(", "))
      createDir(outputDirectory)
      imageOutput = outputDirectory & "/img"
      createDir(imageOutput)
      writeFile(outputDirectory & "/index.html", generatePage(files, title, imageOutput, generatePageOnly, outputDirectory))

    else:
      error(&"{input[0]} is not a directory or doesn't exist")
  else:
    error("List of file unsupported")

when isMainModule:
  main()