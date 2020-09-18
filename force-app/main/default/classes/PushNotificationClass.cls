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
        system.debug('----');
        return Database.query(query);  
             
    }
    
     @AuraEnabled
    public static List<Package__c> getInstrument(){
        List<Package__c> packageList = new List<Package__c>();
        map<String,Package__c> mapName = new map<String,Package__c>();
        Id lessonRecordType =Schema.SObjectType.Package__c.getRecordTypeInfosByDeveloperName().get('Lesson').getRecordTypeId();
        string query='select Name,Instrument__c  from Package__c where RecordTypeId=:lessonRecordType';
        //return Database.query(query);
        for(Package__c pkg:Database.query(query)){
            mapName.put(pkg.Instrument__c,pkg);
        }    
        
        packageList.addAll(mapName.Values());
       // system.debug('packageList'+packageList);
        /*for(Package__c pkg:Database.query(query)){
            if(mapName.containsKey(pkg.Instrument__c)){
                packageList.add(mapName.get(pkg.Instrument__c));
            }
        } */
        return packageList;   
    }
    @AuraEnabled
    public static List<Enrolment__c> getEnrolment(string teacherId,string CentreList,string InstrumentList,String title, String bodymsg,string imageURL,string buttonURL){
        List<ScheduleMobileNotificationRequest> notifications= new List<ScheduleMobileNotificationRequest>();
        List<Mobile_Notification__c> mobileNotificatoToCreate = new List<Mobile_Notification__c>();
        List<Marketing_Announcement__c> marketAnnounceToCreate = new List<Marketing_Announcement__c>();
       // Id lessonRecordType =Schema.SObjectType.Package__c.getRecordTypeInfosByDeveloperName().get('Lesson').getRecordTypeId();
        string query='select Id,Parent__r.FCM_Token__c,Parent__c from Enrolment__c where Stage__c=\'Enrolled\' and Type__c=\'Regular\'';  
        if(string.isNotBlank(teacherId)){
                query += ' and Teacher__c =:teacherId';
            }
        if(string.isNotBlank(CentreList)){
            List<String> centreIdList = CentreList.split(',');
            query += ' and Center__c in :centreIdList';
        }
        if(string.isNotBlank(InstrumentList)){
            List<String> InstrumentIdList = InstrumentList.split(',');
            query += ' and Package__r.Instrument__c in :InstrumentIdList';
        }
        Marketing_Announcement__c markerAnnouncementObj = new Marketing_Announcement__c();
        markerAnnouncementObj.Title__c=title;
        markerAnnouncementObj.Description__c=bodymsg;
        markerAnnouncementObj.Button_URL__c=buttonURL;
        markerAnnouncementObj.Image_URL__c=imageURL;
        markerAnnouncementObj.Teacher__c=String.isNotBlank(teacherId)?teacherId:NULL;
        markerAnnouncementObj.Center__c=String.isNotBlank(CentreList)?CentreList:NULL;
        markerAnnouncementObj.Instrument__c=String.isNotBlank(InstrumentList)?InstrumentList:NULL;
        
        marketAnnounceToCreate.add(markerAnnouncementObj);
        
        list<Enrolment__c> enrolList =Database.query(query);
        for(Enrolment__c enr:enrolList){
            Mobile_Notification__c mb = new Mobile_Notification__c();
            mb.Title__c=title;
            mb.Body__c=bodymsg;
            mb.Button_URL__c=buttonURL;
            mb.Image_Url__c=imageURL;
            mb.Customer_Name__c=enr.Parent__c;
            mobileNotificatoToCreate.add(mb);
            //notifications.add(new ScheduleMobileNotificationRequest(enr.Parent__c, enr.Parent__r.FCM_Token__c, title, bodymsg,true,imageURL,buttonURL));
        }
        if(notifications.size() > 0 && !System.isBatch() && !System.isFuture()) {		
            //Database.executeBatch(new ScheduleMobileNotificationBatch(notifications),90);		
        }
        try{
            if(mobileNotificatoToCreate.size()>0){
                insert mobileNotificatoToCreate;
            }
            if(marketAnnounceToCreate.size()>0){
                insert marketAnnounceToCreate;
            }
        }catch(Exception Ex){
            system.debug('---->>>>'+Ex.getMessage() +'====>>>>'+ex.getLineNumber());
        }
		return enrolList;      
    }
    
    @AuraEnabled
    public static string createProfileImage(String documentId){
        string url = createProfileData(documentId);        
        return url; 
    }
    
    public static string createProfileData(String documentId){
        Set<Id> setOfContentIds = new Set<Id>();        
        ContentVersion verDetails = [Select Id,VersionData From ContentVersion Where ContentDocumentId =:documentId LIMIT 1];//Here we are getting version detail for newly inserted doc        
        System.debug('verDetails--->'+verDetails);
        ContentVersion cv=verDetails;          
        
        //Attaching doc with DistributionLink to make doc publically by URL
        ContentDistribution cd = new ContentDistribution();
        cd.Name = 'Test';
        cd.ContentVersionId = cv.Id; 
        cd.PreferencesAllowViewInBrowser= true;
        cd.PreferencesLinkLatestVersion=true;
        cd.PreferencesNotifyOnVisit=false;
        cd.PreferencesPasswordRequired=false;
        cd.PreferencesAllowOriginalDownload= false;
        cd.PreferencesAllowPDFDownload = false;
        //cd.RelatedRecordId = parentId;
        insert cd;
        
        ContentDistribution contentDis = [SELECT DistributionPublicUrl,ContentVersionId,ContentDocumentId FROM ContentDistribution WHERE ID =: cd.Id];
        
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String orgId = '';
        List<Organization> orgList = Database.Query('select isSandbox, Id from organization');
        if(!orgList.isEmpty()){
            orgId = orgList[0].Id;
        } 
        String publicUrl = '';
        string versionId = contentDis.ContentVersionId;
        String urlToParse = contentDis.DistributionPublicUrl;                                                     
        String preUrl = baseUrl+'/sfc/dist/version/renditionDownload?rendition=';
        /*if(ContentDocumentlinkRec.ContentDocument.FileExtension == 'jpg' || ContentDocumentlinkRec.ContentDocument.FileExtension == 'jpeg'){
           preUrl  += 'ORIGINAL_Jpg';
        }else if(ContentDocumentlinkRec.ContentDocument.FileExtension == 'png'){*/
           preUrl  += 'ORIGINAL_Png';
        //}  
        preUrl  += '&contentId='+contentDis.ContentDocumentId+'&operationContext=DELIVERY&page=0&oid='+orgId+'&dpt=null&viewId=';
        list<String> imageIdList = urlToParse.split('/a/');
        publicUrl = preUrl+'&versionId='+versionId+'&d=/a/'+imageIdList[1];
        return publicUrl;
    }
    
    
}