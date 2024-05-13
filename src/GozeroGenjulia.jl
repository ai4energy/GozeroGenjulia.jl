module GozeroGenjl

# using Pkg
# Pkg.add("Lerche")
using Lerche
struct ApiSyntax
    version::String
end

gozero_grammar = raw"""
    ?start: spec

    ?spec: syntax_lit


    syntax_lit: "syntax" "=" STRING
    
    WHITESPACE: /[ \t\r\n\f]+/
    COMMENT: /(?s)\/\*.*?\*\//
    LINE_COMMENT: /\/\/[^\n]*\n?/
    STRING: ESCAPED_STRING
    RAW_STRING: /`([^`\\]|\\[\s\S])*`/

    %import common.ESCAPED_STRING
    %import common.SIGNED_NUMBER

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
@rule  syntax_lit(t::TreeToAPISPEC,tree) = ApiSyntax(tree[1][2:end-1])

gozero_parser = Lark(gozero_grammar, parser="lalr", lexer="standard", transformer=TreeToAPISPEC());
# 测试 API 描述
api_description = raw"""syntax = "v1"
/* dfa wom 
fda woshi zhushi
*/

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
