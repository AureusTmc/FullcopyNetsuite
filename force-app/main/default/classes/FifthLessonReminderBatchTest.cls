/*
Name        :        FifthLessonReminderBatchTest
Date        :        24 Septmber 2019
Author      :        
Description :        It is the test class of FifthLessonReminderBatch.
*/
@isTest
private class FifthLessonReminderBatchTest{
    
    @testSetup
    // Insert Email Template data
    static void emailSetup(){
        EmailTemplate et = new EmailTemplate ();
        et.developerName = 'FifthLessonReminderFor10Days';
        et.isActive = true; 
        et.Name = 'FifthLessonReminderFor10Days'; 
        et.TemplateType = 'Text';  
        et.FolderId = UserInfo.getUserId(); 
        insert et; 
        System.debug('email Name is'+et.DeveloperName);
    }
    @isTest
    static void invokeFifthLessonReminder(){ 
        String CRON_EXP = '0 0 0 15 3 ? *';
        Integer numberOfdays = 10;
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
        
        //updated by @nishi 17 sep 2020
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
        
        Account objCentr = TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        //updated by @nishi 17 sep 2020
        objCentr.Organisation__c = organisationRecord.id;
        objCentr.Organisation_Sharing__c ='Aureus Academy Singapore';
        INSERT objCentr;
        
      	Account objTeachr = TestUtil.createAccount('Teacher',false,true);
      	Account objCustmr = TestUtil.createAccount('Customer',True,true);
       Program__C objProg = TestUtil.createProgram('Active','Piano',true);
        Package__c objPack = TestUtil.createPackage(objProg.id,objCentr.id,'45',true);
        Enrolment__c objENrol = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true);
        if(numberOfdays == 15){
            Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c = Date.today().addDays(15),Parent__c = objCustmr.Id,
                                                                  Enrolment__c = objENrol.Id,Package__C=objPack.id,Start_Time__c = time.newInstance(13,00,00,00),
                                                                  End_Time__c  =time.newInstance(13,45,00,00));
            insert objFifthLesson;
        }
        if(numberOfdays == 10){
            Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c = Date.today().addDays(10),Parent__c = objCustmr.Id,
                                                                  Enrolment__c = objENrol.Id,Package__C=objPack.id,Start_Time__c = time.newInstance(13,00,00,00),
                                                                  End_Time__c  =time.newInstance(13,45,00,00));
            insert objFifthLesson;
        }
        Test.startTest();
        	String jobId = System.schedule('FifthLessonReminderBatchSchedular10Days',  CRON_EXP, new FifthLessonReminderBatchSchedular10Days());
        	String jobId2 = System.schedule('FifthLessonReminderBatchSchedular15Days',  CRON_EXP, new FifthLessonReminderBatchSchedular15Days());
        Test.stopTest();
        //Calling FifthLessonReminder Batch class     
        
    } 
    
}