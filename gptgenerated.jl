module GozeroGenjl

using Lerche

struct ApiSyntax
    version::String
end

gozero_grammar = raw"""
    gozeroapi: spec*

    production_name: /[A-Za-z_][A-Za-z0-9_]*/
    token: /\"[^\"]*\"/ | /\'[^\']*\'/
    
    spec: syntax_stmt | info_stmt | import_stmt | type_stmt | service_stmt

    syntax_stmt: "syntax" "=" interpreted_string_lit
    info_stmt: "info" "(" info_key_value_expr* ")"
    import_stmt: import_literal_stmt | import_group_stmt
    type_stmt: type_literal_stmt | type_group_stmt
    service_stmt: service_decl

    interpreted_string_lit: STRING
    raw_string_lit: /`[^`]*`/
    identifier: /[A-Za-z_][A-Za-z0-9_]*/

    info_key_value_expr: info_key_lit interpreted_string_lit
    info_key_lit: identifier ":"

    import_literal_stmt: "import" interpreted_string_lit
    import_group_stmt: "import" "(" interpreted_string_lit* ")"

    type_literal_stmt: "type" type_expr
    type_group_stmt: "type" "(" type_expr* ")"
    type_expr: identifier "="? data_type

    data_type: any_data_type | array_data_type | base_data_type | interface_data_type | map_data_type | pointer_data_type | slice_data_type | struct_data_type
    any_data_type: "any"
    array_data_type: "[" decimal_digit? "]" data_type
    base_data_type: "bool" | "uint8" | "uint16" | "uint32" | "uint64" | "int8" | "int16" | "int32" | "int64" | "float32" | "float64" | "complex64" | "complex128" | "string" | "int" | "uint" | "uintptr" | "byte" | "rune" | "any"
    interface_data_type: "interface{}"
    map_data_type: "map" "[" data_type "]" data_type
    pointer_data_type: "*" data_type
    slice_data_type: "[]" data_type
    struct_data_type: "{" elem_expr* "}"

    elem_expr: elem_name_expr? data_type tag?
    elem_name_expr: identifier ("," identifier)*
    tag: raw_string_lit

    service_decl: at_server_stmt? "service" service_name_expr "(" service_item_stmt* ")"
    service_name_expr: identifier ("-api")?
    at_server_stmt: "@server" "(" at_server_kv_expr* ")"
    at_server_kv_expr: at_server_key_lit at_server_value_lit?
    at_server_key_lit: identifier ":"
    at_server_value_lit: path_lit | identifier ("," identifier)*
    path_lit: /\"\/[^\"]*\"/
    service_item_stmt: at_doc_stmt? at_handler_stmt route_stmt

    at_doc_stmt: at_doc_literal_stmt | at_doc_group_stmt
    at_doc_literal_stmt: "@doc" interpreted_string_lit
    at_doc_group_stmt: "@doc" "(" at_doc_kv_expr* ")"
    at_doc_kv_expr: at_server_key_lit interpreted_string_lit

    at_handler_stmt: "@handler" identifier
    route_stmt: method path_expr body_stmt? ("returns" body_stmt)?
    method: "get" | "head" | "post" | "put" | "patch" | "delete" | "connect" | "options" | "trace"
    path_expr: "/" identifier ( "-" identifier | ":" identifier)*
    body_stmt: "(" identifier ")"

    decimal_digit: /[0-9]/

    WHITESPACE: /[ \t\r\n\f]+/
    COMMENT: /\/\*.*?\*\//
    LINE_COMMENT: /\/\/[^\n]*\n?/
    STRING: /"([^"\\]*(\\.[^"\\]*)*)"/

    %ignore WHITESPACE
    %ignore COMMENT
    %ignore LINE_COMMENT
"""

struct TreeToAPISPEC <: Transformer end

@rule gozeroapi(t::TreeToAPISPEC, tree) = tree[1]
@rule syntax_stmt(t::TreeToAPISPEC, tree) = ApiSyntax(tree[1][2:end-1])
@rule info_stmt(t::TreeToAPISPEC, tree) = tree[1]

gozero_parser = Lark(gozero_grammar, parser="lalr", start="gozeroapi", lexer="standard", transformer=TreeToAPISPEC())
gozero_parser = Lark(gozero_grammar, parser="lalr", start="gozeroapi", lexer="standard")

# 测试 API 描述
api_description = raw"""syntax = "v1"
/* 这是一个注释 */
info (abc: "my"
desc: "演示如何编写 api 文件")
"""

# 使用解析器解析 API 描述
j = Lerche.parse(gozero_parser, api_description)

# 打印解析结果
println(j)

end # module GozeroGenjl
