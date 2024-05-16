module GozeroJulia

export parse_api, ApiSpec, ApiSyntax, struct, Service, Doc, Annotation, Import, Group, Info, Member, Route, DefineStruct, Primitivestruct, Mapstruct, Arraystruct, Interfacestruct, Pointerstruct, AtDoc

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


function parse_syntax(lines::Vector{String})
    version = ""
    doc = Doc(String[])
    comment = Doc(String[])
    
    for line in lines
        if occursin("syntax", line)
            version = strip(split(line, "=")[2])
        elseif occursin("doc", line)
            push!(doc.content, strip(line))
        elseif occursin("comment", line)
            push!(comment.content, strip(line))
        end
    end    
    return ApiSyntax(version, doc, comment)
end


filename = joinpath(@__DIR__, "..", "examples/demo.api")
lines = String.(split(read(filename, String), "\n"))
parse_syntax(lines)

end # module
