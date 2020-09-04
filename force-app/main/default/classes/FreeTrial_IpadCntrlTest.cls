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
                
                Account objCentr = TestUtil.createAccount('Centre',false,FALSE);
                objCentr.Country__c = country.Id;
                objCentr.Centre_Status__c = 'Active';
                objCentr.name='Aureus Forum';
                objCentr.CentreName_Cust__c='Aureus Forum'; 
                objCentr.Location__c='Aureus Forum';
                Insert objCentr;
                
                Centre_Users__c centerUserObj = new Centre_Users__c();
                centerUserObj.Designation__c = 'Centre Manager';
                centerUserObj.Centre_Name__c = objCentr.Id;
                centerUserObj.User_Name__c = objUser.Id;
                insert centerUserObj;
                
                Account objTeachr=testUtil.createAccount('Teacher',false,False);
                objTeachr.Minor_Instruments_Disciplines__c='Piano';
                objTeachr.Major_Instruments_Disciplines__c = 'Piano';
                objTeachr.Status__c = ConstantsClass.teacherWorkingStatus;
                objTeachr.Enable_Trial_Bookings__c = true;
                insert objTeachr;
                
                List <Teacher_Working_Hour__c> listTWH = new List <Teacher_Working_Hour__c>();
                For( Teacher_Working_Hour__c objTechWorkHour : TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,false,False,7)){
                    objTechWorkHour.Center_Name__c = objCentr.Id;
                    listTWH.add( objTechWorkHour );
                }
                insert listTWH;
                Program__C objProg = TestUtil.createProgram('Active','Piano',true);
                Package__c objPack = testUtil.createPackage(objProg.id,objCentr.id,'30',false); 
                objPack.Type__c = 'Trial';
                insert objPack;
                
                Class__c objCLass = AureusCalendarControllerTestHelper.createGroupClass('test Group Class1',objPack.id,objCentr.Id,objProg.id,date.today(),date.today().addYears(1),Time.newInstance(11,0,0,0),Time.newInstance(11,30,0,0),objTeachr.Id,false);
                objCLass.Total_Enrolment__c = 2;
                objCLass.Centre_Name__c = objCentr.Id; 
                // objClass.Teacher__c = objTeachr.Id;
                objCLass.Start_Time__c = Time.newInstance(10, 0, 0, 0);
                objCLass.End_Time__c = Time.newInstance( 10, 30, 0, 0);
                insert objClass;
                
                
                
            }//end of profile list size
        }Catch( System.DmlException dmlExcep ){
            system.debug(' error --> ' + dmlExcep.getMessage() + dmlExcep.getLineNumber());
        }
        Catch( Exception dmlExcep ){
            system.debug(' error --> ' + dmlExcep.getMessage() + dmlExcep.getLineNumber());
        }
    }
    
    
    //Method 1st
    public static testMethod void TestData(){
        List< User > listCurrentUser = [ SELECT Id 
                                        FROM User 
                                        WHERE Name = 'testUser'];
        
        Account refrelCustomer=TestUtil.createAccount('Customer',True,false);
        refrelCustomer.FirstName ='test';
        refrelCustomer.LastName = 'Class';
        refrelCustomer.PersonEmail = 'Aureas@Gmail.test'; 
        insert refrelCustomer;
        
        account refrelAccount = [SELECT id,name,Unique_Referral_Code__c from account where id =:refrelCustomer.id];
        string uniqueRefrelCode = refrelAccount.Unique_Referral_Code__c;
        
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
        
        Booking__c objBook = TestUtil.createBooking([ Select id from account where name = 'testTeacher' ].Id,'Lesson','Regular',false);
        objBook.Student__c = objCustmrStu.Id;
        objBook.Start_Time__c = Time.newInstance(8, 30, 0,0);
        objBook.End_Time__c = Time.newInstance(12, 4, 3, 4);
        objBook.Status__c = 'Pending';
        objBook.Type__c = 'Trial';
        objBook.Booking_Date__c = System.today().addDays(7);
        insert objBook;
        System.debug('booking==>'+objBook);
        
        Account objTeachr = [ SELECT Id FROM ACCOUNT WHERE Minor_Instruments_Disciplines__c ='Piano'];
        Account objCentr = [ SELECT Id FROM ACCOUNT WHERE Centre_Status__c = 'Active'];
        Package__c objPack = [ SELECT ID from Package__c ];
        
        Attachment att = new Attachment(ParentId=objTeachr.Id, Name='Profile Image.jpeg',ContentType='image/jpeg',Body=Blob.valueOf('sdf'));
        insert att;
        
        List<Booking__c> bookList = new List<Booking__c>();
        Booking__c bkgObj = TestUtil.createBooking(objTeachr.Id,'Lesson','Regular',false);
        bkgObj.Student__c=objCustmrStu.Id;
        insert bkgObj;
        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false); 
        objENrol.Stage__c = 'Enrolled';
        objENrol.Referral_code_used__c = refrelAccount.Unique_Referral_Code__c;
        objENrol.Referred_by__c = refrelAccount.Id;
        insert objENrol;
        
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(2019, 10, 29), Center__c=Label.Aureus_at_Home_Id, End_Time__c=time.newInstance(10, 0, 0, 0), Enrolment__c=objEnrol.id,
                                                              Package__c=objPack.id, Start_Time__c= time.newInstance(10, 30, 0, 0), Student__c=objCustmr.id, Teacher_Account__c=objTeachr.id, Remarks__c='40',
                                                              IsActive__c=true ,Parent__c=objCustmr.id);
        objFifthLesson.Teacher_Account__c = objTeachr.id;
        insert objFifthLesson;
        
        
        if( listCurrentUser.size() > 0  ){
            
            system.runAs( listCurrentUser[0] ){
                ApexPages.currentPage().getParameters().put('refcode',uniqueRefrelCode);
                
                FreeTrial_IpadCntrl objFreeTrialIpadCntrl = new FreeTrial_IpadCntrl();
                objFreeTrialIpadCntrl.uniqueRefCode = uniqueRefrelCode;
                objFreeTrialIpadCntrl.checkExistingCustomer();
                
                
                objFreeTrialIpadCntrl.slcdNoOfStudent = '1';
                
                objFreeTrialIpadCntrl.slcdCenter = 'Aureus Forum';
                objFreeTrialIpadCntrl.slcdDate= '12/12/2019';
                objFreeTrialIpadCntrl.getNoOfStudent();
                objFreeTrialIpadCntrl.slcdStuIndex =1;
                objFreeTrialIpadCntrl.isPageInMobile = true;
                objFreeTrialIpadCntrl.slcdCenter = [ SELECT Id from Account where name = 'Aureus Forum'].id;
                objFreeTrialIpadCntrl.slcdInstrument = 'Piano';
                objFreeTrialIpadCntrl.setTrialInsetrument();
                objFreeTrialIpadCntrl.fetchPreWeekSlot();
                objFreeTrialIpadCntrl.fetchNextWeekSlot();
                objFreeTrialIpadCntrl.processDuration();
                objFreeTrialIpadCntrl.slcdTeacher();
                objFreeTrialIpadCntrl.processExistingStu();
                objFreeTrialIpadCntrl.slcdDate = System.today().addDays(1).format();
                objFreeTrialIpadCntrl.slcdSlot ='12:15';
                objFreeTrialIpadCntrl.enrModelList[0].slcdInstrument = 'Piano';
                objFreeTrialIpadCntrl.fetchTeacherDetails();
                objFreeTrialIpadCntrl.getCenters();
                
                Test.startTest();
                objFreeTrialIpadCntrl.backBtnCmp1();
                objFreeTrialIpadCntrl.nextBtnCmp1();
                objFreeTrialIpadCntrl.backBtnCmp2();
                objFreeTrialIpadCntrl.nextBtnCmp2();
                objFreeTrialIpadCntrl.backBtnCmp3();
                objFreeTrialIpadCntrl.nextBtnCmp3();
                objFreeTrialIpadCntrl.backBtnCmp4();
                objFreeTrialIpadCntrl.backBtnCmp6();
                objFreeTrialIpadCntrl.nextBtnCmp6();
                objFreeTrialIpadCntrl.backBtnCmp5();
                objFreeTrialIpadCntrl.enrModelList[0].studentAcc = objCustmrStu;
                objFreeTrialIpadCntrl.isParAlsoAStudent = true;
                objFreeTrialIpadCntrl.nextBtnCmp4();
                objFreeTrialIpadCntrl.enrModelList[0].slcdSlot = '12:15';
                objFreeTrialIpadCntrl.enrModelList[0].slcdDuration = 30;
                objFreeTrialIpadCntrl.saveTrialData();
                objFreeTrialIpadCntrl.parentAcc.PersonEmail = 'test1@tmc.com';
                objFreeTrialIpadCntrl.saveTrialData();
                
                
                
                objFreeTrialIpadCntrl.slcdLessonType();
                objFreeTrialIpadCntrl.fetchInstrumentForGrpLsn();
                objFreeTrialIpadCntrl.slcdCenter = objFreeTrialIpadCntrl.slcdCenter.replace('U','K');
                objFreeTrialIpadCntrl.slcdLessonType();
                objFreeTrialIpadCntrl.slcdLsnType = 'Individual1';
                objFreeTrialIpadCntrl.slcdLessonType();
                objFreeTrialIpadCntrl.countryCode = 'SG';
                objFreeTrialIpadCntrl.slcdCenter = objBook.Id;	// Used for cls.Centre_Name__c != slcdCenter
                objFreeTrialIpadCntrl.fetchInstrumentForGrpLsn();
                
                objFreeTrialIpadCntrl.enrModelList[0].slcdLsnType = 'Group';
                objFreeTrialIpadCntrl.slcdCenter = [ SELECT Id from Account where name = 'Aureus Forum'].id;
                objFreeTrialIpadCntrl.slcdTchrId = [ SELECT Id from Account where name = 'testTeacher'].id;
                
                objBook.RecordTypeId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Group Class').getRecordTypeId(); 
                objBook.Class__c = [ SELECT Id From Class__c LIMIT 1 ][0].Id;
                objBook.Booking_Date__c =  objFreeTrialIpadCntrl.enrModelList[0].slcdDateDt; 
                update objBook;
                
                
                FreeTrial_IpadCntrl.TeacherModel objTeacherModel = new FreeTrial_IpadCntrl.TeacherModel( objBook.Teacher_Account__c, 'tecName', 'teacBioCon', 'highestQualification', new List< String > {'highestQualification'});
                objFreeTrialIpadCntrl.slcdTeacher();
                objFreeTrialIpadCntrl.slcdCenter = Label.Aureus_at_Home_Id;
                objFreeTrialIpadCntrl.saveTrialData();
                
                
                objFreeTrialIpadCntrl.slcdStuIndex = 1;
                objFreeTrialIpadCntrl.enrModelList[0].slcdInstrument = 'Piano';
                
                objFreeTrialIpadCntrl.slcdDate = '3/19/2020';
                objFreeTrialIpadCntrl.enrModelList[0].slcdFullSlot = '@@@@10:15';
                
                objFreeTrialIpadCntrl.enrModelList[0].slcdSlotTchrs.add( objTeacherModel );
                objFreeTrialIpadCntrl.enrModelList.add( objFreeTrialIpadCntrl.enrModelList[0] );
                
                system.debug('Trial enrol --->  ' + objFreeTrialIpadCntrl.enrModelList[0] );
                system.debug('test time -->?  ' +objFreeTrialIpadCntrl.enrModelList[0].slcdFullSlot.substring(4, objFreeTrialIpadCntrl.enrModelList[0].slcdFullSlot.length()));
                
                objFreeTrialIpadCntrl.fetchTeacherDetails();
                
                objFreeTrialIpadCntrl.enrModelList[0].calStartDate = System.today();
                objFifthLesson.Booking_Date__c = objFreeTrialIpadCntrl.enrModelList[0].calStartDate;
                update objFifthLesson;
                
                system.debug('objFifthLesson ---> ' + objFifthLesson );
                objFreeTrialIpadCntrl.enrModelList[0].calStartDate = System.today().addDays(6);
                objFreeTrialIpadCntrl.enrModelList[0].slcdDuration = 30;
                objFreeTrialIpadCntrl.slcdCenter = objCentr.Id;
                objFreeTrialIpadCntrl.fetchTimeSlot( objFreeTrialIpadCntrl.enrModelList[0] );
                
                objFreeTrialIpadCntrl.isParAlsoAStudent = false;
                objFreeTrialIpadCntrl.checkExistingCustomer();
                objFreeTrialIpadCntrl.slcdCenter = Label.Aureus_at_Home_Id;
                objFreeTrialIpadCntrl.fetchInstrument();
                Test.stopTest();
                
            }
        }
    }
     @isTest
    private static void unitTest2(){
        
        List< User > listCurrentUser = [ SELECT Id 
                                        FROM User 
                                        WHERE Name = 'testUser'];
        
        Country__c cntry = new Country__c();
        cntry.Name = 'SG';
        cntry.Country_Name__c ='Singapore';
        cntry.Currency_Code__c ='SGD';
        cntry.Tax_Rate__c = 7;
        cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        cntry.Stripe_Base_Url__c ='https://api.stripe.com';
        cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        insert cntry;
        
        School__c schl =  TestUtil.createSchool(false);
        schl.Country__c = cntry.Id;
        INSERT schl;
        
        Organisation__c organisation = new Organisation__c(
            Name = 'Aureus Academy Singapore',
            Bank_Account_Number__c = '647743343001',
            Bank_Name__c = 'OVERSEA-CHINESE BANKING CORP GROUP',
            Branch_Code__c = '001',
            CPF_Advice_Code__c = '01',
            CPF_Payment_Type__c = 'PTE',
            Country__c =cntry.Id,
            Sage_Company__c = 'AGP');
        insert organisation;
        
        
        Referral_Discount__c referral_discount = new Referral_Discount__c(
            Name = 'Std. Referral (SG)',
            Discount_Amount_Referrer__c = 70.09,
            Discount_Amount_Referee__c = 70.09,
            Country__c = cntry.Id,
            Default__c = 'Yes',
            Active__c = 'Yes');
        insert referral_discount;
        
        
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = cntry.Id;
        objCentr.Organisation__c = organisation.Id;
           Insert objCentr;
        
        
             Account refrelCustomer=TestUtil.createAccount('Customer',True,false);
        refrelCustomer.FirstName ='test';
        refrelCustomer.LastName = 'Class';
        refrelCustomer.PersonEmail = 'Aureas@Gmail.test'; 
        insert refrelCustomer;
        
        
        account refrelAccount = [SELECT id,name,Unique_Referral_Code__c from account where id =:refrelCustomer.id];
        string uniqueRefrelCode = refrelAccount.Unique_Referral_Code__c;
         Account objtechr=TestUtil.createAccount('Teacher',False,true);
           Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.Referred_by__c =refrelAccount.Id;
           Program__C objProg=TestUtil.createProgram('Active','Piano',true);
            Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true); 
          Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objtechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Pending Enrolment';
        objEnrol.Lessons_Start_Date__c = System.today().addDays(10);
         objEnrol.Referral_code_used__c = refrelAccount.Unique_Referral_Code__c;
        objEnrol.Referred_by__c = refrelAccount.Id;
        insert objENrol;
      
     
        FreeTrial_IpadCntrl freeTrailObj = new FreeTrial_IpadCntrl();
        freeTrailObj.sendMailToReffrel(objENrol);
                    
        
    }
    
    
}