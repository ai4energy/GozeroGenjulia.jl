lexer grammar ApiLexer;

// Keywords
ATDOC:              '@doc';
ATHANDLER:          '@handler';
INTERFACE:          'interface{}';
ATSERVER:           '@server';

// Whitespace and comments
WS:                 [ \t\r\n\u000C]+ -> channel(HIDDEN);
COMMENT:            '/*' .*? '*/' -> channel(88);
LINE_COMMENT:       '//' ~[\r\n]* -> channel(88);
STRING:             '"' (~["\\] | EscapeSequence)* '"';
RAW_STRING:         '`' (~[`\\\r\n] | EscapeSequence)+ '`';
LINE_VALUE:         ':' [ \t]* (STRING|(~[\r\n"`]*));
ID:         Letter LetterOrDigit*;


LetterOrDigit
    : Letter
    | [0-9]
    ;
fragment ExponentPart
    : [eE] [+-]? Digits
    ;

fragment EscapeSequence
    : '\\' [btnfr"'\\]
    | '\\' ([0-3]? [0-7])? [0-7]
    | '\\' 'u'+ HexDigit HexDigit HexDigit HexDigit
    ;
fragment HexDigits
    : HexDigit ((HexDigit | '_')* HexDigit)?
    ;
fragment HexDigit
    : [0-9a-fA-F]
    ;
fragment Digits
    : [0-9] ([0-9_]* [0-9])?
    ;

fragment Letter
    : [a-zA-Z$_] // these are the "java letters" below 0x7F
    | ~[\u0000-\u007F\uD800-\uDBFF] // covers all characters above 0x7F which are not a surrogate
    | [\uD800-\uDBFF] [\uDC00-\uDFFF] // covers UTF-16 surrogate pairs encodings for U+10000 to U+10FFFF
    ;

grammar ApiParser;

import ApiLexer;

@lexer::members{
    const COMEMNTS = 88
}

api:            spec*;
spec:           syntaxLit
                |importSpec
                |infoSpec
                |typeSpec
                |serviceSpec
                ;

// syntax
syntaxLit:      {match(p,"syntax")}syntaxToken=ID assign='=' {checkVersion(p)}version=STRING;

// import
importSpec:     importLit|importBlock;
importLit:      {match(p,"import")}importToken=ID importValue ;
importBlock:    {match(p,"import")}importToken=ID '(' importBlockValue+ ')';
importBlockValue:   importValue;
importValue:    {checkImportValue(p)}STRING;

// info
infoSpec:       {match(p,"info")}infoToken=ID lp='(' kvLit+ rp=')';

// type
typeSpec:       typeLit
                |typeBlock;

// eg: type Foo int
typeLit:        {match(p,"type")}typeToken=ID  typeLitBody;
// eg: type (...)
typeBlock:      {match(p,"type")}typeToken=ID lp='(' typeBlockBody* rp=')';
typeLitBody:    typeStruct|typeAlias;
typeBlockBody:  typeBlockStruct|typeBlockAlias;
typeStruct:     {checkKeyword(p)}structName=ID structToken=ID? lbrace='{'  field* rbrace='}';
typeAlias:      {checkKeyword(p)}alias=ID assign='='? dataType;
typeBlockStruct: {checkKeyword(p)}structName=ID structToken=ID? lbrace='{'  field* rbrace='}';
typeBlockAlias: {checkKeyword(p)}alias=ID assign='='? dataType;
field:          {isNormal(p)}? normalField|anonymousFiled ;
normalField:    {checkKeyword(p)}fieldName=ID dataType tag=RAW_STRING?;
anonymousFiled: star='*'? ID;
dataType:       {isInterface(p)}ID
                |mapType
                |arrayType
                |inter='interface{}'
                |time='time.Time'
                |pointerType
                |typeStruct
                ;
pointerType:    star='*' {checkKeyword(p)}ID;
mapType:        {match(p,"map")}mapToken=ID lbrack='[' {checkKey(p)}key=ID rbrack=']' value=dataType;
arrayType:      lbrack='[' rbrack=']' dataType;

// service
serviceSpec:    atServer? serviceApi;
atServer:       ATSERVER lp='(' kvLit+ rp=')';
serviceApi:     {match(p,"service")}serviceToken=ID serviceName lbrace='{' serviceRoute* rbrace='}';
serviceRoute:   atDoc? (atServer|atHandler) route;
atDoc:          ATDOC lp='('? ((kvLit+)|STRING) rp=')'?;
atHandler:      ATHANDLER ID;
route:          {checkHTTPMethod(p)}httpMethod=ID path request=body? response=replybody?;
body:           lp='(' (ID)? rp=')';
replybody:      returnToken='returns' lp='(' dataType? rp=')';
// kv
kvLit:          key=ID {checkKeyValue(p)}value=LINE_VALUE;

serviceName:    (ID '-'?)+;
path:           (('/' (pathItem ('-' pathItem)*))|('/:' (pathItem ('-' pathItem)?)))+ | '/';
pathItem:       (ID|LetterOrDigit)+;