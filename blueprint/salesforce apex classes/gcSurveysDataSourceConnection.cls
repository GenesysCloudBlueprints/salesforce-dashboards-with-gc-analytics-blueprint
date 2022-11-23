global class gcSurveysDataSourceConnection 
    extends DataSource.Connection {
        private DataSource.ConnectionParams connectionInfo;
    global gcSurveysDataSourceConnection(DataSource.ConnectionParams connectionParams) {
        this.connectionInfo = connectionParams;
    }
        
    override global List<DataSource.Table> sync() {
        List<DataSource.Table> tables = new List<DataSource.Table>();
        List<DataSource.Column> columns;
        columns = new List<DataSource.Column>();
        columns.add(DataSource.Column.text('ExternalId', 36));
        columns.add(DataSource.Column.text('mediaType', 50));
        columns.add(DataSource.Column.text('metric', 100));
        columns.add(DataSource.Column.integer('nSurveyResponses', 18));
        columns.add(DataSource.Column.integer('nSurveysSent', 18));
        columns.add(DataSource.Column.integer('statsCount', 18));
        columns.add(DataSource.Column.integer('statsSum', 18));
        columns.add(DataSource.Column.integer('statsMax', 18));
        columns.add(DataSource.Column.integer('statsMin', 18));
        return tables;
    }
        
    override global DataSource.TableResult query(DataSource.QueryContext context) {
        String url = '/api/v2/analytics/surveys/aggregates/query';
        
        List<Map<String, Object>> rows = getData(url);
        return DataSource.TableResult.get(true, null, context.tableSelection.tableSelected, rows);
    }
        
    public List<Map<String, Object>> getData(String url) {
        JSONParser data = JSON.createParser(getResponse(url));
        return getData(data);
    }
     
    private String getResponse(String url) {
        HttpResponse response = purecloud.SDK.Rest.post(url, postBody());
        System.debug('Response- ' + response);
        return response.getBody();
    }

    private List<Map<String, Object>> getData (JSONparser json){
        System.debug('JSONparserDEBUG- ' + json);
        List<Map<String, Object>> data = new List<Map<String, Object>>();
        Map<String, Object> element = new Map<String, Object>();
        
        integer keysFilled = 0;
        integer externalId = 1;
        
        while (json.nextToken() != null) {
            String text = json.getText();
            switch on text {
                when 'mediaType' {
                    json.nextToken();
                    element.put('mediaType', json.getText());
                    keysFilled++;
                }
                when 'nSurveyResponses' {
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    element.put('nSurveyResponses', json.getIntegerValue());
                    keysFilled++;
                }
                when 'nSurveysSent' {
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    element.put('nSurveysSent', json.getIntegerValue());
                    keysFilled++;
                }
                when 'oSurveyTotalScore' {
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    element.put('statsMax', json.getIntegerValue());
                    json.nextToken();
                    json.nextToken();
                    element.put('statsMin', json.getIntegerValue());
                    json.nextToken();
                    json.nextToken();
                    element.put('statsCount', json.getIntegerValue());
                    json.nextToken();
                    json.nextToken();
                    element.put('statsSum', json.getIntegerValue());
                    keysFilled++;
                }
                when 'group' {
                    if (keysFilled > 0) {
                        element.put('ExternalId', externalId);
                        externalId++;
                        data.add(element);
                        System.debug('Response adding row to table- ' + element);
                        element = new Map<String, Object>();
                        keysFilled=0;
                    }
                }
            }
        }
        element.put('ExternalId', externalId);
        data.add(element);
        return data;
    }
        
    private String postBody() {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeBooleanField('flattenMultivaluedDimensions', true);
        gen.writeFieldName('filter');
        gen.writeStartObject();
        gen.writeStringField('type', 'AND');
        gen.writeFieldName('predicates');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('dimension', 'surveyFormContextId');
        gen.writeStringField('value', '5e1d5b3a-0925-4b42-9e84-d6c298009fc3');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('dimension', 'userId');
        gen.writeStringField('operator', 'exists');
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeFieldName('groupBy');
        gen.writeStartArray();
        gen.writeString('surveyFormContextId');
        gen.writeEndArray();
        gen.writeFieldName('metrics');
        gen.writeStartArray();
        gen.writeString('oSurveyTotalScore');
        gen.writeString('nSurveyResponses');
        gen.writeString('nSurveysSent');
        gen.writeEndArray();
        gen.writeStringField('interval', getInterval());
        gen.writeEndObject();
        
        System.debug('Response- ' + gen.getAsString());
        return gen.getAsString();
    }
        
        private string getInterval() {
            Date now = Date.today();
            string month = string.valueOf(now.month());
            if (month.length()<2) {
                month = '0' + month;
            }
            string year = string.valueOf(now.year());
            string endOfMonth = string.valueOf(date.daysInMonth(now.year(), now.month()));
            return year + '-' + month + '-01T00:00:00/' + year + '-' + month + '-' + endOfMonth + 'T00:00:00';
        }
}