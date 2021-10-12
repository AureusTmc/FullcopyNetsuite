@isTest
public class FreeTrial_IpadCntrlTest {
    
    
    @testSetup
    public static void dataFactory(){
        try{
            List< Profile > listProfile = [ SELECT Id 
                                           FROM Profile
                                           WHERE Name = 'System Administrator'];
            if( listProfile.size() > 0 ){
                
                User objUser = new User(
                    ProfileId = listProfile[0].Id,
                    LastName = 'testUser',
                    Email = 'puser000@amamama.com',
                    Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                    CompanyName = 'TEST',
                    Title = 'title',
                    Alias = 'alias',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US'
                    
                );
                insert objUser;
                
                Country__c country = new Country__c();
                country.Name = 'SG';
                country.Country_Name__c = 'Singapore';
                country.Tax_Rate__c = 7.0;
                country.Currency_Code__c = 'SGD';
                country.Student_Policies_Template_Id__c = 'test';
                country.Stripe_Base_Url__c = 'www.test.com';
                country.Stripe_Publishable_Key__c = 'ABC';
                country.Stripe_Secret_Key__c = 'deede';
                insert country;
                
                
                // update 27 09 2020 @nishi jain 
                Organisation__c organisationRecord = new Organisation__c();
                organisationRecord.Name =  'Aureus Academy Singapore';
                organisationRecord.Bank_Account_Number__c = '1123456789';
                organisationRecord.Branch_Code__c = 'test';
                organisationRecord.Country__c = country.id;
                organisationRecord.Stripe_Base_Url__c = 'www.test.com';
                organisationRecord.Stripe_Publishable_Key__c = 'ABC';
                organisationRecord.Stripe_Secret_Key__c = 'test_key';
                organisationRecord.Sage_Company__c = 'AGP';
                Insert organisationRecord;
                
                // update 27 09 2020 @nishi jain 
                Organisation__c organisationRecord2 = new Organisation__c();
                organisationRecord2.Name = 'Ossia Music School Singapore';
                organisationRecord2.Bank_Account_Number__c = '1123456789';
                organisationRecord2.Branch_Code__c = 'test';
                organisationRecord2.Country__c = country.id;
                organisationRecord2.Stripe_Base_Url__c = 'www.test.com';
                organisationRecord2.Stripe_Publishable_Key__c = 'ABC';
                organisationRecord2.Stripe_Secret_Key__c = 'test_key';
                organisationRecord2.Sage_Company__c = 'AGP';
                Insert organisationRecord2;
                
                
                //added by @nishi 27 sep 2020 
                List<Account> ListCentre = new List<Account>();
                ListCentre.add(AureusCalendarControllerTestHelper.createCentre('Aureus Forum', country.Id,FALSE));
                ListCentre.add(AureusCalendarControllerTestHelper.createCentre('Ossia Bukit Timah', country.Id,FALSE));
                ListCentre[0].Organisation__c = organisationRecord.id;
                ListCentre[0].Organisation_Sharing__c ='Aureus Academy Singapore';
                ListCentre[1].Organisation__c = organisationRecord2.id;
                ListCentre[1].Organisation_Sharing__c ='Ossia Music School Singapore';
                ListCentre[0].Centre_Status__c = 'Active';
                ListCentre[1].Centre_Status__c = 'Active';
                Insert ListCentre; 
                account objCentr = ListCentre[0];
                account ossiaCentr = ListCentre[1];
                //added by @nishi 27 sep 2020
                system.assert(objCentr.Id !=Null);
                
                List<Centre_Users__c> ListCentreuser = new List<Centre_Users__c>();
                
                Centre_Users__c centerUserObj = new Centre_Users__c();
                centerUserObj.Designation__c = 'Centre Manager';
                centerUserObj.Centre_Name__c = ListCentre[0].Id;
                centerUserObj.User_Name__c = objUser.Id;
                insert centerUserObj;
                
                List<account> teacherlist = new List<account>();
                Account objTeachr=testUtil.createAccount('Teacher',false,False);
                objTeachr.Minor_Instruments_Disciplines__c='Piano';
                objTeachr.Major_Instruments_Disciplines__c = 'Piano';
                objTeachr.Status__c = ConstantsClass.teacherWorkingStatus;
                objTeachr.Enable_Trial_Bookings__c = true;
                teacherlist.add( objTeachr);
                Account objTeachr2=testUtil.createAccount('Teacher',false,False);
                objTeachr2.LastName='testossiaTeacher';
                objTeachr2.Minor_Instruments_Disciplines__c='Piano';
                objTeachr2.Major_Instruments_Disciplines__c = 'Piano';
                objTeachr2.Status__c = ConstantsClass.teacherWorkingStatus;
                objTeachr2.Enable_Trial_Bookings__c = true;
                teacherlist.add( objTeachr2);
                insert teacherlist;
                
                system.assert(objTeachr.Id !=Null);
                
                List <Teacher_Working_Hour__c> listTWH = new List <Teacher_Working_Hour__c>();
                For( Teacher_Working_Hour__c objTechWorkHour : TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,false,False,7)){
                    objTechWorkHour.Center_Name__c = objCentr.Id;
                    listTWH.add( objTechWorkHour );
                }
                For( Teacher_Working_Hour__c objTechWorkHour : TestUtil.createTeacher_Working_Hour(objTeachr2.id,ossiaCentr.Id,false,False,7)){
                    objTechWorkHour.Center_Name__c = objCentr.Id;
                    listTWH.add( objTechWorkHour );
                }
                insert listTWH;
                Program__C objProg = TestUtil.createProgram('Active','Piano',true);
                List<package__c> packLIst= new List<package__c>();
                Package__c objPack = testUtil.createPackage(objProg.id,objCentr.id,'30',false); 
                objPack.Type__c = 'Trial';
                packLIst.add(objPack);
                Package__c objossiaCentrPack = testUtil.createPackage(objProg.id,ossiaCentr.id,'30',false); 
                objossiaCentrPack.Type__c = 'Trial';
                objossiaCentrPack.Grade_New__c ='Grade 1';
                packLIst.add(objossiaCentrPack);
                insert packLIst;
                
                
                
            }//end of profile list size
        }Catch( System.DmlException dmlExcep ){
            system.debug(' error --> ' + dmlExcep.getMessage() + dmlExcep.getLineNumber());
        }
        Catch( Exception dmlExcep ){
            system.debug(' error --> ' + dmlExcep.getMessage() + dmlExcep.getLineNumber());
        }
    }
    
    public static testMethod void TestData(){
        List< User > listCurrentUser = [ SELECT Id 
                                        FROM User 
                                        WHERE Name = 'testUser'];
        // List< Account > listAccountCenter = [ SELECT Id
        //                                   FROM Account 
        //                                 WHERE Name = 'Aureus 112 Katong'];
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Gender__c = 'Male';
        objCustmr.PersonBirthdate = date.today();
        INSERT objCustmr;
        
        
        Account objCustmrStu = new Account();
        objCustmrStu.FirstName = 'testStudent';
        objCustmrStu.LastName = 'test';
        objCustmrStu.personEmail = 'test1@tmc.com';
        objCustmrStu.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmrStu.Gender__c = 'Male';
        objCustmrStu.PersonBirthdate = date.today();
        objCustmrStu.Parent__c = objCustmr.Id;
        insert objCustmrStu;
        system.debug('teacher records aree -->'+[ Select id from account where name = 'testTeacher' ]);
        Booking__c objBook = TestUtil.createBooking([ Select id from account where name = 'testTeacher' ].Id,'Lesson','Regular',false);
        objBook.Student__c = objCustmrStu.Id;
        objBook.Start_Time__c = Time.newInstance(1, 2, 3, 4);
        objBook.End_Time__c = Time.newInstance(4, 2, 3, 4);
        objBook.Status__c = 'Pending';
        objBook.Type__c = 'Trial';
        objBook.Booking_Date__c = System.today().addDays(7);
        insert objBook;
        System.debug('booking==>'+objBook);
        
        Account objTeachr = [ SELECT Id FROM ACCOUNT WHERE Minor_Instruments_Disciplines__c ='Piano'and  name = 'testTeacher' ];
        Account objCentr = [ SELECT Id,organisation__c FROM ACCOUNT WHERE Centre_Status__c = 'Active'and  name='Aureus Forum'];
        Package__c objPack = [ SELECT ID,program__C from Package__c where location__C=: objCentr.id limit 1];
        
        Attachment att = new Attachment(ParentId=objTeachr.Id, Name='Profile Image.jpeg',ContentType='image/jpeg',Body=Blob.valueOf('sdf'));
        insert att;
        
        List<Booking__c> bookList = new List<Booking__c>();
        Booking__c bkgObj = TestUtil.createBooking(objTeachr.Id,'Lesson','Regular',false);
        bkgObj.Student__c=objCustmrStu.Id;
        bkgObj.Start_Time__c = Time.newInstance(10, 0, 0, 0);
        bkgObj.End_Time__c = Time.newInstance( 10, 30, 0, 0);
        bkgObj.Booking_Date__c = system.today();
        insert bkgObj;
        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false); 
        objENrol.Stage__c = 'Enrolled';
        
        insert objENrol;
        
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(system.today().year(), system.today().month(), 29), Center__c=Label.Aureus_at_Home_Id, End_Time__c=time.newInstance(10, 30, 0, 0), Enrolment__c=objEnrol.id,
                                                              Package__c=objPack.id, Start_Time__c= time.newInstance(10, 0, 0, 0), Student__c=objCustmr.id, Teacher_Account__c=objTeachr.id, Remarks__c='40',
                                                              IsActive__c=true ,Parent__c=objCustmr.id);
        objFifthLesson.Teacher_Account__c = objTeachr.id;
        insert objFifthLesson;
        Class__c objCLass = AureusCalendarControllerTestHelper.createGroupClass('test Group Class1',objPack.id,objCentr.Id,objPack.program__C,date.today(),date.today().addYears(1),Time.newInstance(11,0,0,0),Time.newInstance(11,30,0,0),objTeachr.Id,false);
        objCLass.Total_Enrolment__c = 2;
        objCLass.Start_Time__c = Time.newInstance(10, 0, 0, 0);
        objCLass.End_Time__c = Time.newInstance( 10, 30, 0, 0);
        insert objCLass;
        
        
        if( listCurrentUser.size() > 0  ){
            
            system.runAs( listCurrentUser[0] ){
                test.startTest();
                FreeTrial_IpadCntrl objFreeTrialIpadCntrl = new FreeTrial_IpadCntrl();
                objFreeTrialIpadCntrl.getCenters();
                objFreeTrialIpadCntrl.slcdNoOfStudent = '1';
                objFreeTrialIpadCntrl.slcdCenter =objCentr.id;
                objFreeTrialIpadCntrl.slcdDate=system.today().day()+'/'+system.today().month()+'/'+system.today().year();
                objFreeTrialIpadCntrl.getNoOfStudent();
                objFreeTrialIpadCntrl.slcdStuIndex =1;
                objFreeTrialIpadCntrl.isPageInMobile = true;
                objFreeTrialIpadCntrl.slcdInstrument = 'Piano';
                objFreeTrialIpadCntrl.setTrialInsetrument();
                objFreeTrialIpadCntrl.fetchPreWeekSlot();
                objFreeTrialIpadCntrl.fetchNextWeekSlot();
                objFreeTrialIpadCntrl.slcdDuration = 30;
                objFreeTrialIpadCntrl.processDuration();
                objFreeTrialIpadCntrl.slcdTchrId = objTeachr.id;
                objFreeTrialIpadCntrl.slcdDate = System.today().addDays(1).format();
                objFreeTrialIpadCntrl.slcdSlot =System.now().addDays(1).format('E')+'-12:15';
                objFreeTrialIpadCntrl.slcdTeacher();
                objFreeTrialIpadCntrl.processExistingStu();
                
                objFreeTrialIpadCntrl.enrModelList[0].slcdInstrument = 'Piano';
                objFreeTrialIpadCntrl.fetchTeacherDetails();
                
                objFreeTrialIpadCntrl.backBtnCmp1();
                objFreeTrialIpadCntrl.nextBtnCmp1();
                objFreeTrialIpadCntrl.backBtnCmp2();
                objFreeTrialIpadCntrl.nextBtnCmp2();
                objFreeTrialIpadCntrl.backBtnCmp3();
                objFreeTrialIpadCntrl.nextBtnCmp3();
                
                objFreeTrialIpadCntrl.enrModelList[0].studentAcc = objCustmrStu;
                objFreeTrialIpadCntrl.isParAlsoAStudent = true;
                objFreeTrialIpadCntrl.slcdLessonType();
                objFreeTrialIpadCntrl.parentAcc.firstName =objCustmr.FirstName;
                objFreeTrialIpadCntrl.parentAcc.lastName =objCustmr.lastName;
                objFreeTrialIpadCntrl.parentAcc.personEmail =objCustmr.personEmail;
                objFreeTrialIpadCntrl.PersonMobilePhoneCustom ='12344';
                //objFreeTrialIpadCntrl.parentAcc.parent__c=objCustmrStu.id;
                objFreeTrialIpadCntrl.saveTrialData();
                objFreeTrialIpadCntrl.backBtnCmp4();
                objFreeTrialIpadCntrl.backBtnCmp6();
                objFreeTrialIpadCntrl.nextBtnCmp6();
                objFreeTrialIpadCntrl.backBtnCmp5();
                objFreeTrialIpadCntrl.nextBtnCmp4();  
                
                
                objFreeTrialIpadCntrl.slcdCenter = Label.Aureus_at_Home_Id;
                objFreeTrialIpadCntrl = new FreeTrial_IpadCntrl();
                objFreeTrialIpadCntrl.saveTrialData();
                
                
                objFreeTrialIpadCntrl = new FreeTrial_IpadCntrl(); 
                objFreeTrialIpadCntrl.slcdLsnType ='Group';
                objFreeTrialIpadCntrl.getCenters();
                objFreeTrialIpadCntrl.slcdNoOfStudent = '1';
                objFreeTrialIpadCntrl.slcdCenter =objCentr.id;
                objFreeTrialIpadCntrl.slcdDate=system.today().day()+'/'+system.today().month()+'/'+system.today().year();
                objFreeTrialIpadCntrl.getNoOfStudent();
                objFreeTrialIpadCntrl.slcdStuIndex =1;
                objFreeTrialIpadCntrl.isPageInMobile = true;
                objFreeTrialIpadCntrl.slcdInstrument = 'Piano';
                objFreeTrialIpadCntrl.setTrialInsetrument();
                objFreeTrialIpadCntrl.fetchPreWeekSlot();
                objFreeTrialIpadCntrl.fetchNextWeekSlot();
                objFreeTrialIpadCntrl.slcdDuration = 30;
                objFreeTrialIpadCntrl.processDuration();
                objFreeTrialIpadCntrl.slcdTchrId = objTeachr.id;
                objFreeTrialIpadCntrl.slcdDate = System.today().addDays(1).format();
                objFreeTrialIpadCntrl.slcdSlot =System.now().addDays(1).format('E')+'-10:00';
                objFreeTrialIpadCntrl.slcdTeacher();
                objFreeTrialIpadCntrl.processExistingStu();
                
                objFreeTrialIpadCntrl.enrModelList[0].slcdInstrument = 'Piano';
                objFreeTrialIpadCntrl.fetchTeacherDetails();
                
                objFreeTrialIpadCntrl.backBtnCmp1();
                objFreeTrialIpadCntrl.nextBtnCmp1();
                objFreeTrialIpadCntrl.backBtnCmp2();
                objFreeTrialIpadCntrl.nextBtnCmp2();
                objFreeTrialIpadCntrl.backBtnCmp3();
                objFreeTrialIpadCntrl.nextBtnCmp3();
                
                objFreeTrialIpadCntrl.enrModelList[0].studentAcc = objCustmrStu;
                objFreeTrialIpadCntrl.isParAlsoAStudent = true;
                objFreeTrialIpadCntrl.slcdLessonType();
                objFreeTrialIpadCntrl.processDuration();
                objFreeTrialIpadCntrl.parentAcc.firstName =objCustmr.FirstName;
                objFreeTrialIpadCntrl.parentAcc.lastName =objCustmr.lastName;
                objFreeTrialIpadCntrl.parentAcc.personEmail =objCustmr.personEmail;
                objFreeTrialIpadCntrl.PersonMobilePhoneCustom ='12344';
                objFreeTrialIpadCntrl.saveTrialData();
                test.stopTest();
            }
        }
    }
    // nishi: 26-Sep-2020: for ossia regarding changes
    
    public static testMethod void TestOssiaChanges(){
        List< User > listCurrentUser = [ SELECT Id 
                                        FROM User 
                                        WHERE Name = 'testUser'];
        // List< Account > listAccountCenter = [ SELECT Id
        //                                   FROM Account 
        //                                 WHERE Name = 'Aureus 112 Katong'];
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Gender__c = 'Male';
        objCustmr.PersonBirthdate = date.today();
        INSERT objCustmr;
        
        
        Account objCustmrStu = new Account();
        objCustmrStu.FirstName = 'testStudent';
        objCustmrStu.LastName = 'test';
        objCustmrStu.personEmail = 'test1@tmc.com';
        objCustmrStu.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmrStu.Gender__c = 'Male';
        objCustmrStu.PersonBirthdate = date.today();
        objCustmrStu.Parent__c = objCustmr.Id;
        insert objCustmrStu;
        Booking__c objBook = TestUtil.createBooking([ Select id from account where name = 'testossiaTeacher' ].Id,'Lesson','Regular',false);
        objBook.Student__c = objCustmrStu.Id;
        objBook.Start_Time__c = Time.newInstance(1, 2, 3, 4);
        objBook.End_Time__c = Time.newInstance(4, 2, 3, 4);
        objBook.Status__c = 'Pending';
        objBook.Type__c = 'Trial';
        objBook.Booking_Date__c = System.today().addDays(7);
        insert objBook;
        System.debug('booking==>'+objBook);
        
        Account objTeachr = [ SELECT Id FROM ACCOUNT WHERE Minor_Instruments_Disciplines__c ='Piano'and  name = 'testossiaTeacher' ];
        Account objCentr = [ SELECT Id,organisation__c FROM ACCOUNT WHERE Centre_Status__c = 'Active'and  name='Ossia Bukit Timah'];
        Package__c objPack = [ SELECT ID,program__C from Package__c where location__C=: objCentr.id limit 1];
        
        Attachment att = new Attachment(ParentId=objTeachr.Id, Name='Profile Image.jpeg',ContentType='image/jpeg',Body=Blob.valueOf('sdf'));
        insert att;
        
        List<Booking__c> bookList = new List<Booking__c>();
        Booking__c bkgObj = TestUtil.createBooking(objTeachr.Id,'Lesson','Regular',false);
        bkgObj.Student__c=objCustmrStu.Id;
        bkgObj.Start_Time__c = Time.newInstance(10, 0, 0, 0);
        bkgObj.End_Time__c = Time.newInstance( 10, 30, 0, 0);
        bkgObj.Booking_Date__c = system.today();
        insert bkgObj;
        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false); 
        objENrol.Stage__c = 'Enrolled';
        objENrol.Referred_by__c =objCustmrStu.id;
        objENrol.Referral_code_used__c ='21234';
        insert objENrol;
        
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(system.today().year(), system.today().month(), 29), Center__c=Label.Aureus_at_Home_Id, End_Time__c=time.newInstance(10, 30, 0, 0), Enrolment__c=objEnrol.id,
                                                              Package__c=objPack.id, Start_Time__c= time.newInstance(10, 0, 0, 0), Student__c=objCustmr.id, Teacher_Account__c=objTeachr.id, Remarks__c='40',
                                                              IsActive__c=true ,Parent__c=objCustmr.id);
        objFifthLesson.Teacher_Account__c = objTeachr.id;
        insert objFifthLesson;
        Class__c objOssiaCLass = AureusCalendarControllerTestHelper.createGroupClass('test ossia Group Class2',objPack.id,objCentr.Id,objPack.program__c,date.today(),
                                                                                     date.today().addYears(1),Time.newInstance(11,0,0,0),Time.newInstance(11,30,0,0),objTeachr.Id,false);
        objOssiaCLass.Total_Enrolment__c = 2;
        objOssiaCLass.Start_Time__c = Time.newInstance(10, 0, 0, 0);
        objOssiaCLass.End_Time__c = Time.newInstance( 10, 30, 0, 0);
        objOssiaCLass.Grade__C = 'Grade 1;';
        insert objOssiaCLass;
        
        List<Ossia_Group_Grade_Package__c> listOssiaGroupGradePackage = new List<Ossia_Group_Grade_Package__c> ();
        listOssiaGroupGradePackage.add(OssiaCenterCalendarControllerTestHelper.createOssiaGroupGradePackage('Grade 1',objOssiaCLass.id,objPack.id,false));
        insert listOssiaGroupGradePackage;
        
        
        if( listCurrentUser.size() > 0  ){
            
            system.runAs( listCurrentUser[0] ){
                test.startTest();
                Test.setCurrentPageReference(new PageReference('Page.FreeTrial_Ipad')); 
                System.currentPageReference().getParameters().put('org', 'ossia');
                System.currentPageReference().getParameters().put('refcode', objCustmrStu.Unique_Referral_Code__c);
                FreeTrial_IpadCntrl objFreeTrialIpadCntrl = new FreeTrial_IpadCntrl();
                objFreeTrialIpadCntrl.getCenters();
                objFreeTrialIpadCntrl.slcdNoOfStudent = '1';
                objFreeTrialIpadCntrl.slcdCenter =objCentr.id;
                objFreeTrialIpadCntrl.slcdDate=system.today().day()+'/'+system.today().month()+'/'+system.today().year();
                objFreeTrialIpadCntrl.getNoOfStudent();
                objFreeTrialIpadCntrl.slcdStuIndex =1;
                objFreeTrialIpadCntrl.isPageInMobile = true;
                objFreeTrialIpadCntrl.slcdInstrument = 'Piano';
                objFreeTrialIpadCntrl.setTrialInsetrument();
                objFreeTrialIpadCntrl.fetchPreWeekSlot();
                objFreeTrialIpadCntrl.fetchNextWeekSlot();
                objFreeTrialIpadCntrl.slcdDuration = 30;
                objFreeTrialIpadCntrl.processDuration();
                objFreeTrialIpadCntrl.slcdTchrId = objTeachr.id;
                objFreeTrialIpadCntrl.slcdDate = System.today().addDays(1).format();
                objFreeTrialIpadCntrl.slcdSlot =System.now().addDays(1).format('E')+'-12:15';
                objFreeTrialIpadCntrl.slcdTeacher();
                objFreeTrialIpadCntrl.processExistingStu();
                
                objFreeTrialIpadCntrl.enrModelList[0].slcdInstrument = 'Piano';
                objFreeTrialIpadCntrl.fetchTeacherDetails();
                
                objFreeTrialIpadCntrl.backBtnCmp1();
                objFreeTrialIpadCntrl.nextBtnCmp1();
                objFreeTrialIpadCntrl.backBtnCmp2();
                objFreeTrialIpadCntrl.nextBtnCmp2();
                objFreeTrialIpadCntrl.backBtnCmp3();
                objFreeTrialIpadCntrl.nextBtnCmp3();
                
                objFreeTrialIpadCntrl.enrModelList[0].studentAcc = objCustmrStu;
                objFreeTrialIpadCntrl.isParAlsoAStudent = true;
                objFreeTrialIpadCntrl.slcdLessonType();
                objFreeTrialIpadCntrl.parentAcc.firstName =objCustmr.FirstName;
                objFreeTrialIpadCntrl.parentAcc.lastName =objCustmr.lastName;
                objFreeTrialIpadCntrl.parentAcc.personEmail =objCustmr.personEmail;
                objFreeTrialIpadCntrl.PersonMobilePhoneCustom ='12344';
                //objFreeTrialIpadCntrl.parentAcc.parent__c=objCustmrStu.id;
                objFreeTrialIpadCntrl.saveTrialData();
                objFreeTrialIpadCntrl.checkExistingCustomer();
                objFreeTrialIpadCntrl.sendMailToReffrel(objENrol);
                objFreeTrialIpadCntrl.backBtnCmp4();
                objFreeTrialIpadCntrl.backBtnCmp6();
                objFreeTrialIpadCntrl.nextBtnCmp6();
                objFreeTrialIpadCntrl.backBtnCmp5();
                objFreeTrialIpadCntrl.nextBtnCmp4();  
                
                
                objFreeTrialIpadCntrl.slcdCenter = Label.Aureus_at_Home_Id;
                objFreeTrialIpadCntrl = new FreeTrial_IpadCntrl();
                objFreeTrialIpadCntrl.saveTrialData();
                
                
                objFreeTrialIpadCntrl = new FreeTrial_IpadCntrl(); 
                objFreeTrialIpadCntrl.slcdLsnType ='Group';
                objFreeTrialIpadCntrl.getCenters();
                objFreeTrialIpadCntrl.slcdNoOfStudent = '1';
                objFreeTrialIpadCntrl.slcdCenter =objCentr.id;
                objFreeTrialIpadCntrl.slcdDate=system.today().day()+'/'+system.today().month()+'/'+system.today().year();
                objFreeTrialIpadCntrl.getNoOfStudent();
                objFreeTrialIpadCntrl.slcdStuIndex =1;
                objFreeTrialIpadCntrl.isPageInMobile = true;
                objFreeTrialIpadCntrl.slcdInstrument = 'Piano';
                objFreeTrialIpadCntrl.setTrialInsetrument();
                objFreeTrialIpadCntrl.fetchPreWeekSlot();
                objFreeTrialIpadCntrl.fetchNextWeekSlot();
                objFreeTrialIpadCntrl.slcdDuration = 30;
                objFreeTrialIpadCntrl.processDuration();
                objFreeTrialIpadCntrl.slcdTchrId = objTeachr.id;
                objFreeTrialIpadCntrl.slcdDate = System.today().addDays(1).format();
                objFreeTrialIpadCntrl.slcdSlot =System.now().addDays(1).format('E')+'-10:00';
                objFreeTrialIpadCntrl.slcdTeacher();
                objFreeTrialIpadCntrl.processExistingStu();
                
                objFreeTrialIpadCntrl.enrModelList[0].slcdInstrument = 'Piano';
                objFreeTrialIpadCntrl.fetchTeacherDetails();
                
                objFreeTrialIpadCntrl.backBtnCmp1();
                objFreeTrialIpadCntrl.nextBtnCmp1();
                objFreeTrialIpadCntrl.backBtnCmp2();
                objFreeTrialIpadCntrl.nextBtnCmp2();
                objFreeTrialIpadCntrl.backBtnCmp3();
                objFreeTrialIpadCntrl.nextBtnCmp3();
                
                objFreeTrialIpadCntrl.enrModelList[0].studentAcc = objCustmrStu;
                objFreeTrialIpadCntrl.isParAlsoAStudent = true;
                objFreeTrialIpadCntrl.slcdLessonType();
                objFreeTrialIpadCntrl.processDuration();
                objFreeTrialIpadCntrl.parentAcc.firstName =objCustmr.FirstName;
                objFreeTrialIpadCntrl.parentAcc.lastName =objCustmr.lastName;
                objFreeTrialIpadCntrl.parentAcc.personEmail =objCustmr.personEmail;
                objFreeTrialIpadCntrl.PersonMobilePhoneCustom ='12344';
                objFreeTrialIpadCntrl.slcdTeacher();
                objFreeTrialIpadCntrl.saveTrialData();
                
                test.stopTest();
            }
        }
    }
}