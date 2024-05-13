module GozeroGenjl

# using Pkg
# Pkg.add("Lerche")
using Lerche
struct ApiSyntax
    version::String
end
struct infoSyntax
    version::String
end
gozero_grammar = raw"""
input: SyntaxStmt

Syntax         = { Production } .
Production     = production_name "=" [ Expression ] "." .
Expression     = Term { "|" Term } .
Term           = Factor { Factor } .
Factor         = production_name | token [ "…" token ] | Group | Option | Repetition .
Group          = "(" Expression ")" .
Option         = "[" Expression "]" .
Repetition     = "{" Expression "}" .


SyntaxStmt     = "syntax" "=" "v1" .

"""


struct TreeToAPISPEC <: Transformer end
####以下的解析函数使用@rule的宏定义的函数代替，所以注释掉了
#= Lerche.transformer_func(t::TreeToAPISPEC, ::Val{:syntax_lit}, meta::Lerche.Meta, tree) = begin
            SyntaxData(tree[1][2:end-1]) 
end
 =#
@rule  syntax_lit(t::TreeToAPISPEC,tree) = ApiSyntax(tree[1][2:end-1])
@rule  info_lit(t::TreeToAPISPEC,tree) = tree

gozero_parser = Lark(gozero_grammar, start="input", parser="lalr", lexer="standard")

# 测试 API 描述
api_description = raw"""
syntax = "v1"


"""

# 使用解析器解析 API 描述
j = Lerche.parse(gozero_parser,api_description)

# 打印解析结果
println(j)





end # module GozeroGenjl
