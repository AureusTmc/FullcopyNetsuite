@isTest
public class RescheduleAllBookingsTest {
    @isTest
    public static void invokeAureusCalendarController(){
        Firebase_Settings__c objSetting = new Firebase_Settings__c();
        objSetting.Name = 'setting';
        objSetting.Enable_Notifications__c = false;
        insert objSetting;
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
        
        // update 21 09 2020 @nishi jain 
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
        
        /* Organisation__c org = new Organisation__c(Country__c = country.Id);
			INSERT org;*/
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        // update 21 09 2020 @nishi jain 
        objCentr.Center_Email__c =  'Test@gmail.com';
        objCentr.Organisation__c = organisationRecord.Id;
        objCentr.Organisation_Sharing__c ='Aureus Academy Singapore';
        Insert objCentr;
        
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        objTeachr.Center_Email__c ='Test@gmail.com';
        objTeachr.Employee_Duty_Type__c = 'Duty';
        insert objTeachr;
        
        Leave_Request__c request = new Leave_Request__c(Employee__c = objTeachr.Id, Leave_End_Date__c = System.today().addDays(14), 
                                                        Leave_Start_Date__c = System.today().addDays(14), Leave_Type__c = 'Teacher MC',
                                                        Status__c = 'Approved');
        INSERT request;
        
        Public_Holiday__c holiday = new Public_Holiday__c(Country__c = country.Id, Execution_Date__c = System.today(), Organisation_Status__c = 'Closed',
                                                          Public_Holiday_Date__c = System.today().addDays(21), Status__c = 'Execution completed', Organisation__c = organisationRecord.Id);
        INSERT holiday;
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr; 
        
        //Account objCustmr1=TestUtil.createAccount('Customer',True,True);
        
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true);
        
        Package__c objPackmakeup = testUtil.createPackage(objProg.id,objCentr.id,'45',false);
        objPackmakeup.Type__c = 'Makeup';
        insert objPackmakeup;
        
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
        List<Booking__c> ListOfBooking = new List<Booking__c>();
        Booking__c objBookREgular = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',FALSE);
        objBookREgular.Enrolment__c = objENrol.Id;
        objBookREgular.Status__c = 'Scheduled';
        objBookREgular.Package__c = objPack.Id;
        // objBookREgular.Center__c = objCentr.id;
        objBookREgular.Booking_Date__c = System.today();
        
        // update 21 09 2020 @nishi jain 
        //INSERT objBookREgular;
        ListOfBooking.add(objBookREgular);
        
        Booking__c objBookREgular2 = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',FALSE);
        objBookREgular2.Enrolment__c = objENrol.Id;
        objBookREgular2.Status__c = 'Scheduled';
        objBookREgular2.Package__c = objPack.Id;
        objBookREgular2.Booking_Date__c = System.today().addDays(365);
        // INSERT objBookREgular2;
        // update 21 09 2020 @nishi jain 
        ListOfBooking.add(objBookREgular2); 
        
        Booking__c objBook = TestUtil.createBooking(objTeachr.id,'Lesson','Make-up',FALSE);
        objBook.Enrolment__c = objENrol.Id;
        objBook.Status__c = 'Scheduled';
        objBook.Package__c = objPackmakeup.Id;
        //INSERT objBook;
        ListOfBooking.add(objBook); 
        
        
        Package__c objPackAdhoc = testUtil.createPackage(objProg.id,objCentr.id,'45',false);
        objPackAdhoc.Type__c = 'Adhoc';
        //insert objPackAdhoc;
        List<Fifth_Lesson__c> Fifth_LessonList = new List<Fifth_Lesson__c>();
        
        
        Booking__c objBook2 = TestUtil.createBooking(objTeachr.id,'Lesson','Ad-hoc',FALSE);
        objBook2.Enrolment__c = objENrol.Id;
        objBook2.Status__c = 'Scheduled';
        objBook2.Package__c = objPackAdhoc.Id;
        ListOfBooking.add(objBook2);
        
        Booking__c objBook3 = TestUtil.createBooking(objTeachr.id,'Lesson','Busy',FALSE);
        objBook3.Category__c = 'Placeholder';
        objBook3.Enrolment__c = objENrol.Id;
        objBook3.Status__c = 'Scheduled';
        ListOfBooking.add(objBook3);
     
        Insert ListOfBooking;
        
