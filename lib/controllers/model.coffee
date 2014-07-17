epg = require "easy-pg"
client = epg "pg://postgres@localhost/codetalker"
    
module.exports.sendResultsFromDb = (query, sendResults, returnError) ->
    client.query "SELECT * FROM code LIMIT 10", null, (err, result) ->
        // TODO: no part_of_range in results
        if err
            return console.error "fetch error: #{err}"
        console.log "Query result is #{result}"
        sendResults result.rows