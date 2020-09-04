/*
Name        :        FifthLessonBefore6DaysBatchTest
Date        :        10/14/2019
Author      :        
Description :        It is the test class of FifthLessonBefore6DaysBatch.
*/
@isTest
public class FifthLessonBefore6DaysBatchTest {
    @isTest
    static void invokeFifthLessonCreation(){ 
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
        Account objCentr = TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
      	Account objTeachr = TestUtil.createAccount('Teacher',false,true);
      	Account objCustmr = TestUtil.createAccount('Customer',True,true);
      	Program__C objProg = TestUtil.createProgram('Active','Piano',true);
        Package__c objPack = TestUtil.createPackage(objProg.id,objCentr.id,'45',true);
        
        Enrolment__c objENrol = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,FALSE);
        objENrol.Parent__c = objCustmr.Id;
        objENrol.Lesson_Day__c = 'Tuesday';
        INSERT objENrol;
        
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c = Date.newInstance(2019, 10, 29),Parent__c = objCustmr.Id,Student__c = objCustmr.Id,
                                                              Enrolment__c = objENrol.Id, Start_Time__c = objENrol.Lesson_Start_time__c, End_Time__c = objENrol.Lesson_Start_time__c.addMinutes(45),
                                                              Teacher_Account__c = objENrol.Teacher__c, Center__c = objENrol.Center__c, Package__c = objPack.Id);
            insert objFifthLesson;

        Test.startTest();
			Database.executeBatch(new FifthLessonBefore6DaysBatch(Date.newInstance(2019, 10, 23)))  ;      
        	String jobId = System.schedule('FifthLessonBefore6DaysSchedular',  CRON_EXP, new FifthLessonBefore6DaysSchedular());
        Test.stopTest();    
    }
}