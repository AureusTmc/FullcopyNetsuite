@isTest
private class ConvertToAdhocTest {
    static testMethod void convertToAdhoc(){
        
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
        
        Account objCentr=TestUtil.createAccount('Centre',false,false);
        objCentr.Country__c=country.id;
        insert objCentr;
        
        Account objCustmr=TestUtil.createAccount('Customer',true,False);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
        
        Account objTchr=TestUtil.createAccount('Teacher',false,false);
        objTchr.Minor_Instruments_Disciplines__c='Piano';
        insert objTchr;
        
        //  Enrolment__c enrolRecord = TestUtil.createEnrolment(true); 
        // insert enrolRecord;
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPackTypeAdhoc = testUtil.createPackage(objProg.id,objCentr.id,'45',FALSE);
        objPackTypeAdhoc.Type__c = 'Adhoc';
        Insert objPackTypeAdhoc;
        //Package__c objPackTemp=testUtil.createPackage(objProg.id,objCentr.id,'60',true);
        List<Teacher_working_Hour__c> listTwh=TestUtil.createTeacher_Working_Hour(objTchr.Id, objCentr.Id,false,true,7);
        // Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTchr.Id,objCustmr.Id,objPack.id,true);
        
        /* Booking__c objBook = TestUtil.createBooking(objTchr.Id,'Lesson','Regular',false);
        Booking__c busyBook = TestUtil.createBooking(objTchr.Id,'Lesson','busy',false);
        busyBook.Status__c = 'Scheduled';
        busyBook.Start_Time__c=Time.newInstance(10,0,0,0);
        busyBook.End_Time__c=Time.newInstance(11,0,0,0);
        insert busyBook;
        Booking__c objMakeupBook = TestUtil.createBooking(objTchr.Id,'Lesson','Make-up',false);
        objMakeupBook.Make_up_Utilize_Bookings__c = 
        objBook.Enrolment__c=objENrol.Id;
        objBook.Student__c=objCustmr.id;
        objBook.status__c = 'Pending';
        objBook.Available_Make_up_Units__c = 0;
        insert objBook;*/
        List<Fifth_Lesson__c> fifthLessionList = new List<Fifth_Lesson__c>();
        fifthLessionList.add(new Fifth_Lesson__c(Booking_Date__c=date.newInstance(2019, 8, 9),Center__c=objCentr.id,End_Time__c=time.newInstance(11, 0, 0, 0),Enrolment__c=objENrol.id,
                                                 Package__c=objPack.id,Start_Time__c= time.newInstance(10, 0, 0, 0),Student__c=objCustmr.id,Teacher_Account__c=objTchr.id,Remarks__c='40',
                                                 IsActive__c=true,Parent__c=objCustmr.id));
        insert fifthLessionList;
        
        
        
        // List<Enrolment__c> listEnrollment= TestUtil.createEnrolment(objCentr.id, objTchr.id, objCustmr.id, objPack.id, isDml);
        // List<case> recordIdOfcase =new List<case>([SELECT ID From case]); 
        //List<Fifth_Lesson__c> recordIdFitfthLession = new List<Fifth_Lesson__c>([SELECT ID FROM Fifth_Lesson__c]);
       
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
         ConvertToAdhoc objeConvertoAdhoc = new ConvertToAdhoc(fifthLessionList[0].id, '',true);
        objeConvertoAdhoc.convertFifthLesson();
        test.stopTest();
        
    }
}