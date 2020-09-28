/*
Name        :        PianoRentalPurchasePageV2ControllerTest
Date        :        28 Sep 2020
Author      :        Karan Singh Soni
Apex Class :        PianoRentalPurchasePageV2Controller
*/
@isTest
public class PianoRentalPurchasePageV2ControllerTest {
    
    //_________________________________________________________________  Test Setup ___________________________________________________________________
    @testSetup
    public static void createTestData(){ 
        
        
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = country.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        insert organisationRecord;  
        
        Account objCustmr=TestUtil.createAccount('Customer',true,False);
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        objCentr.Organisation__c = organisationRecord.id;
        objCentr.Organisation_Sharing__c ='Aureus Academy Singapore';
        insert objCentr;
        
        Account objTchr=TestUtil.createAccount('Teacher',false,false);
        objTchr.Personal_Email__c = 'Test@gmail.com';
        insert objTchr;
        
        List<Teacher_working_Hour__c> listTwh=TestUtil.createTeacher_Working_Hour(objTchr.Id, objCentr.Id,true,false,7);
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Package__c objPack2=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        
        Lead objLead =TestUtil.createLead(objCentr.Location__c, 'Website', 'testEmaillead@gmail.com', objCentr.id, false);
        objLead.IsConverted=false;
        insert objLead;
        objCustmr.Lead__c=objLead.id;
        objCustmr.Person_Email__c = 'test@xyz.com';
        insert objCustmr;
        
        Enrolment__C objEnrol=new Enrolment__C();
        objEnrol.Center__c=objCentr.id;
        objEnrol.Teacher__c=objTchr.id;
        objEnrol.Parent__c=objCustmr.id;
        objEnrol.Student__c=objCustmr.id;
        objEnrol.Package__c=objPack.id;
        objEnrol.Type__c='Instrument';
        objEnrol.Stage__c='Piano Rental Active';
        objEnrol.RecordTypeId = Schema.SObjectType.Enrolment__C.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();
        insert objEnrol;
        
        Booking__C objBook=Testutil.createBooking(objTchr.Id,'Lesson','Regular',False);
        objbook.Enrolment__c=objEnrol.id;
        insert objBook;
        
        Subscription__C objSubs=new Subscription__C();
        objSubs.Parent__c = objCustmr.Id;
        objSubs.Center__c = objCentr.Id;
        objSubs.Subscription_Start_Date__c = date.today();
        objSubs.Next_Bill_Date__c = date.today().addMonths(1);
        insert objSubs;
        
        Subscription_Line_Item__C objSLI  =new Subscription_Line_Item__C();
        objSLI.Subscription__c = objSubs.Id;
        objSLI.Enrolment__c = objEnrol.Id;
        objSLI.Next_Bill_Date__c = Date.newInstance(System.today().addMonths(1).year(), System.today().month() + 1, 1);
        objSLI.Status__c = 'Active';
        objSLI.Amount__c = 10.2;
        objSLI.Subscription_Start_Date__c = Date.newInstance(System.today().year(), System.today().month(), 1);
        insert objSLI;
        
    }//end of test setup
    
    public static testMethod void testMethod1(){
        
        List< Enrolment__c > listEnrol = [SELECT Id,Delivery_Charges__c,Teacher__c,Stair_Charges__c,Center__c FROM Enrolment__c ];
        if( listEnrol.size() == 0 ) return;
        
        listEnrol[0].Delivery_Charges__c = 10;
        listEnrol[0].Stair_Charges__c = 10;
        update listEnrol;
        
        ApexPages.StandardController sc = new ApexPages.StandardController( listEnrol[0] );
        PianoRentalPurchasePageV2Controller objPianoRentalController = new PianoRentalPurchasePageV2Controller(sc);
        
        PageReference pageRef = Page.PianoRentalPurchasePageV2;
        pageRef.getParameters().put('id', String.valueOf(listEnrol[0].Id));
        Test.setCurrentPage(pageRef);
        
        objPianoRentalController.sendEmailToPOS();

    }//end testMethod1
}