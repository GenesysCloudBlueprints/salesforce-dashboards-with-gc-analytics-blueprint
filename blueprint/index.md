# salesforce-analytics-dashboard
This readme will guide you through the process of creating, editing, and adding Apex classes that you will then use to create reports that will be tied 
into dashboards for use in Salesforce.

# Create your Apex Classes
You will need two apex classes for each API call to Genesys Cloud. A data connection, which stores the API call as well as your logic to process the response and a data source provider which creates the Salesforce Custom connection for use as an external data source.

## Data Source Connection
### This class contains your API call and logic to process the response. You will to make sure you match up your external object to the passed values in this code.

The Apex classes are included in this repo. It is recommended you open then in a coding application to review and make adjustsments if you plan to do so.
Below includes a single set of the Apex classes for use as an example.

> You must specify a unique name for this new apex class labeled below as gcQueueDataSourceProvider.
>	
> The pairing of a datasourceconnection is required and you must provide that name below gcQueueDataSourceConnection.
>
> You are welcome to keep the names, or change them according to the instructions. The names must be unique. 

```
global class gcQueueDataSourceConnection 
	extends DataSource.Connection {
        private DataSource.ConnectionParams connectionInfo;
    global gcQueueDataSourceConnection(DataSource.ConnectionParams connectionParams) {
        this.connectionInfo = connectionParams;
    }
    
    /**
    *   Example vales to be passed to salesforce in order to build reports
    **/

    override global List<DataSource.Table> sync() {
        List<DataSource.Table> tables = new List<DataSource.Table>();
        List<DataSource.Column> columns;
        columns = new List<DataSource.Column>();
        columns.add(DataSource.Column.text('ExternalId', 36));
        columns.add(DataSource.Column.text('surveyFormName', 50));
        columns.add(DataSource.Column.text('mediaType', 25));
        columns.add(DataSource.Column.integer('count', 3));
        columns.add(DataSource.Column.integer('sum', 3));
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
        return response.getBody();
    }
    /**
    *   this is an example of processing the response from Genesys Cloud. You will need to search the response  
    *   and create rows from the associated data contained within
    **/

    private List<Map<String, Object>> getData (JSONparser json){
        List<Map<String, Object>> data = new List<Map<String, Object>>();
        Map<String, Object> element = new Map<String, Object>();
        
        integer keysFilled = 0;
        integer externalId = 0;
        string userId = 'none';
        
        while (json.nextToken() != null) {
            String text = json.getText();
            switch on text {
                when 'userId' {
                    json.nextToken();
                    userId = json.getText();
                    element.put('ExternalId', userId + String.valueOf(externalId));
                    externalId++;
                    keysFilled++;
                }                        
                when 'nSurveyNpsPromoters' {
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    json.nextToken();
                    element.put('Promoters', json.getIntegerValue());
                    keysFilled++;
                }
                when 'count', 'sum' {
                    json.nextToken();
                    element.put(text, json.getIntegerValue());
                    keysFilled++;
                }
                when 'mediaType', 'surveyFormName' {
                    json.nextToken();
                    element.put(text, json.getText());
                    keysFilled++;
                }
                when 'group' {
                    if (keysFilled > 0) {
                        element.put('Agent', userId);
                        data.add(element);
                        element = new Map<String, Object>();
                        keysFilled=0;
                    }
                }
            }
        }
        element.put('Agent', userId);
        data.add(element);
        return data;
    }
    
    /**
    *   this is an example of the request JSON construction. The logic is simple enough to follow. I recommend 
    *   you use a code editor and follow along as you create this
    **/
    
    private String postBody() {
	JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('interval', getInterval());
        gen.writeFieldName('filter');
        gen.writeStartObject();
        gen.writeStringField('type', 'AND');
	gen.writeFieldName('predicates');
	gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('dimension', 'surveyFormName');
        gen.writeStringField('operator', 'matches');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('dimension', 'userId');
        gen.writeStringField('operator', 'exists');
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeFieldName('groupBy');
        gen.writeStartArray();
        gen.writeString('surveyFormName');
        gen.writeString('userId');
        gen.writeEndArray();
	gen.writeFieldName('metrics');
        gen.writeStartArray();
        gen.writeString('nSurveyNpsPromoters');
        gen.writeString('oSurveyQuestionScore');
        gen.writeEndArray();
	gen.writeBooleanField('flattenMultivaluedDimensions', true);
        gen.writeEndObject();
        
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
```

## Data Source Provider
### This code will facilitate the creation of the external data source and authentication for your new connection.

> You must specify a unique name for this new apex class labeled below as gcQueueDataSourceProvider.
>	
> The pairing of a datasourceconnection is required and you must provide that name below gcQueueDataSourceConnection.
>
> You are welcome to keep the names, or change them according to the instructions. The names must be unique. 

	
```/**
 *   Extends the DataSource.Provider base class to create a 
 *   custom adapter for Salesforce Connect. The class informs 
 *   Salesforce of the functional and authentication 
 *   capabilities that are supported by or required to connect 
 *   to an external system.
 **/
global class gcQueueDataSourceProvider
    extends DataSource.Provider {
 
    /**
     *   Declares the types of authentication that can be used 
     *   to access the external system.
     **/
    override global List<DataSource.AuthenticationCapability>
        getAuthenticationCapabilities() {
        List<DataSource.AuthenticationCapability> capabilities =
            new List<DataSource.AuthenticationCapability>();
        capabilities.add(
            DataSource.AuthenticationCapability.ANONYMOUS);
        return capabilities;
    }
 
    /**
     *   Declares the functional capabilities that the 
     *   external system supports.
     **/
    override global List<DataSource.Capability>
        getCapabilities() {
        List<DataSource.Capability> capabilities =
            new List<DataSource.Capability>();
        capabilities.add(DataSource.Capability.ROW_QUERY);
        return capabilities;
    }
 
    /**
     *   Declares the associated DataSource.Connection class.
     **/
    override global DataSource.Connection getConnection(
        DataSource.ConnectionParams connectionParams) {
        return new gcQueueDataSourceConnection(connectionParams);
    }
}
```


