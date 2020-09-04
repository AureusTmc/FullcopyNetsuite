/*
Name        :        AccountControllerTest
Date        :        12,22 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of AccountController.
*/

@isTest
public class AccountControllerTest {
    public static testMethod void invokeAccountController(){
        Country__c cntry = new Country__c();
        cntry.Name = 'SG';
        cntry.Country_Name__c ='Singapore';
        cntry.Currency_Code__c ='SGD';
        cntry.Tax_Rate__c = 7;
        cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        cntry.Stripe_Base_Url__c ='https://api.stripe.com';
        cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        insert cntry;  
        
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c = cntry.Id;
        Insert objCentr;
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        
        insert objENrol;
        
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        ObjBook.Enrolment__c=objEnrol.id;
        objBook.Center__c=objCentr.Id;
        objBook.Booking_Date__c=System.today();
        
        insert objBook;
        
        User objUser=TestUtil.createUser(True);
        Centre_Users__c objCentrUser= new Centre_Users__c();
        objCentrUser.Centre_Name__c=objCentr.Id;
        objCentrUser.User_Name__c=objUser.Id;
        insert objCentrUser;
        
        Task objTask=new Task();
        //objTask.OwnerId=objUser.Id;
        objTask.OwnerId=UserInfo.getUserId();
        objTask.Status='Open';
        objTask.ActivityDate=Date.today().addDays(2);
        objtask.Priority='High';
        insert objTask;
        
        Case objCase=new Case();
        objCase.Enrolment__c=ObjEnrol.id;
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        objCase.Status='New';
        objCase.Origin='Email';
        insert objCase;
        
        AccountController.fetchAccount();
        AccountController.findTask(objCentr.id,'');  
        AccountController.updatePendingEnrolmentStage('Confirm', ObjEnrol.id);
        //AccountController.updateStage('Confirm',objEnrol.Id,objCentr.Id);
        AccountController.updateTaskStage(objTask.id,' descriptionTask');      
        //AccountController.findBooking(objCentr.Id);
        
        objEnrol.Stage__c='Enrolled';
        objEnrol.Type__c='Regular';
        objEnrol.Enrolment_Created_Date__c = System.today();
        update objEnrol;
        
        AccountController.findRegularBooking(objCentr.Id,'');
        //AccountController.findBookedBooking(objCentr.Id,'');    As somebody change the object field
        //same with findBookedBooking
        
        
        objEnrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        update objEnrol;
        AccountController.findPendingEnrolmentCase(objCase.Id);
        AccountController.findDateList();
        AccountController.findUserList();
        //AccountController.findApprovalRequest('searchKey');
        AccountController.findCases(objCentr.id);
        AccountController.findAllNullCases(objCentr.id);
        AccountController.findSalesEnquiryCases(objCentr.id);
         // Added By Ravi
        Invoice__c objInvoice = TestUtil.createInvoice(objCustmr.Id,false); 
        objInvoice.Center__c=objCentr.Id;
        objInvoice.Status__c='Due';
        Insert objInvoice;
        AccountController.findInvoices(objCentr.Id,true);
        AccountController.findInvoices('',true);
         // Added By Ravi
        
        objEnrol.Type__c='Regular';
        update objEnrol;
        AccountController.getChartMap(objCentr.id);
        AccountController.getUser();
        
        objCase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId();
        update objCase;
        AccountController.updateOwner(objCase.Id);
        
        objCase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseServiceEnqRecTypeName).getRecordTypeId();
        update objCase;
        AccountController.updateServiceOwner(objCase.Id);
        AccountController.updateAllNullOwner(objCase.Id);
        
        
        objCentrUser.User_Name__c=UserInfo.getUserId();
        Update objCentrUser;
		
        AccountController.setDefaultLocation(objCentr.id);
    }
    
    // Added By Ravi
        public static testMethod void invokeAccContr(){
            Country__c cntry = new Country__c();
            cntry.Name = 'SG';
            cntry.Country_Name__c ='Singapore';
            cntry.Currency_Code__c ='SGD';
            cntry.Tax_Rate__c = 7;
            cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
            cntry.Stripe_Base_Url__c ='https://api.stripe.com';
            cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
            cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
            insert cntry;  
            
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,False);
        objCentr.Country__c = cntry.Id;
        Insert objCentr;
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        insert objENrol;
        Booking__c objBook=TestUtil.createBooking(objtechr.Id,ConstantsClass.recordTypeLesson,'Trial',false);
        objBook.Enrolment__c=objENrol.Id;
        Insert objBook;
        Invoice__c objInvoice = TestUtil.createInvoice(objCustmr.Id,false); 
        objInvoice.Center__c=objCentr.Id;
        objInvoice.Status__c='Due';
        Insert objInvoice;
        
        AccountController.updatePendingEnrolmentStage('Reject', ObjEnrol.id);
        AccountController.findInvoices(objCentr.Id,false);
        AccountController.findInvoices('',false);    
        AccountController.findRegularBooking(objCentr.Id,'Last 7 Days');
        AccountController.findRegularBooking(objCentr.Id,'Last 30 Days');
        AccountController.findMakeUpBooking(objCentr.Id);     
    }
     // Added By Ravi
}