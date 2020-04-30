Red []

; 1. ugly white space processing
; 2. maybe incorrect

white-space: [ any [ #" " | #"^/" ] ]

; lexical elements

; letters and digits
letter: charset [ #"A" - #"Z" #"a" - #"z" ]
; probe parse "b" [letter]
; probe parse "1" [letter]
decimal-digit: charset [ #"0" - #"9" ]
; probe parse "b" [decimal-digit]
; probe parse "3" [decimal-digit]
octal-digit: charset [ #"0" - #"7" ]
; probe parse "b" [octal-digit]
; probe parse "3" [octal-digit]
; probe parse "9" [octal-digit]
hex-digit: charset [ #"0" - #"9" #"A" - #"F" #"a" - #"f" ]
; probe parse "b" [hex-digit]
; probe parse "3" [hex-digit]
; probe parse "g" [hex-digit]

; identifiers
ident: [ letter any [ letter | decimal-digit | #"_" ] ]
; probe parse "a" ident
; probe parse "a_b" ident
; probe parse "sat1" ident
; probe parse "1a" ident
; probe parse "a!" ident
full-ident: [ ident any [ #"." ident ] ]
; probe parse "Hello" full-ident
; probe parse "com.qq.weixin.mp.Hello" full-ident
; probe parse "com.qq.weixin.mp..Hello" full-ident
; probe parse "com.qq.weixin.mp." full-ident
message-name: ident
enum-name: ident
field-name: ident
oneof-name: ident
map-name: ident
service-name: ident
rpc-name: ident
message-type: [ opt #"." any [ ident #"." ] message-name ]
; probe parse "Hello" message-type
; probe parse ".com.qq.weixin.mp.Hello" message-type
; probe parse "com.qq.weixin.mp.Hello" message-type
; probe parse "..com.qq.weixin.mp.Hello" message-type
; probe parse "com.qq.weixin.mp." message-type
enum-type: [ opt #"." any [ ident #"." ] enum-name ]

; integer literals
decimal-digit-without-zero: charset [ #"1" - #"9" ]
decimal-lit: [ decimal-digit-without-zero any decimal-digit ]
; probe parse "123" decimal-lit
; probe parse "0" decimal-lit
; probe parse "2" decimal-lit
octal-lit: [ #"0" any octal-digit ]
; probe parse "0" octal-lit
; probe parse "04" octal-lit
; probe parse "08" octal-lit
; probe parse "1" octal-lit
hex-lit: [ #"0" [ #"x" | #"X" ] some hex-digit]
; probe parse "0x1" hex-lit
; probe parse "0x" hex-lit
; probe parse "0xFF" hex-lit
; probe parse "0xg" hex-lit
int-lit: [ decimal-lit | hex-lit | octal-lit ]
; probe parse "123" int-lit
; probe parse "0" int-lit
; probe parse "2" int-lit
; probe parse "04" int-lit
; probe parse "0xFF" int-lit

; floating-point literals
decimals: [ some decimal-digit ]
exponent: [ [ #"e" | #"E" ] opt [ #"+" | #"-" ] decimals ]
float-lit: [ "inf" | "nan" | [ #"." decimals opt exponent | decimals exponent | decimals #"." opt decimals opt exponent] ]

; boolean
bool-lit: [ 'true | 'false ]

; string literals
hex-escape: [ #"\" [ #"x" | #"X" ] hex-digit hex-digit ]
oct-escape: [ #"\" octal-digit octal-digit octal-digit ]
char-escape: [ #"\" [ #"a" | #"b" | #"f" | #"n" | #"r" | #"t" | #"v" | #"\" | #"'" | #"^"" ] ]
char-value-exclusion: complement charset [ #"^@" #"^/" #"^(esc)" #"^"" ]
char-value: [ hex-escape | oct-escape | char-escape | char-value-exclusion ]
str-lit: [ #"'" any char-value #"'" | #"^"" any char-value #"^""]
; parse-trace {"other.proto"} str-lit
quote-rule: [ #"'" | #"^"" ]

empty-statement: [ #";" ]

constant: [ full-ident | [ #"-" | #"+" ] int-lit | [ #"-" | #"+" ] float-lit | str-lit | bool-lit ]

syntax: [ "syntax" white-space #"=" white-space quote-rule "proto3" quote-rule #";" ]
; input-str: {syntax = "proto3";}
; parse input-str syntax

import: [ "import" white-space opt [ "weak" | "public" ] white-space str-lit #";" ]
; parse-trace {import public "other.proto";} import

package: [ "package" white-space full-ident ";" ]
; parse-trace {package foo.bar;} package

option-name: [ [ ident | #"(" full-ident #")" ] any [ #"." ident ] ]
; parse-trace {java_package} option-name
option: [ "option" white-space option-name white-space #"=" white-space constant ";" ]
; parse-trace {option java_package = "com.example.foo";} option

; fields
type: [ "double" | "float" | "int32" | "int64" | "uint32" | "uint64"
    | "sint32" | "sint64" | "fixed32" | "fixed64" | "sfixed32" | "sfixed64"
    | "bool" | "string" | "bytes" | message-type | enum-type ]
field-number: int-lit

; normal field
field-option: [ option-name white-space #"=" constant ]
field-options: [ field-option any [ #"," field-option ] ]
field: [ opt "repeated" white-space type white-space field-name white-space #"="
    white-space field-number white-space opt [ #"[" field-options #"]" ] #";" ]
; parse-trace {foo.bar nested_message = 2;} field
; parse-trace {repeated int32 samples = 4 [packed=true];} field

; one-of field
oneof-field: [ type white-space field-name white-space #"="
    white-space field-number white-space opt [ #"[" field-options #"]" ] #";" ]
oneof: [ "oneof" white-space oneof-name white-space #"{"
    any [ white-space [ option | oneof-field | empty-statement ] white-space ] #"}" ]
; parse-trace {oneof foo {
;     string name = 4;
;     SubMessage sub_message = 9;
; }} oneof

; map field
key-type: [ "int32" | "int64" | "uint32" | "uint64" | "sint32" | "sint64" 
    | "fixed32" | "fixed64" | "sfixed32" | "sfixed64" | "bool" | "string" ]
map-field: [ "map" #"<" key-type #"," white-space type #">" white-space map-name white-space #"="
    white-space field-number white-space opt [ #"[" field-options #"]" ] #";" ]
; parse-trace {map<string, Project> projects = 3;} map-field

; reserved
range: [ int-lit white-space opt [ "to" white-space [ int-lit | "max" ] ] ]
ranges: [ range any [ #"," white-space range ] ]
field-names: [ quote-rule field-name quote-rule any [ #"," white-space quote-rule field-name quote-rule ] ]
reserved: [ "reserved" white-space [ ranges | field-names ] #";" ]
; parse-trace {reserved 2, 15, 9 to 11;} reserved
; parse-trace {reserved "foo", "bar";} reserved

; top level definitions

; enum definition
enum-value-option: [ option-name white-space #"=" white-space constant ]
enum-field: [ ident white-space #"=" white-space int-lit white-space
    opt [ #"[" enum-value-option any [ #"," white-space enum-value-option ] #"]" ] #";" ]
enum-body: [ #"{" any [ white-space [ option | enum-field | empty-statement ] ] white-space #"}" ]
enum: [ "enum" white-space enum-name white-space enum-body ]
; parse-trace {enum EnumAllowingAlias {
;   option allow_alias = true;
;   UNKNOWN = 0;
;   STARTED = 1;
;   RUNNING = 2 [(custom_option) = "hello world"];
; }} enum

; message definition
message-body: [ #"{" any [ white-space
    [ field | enum | message | option | oneof | map-field | reserved | empty-statement ] ]
    white-space #"}" ]
message: [ "message" white-space message-name white-space message-body ]
; parse-trace {message Outer {
;   option (my_option).a = true;
;   message Inner {
;     int64 ival = 1;
;   }
;   map<int32, string> my_map = 2;
; }} message

; service definition
rpc: [ "rpc" white-space rpc-name white-space
    #"(" white-space opt [ "stream" white-space ] message-type white-space #")" white-space
    "returns" white-space #"(" white-space opt [ "stream" white-space ] message-type white-space #")" white-space
    [ #"{" any [ white-space [ option | empty-statement ] white-space ] #"}" | #";" ] ]
service: [ "service" white-space service-name white-space #"{"
    any [ white-space [ option | rpc | empty-statement ] white-space] #"}" ]
; parse-trace {service SearchService {
;   rpc Search (SearchRequest) returns (SearchResponse);
; }} service

top-level-def: [ message | enum | service ]

proto: [
    syntax white-space
    [ any [ white-space [ import | package | option | top-level-def ] white-space ] ]
]

file: %kv.proto
input-lines: ""
foreach [line] read/lines file [
    either none? find line "//" [
        append input-lines line
    ] [
        append input-lines copy/part line find line "//"
    ]
    append input-lines newline
]
parse input-lines proto