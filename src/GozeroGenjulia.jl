module GozeroGenjl

# using Pkg
# Pkg.add("Lerche")
using Lerche
gozero_grammar = raw"""
    ?start: spec

    ?spec: syntax_lit


    syntax_lit: "syntax" "=" STRING
    
    STRING: ESCAPED_STRING

    %import common.ESCAPED_STRING
    %import common.SIGNED_NUMBER
    %import common.WS

    %ignore WS
"""

struct TreeToAPISPEC <: Transformer
end

Lerche.transformer_func(t::TreeToAPISPEC, ::Val{:syntax_lit}, meta::Lerche.Meta, tree) = begin
    Dict("syntax"=>tree)
end

gozero_parser = Lark(gozero_grammar, parser="lalr", lexer="standard", transformer=TreeToAPISPEC());
# 测试 API 描述
api_description = raw"""syntax = "v1"

"""

# 使用解析器解析 API 描述
j = Lerche.parse(gozero_parser,api_description)

# 打印解析结果
println(j)

end # module GozeroGenjl