# Adding your Apex classes to Salesforce

### In order to use the classes you created, you will need to first add them to Salesforce.

> You will need to perform these steps three times, one for each 'set' of Apex classes.

1. Open **Setup**.

![Step 1](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git1.png?raw=true)

2. Search for **apex** in the quick find and select **Aoex Classes** then **New**.

![Step 2](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git2.png?raw=true)

3. Paste in the code for either class, save, then repeat for the remaining class code.

> YOU MUST ADD THE DATASOURCECONNECTION CLASS FIRST.
> The code will be checked for Syntax. If you encounter any issues, it will notify you and 
> must be corrected before it will be allowed to be saved

![Step 3](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git3.png?raw=true)

# Creating an external data source and matching external object

### Now that you have created and imported your required Apex classes you will need to use them.

1. In the quick find from earlier, search for **external**

![Step 4](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git4.png?raw=true)

2. Select **External Data Sources**. Then **New External Data Source** and fill in the information 
similar to below and select your new Salesforce Connect: Custom matching the Apex class you just uploaded.
Leave **Identity Type** and **Authentication Protocol** on their default values.

> The unique name should be relevant to the project/org/queues

![Step 4.1](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git4.1.png?raw=true)

![Step 5](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git5.png?raw=true)

3. Open the **External Objects** topic next, followed by **New External Object**.

![Step 6](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git6.png?raw=true)

4. Fill out the page in order. The label and plural can be anything, adjust as necessary. 
The **Object Name** must be unique. In the External Connection Detail portion, you must click the search 
icon and find the external data source in the list, then select it. Name the table whatever you would 
like it to show up as in the reports creator. **YOU MUST ENABLE REPORTS FOR THIS TO SHOW**

![Step 7](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git7.png?raw=true)

5. When you are done select save and open your **data source connection** class for reference. You will 
need to match custom fields to the returned data.

![Step 8](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git8.png?raw=true)

# Creating the report

>Now that you have the external data and objects with the apex classes you can create your report

1. Navigate to **Reports** and start a **New Report** which will launch the **Report Builder**.

![Step 9](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git9.png?raw=true)

2. From here, select **Other Reports** and find the external object you named earlier. Then **Start Report**.

![Step 10](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git10.png?raw=true)

## Now that you know how to get staretd with the reports, we can set up each individual report for the 
dashboard.

> You will need to test your class first. To do that, select **Run**. This will kick off your Apex classes and return the data you 
> 
> specified. This will return the data you setup in the external object for use in making charts.

### Survery Results 1 & 2

1. Set *Media Type* as your Group Rows and *Surveys Sent* and *Survey Responses* 
2. Create a chart and follow the settings in the image below. Making sure to check **Show Values** and set the legend to the bottom.
3. Verify the chart makes sense. 
4. Verify the chart looks relevant and save it with an appropriate name.

![Step 11](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git11.png?raw=true)

1. You will need to set the Group Rows to *Media Type* first.
2. Open the fields menu from the left side of the page and select *Create Formula*.
3. Set the *Total* to be divided by *Count*
4. Add this function along with the minumum and maximum values.
5. Create a chart to reflect the values from the image below. Making sure to check **Show Values** and set the legend to the bottom.
6. Verify the chart looks relevant and save it with an appropriate name.

![Step 12](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git12.png?raw=true)

### WFM Results

1. Set the Group Rows to *Day*. Add *Handled* and *Offered* to the Columns selection.
2. Create a chart and add the values from the image below.
3. Verify the data and save with an appropriate name.

![Step 13](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git13.png?raw=true)

### Queue Results 1 & 2

1. Set Group Rows to *Queue* and *Media Type*. Then set *Total Members* and *Users on Queue* to your Columns Selection.
2. Create a chart and set the values to match the image below. Making sure to check **Show Values** and set the legend to the bottom.
3. Verify the chart looks relevant and save it with an appropriate name.

![Step 14](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git21.png?raw=true)

1. Set Group Rows to *Queue*. Then set *Waiting*, *Alerting*, and *Interacting* to your Columns Selection.
2. Create a chart and set the values to match the image below. Making sure to check **Show Values** and set the legend to the bottom.
3. Verify the chart looks relevant and save it with an appropriate name.

# Creating a dashboard

1. Select the *dashboard* topic and select create new

![Step 15](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git15.png?raw=true)

![Step 16](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git16.png?raw=true)

2. Provide an appropriate name and select *Create*

![Step 17](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git17.png?raw=true)

3. Select *Add component*. Added each report, one at a time, and place it a visually appealing location.

> Make sure to select USE CHART SETTINGS FROM THE REPORT. Otherwise it will not look the way you set up.

![Step 18](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git18.png?raw=true)

![Step 19](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git19.png?raw=true)

![Step 20](https://github.com/GenesysTS/salesforce-analytics-dashboard/blob/main/img/git20.png?raw=true)
