$script:scriptPath = $MyInvocation.MyCommand.Definition

function script:Test.Tokenize-Basic()
{
    $a = Tokenize-Basic "foo"
    Assert-ArrayEqual f,o,o ($a|%{$_.Value}) 
    Assert-ArrayEqual character,character,character ($a|%{$_.Kind})

    $a = Tokenize-Basic "f`n "
    Assert-ArrayEqual character,newline,whitespace ($a|%{$_.Kind})
}

function script:Test.Tokenize-Text()
{
    $a = Tokenize-Text "foo bar" 
    Assert-ArrayEqual "foo"," ","bar" ($a | %{ $_.Value} ) "Simple"
    Assert-ArrayEqual word,whitespace,word ($a | % { $_.Kind}) "Simple"

    $a = Tokenize-Text 'foo,bar'
    Assert-ArrayEqual 'foo',',','bar' ($a|%{$_.Value}) "Quoted String"
    Assert-ArrayEqual word,character,word ($a|%{$_.Kind}) "Quoted String"

    $a = Tokenize-Text '"foo'| % { $_.Value }
    Assert-ArrayEqual '"',"foo" $a "Missing trailing quote"

    $a = Tokenize-Text "1 222" 
    Assert-ArrayEqual "1"," ","222" ($a | %{ $_.Value} ) "Simple"
    Assert-ArrayEqual number,whitespace,number ($a | % { $_.Kind}) "Simple"
}

function script:Test.ConvertTo-QuotedString()
{
    $a = Tokenize-Text '"foo",bar' | ConvertTo-QuotedString
    Assert-ArrayEqual '"foo"',',','bar' ($a|%{$_.Value}) "Quoted String"
    Assert-ArrayEqual quotedstring,character,word ($a|%{$_.Kind}) "Quoted String"

    $a = Tokenize-Text '"foo'| ConvertTo-QuotedString | % { $_.Value }
    Assert-ArrayEqual '"',"foo" $a "Missing trailing quote"
}

function script:Test.Tokenize-CppText()
{
    $a = Tokenize-CppText '"foo",bar' 
    Assert-ArrayEqual '"foo"',',','bar' ($a|%{$_.Value}) "Cpp Quoted String"
    Assert-ArrayEqual quotedstring,character,word ($a|%{$_.Kind}) "Cpp Quoted String"

    $a = Tokenize-CppText "foo /* bar */"
    Assert-ArrayEqual "foo"," ","/* bar */" ($a|%{$_.Value}) "BlockComment"
    Assert-ArrayEqual word,whitespace,blockcomment ($a|%{$_.Kind}) "BlockComment"

    $a = Tokenize-CppText "foo /* bar **/"
    Assert-ArrayEqual "foo"," ","/* bar **/" ($a|%{$_.Value}) "BlockComment"
    Assert-ArrayEqual word,whitespace,blockcomment ($a|%{$_.Kind}) "BlockComment"

    $a = Tokenize-CppText "// bar`nfoo"
    Assert-ArrayEqual "// bar`n","foo" ($a|%{$_.Value}) "LineComment"
    Assert-ArrayEqual LineComment,word ($a|%{$_.Kind}) "LineComment"
}

. script "unit" 
. script "token"

Test.Tokenize-Basic
Test.Tokenize-Text
Test.ConvertTo-QuotedString
Test.Tokenize-CppText
