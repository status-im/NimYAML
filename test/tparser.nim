#            NimYAML - YAML implementation in Nim
#        (c) Copyright 2016 Felix Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.

import os, terminal, strutils, streams, macros, unittest, sets, osproc
import testEventParser, commonTestUtils
import ../yaml, ../yaml/data

const
  testSuiteFolder = "yaml-test-suite-copy"

proc echoError(msg: string) =
  styledWriteLine(stdout, fgRed, "[error] ", fgWhite, msg, resetStyle)


proc parserTest(path: string, errorExpected : bool): bool =
  var
    tagLib = initExtendedTagLibrary()
    parser: YamlParser
  parser.init(tagLib)
  # We can't open these files in Mingw, even after converting the paths with
  # `cygpath -w ...`.
  var
    actual = parser.parse(execCmdEx("cat " & path & "/in.yaml")[0])
    expectedIn = newStringStream(execCmdEx("cat " & path & "/test.event")[0])
    expected = parseEventStream(expectedIn, tagLib)
  defer:
    expectedIn.close()
  var i = 1
  try:
    while true:
      let actualEvent = actual.next()
      let expectedEvent = expected.next()
      if expectedEvent != actualEvent:
        result = errorExpected
        if not result:
          echoError("At event #" & $i &
                    ": Actual events do not match expected events")
          echo ".. expected event:"
          echo "  ", expectedEvent
          echo ".. actual event:"
          echo "  ", actualEvent
          echo ".. difference:"
          stdout.write("  ")
          printDifference(expectedEvent, actualEvent)

        return
      i.inc()
      if actualEvent.kind == yamlEndStream:
        break
    result = not errorExpected
    if not result:
      echo "Expected error, but parsed without error."
  except:
    result = errorExpected
    if not result:
      echoError("Caught an exception at event #" & $i &
                " test was not successful")
      let e = getCurrentException()
      if e.parent of YamlParserError:
        let pe = (ref YamlParserError)(e.parent)
        echo "line ", pe.mark.line, ", column ", pe.mark.column, ": ", pe.msg
        echo pe.lineContent
      else: echo e.msg

macro genTests(): untyped =
  let
    pwd = staticExec("pwd").strip
    absolutePath = '"' & (pwd / testSuiteFolder).replace('\\', '/') & '"'
  echo "[tparser] Generating tests from " & absolutePath

  let errorTests = toHashSet(staticExec("cd " & (absolutePath & "/tags/error") &
                         " && ls -1d *").splitLines())
  var ignored = toHashSet([".git", "name", "tags", "meta"])

  result = newStmtList()
  # walkDir for some crude reason does not work with travis build
  let dirItems = staticExec("ls -1d " & absolutePath &  "/*")
  for dirPath in dirItems.replace('\\', '/').splitLines():
    if dirPath.strip.len == 0: continue
    let testId = dirPath[^4..^1]
    if ignored.contains(testId): continue
    let title = staticExec("cat " & dirPath & "/===").strip

    result.add(newCall("test",
        newLit(strip(title) & " [" &
        testId & ']'), newCall("doAssert", newCall("parserTest",
        newLit(dirPath), newLit(errorTests.contains(testId))))))
  result = newCall("suite", newLit("Parser Tests (from " & testSuiteFolder & ")"), result)

genTests()
