@isTest
private class ConvertToMakeupTest{
    @isTest
    static void InsertConvertToMakeup(){
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
        
        Account objCustmr = TestUtil.createAccount('Customer',True,FALSE);
        objCustmr.Available_Make_up_Units__c = 100;
        INSERT objCustmr;
        
        Program__C objProg = TestUtil.createProgram('Active','Piano',true);
        
        Package__c objPack = TestUtil.createPackage(objProg.id,objCentr.id,'45',true);
        Enrolment__c objENrol = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true);
        Booking__c bookingObj = TestUtil.createBooking(objTeachr.Id, 'Lesson','Regular',FALSE); 
        bookingObj.Package__c = objPack.Id;
        INSERT bookingObj;
        System.debug('@@@Booking object is'+bookingObj);
        
        /*Test.startTest();
        System.debug(AureusCalendarController.cancelBooking(bookingObj.Id,'','Personal Reason','Test Remark','false','false','false'));
        Test.stopTest();*/
        
        
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c = Date.Today(),Start_Time__c = objENrol.Lesson_Start_time__c,
                                                              End_Time__c = objENrol.Lesson_Start_time__c.addMinutes(45),Parent__c = objCustmr.Id);
        insert objFifthLesson;
        System.debug('@@@'+objFifthLesson);

        ConvertToMakeup makupObj = new ConvertToMakeup(objFifthLesson.Id,'',true);
        makupObj.convertFifthLesson();
    }
}