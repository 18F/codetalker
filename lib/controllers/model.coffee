request = require "request"

url = (content) ->
    "http://127.0.0.1:8080/#{content}/:json"
           
module.exports.sendOneContractor = (query, sendResults, returnError) ->
    qry = "ccr_raw?cage_code='#{query.params.cagecode}'"
    request url(qry), (err, response, body) ->
        if err
            returnError 400, err
            return
        body = JSON.parse body
        # convert to JSONAPI format for one resource
        contractors = body.ccr_raw
        if contractors.length
            result = { contractors: contractors[0] }
            sendResults result
        else
            returnError 404, "No record found for CAGE #{query.params.cagecode}."

module.exports.sendResultsFromDb = (query, sendResults, returnError) ->
    request htsql_query(query), (err, response, body) ->
        if err
            returnError 400, err
            return
        body = JSON.parse body
        rows = []
        for row in body.results[0].code
            if row.contractors?
                actual_contractors = (c.ccr_raw[0] for c in row.contractors)
                row.contractors = actual_contractors
            rows.push row
        results =
            num_found: body.results[0].num_found
            results: rows
        sendResults(results)
        
replaceArrayElement = (inpt, target, replace_with) ->
    # replace ALL appearances of `target` with ONE of `replace_with`, at the end
    # cannot believe I have to write this by hand
    result = (e for e in inpt when e != target)
    if result.length < inpt.length
        result.push(replace_with)
    return result
        
filter = (query) ->
    if query.code
        code = "&code='#{query.code}'"
    else
        code = ""
    "?is_null(part_of_range)&year='#{query.year}'" + "#{code}"
    
htsql_query = (query) ->
    all_fields = ['code','year','title','description','crossrefs','contractors']
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
        
    fields = replaceArrayElement fields, 'crossrefs', '/crossrefs{code,text}'
    fields = replaceArrayElement fields, 'contractors', '/ccr_naics{/ccr_raw} :as contractors'
        
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
    
