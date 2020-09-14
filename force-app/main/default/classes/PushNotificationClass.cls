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
    public static List<Package__c> getInstrument(){
       // List<Package__c> packageList = new List<Package__c>();
       // map<String,Package__c> mapName = new map<String,Package__c>();
        Id lessonRecordType =Schema.SObjectType.Package__c.getRecordTypeInfosByDeveloperName().get('Lesson').getRecordTypeId();
        string query='select Name from Package__c where RecordTypeId=:lessonRecordType group by Name';
        return Database.query(query);
       /* for(Package__c pkg:Database.query(query)){
            mapName.put(pkg.Name,pkg);
        }    
        
        packageList.addAll(mapName.Values());
        system.debug('packageList'+packageList);
        for(Package__c pkg:Database.query(query)){
            if(mapName.containsKey(pkg.Name)){
                packageList.add(mapName.get(pkg.Name));
            }
        } 
        return packageList;*/   
    }
    @AuraEnabled
    public static List<Enrolment__c> getEnrolment(string teacherId,string CentreList,string InstrumentList){
        system.debug('teacherId'+teacherId);
       // Id lessonRecordType =Schema.SObjectType.Package__c.getRecordTypeInfosByDeveloperName().get('Lesson').getRecordTypeId();
        string query='select Id from Enrolment__c where Stage__c=\'Enrolled\' and Type__c=\'Regular\'';  
        if(string.isNotBlank(teacherId)){
                query += ' and Teacher__c =:teacherId';
            }
        if(string.isNotBlank(CentreList)){
            List<String> centreIdList = CentreList.split(',');
            query += ' and Center__c in :centreIdList';
        }
        if(string.isNotBlank(InstrumentList)){
            List<String> InstrumentIdList = InstrumentList.split(',');
            query += ' and Package__r.Name in :InstrumentIdList';
        }
		return Database.query(query);      
    }
    
    
}