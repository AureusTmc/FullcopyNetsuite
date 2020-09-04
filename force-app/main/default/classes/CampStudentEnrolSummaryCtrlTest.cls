/**
* Name: CampPackagesDetailCtrlTest
* Author: Jatin
* Date : 11-March-2020
* Description: this class Used to test CampPackagesDetailCtrlTest controller class
*/
@isTest
public class CampStudentEnrolSummaryCtrlTest {
    
    @testSetup
    private static void createData() {
        
        CampEnrolmentTestHelper.createCampData();
        
    }
    
    public static CampDetailsForEnrolStudentController createCampDetailsForEnrolStudentController(CampDetailsForEnrolStudentController objController,Account stuObj,list<Camp__c> lstCamp,list<Camp_Available_Package__c> lstPackages,list<Camp_Days__c> lstCampDays){
        List<CampDetailsForEnrolStudentController.StudentDetail> listOfStudentDetail = new List<CampDetailsForEnrolStudentController.StudentDetail>();
        CampDetailsForEnrolStudentController.StudentDetail objStudentDetail = new CampDetailsForEnrolStudentController.StudentDetail();
        List<CampDetailsForEnrolStudentController.student> listOfStudent = new List<CampDetailsForEnrolStudentController.Student>();
        
        CampDetailsForEnrolStudentController.student objStudentWrapper = new CampDetailsForEnrolStudentController.Student();
        objStudentWrapper.id = '1';
        objStudentWrapper.FirstName = stuObj.FirstName;
        objStudentWrapper.LastName = stuObj.LastName;
        objStudentWrapper.FullName = stuObj.Name;
        objStudentWrapper.BirthDate = stuObj.PersonBirthdate.day()+'/'+stuObj.PersonBirthdate.month()+'/'+stuObj.PersonBirthdate.year();
        objStudentWrapper.Gender = stuObj.Gender__c;
        objStudentWrapper.stuPreExperience ='No';
        objStudentWrapper.stuFoodAllergy = 'No';
        objStudentDetail.student = objStudentWrapper;
        objStudentDetail.packageId = lstPackages[0].id;
        objStudentDetail.selectedPackageName = lstPackages[0].Name;
        List<CampDetailsForEnrolStudentController.CampDays> listOfCampDays = new List<CampDetailsForEnrolStudentController.CampDays>();
        integer index =1; 
        List<String> campDates = new List<string>();
        for(Camp_Days__c objCamp_Days : lstCampDays) {
            CampDetailsForEnrolStudentController.CampDays objCampDays = new CampDetailsForEnrolStudentController.CampDays();
            objCampDays.campDay= string.ValueOf(index);
            objCampDays.campId = objCamp_Days.id;
            objCampDays.campDate = string.ValueOf(objCamp_Days.Dates_Of_The_Camp__c);
            listOfCampDays.add(objCampDays);
            index++;
            campDates.add(DateTime.newInstance(objCamp_Days.Dates_Of_The_Camp__c,objCamp_Days.Camp_Start_Time__c).format('MMM dd, yyyy'));
        }
        objStudentDetail.campDays = listOfCampDays;
        objStudentDetail.campDates = String.join(campDates,';');
        listOfStudentDetail.add(objStudentDetail);
        objController.selCountryCode = lstCamp[0].Centre__r.Country__r.Currency_Code__c;
        objController.isAureusAtHome = false;
        objController.travelDuration = 0;
        objController.centerName = lstCamp[0].Centre__c;
        objController.selectedCampId  =lstCamp[0].id;
        objController.centerId =lstCamp[0].Centre__c;
        objController.studentDetails =Json.serialize(listOfStudentDetail);
        objController.fetchExistingStuDetail();
        return objController;
    }
    private static testMethod  void test_StudentExistAndSiteUser(){
        CampDetailsForEnrolStudentController objController = new CampDetailsForEnrolStudentController();
        list<Camp__c> lstCamp= [SELECT Id,Centre__c,Centre__r.Country__r.Currency_Code__c, Name
                                FROM Camp__c
                                Where Status__c =:ConstantsClass.campActiveStatus];
        list<Camp_Available_Package__c> lstPackages = [SELECT Id, Name,No_of_days__c FROM Camp_Available_Package__c 
                                                       where Camp_Name__c =:lstCamp[0].id 
                                                       and Active__c= true  
                                                       Order by No_of_days__c DESC];
        
        list<Camp_Days__c> lstCampDays = [ SELECT Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                          FROM Camp_Days__c 
                                          where Camp_Name__c =: lstCamp[0].id 
                                          and Status__c ='Active'
                                          Order by Dates_Of_The_Camp__c];
        
        List<Account> stuList = [SELECT Id,Name,Centre_Name__c,PersonEmail,Lastname,FirstName,PersonBirthdate,Gender__c 
                                 FROM Account 
                                 where recordtype.Name='Customer']; 
        List<Account> listOfAccount = new List<Account>();
        listOfAccount.add(new Account(Parent__c = stuList[0].id,id=stuList[1].id));
        update listOfAccount;
        objController.parentAcc = new Account(FirstName=stuList[0].FirstName,Lastname =stuList[0].LastName,PersonEmail =stuList[0].PersonEmail);
        objController = createCampDetailsForEnrolStudentController(objController,stuList[0],lstCamp,lstPackages,lstCampDays);
        system.assertEquals(true,String.isnotBlank(objController.accountModalDetails),'AccountModalDetails List is Empty');
        CampStudentEnrolSummaryCtrl objCampStudentEnrolSummaryCtrl = new CampStudentEnrolSummaryCtrl();
        objCampStudentEnrolSummaryCtrl.accountModalDetails =objController.accountModalDetails;
        objCampStudentEnrolSummaryCtrl.getEnrolStudentDetails();
        objCampStudentEnrolSummaryCtrl.createParentDetails();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        Test.setMock(HttpCalloutMock.class, new PandaDocUtilityTestMocks());
        objCampStudentEnrolSummaryCtrl.signAgreement();
        objCampStudentEnrolSummaryCtrl.waitAgreement();
        objCampStudentEnrolSummaryCtrl.sendAgreement();
        objCampStudentEnrolSummaryCtrl.createSession();
        objCampStudentEnrolSummaryCtrl.saveParentCardDetailsSiteUser();
        test.stopTest();
        
        
    }
    private static testMethod  void test_StudentExistAndInternalUserUserStripe(){
        CampDetailsForEnrolStudentController objController = new CampDetailsForEnrolStudentController();
        CampDetailsForEnrolStudentController.AccountModal objAccModal = new CampDetailsForEnrolStudentController.AccountModal();
        list<Camp__c> lstCamp= [SELECT Id,Centre__c,Centre__r.Country__r.Currency_Code__c, Name
                                FROM Camp__c
                                Where Status__c =:ConstantsClass.campActiveStatus];
        list<Camp_Available_Package__c> lstPackages = [SELECT Id, Name,No_of_days__c FROM Camp_Available_Package__c 
                                                       where Camp_Name__c =:lstCamp[0].id 
                                                       and Active__c= true  
                                                       Order by No_of_days__c DESC];
        
        list<Camp_Days__c> lstCampDays = [ SELECT Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                          FROM Camp_Days__c 
                                          where Camp_Name__c =: lstCamp[0].id 
                                          and Status__c ='Active'
                                          Order by Dates_Of_The_Camp__c];
        
        List<Account> stuList = [SELECT Id,Name,Centre_Name__c,PersonEmail,Lastname,FirstName,PersonBirthdate,Gender__c 
                                 FROM Account 
                                 where recordtype.Name='Customer']; 
        List<Account> listOfAccount = new List<Account>();
        listOfAccount.add(new Account(Parent__c = stuList[0].id,id=stuList[1].id));
        listOfAccount.add(new Account(id = stuList[0].id,Stripe_Customer_Id__c='sk_test_BQokikJOvBiI2HlWgH4olfQ2',Card_Number__c = '3155', Card_Type__c = 'Visa'));
        update listOfAccount;
        objController.parentAcc = new Account(FirstName=stuList[0].FirstName,Lastname =stuList[0].LastName,PersonEmail =stuList[0].PersonEmail);
        Attachment attachment = new Attachment();
        attachment.Body = Blob.valueOf('Body');
        attachment.Name = 'test.pdf';
        attachment.contentType = 'application/pdf';
        attachment.ParentId = stuList[0].id; 
        insert attachment;
        objController = createCampDetailsForEnrolStudentController(objController,stuList[0],lstCamp,lstPackages,lstCampDays);
        system.assertEquals(true,String.isnotBlank(objController.accountModalDetails),'AccountModalDetails List is Empty');
        CampStudentEnrolSummaryCtrl objCampStudentEnrolSummaryCtrl = new CampStudentEnrolSummaryCtrl();
        objCampStudentEnrolSummaryCtrl.pandaDocAttachmentName = 'test';
        objCampStudentEnrolSummaryCtrl.accountModalDetails =objController.accountModalDetails;
        objCampStudentEnrolSummaryCtrl.getEnrolStudentDetails();
        objCampStudentEnrolSummaryCtrl.createParentDetails();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "paid": true,"id":"cus_EmndZcxxpUhDzD", "object": "customer", "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
        objCampStudentEnrolSummaryCtrl.saveParentCardDetailsAndGenerateInvoice();
        test.stopTest();
    }
    
