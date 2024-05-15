module GozeroJulia

export parse_api, ApiSpec, ApiSyntax, struct, Service, Doc, Annotation, Import, Group, Info, Member, Route, DefineStruct, Primitivestruct, Mapstruct, Arraystruct, Interfacestruct, Pointerstruct, AtDoc

# 定义基础结构
struct Doc
    content::Vector{String}
end

struct Annotation
    properties::Dict{String, String}
end


struct Info
    title::String
    desc::String
    version::String
    author::String
    email::String
    properties::Dict{String, String}
end

struct ApiSyntax
    version::String
    doc::Doc
    comment::Doc
end


struct Import
    value::String
    doc::Doc
    comment::Doc
end

struct AtDoc
    properties::Dict{String, String}
    text::String
end


abstract type  ApiStruct end

struct Route
    atserverannotation::Annotation
    method::String
    path::String
    requeststruct::ApiStruct
    responsestruct::ApiStruct
    docs::Doc
    handler::String
    atdoc::AtDoc
    handlerdoc::Doc
    handlercomment::Doc
    doc::Doc
    comment::Doc
end

struct Group
    annotation::Annotation
    routes::Vector{Route}
end


struct Service
    name::String
    groups::Vector{Group}
end

struct ApiSpec
    info::Info
    syntax::ApiSyntax
    imports::Vector{Import}
    apistructs::Vector{ApiStruct}
    service::Service
end


struct Member
    name::String
    Memberstruct::ApiStruct
    tag::String
    comment::String
    docs::Doc
    isinline::Bool
end




struct DefineStruct <: ApiStruct
    rawname::String
    members::Vector{Member}
    docs::Doc
end

struct Primitivestruct <: ApiStruct
    rawname::String
end

struct Mapstruct <: ApiStruct
    rawname::String
    key::String
    value::ApiStruct
end

struct Arraystruct <: ApiStruct
    rawname::String
    value::ApiStruct
end

struct Interfacestruct <: ApiStruct
    rawname::String
end

struct Pointerstruct <: ApiStruct
    rawname::String
    Pointerstructstruct::ApiStruct
end


# 解析 Doc
function parse_doc(lines::Vector{String}, index::Int)::Tuple{Doc, Int}
    content = String[]
    while index <= length(lines) && !occursin(r"\)", lines[index])
        push!(content, strip(lines[index]))
        index += 1
    end
    return Doc(content), index + 1
end

# 解析 Annotation
# function parse_annotation(lines::Vector{String}, index::Int)::Tuple{Annotation, Int}
#     properties = Dict{String, String}()
#     while index <= length(lines) && !occursin(r"\)", lines[index])
#         line = strip(lines[index])
#         key_value = match(r'(\w+)\s*:\s*\"(\[^"\]+)\"', line)
#         if key_value !== nothing
#             key, value = key_value.captures
#             properties[key] = value
#         end
#         index += 1
#     end
#     return Annotation(properties), index + 1
# end

# 解析 ApiSyntax
function parse_syntax(lines::Vector{String}, index::Int)::Tuple{ApiSyntax, Int}
    version = ""
    doc = Doc([])
    comment = Doc([])
    index += 1  # 跳过 syntax 开始行

    while index <= length(lines) && !occursin(r"\)", lines[index])
        line = strip(lines[index])
        if occursin(r'version\s*:\s*"(v\d+)"', line)
            version = match(r'version\s*:\s*"(v\d+)"', line).captures[1]
        elseif startswith(line, "doc")
            doc, index = parse_doc(lines, index + 1)
        elseif startswith(line, "comment")
            comment, index = parse_doc(lines, index + 1)
        end
        index += 1
    end

    api_syntax = ApiSyntax(version, doc, comment)
    return api_syntax, index + 1  # 跳过 syntax 结束行
end

# 解析 DefineStruct
function parse_define_struct(lines::Vector{String}, index::Int)::Tuple{DefineStruct, Int}
    struct_name = match(r'struct\s+(\w+)\s*{', lines[index]).captures[1]
    index += 1  # 跳过 struct 开始行
    members = Vector{Member}()
    while index <= length(lines) && !occursin(r"\}", lines[index])
        line = strip(lines[index])
        field = match(r'(\w+)\s+(\w+)\s*`json:"([^"]+)"`', line)
        if field !== nothing
            push!(members, Member(field.captures[1], Primitivestruct(field.captures[2]), field.captures[3], "", Doc([]), false))
        end
        index += 1
    end
    define_struct = DefineStruct(struct_name, members, Doc([]))
    return define_struct, index + 1  # 跳过 struct 结束行
end

# 解析 Service
function parse_service(lines::Vector{String}, index::Int)::Tuple{Service, Int}
    service_name = match(r'service\s+(\w+)\s*{', lines[index]).captures[1]
    index += 1  # 跳过 service 开始行
    routes = Route[]
    while index <= length(lines) && !occursin(r"\}", lines[index])
        line = strip(lines[index])
        if occursin(r'@handler', line)
            handler = match(r'@handler\s+(\w+)', line).captures[1]
            index += 1
            line = strip(lines[index])
            endpoint = match(r'(\w+)\s+(\S+)\s+\((\w+)\)\s+returns\s+\((\w+)\)', line)
            if endpoint !== nothing
                method, path, request_struct, response_struct = endpoint.captures
                push!(routes, Route(Annotation(Dict()), method, path, Primitivestruct(request_struct), Primitivestruct(response_struct), Doc([]), handler, AtDoc(Dict(), ""), Doc([]), Doc([]), Doc([]), Doc([])))
            end
        end
        index += 1
    end
    api_service = Service(service_name, [Group(Annotation(Dict()), routes)])
    return api_service, index + 1  # 跳过 service 结束行
end

# 解析 API
function parse_api(input::String)::ApiSpec
    lines = split(input, "\n")
    syntax = ApiSyntax("", Doc([]), Doc([]))
    structs = struct[]
    service = Service("", [])

    index = 1
    while index <= length(lines)
        line = strip(lines[index])
        if startswith(line, "syntax")
            syntax, index = parse_syntax(lines, index)
        elseif startswith(line, "struct")
            define_struct, index = parse_define_struct(lines, index)
            push!(structs, define_struct)
        elseif startswith(line, "service")
            service, index = parse_service(lines, index)
        else
            index += 1
        end
    end

    return ApiSpec(Info("", "", "", "", "", Dict()), syntax, [], structs, service)
end

end # module
