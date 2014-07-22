request = require "request"
           
module.exports.sendResultsFromDb = (query, sendResults, returnError) ->
    qry = htsql_query query, returnError
    request htsql_query(query), (err, response, body) ->
        if err
            returnError 400, err
            return
        sendResults(body)
        
url = (content) ->
    "http://127.0.0.1:8080/#{content}/:json"
    
filter = (query) ->
    if query.code
        code = "&code='#{query.code}'"
    else
        code = ""
    "?is_null(part_of_range)&year='#{query.year}'" + "#{code}"
    
htsql_query = (query) ->
    all_fields = ['code','year','title','description','crossrefs']
    if query.field
        if typeof query.field is 'string'
            fields = [query.field,]
        else
            fields = query.field
        fields = (f.toLowerCase() for f in fields)
        fields = (f for f in all_fields when f in fields)
        if not fields.length
            throw "Only fields #{all_fields} accepted"
    else
        fields = all_fields
        
    if 'crossrefs' in fields
        fields.pop 'crossrefs'
        fields.push "/crossrefs{code,text}"
        # TODO: got to be a better way to array replace
        
    if not query.limit?
        query.limit = 25
    
    if query.limit > 50
        query.limit = 50
        
    if not query.start?
        query.start = 1
        
    if query.page?
        query.start = ((query.page-1) * query.limit) + 1
            
    limit_clause = ".limit(#{query.limit},#{query.start-1})"
       
    content = "(code{#{fields}}#{filter(query)})#{limit_clause}"
    result = url("{count(code#{filter(query)}) :as num_found,/#{content}} :as results")
    console.log "\n\nurl found is #{result}\n\n"
    return result
    
