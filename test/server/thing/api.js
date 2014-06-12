'use strict';

var should = require('should'),
    app = require('../../../server'),
    request = require('supertest');

describe('Querying NAICS by year', function() {
  
  it('should respond with JSON array when given a valid year', function(done) {
    request(app)
      .get('/api/q?year=2012')
      .expect(200)
      .expect('Content-Type', /json/)
      .end(function(err, res) {
        if (err) return done(err);
        res.body.results.should.be.instanceof(Array);
      });

      request(app)
      .get('/api/q?year=2007')
      .expect(200)
      .expect('Content-Type', /json/)
      .end(function(err, res) {
        if (err) return done(err);
        res.body.results.should.be.instanceof(Array);
        done();
      });
  });

  it('should require a year parameter', function(done) {
    request(app)
      .get('/api/q')
      .expect(400)
      .expect('Content-Type', /json/)
      .end(function(err, res) {
        if (err) return done(err);
        res.body.should.have.property('error', 'Please include a NAICS year.');
        done();
      });
  });

  it('should respond with an array for year 2007', function(done) {
    request(app)
      .get('/api/q?year=2007')
      .expect(200)
      .expect('Content-Type', /json/)
      .end(function(err, res) {
        if (err) return done(err);
        //res.body.should.have.property('results');
        res.body.results.should.be.instanceof(Array);
        done();
      });
  });

  it('should reject an invalid NAICS year', function(done) {
    request(app)
      .get('/api/q?year=2099')
      .expect(400)
      .expect('Content-Type', /json/)
      .end(function(err, res) {
        if (err) return done(err);
        res.body.should.have.property('error', 'Please use a valid NAICS year.');
        done();
      });
  });

  it("should generate an error if year parameter is valid but we don't have data for it", function(done) {
    request(app)
      .get('/api/q?year=2002')
      .expect(404)
      .expect('Content-Type', /json/)
      .end(function(err, res) {
        if (err) return done(err);
        res.body.should.have.property('error', 'NAICS API does not currently include 2002 data.');
      });

      request(app)
      .get('/api/q?year=1997')
      .expect(404)
      .expect('Content-Type', /json/)
      .end(function(err, res) {
        if (err) return done(err);
        res.body.should.have.property('error', 'NAICS API does not currently include 1997 data.');
        done();
      });
  });

  it('should return all 2,335 entries for year 2007', function (done) {
      request(app)
      .get('/api/q?year=2007')
      .expect(200)
      .expect('Content-Type', /json/)
      .end(function(err, res) {
        if (err) return done(err);

        res.body.results.should.have.property('length', 2335); 
        //should(res.body.results).have.property('length', 2328); 
        done();
      });
  });


  it('should return all 2209 entries for year 2012', function (done) {
      request(app)
      .get('/api/q?year=2012')
      .expect(200)
      .expect('Content-Type', /json/)
      .end(function(err, res) {
        if (err) return done(err);

        res.body.results.should.have.property('length', 2216); 
        //should(res.body.results).have.property('length', 2328); 
        done();
      });
  });

});