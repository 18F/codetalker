"""
Run application as API server.
"""
import os
import os.path
import sys
from flask import Flask, abort, request
from flask.ext.sqlalchemy import SQLAlchemy
from flask.ext import restful
from sqlalchemy_jsonapi import JSONAPI
import dateutil.parser
sys.path.append(os.path.abspath('..'))

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv('CODETALKER_DATABASE_URI',
                                                  "postgresql://:@/codetalker")
api = restful.Api(app)
db = SQLAlchemy(app)
from codetalker.models.models import NaicsModel, CageModel

def error_message(message, status):
    return {"message": message, "status": status, "code": "", "more_info": "", }


class OneResource(restful.Resource):

    def get(self, id):
        qry = self.model.query.filter_by(id=id)
        result = self.serializer.serialize(qry)
        if not result[self.resource_name]:
            return error_message("%s %s does not exist" % (self.resource_name, id), 404), 404
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
    all_fields = set(['change_indicator', 'id', 'links',
                      'code', '_year', 'title',
                      'description',
                      'examples'])
    all_includes = set(['crossrefs', 'cages'])

    def _year_from_datestring(self, datestring):
        """
        Limit query results to those from the latest year not exceeding
        the given date (or simply the most recent, if no date param given)
        """
        if not datestring:
            return self.years[-1]
        try:
            dt = dateutil.parser.parse(datestring)
        except TypeError:
            abort(400, {"message": "%s not a valid date format (use format YYYYMMDD)" % (datestring, )})
        years_before = [y for y in self.years if y <= dt.year]
        if not years_before:
            abort(404, {"message": "Years before %d have not yet been loaded into Codetalker" % (self.years[0])})
                        
        return years_before[-1]

    def get(self, **kwarg):
        year = self._year_from_datestring(request.args.get('date'))
        qry = NaicsModel.query.filter_by(_year=year)
        qry = qry.filter_by(part_of_range=None)

        # Default limit of 25 records; limit to 50 even if user requests more
        try:
            limit = min(int(request.args.get('limit', 25)), 50)
        except TypeError:
            return error_message("``limit`` should be an integer (%s given)" % (request.args['limit']), 400), 400
        qry = qry.limit(limit)

        if 'page' in request.args:
            try:
                page = int(request.args['page'])
            except TypeError:
                return error_message("``page`` should be an integer (%s given)" % (request.args['page']), 400), 400
            offset = (page-1) * limit
        else:
            try:
                offset = int(request.args.get('start', 1)) - 1
            except TypeError:
                return error_message("``start`` should be an integer (%s given)" % (request.args['start']), 400), 400
        qry = qry.offset(offset)

        # sqlalchemy_jsonapi calls them "fields" if they're scalars and
        # "includes" if they're linked resources, but our API uses the
        # ``field`` parameter for all of them, to determine which to include
        # in output
        fields = set([f.lower() for f in request.args.getlist('field')]) \
                 or self.all_fields
        fields &= self.all_fields
        includes = set([i.lower() for i in request.args.getlist('field')]) \
                   or self.all_includes
        includes &= self.all_includes
        if (not fields) and (not includes):
            return error_message("valid values for ``field``: %s" % ("\n".join(self.all_fields | self.all_includes)), 400), 400

        # sqlalchemy_jsonapi does all the work of going from a SQLAlchemy query
        # to a jsonapi.org-formatted source
        result = self.serializer.serialize(qry, fields=list(fields),
                                           include=list(includes))
        return result


api.add_resource(NaicsQuery, '/api/q')

def runserver():
    app.run(debug=True)

if __name__ == '__main__':
    runserver()

