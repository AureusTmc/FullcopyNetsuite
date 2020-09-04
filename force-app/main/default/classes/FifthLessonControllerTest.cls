@isTest
private class FifthLessonControllerTest {
    static testMethod void  fetchLessonDetails(){
       
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
        
        /*calling of create account method and generating its center*/
        Account objData = TestUtil.createAccount('Centre',false,FALSE);
        objData.Country__c = country.Id;
        insert objData;
        
        /*calling of create account method and generating its teacher*/
        Account objTchr = TestUtil.createAccount('Teacher',false,true);
        
        Account objCust = TestUtil.createAccount('Customer',false,true);       
        
        /*calling of create teacher_Working_Hour method which in turn is returning list of TeacherWorkingHour */
        List<Teacher_Working_Hour__c> workinghourList = TestUtil.createTeacher_Working_Hour(objTchr.id,objData.id,true,false,7);
        System.debug('My List:'+workinghourList);
        
      /*calling of create program method and generating program record*/
       Program__c objProg = TestUtil.createProgram('Active','Piano',true);
        System.debug(objProg.id);
        /*calling of create program method and generating package record*/
      Package__c objPack=testUtil.createPackage(objProg.id,objData.id,'45',true); 
        System.debug(objPack.id);
        
        /*calling of create program method and generating enrolment record*/
        Enrolment__c objEnrol = TestUtil.createEnrolment(objData.Id,objTchr.Id,objCust.Id,objPack.id,true);        
        
        /*calling of create Booking Method and generating booking record*/
        Booking__c objBook = TestUtil.createBooking(objTchr.id,'Lesson','Regular',false);
        
        /*creating a record for fifthlesson*/
        Fifth_Lesson__c fifthLesson = new Fifth_Lesson__c(Teacher_Account__c = objTchr.Id,Booking_Date__c = objBook.Booking_Date__c,Start_Time__c =objBook.Start_Time__c);
        insert fifthLesson;
        
       
        /*calling fetchLessonDetails method*/
         FifthLessonController.fetchLessonDetails(fifthLesson.id);
        
        /*calling bookingConvert method*/
         String success = FifthLessonController.bookingConvert(fifthLesson.id,'','placeholder',false);
     
        system.assert(String.isNotBlank(success), 'Placeholder booking failed');
        
    }

}