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

  if (year) {
    if (year == '2007' || year == '2012') { 

      if (year == '2007') {
        model = naics_2007;
      }else { 
        model = naics_2012;
      }

      code = query.code

      if (code) {


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

          var resp = {
            'num_found': results.length,
            'results': results
          };

          res.json(resp);

        }
      }
      else if (year == '2002' || year == '1997') {
        res.send(404, {'error':'NAICS API does not currently include ' + year + ' data.'});
      }
      else {
        res.send(400, {'error':'Please use a valid NAICS year.'});
      }
    }else {
      res.send(400, { 'error': 'Please include a NAICS year.' });
    }
  };