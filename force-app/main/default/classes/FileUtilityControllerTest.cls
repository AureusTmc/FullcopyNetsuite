@isTest
public class FileUtilityControllerTest{
    @isTest
    public static void testUnit(){
        Account objAcc1 = new Account();
        string centerRecordType =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        objAcc1.name='testCenter';
        objAcc1.CentreName_Cust__c='testCenter'; 
        objAcc1.Travel_Time__c=60.00;
        objAcc1.Location__c='Aureus Forum';
        objAcc1.Center_Email__c='rajesh@techmatrixconsulting.com';
        objAcc1.Centre_Status__c='Active';
        insert objAcc1;
        
        Account objAcc = new Account();
        string s=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        objAcc.RecordTypeId =s; 
        objAcc.LastName='testEmployee';
        objAcc.Teacher_Bio__c='testbio';
        objAcc.CentreName_Cust__c='testCenter';
        objAcc.Status__c='Working';   
        objAcc.Employee_Status__c = 'Confirm';
        objAcc.Main_Centre__c = objAcc1.Id;
        objAcc.Joining_Date__c = Date.Today().addDays(-10);
        objAcc.Last_Working_Date__c = Date.today().addDays(10);
        objAcc.Issue_Date__c = Date.Today().addDays(-30);
        objAcc.ID_Type__c = 'Permanent Resident';
        objAcc.PersonBirthdate = date.today().addYears(-30);
        insert objAcc;  
        
        Documents__c doc = new Documents__c(Name = 'Employee Policy');
        insert doc; 
        
        Employee_Document__c eDoc = new Employee_Document__c(Document__c = doc.Id, Name = 'Employee Policy', Employee__c = objAcc.Id, Required__c = false, Stage__c = 'In Process');
        insert eDoc;
        
        string before = 'Testing base 64 encode';            
        Blob beforeblob = Blob.valueOf(before);
        //Insert contentdocument data
        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob; 
        cv.Employee_Document__c = eDoc.id;         
        insert cv;         
                                            
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        //insert new ContentDocumentLink
        ContentDocumentLink newFileShare = new ContentDocumentLink();
        newFileShare.contentdocumentid = testcontent.contentdocumentid;
        newFileShare.LinkedEntityId = eDoc.Id;
        newFileShare.ShareType= 'V';
        
        insert newFileShare;
        
        String json = '[{ "toUploadList": [{ "docList": [], "file_base64": "VGVzdCBTdHJpbmc=", "original_filename": "Winter_20_175x65_v1.png", "selectedDoc": "'+eDoc.id+'" }, { "docList": [], "file_base64": "", "original_filename": "", "selectedDoc": "-- Select --" }, { "docList": [], "file_base64": "", "original_filename": "", "selectedDoc": "-- Select --" }], "uploadedList": [{ "conv": { "Id": "'+cv.Id+'", "Title": "aureus.png", "Employee_Document__c": "'+eDoc.Id+'", "ContentDocumentId": "'+testcontent.contentdocumentid+'", "Employee_Document__r": { "Name": "Employee Policy", "Id": "'+eDoc.Id+'" } }, "file_base64": "", "original_filename": "" }] }]';
        Test.startTest();
        FileUtilityController.getDocumentMap(objAcc.Id);
        FileUtilityController.getFileList(objAcc.Id);
        FileUtilityController.addNewRow(objAcc.Id,json);
        
        
        FileUtilityController.saveFiles(objAcc.Id, json);
        FileUtilityController.updateFiles(objAcc.Id, json);
        FileUtilityController.removeFile(cv.Id, objAcc.Id, objAcc.Id);
        Test.StopTest();
    }
}