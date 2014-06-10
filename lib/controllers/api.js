'use strict';

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
      code;

  var year = query.year;

  if (year) {
    if (year == '2007' || year == '2012') { 
       res.json([
        req.body,
        req.params,
        req.query

        ]);
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