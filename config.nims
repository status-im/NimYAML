mode = ScriptMode.Verbose

proc test(args, path: string) =
  if not dirExists "build":
    mkDir "build"
  exec "nim " & getEnv("TEST_LANG", "c") & " " & getEnv("NIMFLAGS") & " " & args &
    " --outdir:build --verbosity:0 --hints:off --skipParentCfg " & path

task build, "Compile the YAML module into a library":
  test "--app:lib -d:release", "yaml.nim"

task test, "Run all tests":
  test "-r", "test/tests.nim"

task lexerTests, "Run lexer tests":
  test "-r", "test/tlex.nim"

task parserTests, "Run parser tests":
  test "-r", "test/tparser.nim"

task jsonTests, "Run JSON tests":
  test "-r", "test/tjson.nim"

task domTests, "Run DOM tests":
  test "-r", "test/tdom.nim"

task serializationTests, "Run serialization tests":
  test "-r", "test/tserialization.nim"

task quickstartTests, "Run quickstart tests":
  test "-r", "test/tquickstart.nim"

task documentation, "Generate documentation":
  exec "mkdir -p docout"
  withDir "doc":
    exec r"nim c rstPreproc"
    exec r"./rstPreproc -o:tmp.rst index.txt"
    exec r"nim rst2html -o:../docout/index.html tmp.rst"
    exec r"./rstPreproc -o:tmp.rst api.txt"
    exec r"nim rst2html -o:../docout/api.html tmp.rst"
    exec r"./rstPreproc -o:tmp.rst serialization.txt"
    exec r"nim rst2html -o:../docout/serialization.html tmp.rst"
    exec r"nim rst2html -o:../docout/testing.html testing.rst"
    exec r"nim rst2html -o:../docout/schema.html schema.rst"
    exec "cp docutils.css style.css processing.svg ../docout"
  exec r"nim doc2 -o:docout/yaml.html --docSeeSrcUrl:https://github.com/flyx/NimYAML/blob/`git log -n 1 --format=%H` yaml"
  for file in listFiles("yaml"):
    let packageName = file[5..^5]
    exec r"nim doc2 -o:docout/yaml." & packageName &
        ".html --docSeeSrcUrl:https://github.com/flyx/NimYAML/blob/yaml/`git log -n 1 --format=%H` " &
        file

task bench, "Benchmarking":
  test "-r -d:release", "bench/bench.nim"

task clean, "Remove all generated files":
  exec "rm -rf build docout"

task server, "Compile server daemon":
  test "-d:release -d:yamlScalarRepInd", "server/server.nim"

task testSuiteEvents, "Compile the testSuiteEvents tool":
  test "-d:release", "tools/testSuiteEvents.nim"
