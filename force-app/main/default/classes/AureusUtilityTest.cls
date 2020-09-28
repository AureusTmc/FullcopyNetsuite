@isTest
public class AureusUtilityTest {
    @isTest
    public static void invokeAureusTest(){
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
        //added by nishi:25-sep-2020: create organisation
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
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        //added by @nishi 25 sep 2020
        objCentr.Organisation__c = organisationRecord.id;
        objCentr.Organisation_Sharing__c ='Aureus Academy Singapore';
        //updated by @nishi 25 sep 2020
        INSERT objCentr;
        
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Available_Make_up_Units__c = 45;
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
        
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        
        Package__c makeupPAck =testUtil.createPackage(objProg.id,objCentr.id,'45',FALSE);
        makeupPAck.Type__c = 'Makeup';
        INSERT makeupPAck;
        Package__c newObjPack=testUtil.createPackage(objProg.id,objCentr.id,'30', true);
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Parent__c = objCustmr.Id;
        objENrol.Lesson_Day__c = 'Tuesday';
        
        Enrolment__c objENrol2=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol2.Lesson_Day__c = 'Tuesday';
        Enrolment__c objENrol3=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol3.Lesson_Day__c = 'Thursday';
        Enrolment__c objENrol4=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol4.Lesson_Day__c = 'Wednesday';
        Enrolment__c objENrol5=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol5.Lesson_Day__c = 'Thursday';
        Enrolment__c objENrol6 = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol6.Lesson_Day__c = 'Friday';
        Enrolment__c objENrol7 = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol7.Lesson_Day__c = 'Monday';
        List<Enrolment__c> enrolList = new List<Enrolment__c> ();
        enrolList.add(objENrol);
        enrolList.add(objENrol2);
        enrolList.add(objENrol3);
        enrolList.add(objENrol4);
        enrolList.add(objENrol5);
        enrolList.add(objENrol6);
        enrolList.add(objENrol7);
        insert enrolList;
        
        Fifth_Lesson__c fifthobj = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(2019, 10, 29),Center__c=objCentr.id,End_Time__c=time.newInstance(11, 45, 0, 0),Enrolment__c=objENrol.id,
                                                       Package__c=objPack.id,Start_Time__c= time.newInstance(11, 0, 0, 0),Student__c=objCustmr.id,Teacher_Account__c=objTeachr.id, IsActive__c=true,Parent__c=objCustmr.id);
        INSERT fifthobj;
        Booking__c bookObj = TestUtil.createBooking(objTeachr.Id, 'Lesson', 'Regular',false);
        bookObj.status__c = 'Canceled';
        bookObj.Package__c = objPack.Id;
        bookObj.Center__c = objCentr.Id;
        bookObj.Enrolment__c = objENrol.Id;
        bookObj.Make_up_Expiry_Date__c = System.today().addDays(180);
        bookObj.Booking_Date__c = Date.today().addDays(-3);
        bookObj.Available_Make_up_Units__c = 30;
        bookObj.Student__c = objCustmr.Id;
        bookObj.Parent__c = objCustmr.Id;
        //bookObj.Type__c = 'Regular';
        insert bookObj;
        
        Set<String> enrolSet = new Set<String> {objENrol.Id};
            Map<Enrolment__c, Date> enrolmentMap = new Map<Enrolment__c, Date>();
        enrolmentMap.put(objENrol, objENrol.Lessons_Start_Date__c);    
        Email_Settings__mdt templateObj =  [SELECT DeveloperName, Id, Template_Id__c FROM Email_Settings__mdt WHERE DeveloperName = 'Declined' LIMIT 1];
        Invoice__c objInvoice =  TestUtil.createInvoice(objCustmr.Id, true);
        AureusUtility.getSingleEmailMessage(templateObj.Template_Id__c, objCustmr.Id, objInvoice.Id, '');
        
        Package__c objAdhoc=testUtil.createPackage(objProg.id,objCentr.id,'45',false); 
        objAdhoc.Type__c= 'Adhoc';
        insert objAdhoc;
        
