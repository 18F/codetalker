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
        fields = (f for f in all_fields when f in (fs.toLowerCase() for fs in fields))
    else
        fields = all_fields
    ("code.#{f}" for f in fields)
    
    
module.exports.sendResultsFromDb = (query, sendResults, returnError) ->
    
    fields_requested = field_list(query)
    if (query.field) and (not fields_requested.length)
        returnError 400, 'Fields that can be specified: code, year, title, description, crossrefs'
        return
        
    fields = field_list(query) or " NULL "

    if 'code.crossrefs' in fields
        fields.pop 'code.crossrefs'
        group_by_clause = " GROUP BY #{fields} "
        fields.push """ '[' || string_agg(format('{"code": "%s", "text": "%s"}',
                                                 xr.code, REPLACE(xr.text, '"', '\\"')),
                                          ',')
                            || ']' as crossrefs """
        join_clause = " LEFT OUTER JOIN (select * from crossrefs) xr ON (xr.all_codes_id = code.id_) "
    else
        join_clause = ""
        group_by_clause = ""
        
    query_text = """
                  SELECT #{fields}
                  FROM   code #{join_clause}
                  WHERE  part_of_range IS NULL
                  #{in_clause query, 'year'} #{in_clause query, 'code'}
                  #{group_by_clause} #{limit_clause query} ; """
    
    # console.log "\nquery text is\n#{query_text}\n"
    
    client.query query_text, null, (err, result) ->
        if err
            return console.error "fetch error: #{err}"
        if group_by_clause
            for row in result.rows
                row.crossrefs = JSON.parse row.crossrefs
        sendResults result.rows
