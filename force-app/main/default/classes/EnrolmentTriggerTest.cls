/*
Name        :        EnrolmentTriggerTest
Date        :        20 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of EnrolmentTrigger.
*/
@isTest
public class EnrolmentTriggerTest {
    
    public static testMethod void test1(){
        //enrolment__c enrol=TestUtil.createEnrolment(true);
        //TestUtil.updateEnrolment(enrol.Id,true);
        Account objCustmr=TestUtil.createAccount('Customer',true,False);
        
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
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        insert objCentr;
        Account objTchr=TestUtil.createAccount('Teacher',false,false);
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
        
        //objCentr.Id,objTchr.Id,objCustmr.id,objPack.Id
        objEnrol.Center__c=objCentr.id;
        objEnrol.Teacher__c=objTchr.id;
        objEnrol.Parent__c=objCustmr.id;
        objEnrol.Student__c=objCustmr.id;
        objEnrol.Package__c=objPack.id;
        objEnrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        insert objEnrol;
        Booking__C objBook=Testutil.createBooking(objTchr.Id,'Lesson','Regular',False);
        objbook.Enrolment__c=objEnrol.id;
        insert objBook;
        
        Case objCase=testUtil.createCase(False);
        objcase.Stage__c='Trial Attended';
        objCase.Enrolment__c=objEnrol.Id;
        objCase.AccountId=objCustmr.id;
        insert objcase;
        objEnrol.Type__c = 'Regular';
        objEnrol.Stage__c='Cancelled';
        objEnrol.Package__c=objPack2.id;
        update objEnrol;
        
        EnrolmentTriggerHandler.DelBookingCancellation(new List<Enrolment__c> {objEnrol});
    }
    
    // Added by jatin: 16-mar-2020: for test Piano rental 
    private static testMethod  void test_PianoRentalEnrolment(){
        PianoRentalTestHelper.createPianoRentalData();
        List<Enrolment__c> enrolmentList = [Select Id,Parent__c,Parent__r.PersonEmail, center__c,teacher__c,package__C,Aggrement_Id__c,
                                            (SELECT Id,amount__C,Subscription__c FROM Subscription_Line_Items__r )
                                            from Enrolment__c 
                                            where Type__c =: ConstantsClass.enrollmentTypeInstrument
                                            And RecordType.Name =:ConstantsClass.enrollmentInstrumentRecTypeName
                                            And  Stage__c =: ConstantsClass.enrollmentPianoRentalActiveStage];
        
        Subscription__c objSubscription = new Subscription__c(id = enrolmentList[0].Subscription_Line_Items__r[0].Subscription__c,Next_Bill_Date__c =null ,Subscription_Start_Date__c =null);
        update objSubscription;
        Integer remainingDays = date.daysInMonth(system.today().year(), system.today().month()) - system.today().day();
        system.debug(remainingDays);
        
        Decimal rentalTotalAmount = remainingDays * (enrolmentList[0].Subscription_Line_Items__r[0].Amount__c /  date.daysInMonth(system.today().year(), system.today().month()));
        system.debug(rentalTotalAmount);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "paid": true,"id":"cus_EmndZcxxpUhDzD", "object": "customer", "account_balance": '+rentalTotalAmount+', "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
        enrolmentList[0].Final_Delivery_date__c = system.today();
        enrolmentList[0]. Final_Delivery_Timeslot__c = system.now().time();
        update enrolmentList[0];
        
        test.stopTest();
        enrolmentList = PianoRentalHelperController.getRentalEnrolmentList(New Set<String>{enrolmentList[0].id});
        system.assert(enrolmentList[0].Subscription_Line_Items__r[0].Subscription__r.Next_Bill_Date__c != null);  
    }
    
