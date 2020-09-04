public class PushNotificationClass {

    @AuraEnabled
    public static List<Country__c> getCountry(){
		return [select Id,Country_Name__c from Country__c];        
    }
    
    @AuraEnabled
    public static List<Account> getCenter(string country){
        Id centerRecordType =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Centre').getRecordTypeId();
        string query='select Id,Name from Account where RecordTypeId=:centerRecordType';
        if(string.isNotBlank(country)){
            query += ' and Organisation__r.Country__c =:country';
       }else{
           query += ' and Organisation__r.Country__c !=:country';         
        }
		return Database.query(query);       
    }
    
     @AuraEnabled
    public static List<Account> getInstrument(){
        Id lessonRecordType =Schema.SObjectType.Package__c.getRecordTypeInfosByDeveloperName().get('Lesson').getRecordTypeId();
        string query='select Name from Package__c where RecordTypeId=:lessonRecordType group by Name';
		return Database.query(query);       
    }
}