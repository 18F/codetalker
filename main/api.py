"""
Run application as API server.
"""
import os
from flask import Flask, jsonify, abort, request
from flask.ext.sqlalchemy import SQLAlchemy
from flask.ext import restful
from flask.ext.restful import fields, marshal_with
from sqlalchemy_jsonapi import JSONAPI, JSONAPIMixin
import dateutil.parser

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv('CODETALKER_DATABASE_URI',
                                                  "postgresql://:@/codetalker")
api = restful.Api(app)
db = SQLAlchemy(app)
from codetalker.models.models import NaicsModel, CageModel

class OneResource(restful.Resource):

    def get(self, id):
        qry = self.model.query.filter_by(id=id)
        result = self.serializer.serialize(qry)
        if not result[self.resource_name]:
            abort(404)
        return result


class Naics(OneResource):
    resource_name = 'naics'
    serializer = JSONAPI(NaicsModel)
    model = NaicsModel


class Cage(OneResource):
    resource_name = 'cage'
    serializer = JSONAPI(CageModel)
    model = CageModel


api.add_resource(Naics, '/api/NAICS/<string:id>')
api.add_resource(Cage, '/api/CAGE/<string:id>')


class NaicsQuery(Naics):

    years = [2007, 2012]
    all_fields = ['change_indicator', 'id', 'links', 'seq_no',
                  'code', '_year', 'title', 'part_of_range',
                  'description_code', 'trilateral', 'description',
                  'examples']
    all_fields = set(['change_indicator', 'id', 'links',
                      'code', '_year', 'title',
                      'description',
                      'examples'])
    all_includes = set(['crossrefs', 'cages'])

    def _year_from_datestring(self, datestring):
        if not datestring:
            return self.years[-1]
        try:
            dt = dateutil.parser.parse(datestring)
        except TypeError:
            abort(400)
        years_before = [y for y in self.years if y <= dt.year]
        if not years_before:
            abort(404)
        return years_before[-1]

    def get(self, **kwarg):
        year = self._year_from_datestring(request.args.get('date'))
        qry = NaicsModel.query.filter_by(_year=year)
        qry = qry.filter_by(part_of_range=None)

        try:
            limit = min(int(request.args.get('limit', 25)), 50)
        except TypeError:
            abort(500)
        qry = qry.limit(limit)

        if 'page' in request.args:
            try:
                page = int(request.args['page'])
            except TypeError:
                abort(500)
            offset = (page-1) * limit
        else:
            try:
                offset = int(request.args.get('start', 1)) - 1
            except TypeError:
                abort(500)
        qry = qry.offset(offset)

        fields = set([f.lower() for f in request.args.getlist('field')]) \
                 or self.all_fields
        fields &= self.all_fields
        includes = set([i.lower() for i in request.args.getlist('field')]) \
                   or self.all_includes
        includes &= self.all_includes
        if (not fields) and (not includes):
            abort(400)
        result = self.serializer.serialize(qry, fields=list(fields),
                                           include=list(includes))
        return result


api.add_resource(NaicsQuery, '/api/q')


if __name__ == '__main__':
    app.run(debug=True)