    private static testMethod  void test_StudentNotExistAndInternalUserUserStripe(){
        CampDetailsForEnrolStudentController objController = new CampDetailsForEnrolStudentController();
        CampDetailsForEnrolStudentController.AccountModal objAccModal = new CampDetailsForEnrolStudentController.AccountModal();
        list<Camp__c> lstCamp= [SELECT Id,Centre__c,Centre__r.Country__r.Currency_Code__c, Name
                                FROM Camp__c
                                Where Status__c =:ConstantsClass.campActiveStatus];
        list<Camp_Available_Package__c> lstPackages = [SELECT Id, Name,No_of_days__c FROM Camp_Available_Package__c 
                                                       where Camp_Name__c =:lstCamp[0].id 
                                                       and Active__c= true  
                                                       Order by No_of_days__c DESC];
        
        list<Camp_Days__c> lstCampDays = [ SELECT Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                          FROM Camp_Days__c 
                                          where Camp_Name__c =: lstCamp[0].id 
                                          and Status__c ='Active'
                                          Order by Dates_Of_The_Camp__c];
        
        List<Account> stuList = [SELECT Id,Name,Centre_Name__c,PersonEmail,Lastname,FirstName,PersonBirthdate,Gender__c 
                                 FROM Account 
                                 where recordtype.Name='Customer']; 
        List<Account> listOfAccount = new List<Account>();
        listOfAccount.add(new Account(Parent__c = stuList[0].id,id=stuList[1].id));
        listOfAccount.add(new Account(id = stuList[0].id,Stripe_Customer_Id__c='sk_test_BQokikJOvBiI2HlWgH4olfQ2',Card_Number__c = '3155', Card_Type__c = 'Visa'));
        update listOfAccount;
        objController.parentAcc = new Account(FirstName='Jatin',Lastname ='Motiyani Parent' ,PersonEmail ='test@tmc.com');
        objController = createCampDetailsForEnrolStudentController(objController,stuList[0],lstCamp,lstPackages,lstCampDays);
        system.assertEquals(true,String.isnotBlank(objController.accountModalDetails),'AccountModalDetails List is Empty');
        CampStudentEnrolSummaryCtrl objCampStudentEnrolSummaryCtrl = new CampStudentEnrolSummaryCtrl();
        objCampStudentEnrolSummaryCtrl.accountModalDetails =objController.accountModalDetails;
        objCampStudentEnrolSummaryCtrl.getEnrolStudentDetails();
        objCampStudentEnrolSummaryCtrl.createParentDetails();
        
        test.startTest();
        objCampStudentEnrolSummaryCtrl.stripeToken='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "paid": true,"id":"cus_EmndZcxxpUhDzD", "object": "customer", "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
        objCampStudentEnrolSummaryCtrl.saveParentCardDetailsAndGenerateInvoice();
        test.stopTest();
    }
    
