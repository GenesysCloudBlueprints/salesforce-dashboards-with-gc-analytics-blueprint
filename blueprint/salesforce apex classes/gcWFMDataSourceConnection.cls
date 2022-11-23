global class gcWFMDataSourceConnection 
    extends DataSource.Connection {
        private DataSource.ConnectionParams connectionInfo;
    global gcWFMDataSourceConnection(DataSource.ConnectionParams connectionParams) {
        this.connectionInfo = connectionParams;
    }
        
    override global List<DataSource.Table> sync() {
        List<DataSource.Table> tables = new List<DataSource.Table>();
        List<DataSource.Column> columns;
        columns = new List<DataSource.Column>();
        columns.add(DataSource.Column.text('ExternalId', 36));
        columns.add(DataSource.Column.integer('nOffered', 18));
        columns.add(DataSource.Column.integer('tHandle', 18));
        columns.add(DataSource.Column.text('dayId', 36));
        return tables;
    }
        
    override global DataSource.TableResult query(DataSource.QueryContext context) {
        String url = '/api/v2/analytics/conversations/aggregates/query';
        
        List<Map<String, Object>> rows = getData(url);
        return DataSource.TableResult.get(true, null, context.tableSelection.tableSelected, rows);
    }
        
    public List<Map<String, Object>> getData(String url) {
        JSONParser data = JSON.createParser(getResponse(url));
        return getData(data);
    }
     
    private String getResponse(String url) {
        HttpResponse response = purecloud.SDK.Rest.post(url, postBody());
        System.debug('Response- ' + response.getBody());
        return response.getBody();
    }

    private List<Map<String, Object>> getData (JSONparser json){
        System.debug('JSONparserDEBUG- ' + json);
        List<Map<String, Object>> data = new List<Map<String, Object>>();
        Map<String, Object> element = new Map<String, Object>();
        
        integer keysFilled = 0;
        integer externalId = 1;
        integer gPass = 0;
        
        while (json.nextToken() != null) {
            String text = json.getText();
            switch on text {
                when 'tHandle' {
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    element.put('tHandle', json.getIntegerValue());
                    keysFilled++;
                }
                when 'nOffered' {
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    element.put('nOffered', json.getIntegerValue());
                    keysFilled++;
                }
                when 'interval' {
                    if (gPass == 0) {
                        json.nextToken();
                        element.put('dayId', json.getText().substring(5, 10));
                        gPass = 1;
                    } else {
                        if (keysFilled > 0) {
                            element.put('ExternalId', externalId);
                            externalId++;
                            data.add(element);
                            System.debug('Response adding row to table- ' + element);
                            element = new Map<String, Object>();
                            keysFilled=0;
                            json.nextToken();
                            element.put('dayId', json.getText().substring(5, 10));
                        }   
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
        gen.writeStringField('interval', getInterval());
        gen.writeStringField('granularity', 'P1D');
        gen.writeFieldName('groupBy');
        gen.writeStartArray();
        gen.writeString('mediaType');
        gen.writeString('queueId');
        gen.writeString('requestedRoutingSkillId');
        gen.writeString('requestedLanguageId');
        gen.writeString('direction');
        gen.writeEndArray();
        gen.writeFieldName('filter');
        gen.writeStartObject();
        gen.writeStringField('type', 'OR');
        gen.writeFieldName('clauses');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('type', 'AND');
        gen.writeFieldName('predicates');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('dimension', 'queueId');
        gen.writeStringField('operator', 'matches');
        gen.writeStringField('value', '63ec96a7-6e64-43d8-abd5-a1ef70dede21');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('dimension', 'mediaType');
        gen.writeStringField('operator', 'matches');
        gen.writeStringField('value', 'voice');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('dimension', 'requestedLanguageId');
        gen.writeStringField('operator', 'notExists');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('dimension', 'requestedRoutingSkillId');
        gen.writeStringField('operator', 'notExists');
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeFieldName('metrics');
        gen.writeStartArray();
        gen.writeString('nOffered');
        gen.writeString('tHandle');
        gen.writeEndArray();
        gen.writeBooleanField('flattenMultivaluedDimensions', true);
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