    // Added by jatin: 16-mar-2020: for test Piano rental 
    private static testMethod  void test_PianoRentalEnrolment2(){
        PianoRentalTestHelper.createPianoRentalData();
        List<Enrolment__c> enrolmentList = [Select Id,Parent__c,Parent__r.PersonEmail, center__c,teacher__c,package__C,Aggrement_Id__c,
                                            (SELECT Id,amount__C,Subscription__c FROM Subscription_Line_Items__r )
                                            from Enrolment__c 
                                            where Type__c =: ConstantsClass.enrollmentTypeInstrument
                                            And RecordType.Name =:ConstantsClass.enrollmentInstrumentRecTypeName
                                            And  Stage__c =: ConstantsClass.enrollmentPianoRentalActiveStage];
        
        Subscription_Line_Item__c objSubscriptionLineItem = new Subscription_Line_Item__c(id = enrolmentList[0].Subscription_Line_Items__r[0].id,Amount__c= Null);
        update objSubscriptionLineItem;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201,'{ "id": "msFYActMfJHqNTKH8YSvF1", "status": "document.uploaded", "name": "API Sample Document from PandaDoc Template", "date_created": "2018-08-02T08:42:13.836022Z", "date_modified": "2018-08-02T08:42:13.836022Z", "expiration_date": null, "uuid": "msFYActMfJHqNTKH8YSvF1" }'));
        enrolmentList[0].Final_Delivery_date__c = system.today();
        enrolmentList[0]. Final_Delivery_Timeslot__c = system.now().time();
        update enrolmentList[0];
        
        test.stopTest();
        enrolmentList = PianoRentalHelperController.getRentalEnrolmentList(New Set<String>{enrolmentList[0].id});
        system.assert(string.isNotBlank(enrolmentList[0].Aggrement_Id__c));
    }
    
    // Added by jatin: 16-mar-2020: for test Piano rental 
    private static testMethod  void test_GroupClassEnrolment(){
        ClassEditControllerTestHelper.createGroupClassData();
        List<Enrolment__c>  ListOfEnrolment = [select Id,Parent__c,Parent__r.PersonEmail, center__c,teacher__c,package__C,Class__C from Enrolment__c];
        List<class__c > GroupClassList = [select id from Class__C where id !=: ListOfEnrolment[0].Class__C];
        listOfEnrolment[0].Class__C = GroupClassList[0].id;
        update listOfEnrolment[0];
        GroupClassList = [select id,Total_Enrolment__c from Class__C where id =: GroupClassList[0].id];
        System.assert(GroupClassList[0].Total_Enrolment__c == 2) ;  
        delete listOfEnrolment[0];
        GroupClassList = [select id,Total_Enrolment__c from Class__C where id =: GroupClassList[0].id];
        System.assert(GroupClassList[0].Total_Enrolment__c == 1) ;  
    }
    
    // Added by jatin: 16-mar-2020: for test Piano rental 
    private static testMethod  void test_PianoRentalEnrolmentError(){
        PianoRentalTestHelper.createPianoRentalData();
        List<Enrolment__c> enrolmentList = [Select Id,Parent__c,Parent__r.PersonEmail, center__c,teacher__c,package__C,Aggrement_Id__c,
                                            (SELECT Id,amount__C,Subscription__c FROM Subscription_Line_Items__r )
                                            from Enrolment__c 
                                            where Type__c =: ConstantsClass.enrollmentTypeInstrument
                                            And RecordType.Name =:ConstantsClass.enrollmentInstrumentRecTypeName
                                            And  Stage__c =: ConstantsClass.enrollmentPianoRentalActiveStage];
        test.startTest();
        
        enrolmentList[0].Final_Delivery_date__c = system.today();
        Database.SaveResult udpateFinal_Delivery_date = Database.update(enrolmentList[0], false);
        System.assert(udpateFinal_Delivery_date.getErrors().size() == 1);
        
        
        enrolmentList[0].Final_Delivery_date__c = Null;
        enrolmentList[0]. Final_Delivery_Timeslot__c = system.now().time();
        Database.SaveResult udpateFinal_Delivery_Timeslot = Database.update(enrolmentList[0], false);
        System.assert(udpateFinal_Delivery_Timeslot.getErrors().size() == 1);
        
        enrolmentList[0].Final_Delivery_date__c = system.today().addDays(-1);
        udpateFinal_Delivery_date = Database.update(enrolmentList[0], false);
        System.assert(udpateFinal_Delivery_date.getErrors().size() == 1);
        
        EnrolmentTriggerHandler.currQuarterLastDate();
        EnrolmentTriggerHandler.fillOpportunity(enrolmentList[0]);
        test.stopTest();
    }
    
    // Nishi: 4-aug:2020: for cover enrolment trigger resource Id realted Changes
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
        Account objtechr1=TestUtil.createAccount('Teacher',False,true);
        List <Teacher_Working_Hour__c> listOfTeacherWorkingHours = new List <Teacher_Working_Hour__c>();
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(objtechr.id,objCentr.Id,True,False,7));
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(objtechr1.id,objCentr.Id,True,False,7));
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Stage__c ='Requested';
        objENrol.type__c ='Trial';
        objEnrol.Lesson_Start_time__c=null;
        objEnrol.Lessons_Start_Date__c=null;
        objEnrol.Trial_Start_Time__c=Time.newInstance(11,0,0,0);
        objEnrol.Trial_Date__c=date.today().addDays(1);
        upsert objENrol;
        
        objENrol.type__c = 'Regular';
        objENrol.Stage__c = ConstantsClass.enroledStatus;
        objENrol.Teacher__c =objtechr1.id; 
        objEnrol.Lesson_Start_time__c=listOfTeacherWorkingHours[0].Start_Time__c;
        objEnrol.Lessons_Start_Date__c=date.today().addDays(1);
        objEnrol.Referral_code_used__c = objCustmr.Unique_Referral_Code__c;
            objEnrol.Referred_by__c = objCustmr.Id;
        update objENrol; 
        objEnrol.Lesson_Day__c=DateTime.newInstance(objEnrol.Lessons_Start_Date__c.addDays(1), objEnrol.Lesson_Start_time__c).format('EEEE');
        update objENrol;
    }
    
}