        enrolList = [SELECT Id, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c, 
                     Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, 
                     Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, Center__r.Organisation__r.name,
                     Student__r.Name, Parent__r.Available_Make_up_Units__c, Center__r.Name, Center__r.Location__c, Parent__r.personContactId FROM Enrolment__c];
        
        System.debug('@@@enrolList'+enrolList);
        
        AureusUtility.preInvoiceJobOnEnrolment(enrolList);
        
        
    }
    @isTest
    public static void invokeAureusTest2(){
        
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
        //added by nishi:25-sep-2020:
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
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        //updated by @nishi 25 sep 2020
        objCentr.Organisation__c = organisationRecord.id;
        objCentr.Organisation_Sharing__c ='Aureus Academy Singapore';
        Insert objCentr;
        //updated by @nishi 25 sep 2020
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Available_Make_up_Units__c = 45;
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
        
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        
        Package__c makeupPAck =testUtil.createPackage(objProg.id,objCentr.id,'45',FALSE);
        makeupPAck.Type__c = 'Makeup';
        INSERT makeupPAck;
        Package__c newObjPack=testUtil.createPackage(objProg.id,objCentr.id,'30', true);
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Parent__c = objCustmr.Id;
        objENrol.Lesson_Day__c = 'Tuesday';
        
        Enrolment__c objENrol2=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol2.Lesson_Day__c = 'Tuesday';
        Enrolment__c objENrol3=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol3.Lesson_Day__c = 'Thursday';
        Enrolment__c objENrol4=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol4.Lesson_Day__c = 'Wednesday';
        Enrolment__c objENrol5=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol5.Lesson_Day__c = 'Thursday';
        Enrolment__c objENrol6 = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol6.Lesson_Day__c = 'Friday';
        Enrolment__c objENrol7 = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol7.Lesson_Day__c = 'Monday';
        List<Enrolment__c> enrolList = new List<Enrolment__c> ();
        enrolList.add(objENrol);
        enrolList.add(objENrol2);
        enrolList.add(objENrol3);
        enrolList.add(objENrol4);
        enrolList.add(objENrol5);
        enrolList.add(objENrol6);
        enrolList.add(objENrol7);
        insert enrolList;
        
        Fifth_Lesson__c fifthobj = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(2019, 10, 29),Center__c=objCentr.id,End_Time__c=time.newInstance(11, 45, 0, 0),Enrolment__c=objENrol.id,
                                                       Package__c=objPack.id,Start_Time__c= time.newInstance(11, 0, 0, 0),Student__c=objCustmr.id,Teacher_Account__c=objTeachr.id, IsActive__c=true,Parent__c=objCustmr.id);
        INSERT fifthobj;
        Booking__c bookObj = TestUtil.createBooking(objTeachr.Id, 'Lesson', 'Regular',false);
        bookObj.status__c = 'Canceled';
        bookObj.Package__c = objPack.Id;
        bookObj.Center__c = objCentr.Id;
        bookObj.Enrolment__c = objENrol.Id;
        bookObj.Make_up_Expiry_Date__c = System.today().addDays(180);
        bookObj.Booking_Date__c = Date.today().addDays(-3);
        bookObj.Available_Make_up_Units__c = 30;
        bookObj.Student__c = objCustmr.Id;
        bookObj.Parent__c = objCustmr.Id;
        //bookObj.Type__c = 'Regular';
        insert bookObj;
        
        Set<String> enrolSet = new Set<String> {objENrol.Id};
            Map<Enrolment__c, Date> enrolmentMap = new Map<Enrolment__c, Date>();
        enrolmentMap.put(objENrol, objENrol.Lessons_Start_Date__c);    
        Email_Settings__mdt templateObj =  [SELECT DeveloperName, Id, Template_Id__c FROM Email_Settings__mdt WHERE DeveloperName = 'Declined' LIMIT 1];
        Invoice__c objInvoice =  TestUtil.createInvoice(objCustmr.Id, true);
        
        
        Package__c objAdhoc=testUtil.createPackage(objProg.id,objCentr.id,'45',false); 
        objAdhoc.Type__c= 'Adhoc';
        insert objAdhoc;
        
        enrolList = [SELECT Id, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c, 
                     Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, 
                     Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, 
                     Student__r.Name, Parent__r.Available_Make_up_Units__c, Center__r.Name, Center__r.Location__c, Parent__r.personContactId FROM Enrolment__c];
        objENrol.New_Package_Id__c = newObjPack.Id;
        objENrol.Next_Lesson_Start_time__c = Time.newInstance(12, 0, 0, 0);
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessChanged;
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus ;
        objENrol.New_Package_Id__c = enrolList[0].Package__c;
        objENrol.New_Teacher__c = enrolList[0].Teacher__c;
        objENrol.New_Lesson_Day__c = 'Wednesday';
        objENrol.effective_Date__c = System.today().addDays(-3);
        update objENrol;
        test.startTest();
        objENrol = [SELECT Id, Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c, 
                    Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, 
                    Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, 
                    Student__r.Name FROM Enrolment__c WHERE Id = :objENrol.Id LIMIT 1];
        AureusUtility.postInvoiceJobOnEnrolment(new List<Enrolment__c> {objENrol},System.today());
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessCancelType;
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus ;
        update objENrol;
        objENrol = [SELECT Id, Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c,
                    Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, 
                    Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, 
                    Student__r.Name FROM Enrolment__c WHERE Id = :objENrol.Id LIMIT 1];
        AureusUtility.postInvoiceJobOnEnrolment(new List<Enrolment__c> {objENrol},System.today());
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
        objENrol.Next_Lesson_Start_time__c = Time.newInstance(12, 0, 0, 0);
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus ;
        update objENrol;
        objENrol = [SELECT Id,Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c, 
                    Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, 
                    Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, New_Centre__c,
                    Student__r.Name FROM Enrolment__c WHERE Id = :objENrol.Id LIMIT 1];
        AureusUtility.postInvoiceJobOnEnrolment(new List<Enrolment__c> {objENrol},System.today());
        
        AureusUtility.getParentBookingMap(enrolmentMap);
        AureusUtility.getPackageMap();
        objENrol.Package__c = objPack.Id;
        UPDATE objENrol;
        objENrol = [SELECT Id, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Package__r.Duration__c, Parent__c, Center__r.Location__c, Parent__r.personContactId  FROM Enrolment__c WHERE Id = :objEnrol.Id LIMIT 1];
        System.debug('@@@objENrol'+objENrol.Package__r.Duration__c);
        AureusUtility.makeupCreationNotification(new List<Enrolment__c> {objENrol}, new List<Enrolment__c> {objENrol});
        AureusUtility.addBooking(objEnrol,'Regular','Pending',System.today(),false, objPack.Id, '');
        bookObj.Cancellation_Reason__c = 'Teacher Mc';
        UPDATE bookObj;
        List<Case> caseList = AureusUtility.createCase(new List<Booking__c> {bookObj});
        INSERT caseList;
        AureusUtility.sendCaseEmail(new Set<Id> {caseList[0].Id});
        AureusUtility.sendOssiaCaseEmail(new Set<Id> {caseList[0].Id});
        AureusUtility.getRandomSixDigit();
        AureusUtility.getAdhocPackages(new Set<String> {objCentr.Id}, new Set<String> {'30'});
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Enrolment__c = objENrol.Id, Booking_Date__c = Date.Today(),Start_Time__c = objENrol.Lesson_Start_time__c,
                                                              End_Time__c = objENrol.Lesson_Start_time__c.addMinutes(45),Parent__c = objCustmr.Id, Package__c = objPack.Id, Student__c = objCustmr.Id);
        insert objFifthLesson;
        objFifthLesson = [SELECT Id, center__c, Center__r.Name, Parent__c, Parent__r.Available_Make_up_Units__c, 
                          Enrolment__r.Id, Enrolment__r.Student__c, Enrolment__r.Parent__c, 
                          Enrolment__r.Parent__r.Available_Make_up_Units__c, Enrolment__r.Center__r.Country__r.Id,
                          Enrolment__r.Center__r.Country__r.Country_Name__c, Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                          Parent__r.Stripe_Customer_Id__c, Center__r.Organisation__r.name,Enrolment__r.Center__r.Organisation__r.name,
                          Package__r.Duration__c, Enrolment__r.Center__r.Name, Enrolment__r.package__r.Duration__c, Enrolment__r.Center__c, 
                          Enrolment__r.Lesson_Start_time__c, isActive__c, Duration__c, Booking_Date__c, Enrolment__r.Teacher__c,Enrolment__r.Teacher__r.Engagement_Type__c 
                          FROM Fifth_Lesson__c
                          WHERE Id = :objFifthLesson.Id];
        AureusUtility.createFifthBookingBefore6Days(new List<Fifth_Lesson__c> {objFifthLesson});
        AureusUtility.getEmailTemplateId('test template');
        AureusUtility.getInvoicePDF('');
        test.stopTest();
    }
    
    @isTest
    public static void invokeAureusTest3(){
        
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
        //added by nishi:25-sep-2020:create organisation
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
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        //updated by @nishi 25 sep 2020
        objCentr.Organisation__c = organisationRecord.id;
        objCentr.Organisation_Sharing__c ='Aureus Academy Singapore';
        ////updated by @nishi 25 sep 2020
        INSERT objCentr;
        
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Available_Make_up_Units__c = 45;
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
        
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPack1=testUtil.createPackage(objProg.id,objCentr.id,'60',true); 
        Package__c objAdhoc=testUtil.createPackage(objProg.id,objCentr.id,'60',false); 
        objAdhoc.Type__c= 'Adhoc';
        insert objAdhoc;
        Package__c newObjPack=testUtil.createPackage(objProg.id,objCentr.id,'30', true);
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objAdhoc.id,false);
        objENrol.Parent__c = objCustmr.Id;
        objENrol.Lesson_Day__c = 'Tuesday';
        insert objENrol;
        
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Enrolment__c = objENrol.Id, Booking_Date__c = Date.Today(),Start_Time__c = objENrol.Lesson_Start_time__c,
                                                              End_Time__c = objENrol.Lesson_Start_time__c.addMinutes(60),Parent__c = objCustmr.Id, Package__c = objPack1.Id, Student__c = objCustmr.Id);
        objFifthLesson.Center__c =objCentr.id;
        insert objFifthLesson;
        objFifthLesson = [SELECT Id, center__c, Center__r.Name, Parent__c, Parent__r.Available_Make_up_Units__c, 
                          Enrolment__r.Id, Enrolment__r.Student__c, Enrolment__r.Parent__c, 
                          Enrolment__r.Parent__r.Available_Make_up_Units__c, Enrolment__r.Center__r.Country__r.Id,
                          Enrolment__r.Center__r.Country__r.Country_Name__c, Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                          Parent__r.Stripe_Customer_Id__c, Center__r.Organisation__r.name,Enrolment__r.Center__r.Organisation__r.name,
                          Package__r.Duration__c, Enrolment__r.Center__r.Name, Enrolment__r.package__r.Duration__c, Enrolment__r.Center__c, 
                          Enrolment__r.Lesson_Start_time__c, isActive__c, Duration__c, Booking_Date__c, Enrolment__r.Teacher__c ,
                          Enrolment__r.Teacher__r.Engagement_Type__c
                          FROM Fifth_Lesson__c
                          WHERE Id = :objFifthLesson.Id];
        AureusUtility.createFifthBookingBefore6Days(new List<Fifth_Lesson__c> {objFifthLesson});
    }
    
    @isTest
    public static void invokePostInvoiceBatchForGroupClass(){
        ClassEditControllerTestHelper.createGroupClassData();
        List<enrolment__c> listOfEnrol =  [SELECT Id,Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c, Class__c,Class__r.Class_Day__c,
                                           Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, New_Class__c,
                                           Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, 
                                           Student__r.Name FROM Enrolment__c LIMIT 1];
        List<Booking__c> listOfBooking = [SELECT Id, Start_Time__c, Group_Class__c,end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                          Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                          Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c, Is_Fifth_Booking__c ,
                                          Class__c
                                          FROM Booking__c 
                                          WHERE Type__c = :ConstantsClass.groupTypeBooking
                                          AND Status__c != :ConstantsClass.statusCanceled
                                          AND Class__c =: listOfEnrol[0].Class__c];
        List<package__c> listPackage = [select id from package__C where id !=:listOfEnrol[0].Package__c];
        List<Account> listTeacher = [select id from account where id !=:listOfEnrol[0].Teacher__c and RecordType.name='Teacher'];
        List<class__c> listClass = [select id from class__c where id !=:listOfEnrol[0].class__c];
        
        listOfBooking[0].booking_date__c=  System.today().addMonths(13);
        update listOfBooking[0];
        Test.startTest();
        AureusUtility.getFirstWeekDayDate(listOfEnrol[0].Class__r.Class_Day__c,system.today().month(),system.today().year());
        enrolment__c objENrol = listOfEnrol[0];
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessChanged;
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus ;
        objENrol.effective_Date__c = System.today().addDays(-3);
        update objENrol;
        objENrol = [SELECT Id, Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c, Class__c,
                    Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, New_Class__c,
                    Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, 
                    Student__r.Name FROM Enrolment__c WHERE Id = :objENrol.Id LIMIT 1];
        AureusUtility.postInvoiceJobOnEnrolment(new List<Enrolment__c> {objENrol},System.today());
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessCancelType;
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus ;
        update objENrol;
        objENrol = [SELECT Id, Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c,Class__c,
                    Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, New_Class__c,
                    Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, 
                    Student__r.Name FROM Enrolment__c WHERE Id = :objENrol.Id LIMIT 1];
        AureusUtility.postInvoiceJobOnEnrolment(new List<Enrolment__c> {objENrol},System.today());
        objENrol.New_Package_Id__c = listPackage[0].Id;
        objENrol.New_Teacher__c = listTeacher[0].Id;
        objENrol.New_Class__c = listClass[0].Id;
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
        objENrol.Next_Lesson_Start_time__c = Time.newInstance(12, 0, 0, 0);
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus ;
        update objENrol;
        objENrol = [SELECT Id,Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c, Class__c,
                    Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, New_Class__c,
                    Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, 
                    Student__r.Name FROM Enrolment__c WHERE Id = :objENrol.Id LIMIT 1];
        AureusUtility.postInvoiceJobOnEnrolment(new List<Enrolment__c> {objENrol},System.today());
        
        objENrol.New_Package_Id__c = listPackage[0].Id;
        objENrol.New_Teacher__c = listTeacher[0].Id;
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
        objENrol.Next_Lesson_Start_time__c = Time.newInstance(12, 0, 0, 0);
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus ;
        objENrol.effective_Date__c = System.today().addDays(-3);
        update objENrol;
        objENrol = [SELECT Id,Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c, Class__c,
                    Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, New_Class__c,
                    Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, 
                    Student__r.Name FROM Enrolment__c WHERE Id = :objENrol.Id LIMIT 1];
        AureusUtility.postInvoiceJobOnEnrolment(new List<Enrolment__c> {objENrol},System.today());
        Test.stopTest();
    }
    
    //added by nishi: 26-Sep-2020: for code coverage ossia changes
    @isTest
    public static void invokePostInvoiceBatchForOssia(){
        
        OssiaCenterCalendarControllerTestHelper.createCalenderData();
        List<enrolment__c> listOfEnrol =  [SELECT Id,Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c, Class__c,Class__r.Class_Day__c,
                                           Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, New_Class__c,
                                           Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, New_Centre__c,
                                           Student__r.Name FROM Enrolment__c LIMIT 1];
        List<Booking__c> listOfBooking = [SELECT Id, Start_Time__c, Group_Class__c,end_time__c, Booking_Date__c, Teacher_Account__c, Student__r.Name, Enrolment__c, Enrolment__r.new_package_Id__c, 
                                          Enrolment__r.new_package_Id__r.Duration__c, Enrolment__r.Next_Lesson_Start_time__c, Center__c, Enrolment__r.Parent__c, Enrolment__r.Lesson_Day__c, 
                                          Enrolment__r.New_Teacher__c,Enrolment__r.new_Lesson_Day__c, Enrolment__r.Lesson_Start_time__c,package__c, package__r.Duration__c, Is_Fifth_Booking__c ,
                                          Class__c
                                          FROM Booking__c 
                                          WHERE Type__c!= :ConstantsClass.recordTypeLesson
                                          AND Status__c != :ConstantsClass.statusCanceled];
        List<package__c> listPackage = [select id from package__C where id !=:listOfEnrol[0].Package__c];
        List<Account> listTeacher = [select id from account where id !=:listOfEnrol[0].Teacher__c and RecordType.name='Teacher'];
        List<class__c> listClass = [select id from class__c where id !=:listOfEnrol[0].class__c];
        
        listOfBooking[0].booking_date__c=  System.today().addMonths(13);
        update listOfBooking[0];
        Test.startTest();
        enrolment__c objENrol = listOfEnrol[0];
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessChanged;
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus ;
        objENrol.effective_Date__c = System.today().addDays(-3);
        update objENrol;
        objENrol = [SELECT Id, Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c, Class__c,
                    Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, New_Class__c,
                    Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, New_Centre__c,
                    Student__r.Name FROM Enrolment__c WHERE Id = :objENrol.Id LIMIT 1];
        AureusUtility.postInvoiceJobOnEnrolment(new List<Enrolment__c> {objENrol},System.today());
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessCancelType;
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus ;
        update objENrol;
        objENrol = [SELECT Id, Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c,Class__c,
                    Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, New_Class__c,
                    Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, New_Centre__c,
                    Student__r.Name FROM Enrolment__c WHERE Id = :objENrol.Id LIMIT 1];
        AureusUtility.postInvoiceJobOnEnrolment(new List<Enrolment__c> {objENrol},System.today());
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessChangedCenter;
        objENrol.Next_Lesson_Start_time__c = Time.newInstance(12, 0, 0, 0);
        objENrol.New_Centre__c = objENrol.Center__c;
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus ;
        objENrol.New_Package_Id__c = objENrol.Package__c;
        objENrol.New_Teacher__c = objENrol.Teacher__c;
        objENrol.New_Lesson_Day__c = 'Wednesday';
        update objENrol;
        objENrol = [SELECT Id,Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c, 
                    Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, 
                    Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, New_Centre__c,
                    Student__r.Name FROM Enrolment__c WHERE Id = :objENrol.Id LIMIT 1];
        AureusUtility.postInvoiceJobOnEnrolment(new List<Enrolment__c> {objENrol},System.today());
        
        objENrol.New_Package_Id__c = listPackage[0].Id;
        objENrol.New_Teacher__c = listTeacher[0].Id;
        objENrol.Package_Process_Type__c = ConstantsClass.enrollmentProcessUpgradeType;
        objENrol.Next_Lesson_Start_time__c = Time.newInstance(12, 0, 0, 0);
        objENrol.Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus ;
        objENrol.effective_Date__c = System.today().addDays(-3);
        update objENrol;
        objENrol = [SELECT Id,Parent__c, Package__r.Duration__c, Package_Process_Type__c, Package_Process_Status__c,Type__c, Class__c,
                    Effective_Date__c, New_Package_Id__c, Next_Lesson_Start_time__c, New_Teacher__c, New_Lesson_Day__c, New_Class__c,
                    Stage__c, Lesson_Day__c, Student__c, Center__c, Teacher__c, Lesson_Start_time__c, Parent__r.Name, New_Centre__c,
                    Student__r.Name FROM Enrolment__c WHERE Id = :objENrol.Id LIMIT 1];
        AureusUtility.postInvoiceJobOnEnrolment(new List<Enrolment__c> {objENrol},System.today());
        Test.stopTest();
    }
    
    @isTest
    public static void test_createFifthBookingBefore6Days(){
        
        OssiaCenterCalendarControllerTestHelper.createCalenderData();
        List<Booking__c> listOfBooking = [SELECT Id,Type__c,Student__c,center__c,Teacher_Account__c,Package__c,Enrolment__c,Booking_Date__c,
                                          Available_Make_up_Units__c,end_Time__c,parent__c
                                          FROM Booking__c
                                          Where RecordType.name =:ConstantsClass.recordTypeLesson]; 
        Enrolment__c objENrol =  AdvanceActionsHelper.fetchEnrolmentDetailsFromBooking(listOfBooking[0].id);
        test.startTest();
        List<Booking__c> listOfmakeupBooking = [SELECT Id,Type__c,Student__c,center__c,Teacher_Account__c,Package__c,Enrolment__c,Booking_Date__c,
                                                Available_Make_up_Units__c,end_Time__c,Student__r.Name,parent__c
                                                from Booking__c where type__c ='Make-up'  and RecordType.name =:ConstantsClass.recordTypeLesson limit 1]; 
        listOfmakeupBooking[0].Available_Make_up_Units__c = 0;
        listOfmakeupBooking[0].Make_up_Utilize_Bookings__c = listOfBooking[0].Id + '-30;'+ listOfBooking[1].Id + '-30';
        listOfmakeupBooking[0].Make_up_Expiry_Date__c= date.today();
        listOfmakeupBooking[0].enrolment__c = objENrol.id;
        update listOfmakeupBooking[0];
        List<Booking__c> listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__C,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().adddays(1),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        listOfcreateBooking[0].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[0].Available_Make_up_Units__c = 1;
        listOfcreateBooking[0].Cancellation_Reason__c = 'Teacher MC';
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__C,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1).adddays(7),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__C,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().addDays(15).adddays(7),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__C,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,system.today().addMonths(-1).adddays(7),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        
        listOfcreateBooking[1].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[1].Cancellation_Reason__c = 'MC';
        listOfcreateBooking[1].Available_Make_up_Units__c = 1;
        listOfcreateBooking[2].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[2].Available_Make_up_Units__c = 1;
        listOfcreateBooking[2].Cancellation_Reason__c = 'Teacher MC';
        insert listOfcreateBooking;
        objENrol.Available_Make_up_mins__c =100;
        update objENrol;
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Enrolment__c = objENrol.Id, Booking_Date__c = Date.Today(),Start_Time__c = objENrol.Lesson_Start_time__c,
                                                              End_Time__c = objENrol.Lesson_Start_time__c.addMinutes(45),Parent__c = objENrol.Parent__c, 
                                                              Package__c = objENrol.Package__c, Student__c =  objENrol.Student__c);
        insert objFifthLesson;
        objFifthLesson = [SELECT Id, center__c, Center__r.Name, Parent__c, Parent__r.Available_Make_up_Units__c, 
                          Enrolment__r.Id, Enrolment__r.Student__c, Enrolment__r.Parent__c, 
                          Enrolment__r.Parent__r.Available_Make_up_Units__c, Enrolment__r.Center__r.Country__r.Id,
                          Enrolment__r.Center__r.Country__r.Country_Name__c, Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                          Parent__r.Stripe_Customer_Id__c, Center__r.Organisation__r.name,Enrolment__r.Center__r.Organisation__r.name,
                          Package__r.Duration__c, Enrolment__r.Center__r.Name, Enrolment__r.package__r.Duration__c, Enrolment__r.Center__c, 
                          Enrolment__r.Lesson_Start_time__c, isActive__c, Duration__c, Booking_Date__c,
                          Enrolment__r.Teacher__c,Enrolment__r.Teacher__r.Engagement_Type__c ,Enrolment__r.Available_Make_up_mins__c
                          FROM Fifth_Lesson__c
                          WHERE Id = :objFifthLesson.Id];
        AureusUtility.createFifthBookingBefore6Days(new List<Fifth_Lesson__c> {objFifthLesson});
        test.stopTest();
    }
     //added by nishi: 26-Sep-2020:end: for code coverage ossia changes
    
}