        Fifth_Lesson__c  objFifthLesson1 = new Fifth_Lesson__c(Booking__c = objBook.Id, Booking_Date__c=date.newInstance(date.today().addmonths(1).year(),date.today().addmonths(1).month(), date.today().day()),Center__c=objCentr.id,End_Time__c=time.newInstance(11, 0, 0, 0),Enrolment__c=objENrol.id,
                                                               Package__c=objPack.id,Start_Time__c= time.newInstance(10, 0, 0, 0),Student__c=objCustmr.id,Teacher_Account__c=objTeachr.id,Remarks__c='40',
                                                               IsActive__c=false,Parent__c=objCustmr.id);
        //insert objFifthLesson1;
        Fifth_LessonList.add(objFifthLesson1);
        
        
        Fifth_Lesson__c  objFifthLesson2 = new Fifth_Lesson__c(Booking__c = objBook2.Id, Booking_Date__c=date.newInstance(date.today().addmonths(1).year(),date.today().addmonths(1).month(), date.today().day()),Center__c=objCentr.id,End_Time__c=time.newInstance(11, 0, 0, 0),Enrolment__c=objENrol.id,
                                                               Package__c=objPack.id,Start_Time__c= time.newInstance(10, 0, 0, 0),Student__c=objCustmr.id,Teacher_Account__c=objTeachr.id,Remarks__c='40',
                                                               IsActive__c=false,Parent__c=objCustmr.id);
        //insert objFifthLesson2;
        Fifth_LessonList.add(objFifthLesson2);
        
        
        
        
        Fifth_Lesson__c  objFifthLesson3 = new Fifth_Lesson__c(Booking__c = objBook3.Id, Booking_Date__c=date.newInstance(date.today().addmonths(1).year(),date.today().addmonths(1).month(), date.today().day()),Center__c=objCentr.id,End_Time__c=time.newInstance(11, 0, 0, 0),Enrolment__c=objENrol.id,
                                                               Package__c=objPack.id,Start_Time__c= time.newInstance(10, 0, 0, 0),Student__c=objCustmr.id,Teacher_Account__c=objTeachr.id,Remarks__c='40',
                                                               IsActive__c=false,Parent__c=objCustmr.id);
        //insert objFifthLesson3;
        Fifth_LessonList.add(objFifthLesson3);
       Fifth_Lesson__c objFifthLesson4 = new Fifth_Lesson__c( Booking_Date__c=date.newInstance(date.today().addmonths(1).year(),date.today().addmonths(1).month(), date.today().day()),Center__c=objCentr.id,End_Time__c=time.newInstance(11, 0, 0, 0),
                                                            Start_Time__c= time.newInstance(10, 0, 0, 0),Student__c=objCustmr.id,Teacher_Account__c=objTeachr.id,Parent__c=objCustmr.id,Enrolment__c=objENrol.id,
                                                            Package__c=objPack.id);
   
        Fifth_LessonList.add(objFifthLesson4);
        
        Insert Fifth_LessonList;
        objENrol.New_Teacher__c = objTeachr.Id;
        objENrol.new_package_Id__c = objPack.id;
        update objENrol;
        objENrol =  [SELECT Id,name, Effective_Date__c, Lesson_Day__c, Teacher__c, Teacher__r.Employee_Duty_Type__c, 
                     Center__c, Student__c, Student__r.Name, Lesson_Start_time__c, package__r.unit_fee__c,
                     Next_Lesson_Start_time__c,new_package_Id__c,New_Teacher__c,new_package_Id__r.Duration__c,
                     New_Teacher__r.id,New_Teacher__r.Employee_Duty_Type__c,Package__c, Package__r.Duration__c,Parent__c, Center__r.Country__r.Tax_Rate__c, Center__r.Country__r.Currency_Code__c, 
                     Center__r.Country__r.Stripe_Secret_Key__c, Center__r.Country__r.Stripe_Base_Url__c,Center__r.Country__r.Id, 
                     Center__r.Organisation__r.name, (Select Id, Next_Bill_Date__c, Subscription__r.Parent__r.Stripe_Customer_Id__c,
                                                      Subscription__c, Subscription__r.Center__c, Enrolment__c, Enrolment__r.Center__r.Country__r.Tax_Rate__c FROM Subscription_Line_Items__r) 
                     FROM Enrolment__c WHERE Id =: objENrol.id];
        RescheduleAllBookings obj = new RescheduleAllBookings(FALSE, objENrol, System.today(), System.today().addMonths(12));
        objENrol =  [SELECT Id,name, Effective_Date__c, Lesson_Day__c, Teacher__c, Teacher__r.Employee_Duty_Type__c, 
                     Center__c, Student__c, Student__r.Name, Lesson_Start_time__c, package__r.unit_fee__c,
                     Next_Lesson_Start_time__c,new_package_Id__c,New_Teacher__c,new_package_Id__r.Duration__c,
                     New_Teacher__r.id,New_Teacher__r.Employee_Duty_Type__c,Package__c, Package__r.Duration__c,Parent__c, Center__r.Country__r.Tax_Rate__c, Center__r.Country__r.Currency_Code__c, 
                     Center__r.Country__r.Stripe_Secret_Key__c, Center__r.Country__r.Stripe_Base_Url__c,Center__r.Country__r.Id, 
                     Center__r.Organisation__r.Name, (Select Id, Next_Bill_Date__c, Subscription__r.Parent__r.Stripe_Customer_Id__c,
                                                      Subscription__c, Subscription__r.Center__c, Enrolment__c, Enrolment__r.Center__r.Country__r.Tax_Rate__c FROM Subscription_Line_Items__r) 
                     FROM Enrolment__c WHERE Id =: objENrol.id];
        RescheduleAllBookings objw = new RescheduleAllBookings(TRUE, objENrol, System.today(), System.today().addMonths(12));
        objw.createPlaceholderBookingFromFifthLesson(Fifth_LessonList);
    }
}