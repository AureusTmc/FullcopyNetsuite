/*
Name        :        BookingTriggerTest
Date        :        20 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of BookingTrigger.
*/
@isTest
public class BookingTriggerTest {
    public static testMethod void invokeBookingTrigger(){
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

        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true,Enable_Notifications__c = true);
        insert settings;
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,true);
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        objBook.Enrolment__c=objEnrol.id;
        objBook.Status__c='Pending';
        insert objBook;
        objBook.Status__c='Canceled';
        objBook.Is_fifth_booking__c=true;
        objbook.Booking_Date__c=date.today().addDays(30);
        objBook.Available_Make_up_Units__c=30;
        objBook.Student__c=objCustmr.id;
        update objBook;
      
    }
    //@Nishi : for test after cancel Booking Mobile_Notification api call or not
    public static testMethod void testCancelBooking(){
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
        
        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true,Enable_Notifications__c= true);
        insert settings;
        test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,
                                                                               '{"multicast_id":7430610622243333234,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1566819879327140%95528c5095528c50"}]}'
                                                                              );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        test.stopTest();
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.FCM_Token__c ='dVD5mKEVenc:APA91bEJuzKM2bFOg-b-P0HShpR0zF0XL1t15f78bGid0CXdK3F98YZGuTPbJEkamyyEU80fRXQM1f3pqOP_d-dUosGnziJo4ACLRSDw5oHs6nXL47QKelmxf6QkbkaLKxxiE9bAJDb3';
        insert objCustmr;
        
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,true);
        objENrol.Stage__c =ConstantsClass.enroledStatus;
        update objENrol;
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        objBook.Enrolment__c=objEnrol.id;
        objBook.Status__c='Pending';
        objBook.Student__c =objCustmr.id;
        objBook.Parent__c=objCustmr.Id;
        objbook.Booking_Date__c=date.today().addDays(30);
        objbook.Start_Time__c = time.newInstance(15, 00,00, 00);
        insert objBook;
        objBook.Status__c='Canceled';
        objBook.Is_fifth_booking__c=true;
        objBook.Canceled_Date__c =date.today();
        objBook.Cancellation_Reason__c ='Personal Reason';
        objBook.Available_Make_up_Units__c=30;
        objBook.Student__c=objCustmr.id;
        update objBook;
    }
    // @Nishi : for test after cancel Booking Reason 'Teacher Mc' Mobile_Notification api call or not
    public static testMethod void testTeacherMCCancelBooking(){
        
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
        
        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true,Enable_Notifications__c= true);
        insert settings;
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
       
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,true);
        objENrol.Stage__c =ConstantsClass.enroledStatus;
        update objENrol;
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        objBook.Enrolment__c=objEnrol.id;
        objBook.Status__c='Pending';
        objBook.Student__c =objCustmr.id;
        objbook.Booking_Date__c=date.today().addDays(30);
        objbook.Start_Time__c = time.newInstance(15, 00,00, 00);
        insert objBook;
        test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,
                                                                               '{"multicast_id":7430610622243333234,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1566819879327140%95528c5095528c50"}]}'
                                                                              );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        test.stopTest();
        objBook.Status__c='Canceled';
        objBook.Canceled_Date__c =date.today();
        objBook.Cancellation_Reason__c ='Teacher Mc';
        objBook.Available_Make_up_Units__c=30;
        objBook.Student__c=objCustmr.id;
        update objBook;
         
    }
   //  @Nishi : for test after Reschedule Booking Mobile_Notification api call or not
    public static testMethod void testRescheduleBooking(){
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

        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true,Enable_Notifications__c= true);
        insert settings;
        test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,
                                                                               '{"multicast_id":7430610622243333234,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1566819879327140%95528c5095528c50"}]}'
                                                                              );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.FCM_Token__c ='dVD5mKEVenc:APA91bEJuzKM2bFOg-b-P0HShpR0zF0XL1t15f78bGid0CXdK3F98YZGuTPbJEkamyyEU80fRXQM1f3pqOP_d-dUosGnziJo4ACLRSDw5oHs6nXL47QKelmxf6QkbkaLKxxiE9bAJDb3';
        insert objCustmr;
        
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,true);
        objENrol.Stage__c =ConstantsClass.enroledStatus;
        update objENrol;
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        objBook.Enrolment__c=objEnrol.id;
        objBook.Status__c='Pending';
        objBook.Student__c =objCustmr.id;
        objBook.Parent__c=objCustmr.Id;
        objbook.Booking_Date__c=date.today().addDays(30);
        objbook.Start_Time__c = time.newInstance(15, 00,00, 00);
        objbook.Prev_Booking_Date__c =date.today().addDays(-10);
        insert objBook;
        objBook.Status__c='Canceled';
        objBook.Is_fifth_booking__c=true;
        objBook.Canceled_Date__c =date.today();
        objBook.Cancellation_Reason__c ='Personal Reason';
        objBook.Available_Make_up_Units__c=30;
        objBook.Student__c=objCustmr.id;
        objbook.Prev_Booking_Date__c =date.today().addDays(-11);
        objbook.Prev_Start_Time__c = time.newInstance(11, 00,00, 00);
        update objBook;
        test.stopTest();
        system.debug('@@@test='+[SELECT Id, Body__c, Customer_Name__c, Deleted_by_user__c, Status__c, Title__c FROM Mobile_Notification__c]);
        system.debug('@@@test='+[SELECT Id, Body__c, Customer_Name__c, Deleted_by_user__c, Status__c, Title__c FROM Mobile_Notification__c].size());
    }
    
    //  @Nishi :1-Aur2020 :  for test testChangeLesson_Type
    public static testMethod void testChangeLesson_Type(){
        CampEnrolmentTestHelper.createCampData();
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

        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true,Enable_Notifications__c= true);
        insert settings;
        test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,
                                                                               '{"multicast_id":7430610622243333234,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1566819879327140%95528c5095528c50"}]}'
                                                                              );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.FCM_Token__c ='dVD5mKEVenc:APA91bEJuzKM2bFOg-b-P0HShpR0zF0XL1t15f78bGid0CXdK3F98YZGuTPbJEkamyyEU80fRXQM1f3pqOP_d-dUosGnziJo4ACLRSDw5oHs6nXL47QKelmxf6QkbkaLKxxiE9bAJDb3';
        insert objCustmr;
        
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        List <Teacher_Working_Hour__c> listOfTeacherWorkingHours = new List <Teacher_Working_Hour__c>();
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(objtechr.id,objCentr.Id,True,False,7));
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,true);
        objENrol.Stage__c =ConstantsClass.enroledStatus;
        update objENrol;
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        objBook.Enrolment__c=objEnrol.id;
        objBook.type__c=ConstantsClass.bookTypeRegular;
        objBook.Status__c='Pending';
        objBook.Student__c =objCustmr.id;
        objBook.Parent__c=objCustmr.Id;
         objBook.center__c=objCentr.Id;
        objbook.Booking_Date__c=date.today().addDays(30);
        objbook.Start_Time__c = time.newInstance(15, 00,00, 00);
        objbook.Prev_Booking_Date__c =date.today().addDays(-10);
        objbook.Is_Lesson_Type_Change__c = true;
        objBook.Teacher_Account__c=objtechr.id;
        insert objBook;
        objbook.Is_Lesson_Type_Change__c = false;
        update objBook;
        Booking__c objBook2 = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        objBook2.Enrolment__c=objEnrol.id;
        objBook2.type__c=ConstantsClass.bookTypeRegular;
         objBook2.center__c=objCentr.Id;
        objBook2.Status__c='Pending';
        objBook2.Teacher_Account__c=objtechr.id;
        objBook2.Student__c =objCustmr.id;
        objBook2.Parent__c=objCustmr.Id;
        objbook2.Booking_Date__c=date.today().addDays(30);
        objbook2.Start_Time__c = time.newInstance(15, 00,00, 00);
        objbook2.Prev_Booking_Date__c =date.today().addDays(-10);
        objbook2.Is_Lesson_Type_Change__c = true;
        insert objbook2;
        Booking__c objBook3 = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        objBook3.Status__c='Pending';
        objBook3.type__c=ConstantsClass.typeTrial;
        objBook3.Teacher_Account__c=objtechr.id;
        objBook3.center__c=objCentr.Id;
        objBook3.Student__c =objCustmr.id;
        objBook3.Parent__c=objCustmr.Id;
        objBook3.Booking_Date__c=date.today().addDays(30);
        objBook3.Start_Time__c = listOfTeacherWorkingHours[0].Start_Time__c;
        objBook3.End_Time__c = listOfTeacherWorkingHours[0].End_Time__c;
        objBook3.Is_Lesson_Type_Change__c = true; 
        insert objBook3;
    }
}