    private static testMethod  void test_Aggrement(){
         test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "R33xS4Ybe3qtBbRyke2p6a", "name": "[DEV] Enr-13456-RentalPolicy", "date_created": "2020-01-22T08:20:58.179132Z", "date_modified": "2020-01-22T08:20:58.652923Z", "template": { "id": "5jfk4yvnNWaqsjmg4tdnbm", "name": "Delivery Order Template" }, "tokens": [{ "name": "Delivery_Person.FirstName" }], "fields": [{ "uuid": "NmobNHTwG6fdu5bVcnAUbZ", "name": "Stairs", "title": "Stairs", "assigned_to": { "id": "QpQRqhYV4k9K95kAqrgaof", "first_name": "Ashish", "last_name": "Bansal", "email": "ashish@outlook.com", "recipient_type": "signer", "has_completed": false, "role": "Delivery_Person", "type": "recipient" }, "value": "0" }] }'));
        CampStudentEnrolSummaryCtrl objCampStudentEnrolSummaryCtrl = new CampStudentEnrolSummaryCtrl();
        PandaDocUtility.CreateDocument documentDetails = new PandaDocUtility.CreateDocument();
        documentDetails.id ='R33xS4Ybe3qtBbRyke2p6a';
        objCampStudentEnrolSummaryCtrl.documentDetails =documentDetails;
        objCampStudentEnrolSummaryCtrl.personEmail ='test@test.com';
        objCampStudentEnrolSummaryCtrl.waitAgreement();
        objCampStudentEnrolSummaryCtrl.sendAgreement();
        objCampStudentEnrolSummaryCtrl.createSession();
        objCampStudentEnrolSummaryCtrl.agreementCheckbox =true;
        test.stopTest();
    }
}