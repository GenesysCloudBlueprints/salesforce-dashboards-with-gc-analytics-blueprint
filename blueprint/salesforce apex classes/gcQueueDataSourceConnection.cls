global class gcQueueDataSourceConnection 
    extends DataSource.Connection {
        private DataSource.ConnectionParams connectionInfo;
    global gcQueueDataSourceConnection(DataSource.ConnectionParams connectionParams) {
        this.connectionInfo = connectionParams;
    }
        
    override global List<DataSource.Table> sync() {
        List<DataSource.Table> tables = new List<DataSource.Table>();
        List<DataSource.Column> columns;
        columns = new List<DataSource.Column>();
        columns.add(DataSource.Column.text('ExternalId', 36));
        columns.add(DataSource.Column.integer('oWaiting', 18));
        columns.add(DataSource.Column.integer('oInteracting', 18));
        columns.add(DataSource.Column.integer('oAlerting', 18));
        columns.add(DataSource.Column.integer('oMemberUsers', 18));
        columns.add(DataSource.Column.integer('oUserPresences', 18));
        columns.add(DataSource.Column.text('mediaType', 36));
        columns.add(DataSource.Column.text('queue', 36));
        return tables;
    }
        
    override global DataSource.TableResult query(DataSource.QueryContext context) {
        String url = '/api/v2/analytics/queues/observations/query';
        
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
        string queueId = 'none';
        integer gPass = 0;

        while (json.nextToken() != null) {
            String text = json.getText();
            switch on text {
                when 'mediaType' {
                    json.nextToken();
                    element.put('mediaType', json.getText());
                    keysFilled++;
                }
                when 'oWaiting' {
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    element.put('oWaiting', json.getIntegerValue());
                    keysFilled++;
                }
                when 'oInteracting' {
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    element.put('oInteracting', json.getIntegerValue());
                    keysFilled++;
                }
                when 'oAlerting' {
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    element.put('oAlerting', json.getIntegerValue());
                    keysFilled++;
                }
                when 'oUserPresences' {
                    json.nextToken();
                    json.nextToken();
                    if (json.getText() == 'e08eaf1b-ee47-4fa9-a231-1200e284798f') {
                        json.nextToken();
                        json.nextToken();
                        json.nextToken();
                        json.nextToken();
                        element.put('oUserPresences', json.getIntegerValue());
                    }
                    keysFilled++;
                }
                when 'oMemberUsers' {
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    element.put('oMemberUsers', json.getIntegerValue());
                    keysFilled++;
                }
                when 'group' {
                    if (gPass == 0) {
                        json.nextToken();
                        json.nextToken();
                        json.nextToken();
                        queueId = json.getText();
                        System.debug('queueId- ' + queueId);
                        if (queueId == 'd6550b1c-9e9e-4b5f-b387-b575c9f0e94a') {
                            element.put('queue', 'Help Desk');
                        } else if (queueId == '63ec96a7-6e64-43d8-abd5-a1ef70dede21') {
                            element.put('queue', 'Billing');
                        } else if (queueId == '138fd94c-06c7-4523-bfd6-36d5405fa392') {
                            element.put('queue', 'Advisors');
                        }
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
                            json.nextToken();
                            json.nextToken();
                            queueId = json.getText();
                            System.debug('queueId- ' + queueId);
                            if (queueId == 'd6550b1c-9e9e-4b5f-b387-b575c9f0e94a') {
                                element.put('queue', 'Help Desk');
                            } else if (queueId == '63ec96a7-6e64-43d8-abd5-a1ef70dede21') {
                                element.put('queue', 'Billing');
                            } else if (queueId == '138fd94c-06c7-4523-bfd6-36d5405fa392') {
                                element.put('queue', 'Advisors');
                            }
                        }
                    }
                }
            }
        }
        element.put('ExternalId', externalId);
        data.add(element);
        System.debug('adding element outside of loop');
        return data;
    }
        
    private String postBody() {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('detailedMetrics');
        gen.writeStartArray();
        gen.writeString('oWaiting');
        gen.writeString('oInteracting');
        gen.writeEndArray();
        gen.writeFieldName('metrics');
        gen.writeStartArray();
        gen.writeString('oWaiting');
        gen.writeString('oInteracting');
        gen.writeString('oAlerting');
        gen.writeString('oMemberUsers');
        gen.writeString('oActiveUsers');
        gen.writeString('oUserRoutingStatuses');
        gen.writeString('oUserPresences');
        gen.writeString('oOnQueueUsers');
        gen.writeString('oOffQueueUsers');
        gen.writeEndArray();
        gen.writeFieldName('filter');
        gen.writeStartObject();
        gen.writeStringField('type', 'AND');
        gen.writeFieldName('clauses');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('type', 'OR');
        gen.writeFieldName('predicates');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('type', 'dimension');
        gen.writeStringField('dimension', 'queueId');
        gen.writeStringField('value', '138fd94c-06c7-4523-bfd6-36d5405fa392');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('type', 'dimension');
        gen.writeStringField('dimension', 'queueId');
        gen.writeStringField('value', '63ec96a7-6e64-43d8-abd5-a1ef70dede21');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('type', 'dimension');
        gen.writeStringField('dimension', 'queueId');
        gen.writeStringField('value', 'd6550b1c-9e9e-4b5f-b387-b575c9f0e94a');
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
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