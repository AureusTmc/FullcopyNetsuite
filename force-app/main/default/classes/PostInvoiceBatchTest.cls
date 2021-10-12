/*
Name        :        PostInvoiceBatchTest
Date        :        27 June 2019
Description :        It is the test class of PreInvoiceBatch.
*/
@isTest
public class PostInvoiceBatchTest {
    @isTest
    public static void invokePostInvoiceBatch(){
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Available_Make_up_Units__c=30;
        insert objCustmr;
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        DateTime dt = System.today();
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
          /**added by nishi: 25-Sep-2020: for added organisation*/
        // create organisation
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = country.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        Insert organisationRecord;  
        
        Account objCentr=TestUtil.createAccount('Centre',false,false);
        objCentr.Country__c=country.id;
        //add by @nishi 25 sep 2020
        objCentr.Organisation__c = organisationRecord.id;
        objCentr.Organisation_Sharing__c ='Aureus Academy Singapore';
        insert objCentr;
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',false);
        objPack.Offer_Start_Date__c = System.today();
        objPack.Offer_End_Date__c = System.today().addDays(5);
        objPack.Type_of_package__c = 'Prepayment';
        objPack.Promotion_period_In_months__c = '6';
        objPack.Promotion_Discount__c = 100.00;
        objPack.Package_Fee__c = 300.00;
        insert objPack; 
        Enrolment__c objEnrol=TestUtil.createEnrolment(objCentr.id,objTchr.id,objCustmr.id,objPack.id,False);
        objEnrol.Lesson_Day__c= /*dt.format('EEEE')*/'Saturday';
        objEnrol.Stage__c='Enrolled';
        objenrol.Student__c = objCustmr.Id;
        objenrol.Parent__c = objCustmr.Id;
        objenrol.Lessons_Start_Date__c =date.today().addmonths(-1);
        insert objEnrol;
        
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Enrolment__c=objEnrol.id;
        objSubsLine.Plan_Package__c=objPack.id;
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine;
        
        Invoice__C objINV=TestUtil.createInvoice(objCustmr.Id,False);
        objINV.Due_Date__c=Date.today();
        objINV.Center__c = objCentr.Id;
        objINV.Status__c='Due';
        objINv.Admin_Fees__c=60;
        insert objINV;
        
        Invoice_Line_Item__c objINVline=TestUtil.createInvLineItem(objInv.Id,false);
        objINVline.Amount__c=30;
        objINVline.Discount_Amount__c=20;
        objINVline.Is_Deposit__c=false;
        objINVline.Enrolment__c=objEnrol.id;
        insert objINVline;
        
        Set<String> invoiceSet = new Set<String>();
        invoiceSet.add(objINV.Id);
        
        Test.startTest();
        String jobId = System.schedule('PostInvoiceBatchSchedular',  CRON_EXP, new PostInvoiceBatchSchedular());
        Database.executeBatch(new PostInvoiceBatch(new Set<string>{objEnrol.id}), 200);
        Test.stopTest();
    }	
    
    @isTest
    //Modify by jatin 3 March 2020
    public static void invokePostInvoiceBatchForGroupClass(){
        ClassEditControllerTestHelper.createGroupClassData();
        enrolment__c objEnrol = [select id,class__c from enrolment__c limit 1];
        
        List<Booking__c> lstBookings = [SELECT Id, Start_Time__c, Group_Class__c,end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                        Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                        Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c, Is_Fifth_Booking__c ,
                                        Class__c
                                        FROM Booking__c 
                                        WHERE Type__c = :ConstantsClass.groupTypeBooking
                                        AND Status__c != :ConstantsClass.statusCanceled
                                        AND Class__c =: objEnrol.Class__c
                                       ];
        lstBookings[0].Booking_Date__c = System.today().addMonths(13);
        update lstBookings[0];
        Test.startTest();
        Database.executeBatch(new PostInvoiceBatch(new Set<string>{objEnrol.id}), 200);
        Test.stopTest();
    }
    @isTest
    public static void testPianoRentalTestHelper(){
        PianoRentalTestHelper.createPianoRentalData();
        enrolment__c objEnrol = [select id,class__c from enrolment__c limit 1];
        
        Test.startTest();
        Database.executeBatch(new PostInvoiceBatch(new Set<string>{objEnrol.id}), 200);
        Test.stopTest();
    }
}