@isTest
private class strike_lookupControllerTest {
    
    @isTest static void test_getRecentRecords() {
        String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'"}';
        
        Test.startTest();
        String responseString = strike_lookupController.getRecentRecords(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        strike_responseData str = new strike_responseData();
            str.addError('failed');
        System.assertEquals(true, response.get('isSuccess'));
    }
    
    @isTest static void test_getRecordLabel() {
        /*CrmId__c crm = new CrmId__c();
        crm.Name='1';
        insert crm;*/
        
        Account a = new Account(Name='Test Account');
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        insert a;
        
        String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'"}';
        
        Test.startTest();
        String responseString = strike_lookupController.getRecordLabel(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        String objectLabel = String.valueOf(results.get('objectLabel'));
        
        System.assertEquals('Account', objectLabel);
    }
    
    @isTest static void test_getData() {
        
        
        /* CrmId__c crm = new CrmId__c();
        crm.Name='1';
        insert crm;*/
        Account a = new Account(Name='Test Account');
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        insert a;
        
        String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'", "order": "Name", "limit": "5", "searchTerm": "Test"}';
        
        Test.startTest();
        String responseString = strike_lookupController.getRecords(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');
        
        System.assertEquals(1, data.size());
        
        Map<String, Object> record = (Map<String, Object>)data.get(0);
        
        System.assertEquals(a.Id, record.get('value'));
    }
    
    @isTest static void test_getData_subtitleField() {
       /* CrmId__c crm = new CrmId__c();
        crm.Name='1';
        insert crm;*/
        Account a = new Account(Name='Test Account');
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        insert a;
        
        String jsonString = '{"searchField":"Name", "subtitleField": "Name", "object": "Account", "filter": "Name = \'Test Account\'", "searchTerm": "Test"}';
        
        Test.startTest();
        String responseString = strike_lookupController.getRecords(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');
        
        System.assertEquals(1, data.size());
        
        Map<String, Object> record = (Map<String, Object>)data.get(0);
        
        System.assertEquals(a.Id, record.get('value'));
    }
    
    @isTest static void test_getData_addressField() {
        /* CrmId__c crm = new CrmId__c();
        crm.Name='1';
        insert crm;*/
        
        Account a = new Account(
            Name='Test Account',
            BillingStreet='Test Street',
            BillingCity='Test City',
            BillingState='Test State',
            BillingCountry='Test Country',
            BillingPostalCode='Test Postal Code');
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        insert a;
        
        String jsonString = '{"searchField":"Name", "subtitleField": "BillingAddress", "object": "Account", "filter": "Name = \'Test Account\'", "searchTerm": "Test"}';
        
        Test.startTest();
        String responseString = strike_lookupController.getRecords(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');
        
        System.assertEquals(1, data.size());
        
        Map<String, Object> record = (Map<String, Object>)data.get(0);
        
        System.assertEquals(a.Id, record.get('value'));
    }
    
    @isTest static void test_getData_reference() {
       /* CrmId__c crm = new CrmId__c();
        crm.Name='1';
        insert crm;*/
        
        Account a = new Account(FirstName='Test Account', LastName= 'Test');
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        insert a;
        
        Account a2 = new Account(Name= 'Test');
        a2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        insert a2;
        
        Contact c = new Contact(
            LastName='Contact',
            FirstName='Test',
            AccountId = a2.Id);
        insert c;
        
        String jsonString = '{"searchField":"FirstName", "subtitleField": "Account.Name", "object": "Contact", "filter": "Name = \'Test Contact\'", "searchTerm": "Test"}';
        
        Test.startTest();
        String responseString = strike_lookupController.getRecords(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');
        
        System.assertEquals(1, data.size());
        
        Map<String, Object> record = (Map<String, Object>)data.get(0);
        
        System.assertEquals(c.Id, record.get('value'));
    }
}