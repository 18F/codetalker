'use strict';

var naics_2007 = require('naics-2007'),
naics_2012 = require('naics-2012');

/**
 * Get awesome things
 */
 exports.awesomeThings = function(req, res) {
  res.json([
  {
    name : 'HTML5 Boilerplate',
    info : 'HTML5 Boilerplate is a professional front-end template for building fast, robust, and adaptable web apps or sites.',
    awesomeness: 10
  }, {
    name : 'AngularJS',
    info : 'AngularJS is a toolset for building the framework most suited to your application development.',
    awesomeness: 10
  }, {
    name : 'Karma',
    info : 'Spectacular Test Runner for JavaScript.',
    awesomeness: 10
  }, {
    name : 'Express',
    info : 'Flexible and minimalist web application framework for node.js.',
    awesomeness: 10
  }
  ]);
};

exports.q = function(req, res) {

  var query = req.query,
  model,
  year,
  code,
  results,
  all_codes,
  i;

  var year = query.year;

  if(!year){
    returnError(400, 'Please include a NAICS year.');
    return;
  }      

  if (year == '2002' || year == '1997') {
    returnError(404, 'NAICS API does not currently include ' + year + ' data.');
    return;
  }

  if (year == '2007' || year == '2012') { 

    if (year == '2007') {
      model = naics_2007;
    }else { 
      model = naics_2012;
    }

    code = query.code

    if (code) {
        //TODO
      }else{
        results = [];

          //Return a full year's codes
          all_codes = model.all();
          
          //Apply filtering to results 
          for(i=0; i<all_codes.length; i++){

            // if part_of_range exists, skip it from inclusion
            if (all_codes[i].part_of_range) continue;
            results.push(all_codes[i]);
          }

          sendResults(results);

        }
      }else {
        returnError(400, 'Please use a valid NAICS year.');
      }


      function returnError (http_status, error_msg) {
        // Generic error message function
        res.send(http_status, {
          'status': http_status,
          'message': error_msg,
          'code': '',
          'more_info': ''
        });
      }

      function sendResults (results) {
    
        var num_found = results.length;

    // paginate and send results

    if (query.limit || query.page) {
      results = paginate(results);
    }

    var resp = {
      'num_found': num_found,
      'results': results
    };

    res.json(resp);
  }

  function paginate (input) {
    // use &limit and &page to determine paged results

    var isInt = /^\d+$/;
    var limit = query.limit || 10;
    var page = query.page || 1;

    var lower = limit * (page - 1);
    var upper = limit * page;

    input = input.slice(lower, upper);

    return input;
  }
};
