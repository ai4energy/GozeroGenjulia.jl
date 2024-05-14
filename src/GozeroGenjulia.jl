module GozeroGenjl

# using Pkg
# Pkg.add("Lerche")
using Lerche
struct ApiSyntax
    version::String
end

gozero_grammar = raw"""
    gozeroapi: spec*

    decimal_digit: /[0-9]/
    number: /[0-9]/
    lower_letter: /[a-z]/
    letter: /[A-Za-z_]/
    identifier: letter (letter | decimal_digit | "_")*    

    spec: syntax_stmt | info_stmt
    syntax_stmt: "syntax" "=" STRING

    info_stmt: "info" "(" info_key_value_expr* ")"
    info_key_value_expr: info_key_lit interpreted_string_lit
    info_key_lit: identifier ":"
    interpreted_string_lit: STRING

    WHITESPACE: /[ \t\r\n\f]+/
    COMMENT: /(?s)\/\*.*?\*\//
    LINE_COMMENT: /\/\/[^\n]*\n?/
    STRING: ESCAPED_STRING
    %import common.ESCAPED_STRING
    %ignore WHITESPACE
    %ignore COMMENT
    %ignore LINE_COMMENT

"""

struct TreeToAPISPEC <: Transformer end
####以下的解析函数使用@rule的宏定义的函数代替，所以注释掉了
#= Lerche.transformer_func(t::TreeToAPISPEC, ::Val{:syntax_lit}, meta::Lerche.Meta, tree) = begin
            SyntaxData(tree[1][2:end-1]) 
end
 =#

Lerche.transformer_func(t::TreeToAPISPEC, ::Val{:gozeroapi}, meta::Lerche.Meta, tree) = begin
    tree[1]
end

@rule  gozeroapi(t::TreeToAPISPEC,tree) = tree[1]
@rule  syntax_stmt(t::TreeToAPISPEC,tree) = ApiSyntax(tree[1][2:end-1])
@rule  info_stmt(t::TreeToAPISPEC,tree) = tree[1]

gozero_parser = Lark(gozero_grammar, parser="lalr", start="gozeroapi", lexer="standard", transformer=TreeToAPISPEC())
gozero_parser = Lark(gozero_grammar, parser="lalr", start="gozeroapi", lexer="standard")
# 测试 API 描述

api_description = raw"""syntax = "v1"
/* dfa wom 
fda woshi zhushi
*/
info (abc: "my"
desc:    "演示如何编写 api 文件")

"""

# 使用解析器解析 API 描述
j = Lerche.parse(gozero_parser,api_description)

# 打印解析结果
println(j)


function extract_syntax_data(data)
    # 检查 "syntax" 键是否存在于字典中
    if haskey(data, "syntax")
        # 提取 "syntax" 键对应的值，这是一个包含 Token 的数组
        token_array = data["syntax"]
        # 假设我们关注的 Token 总是在数组的第一个位置
        first_token = token_array[1]
        # 创建一个 SyntaxData 实例，提取 Token 中的值（去掉引号）
        return SyntaxData(first_token[2:end-1])  # 假设字符串形式为 "\"v1\""
    else
        error("Key 'syntax' not found in the data.")
    end
end

extract_syntax_data(j)


end # module GozeroGenjl
