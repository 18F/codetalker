epg = require "easy-pg"
client = epg "pg://postgres@localhost/codetalker"

quote_delimited_string_list = (lst) ->
    """#{("\'#{l}\'" for l in lst)}"""
    
in_clause = (query, field_name) ->
    if field_name not of query
        return ""
    if typeof query[field_name] is 'string'
        return " AND code.#{field_name} = '" + query[field_name] + "'"
    else
        return " AND code.#{field_name} IN (#{quote_delimited_string_list query[field_name]})"

limit_clause = (query) ->
    if query.limit
        if query.page
            page = " OFFSET #{query.limit * (query.page - 1)}"
        else if query.start
            page = " OFFSET #{+query.start + 1}"
        else
            page = ""
        return " LIMIT #{query.limit} #{page} "
    ""
        
field_list = (query) ->

    all_fields = ['code','year','title','description','crossrefs']
    if query.field
        if typeof query.field is 'string'
            fields = [query.field,]
        else
            fields = query.field
        fields = (f for f in all_fields when f in fields)
    else
        fields = all_fields
    ("code.#{f}" for f in fields)
    
    
module.exports.sendResultsFromDb = (query, sendResults, returnError) ->
    
    console.log "\n*******************************************\n\n"
    console.log "query is #{JSON.stringify query}"    
    fields = field_list(query) or " NULL "

    if 'code.crossrefs' in fields
        fields.pop 'code.crossrefs'
        fields.push 'xr.code'
        fields.push 'xr.text'
        group_by_clause = " GROUP BY #{fields} "
        fields.push """ '[' || string_agg(format('{"code": "%s", "text": "%s"}',
                                                 crossrefs.code, REPLACE(crossrefs.text, '"', '\\"')),
                                          ',')
                            || ']' as crossrefs """
        join_clause = " JOIN (select * from crossrefs) xr ON (xr.all_codes_id = code.id_) "
    else
        join_clause = ""
        group_by_clause = ""
        
    query_text = "SELECT #{fields}
                  FROM   code #{join_clause}
                  WHERE  part_of_range IS NULL
                  #{in_clause query, 'year'} #{in_clause query, 'code'}
                  #{group_by_clause} #{limit_clause query} ;"

    query_text = """
        select row_to_json(row)
        from (
            select #{fields}
            from   code #{join_clause}
            join   (
              select * from crossrefs
            ) xr on (xr.all_codes_id = code.id_)
            #{in_clause query, 'year'} #{in_clause query, 'code'}
            #{group_by_clause} #{limit_clause query}  
        ) row;
    """
    
    console.log "\nquery text is\n#{query_text}\n"
    
    client.query query_text, null, (err, result) ->
        if err
            return console.error "fetch error: #{err}"
        if group_by_clause
            for row in result.rows
                row.crossrefs = JSON.parse row.crossrefs
                console.log "nparsing of crossrefs was successful\n"
        console.log "query fetched #{result.rows.length} rows"
        sendResults result.rows
