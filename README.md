# NimYAML - YAML implementation for Nim

NimYAML is a YAML implementation in Nim. It aims to implement the complete
YAML 1.2 specification and has a streaming interface that makes it possible to
parse YAML input sequentially, without loading all data into memory at once. It
is able to automatically serialize Nim object to YAML and deserialize them
again.

**Attention**: NimYAML is work in progress. There is no release yet, and some
features are highly experimental.

## Quickstart

### Using the sequential parser

```Nimrod
import yaml

let input = """
an integer: 42
a boolean: yes
a list:
 - 3.14159
 - !!str 23
 - null
"""

var
  parser = newYamlParser(initCoreTagLibrary())
  events = parser.parse(newStringStream(input))

for event in events():
  echo $event
```

Output:

```
yamlStartDocument()
yamlStartMap(tag=?)
yamlScalar(tag=?, typeHint=yTypeUnknown, content="an integer")
yamlScalar(tag=?, typeHint=yTypeInteger, content="42")
yamlScalar(tag=?, typeHint=yTypeUnknown, content="a boolean")
yamlScalar(tag=?, typeHint=yTypeBoolTrue, content="yes")
yamlScalar(tag=?, typeHint=yTypeUnknown, content="a list")
yamlStartSequence(tag=?)
yamlScalar(tag=?, typeHint=yTypeFloat, content="3.14159")
yamlScalar(tag=!!str, typeHint=yTypeInteger, content="23")
yamlScalar(tag=?, typeHint=yTypeNull, content="null")
yamlEndSequence()
yamlEndMap()
yamlEndDocument()
```

### Dumping YAML

```Nimrod
import yaml, streams

proc example(): YamlStream =
  result = iterator(): YamlStreamEvent =
    yield startDocEvent()
    yield startMapEvent()
    yield scalarEvent("an integer")
    yield scalarEvent("42", tag = yTagInteger)
    yield scalarEvent("a list")
    yield startSeqEvent(tag = yTagSequence)
    yield scalarEvent("item", tag = yTagString)
    yield scalarEvent("no", tag = yTagBoolean)
    yield scalarEvent("")
    yield endSeqEvent()
    yield scalarEvent("a float")
    yield scalarEvent("3.14159", tag = yTagFloat)
    yield endMapEvent()
    yield endDocEvent()

present(example(), newFileStream(stdout), initCoreTagLibrary(), psBlockOnly)
echo "\n\n"
present(example(), newFileStream(stdout), initCoreTagLibrary(), psCanonical)
echo "\n\n"
present(example(), newFileStream(stdout), initCoreTagLibrary(), psJson)
```

Output:

```
%YAML 1.2
---
an integer: !!int 42
a list: !!seq
  - !!str item
  - !!bool no
  - ""
a float: !!float 3.14159


%YAML 1.2
---
{
  ? "an integer"
  : !!int "42",
  ? "a list"
  : !!seq [
    !!str "item",
    !!bool "no",
    ""
  ],
  ? "a float"
  : !!float "3.14159"
}


{
  "an integer": 42,
  "a list": [
    "item",
    false,
    ""
  ],
  "a float": 3.14159
}
```

### Using Nim Type Serialization

**Attention**: This feature is highly experimental!

```Nimrod
import yaml.serialization
import tables

serializable:
    type
        Person = object
            firstname, surname: string
            age: int32
            additionalAttributes: Table[string, string]

# loading

let input = """
-
  firstname: Peter
  surname: Pan
  age: 12
  additionalAttributes:
    canFly: yes
    location: Neverland
-
  firstname: Karl
  surname: Koch
  age: 23
  additionalAttributes:
    location: Celle
    occupation: Hacker
"""

var persons: seq[Person]
load(newStringStream(input), persons)
assert persons[0].surname == "Pan"
assert persons[1].additionalAttributes["location"] == "Celle"

# dumping

dump(persons, newFileStream(stdout), psCanonical)
```

Output:

```
%YAML 1.2
--- !nim:seq(nim:Person)
[
  !nim:Person {
    ? !!str "firstname"
    : !!str "Peter",
    ? !!str "surname"
    : !!str "Pan",
    ? !!str "age"
    : !nim:int "12",
    ? !!str "additionalAttributes"
    : !nim:Table(tag:yaml.org,2002:str,tag:yaml.org,2002:str) {
      ? !!str "canFly"
      : !!str "yes",
      ? !!str "location"
      : !!str "Neverland"
    }
  },
  !nim:Person {
    ? !!str "firstname"
    : !!str "Karl",
    ? !!str "surname"
    : !!str "Koch",
    ? !!str "age"
    : !nim:int "23",
    ? !!str "additionalAttributes"
    : !nim:Table(tag:yaml.org,2002:str,tag:yaml.org,2002:str) {
      ? !!str "occupation"
      : !!str "Hacker",
      ? !!str "location"
      : !!str "Celle"
    }
  }
]
```

## TODO list

 * Documentation:
   - Document yaml.serialization
 * Misc:
   - Add type hints for more scalar types
 * Serialization:
   - Support for more standard library types
   - Support polymorphism
   - Support variant objects
   - Support transient fields (i.e. fields that will not be (de-)serialized on
     objects and tuples)
   - Make it possible for user to define a tag URI for custom types
   - Use `concept` type class `Serializable` or something
   - Check for and avoid name clashes when generating local tags for custom
     object types.
   - Possibly use `genSym` for predefined and generated `yamlTag` procs because
     they are an implementation detail and should not be visible to the caller.
     same goes for `lazyLoadTag` and `safeLoadUri`.

## License

[MIT](copying.txt)