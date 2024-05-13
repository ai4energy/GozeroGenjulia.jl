using Lerche
include("api.ebnf")

const gozero_parser = Lerche.Lark(gozero_grammar_spec,start="input",parser="lalr",lexer="contextual")

