import "../yaml/serialization"
import unittest

make_serializable:
    type
        Person = object
            firstname, surname: string
            age: int

suite "Serialization":
    setup:
        var parser = newParser(coreTagLibrary())

    test "Load string sequence":
        let input = newStringStream(" - a\n - b")
        var
            result: seq[string]
            events = parser.parse(input)
        assert events().kind == yamlStartDocument
        construct(events, result)
        assert events().kind == yamlEndDocument
        assert result.len == 2
        assert result[0] == "a"
        assert result[1] == "b"
    
    test "Load Table[int, string]":
        let input = newStringStream("23: dreiundzwanzig\n42: zweiundvierzig")
        var
            result: Table[int, string]
            events = parser.parse(input)
        assert events().kind == yamlStartDocument
        construct(events, result)
        assert events().kind == yamlEndDocument
        assert result.len == 2
        assert result[23] == "dreiundzwanzig"
        assert result[42] == "zweiundvierzig"
    
    test "Load Sequences in Sequence":
        let input = newStringStream(" - [1, 2, 3]\n - [4, 5]\n - [6]")
        var
            result: seq[seq[int]]
            events = parser.parse(input)
        assert events().kind == yamlStartDocument
        construct(events, result)
        assert events().kind == yamlEndDocument
        assert result.len == 3
        assert result[0] == @[1, 2, 3]
        assert result[1] == @[4, 5]
        assert result[2] == @[6]
    
    test "Load custom object":
        let input = newStringStream("firstname: Peter\nsurname: Pan\nage: 12")
        var
            result: Person
            events = parser.parse(input)
        assert events().kind == yamlStartDocument
        construct(events, result)
        assert events().kind == yamlEndDocument
        assert result.firstname == "Peter"
        assert result.surname   == "Pan"
        assert result.age == 12