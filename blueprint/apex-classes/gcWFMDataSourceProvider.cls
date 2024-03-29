/**
 *   Extends the DataSource.Provider base class to create a 
 *   custom adapter for Salesforce Connect. The class informs 
 *   Salesforce of the functional and authentication 
 *   capabilities that are supported by or required to connect 
 *   to an external system.
 **/
global class gcWFMDataSourceProvider
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
        return new gcWFMDataSourceConnection(connectionParams);
    }
}