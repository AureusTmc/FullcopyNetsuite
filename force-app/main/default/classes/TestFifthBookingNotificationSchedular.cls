@isTest
public class TestFifthBookingNotificationSchedular {
    
    @isTest
    public static void invokeTestFifthBookingNotificationSchedular(){
        //updated by @nishi 18 sep 2020
        Country__c country = new Country__c();
        country.Name = 'IN';
        country.Country_Name__c = 'India';  
        country.Currency_Code_PI__c = 'SGD';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'INR';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        //updated by @nishi 18 sep 2020
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
        
        Account objtchr=TestUtil.createAccount('Teacher',false,true);
        Account objCustmr=TestUtil.createAccount('Customer', True, true);
        
        objCustmr.FCM_Token__c = 'test';
        update objCustmr; 
        //updated by @nishi 18 sep 2020
        Account objCustmrCentre = TestUtil.createAccount('Centre', false, false);
        objCustmrCentre.Country__c = country.Id;
        objCustmrCentre.Center_Email__c =  'Test@gmail.com';
        objCustmrCentre.Organisation__c = organisationRecord.id;
        objCustmrCentre.Organisation_Sharing__c ='Aureus Academy Singapore';
        Insert objCustmrCentre;
        //updated by @nishi 18 sep 2020
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCustmrCentre.id,'60',true); 
        Enrolment__c objENrol=TestUtil.createEnrolment(objCustmrCentre.Id,objtchr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c = 'Trial';
        objEnrol.Stage__c = 'Requested';
        
        insert objENrol;
        
        Booking__c objBook=TestUtil.createBooking(objtchr.id,'Lesson','Regular', False);
        Fifth_Lesson__c lesson = new Fifth_Lesson__c();
        lesson.Parent__c = objCustmr.id;
        lesson.Student__c = objCustmr.id;
        lesson.Booking_Date__c = date.newInstance(system.today().year(), system.today().month(),29);
        lesson.start_time__c = System.now().time();
        lesson.Center__c =objCustmrCentre.id;
        insert lesson;
        FifthBookingNotificationSchedular objFifthBookRem= new FifthBookingNotificationSchedular();
        objFifthBookRem.execute(null);
    }
    ///added by nishi: 26-Sep-2020: for manage ossia teacher changes
     @isTest
    public static void testOssiachanges(){
        //updated by @nishi 18 sep 2020
        Country__c country = new Country__c();
        country.Name = 'IN';
        country.Country_Name__c = 'India';  
        country.Currency_Code_PI__c = 'SGD';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'INR';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        //updated by @nishi 18 sep 2020
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Ossia Music School Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = country.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        Insert organisationRecord;
        
        Account objtchr=TestUtil.createAccount('Teacher',false,true);
        objtchr.Engagement_Type__c = 'Commission';
        update objtchr;
        Account objCustmr=TestUtil.createAccount('Customer', True, true);
        
        objCustmr.FCM_Token__c = 'test';
        update objCustmr; 
        //updated by @nishi 18 sep 2020
        Account objCustmrCentre = AureusCalendarControllerTestHelper.createCentre('Ossia Loyang Point', country.Id,FALSE);
        objCustmrCentre.Center_Email__c =  'Test@gmail.com';
        objCustmrCentre.Organisation__c = organisationRecord.id;
        objCustmrCentre.Organisation_Sharing__c ='Ossia Music School Singapore';
        Insert objCustmrCentre;
        //updated by @nishi 18 sep 2020
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCustmrCentre.id,'60',true); 
        Enrolment__c objENrol=TestUtil.createEnrolment(objCustmrCentre.Id,objtchr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c = 'Trial';
        objEnrol.Stage__c = 'Requested';
        
        insert objENrol;
        
        Booking__c objBook=AureusCalendarControllerTestHelper.createBooking(objtchr.id,objENrol.Id,objCustmrCentre.id,objCustmrCentre.Id,objPack.id,date.today(),'Pending','Lesson','Regular',false);
        Fifth_Lesson__c lesson = new Fifth_Lesson__c();
        lesson.Parent__c = objCustmr.id;
        lesson.Student__c = objCustmr.id;
        lesson.Booking_Date__c = date.newInstance(system.today().year(), system.today().month(),29);
        lesson.start_time__c = System.now().time();
        lesson.Center__c =objCustmrCentre.id;
        lesson.Enrolment__c =objENrol.id;
        lesson.IsActive__c = true;
        insert lesson;
        FifthBookingNotificationSchedular objFifthBookRem= new FifthBookingNotificationSchedular();
        objFifthBookRem.execute(null);
    }
}