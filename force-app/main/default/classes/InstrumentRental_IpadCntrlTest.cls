@isTest
public class InstrumentRental_IpadCntrlTest {
    @testSetup
    public static void createData(){
        User usr = TestUtil.createUser(true);
        Account acc = TestUtil.createAccount('Centre',False,true);
        
        
        System.debug('accid==>'+acc.id);
        Account acc2 =  TestUtil.createAccount('Customer',False,true);
        Centre_Users__c cntrUsr = TestUtil.createCentreUser(true);
        Payment__c pymnt = TestUtil.createPayment(acc2.id, true);
        Invoice__c inv = TestUtil.createInvoice(acc2.id, true);
        
        CampEnrolmentTestHelper.createCampData();
    }
    
    public static testMethod void test1(){
        User u = [SELECT ID from User LIMIT 1];
        System.runAs(u){
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
            
            Account accCenter = [SELECT ID from Account WHERE RecordType.name= 'Centre' LIMIT 1];
            accCenter.Country__c = country.id;
            accCenter.Piano_Viewing_Available__c = true;
            accCenter.Centre_Status__c='Active';
            accCenter.CentreName_Cust__c = 'Aureus Academy - Northpoint South W (#02-179/180)';
            update accCenter;
            
            Account cutmrAcc= [SELECT Id,phone from Account WHERE RecordType.name='Customer' LIMIT 1];
            cutmrAcc.PersonEmail = 's@g.com';
            
            update cutmrAcc;
            InstrumentRental_IpadCntrl insRentl = new InstrumentRental_IpadCntrl();
            insRentl.slcdCenter = accCenter.id;
            insRentl.slcdStuIndex = 1;
            insRentl.slcdSlot ='00:00:00:00';
            insRentl.slcdDuration = 4;
            insRentl.slcdDate =System.today().format();
          
            
            InstrumentRental_IpadCntrl.TrialEnrModel trimdl = new InstrumentRental_IpadCntrl.TrialEnrModel();
        
            trimdl.slcdDateDt = date.today();
            trimdl.slcdFullSlot = '00:00:00:00';
            insRentl.enrModelList = new List< InstrumentRental_IpadCntrl.TrialEnrModel>{trimdl};
                System.debug('insRentl.enrModelList==>'+insRentl.enrModelList.size());
            
             
            Account objTeacher=TestUtil.createAccount('Teacher',False,true);
            objTeacher.Job_Title__c = 'Sales Executive';
            update objTeacher;
            
            List <Teacher_Working_Hour__c> objTWh=TestUtil.createTeacher_Working_Hour(objTeacher.id,accCenter.id,true,true,7);
            objTWh[0].Active__c = true;
            objTWh[0].Working_Day__c = 'Fri';
            objTWh[0].Break_Time__c = False;
            objTWh[0].Start_Time__c = Time.newInstance(1, 2, 3, 4);
            objTWh[0].End_Time__c = Time.newInstance(4, 2, 3, 4);
            objTWh[0].Teacher_Name__c = objTeacher.id;
            objTWh[0].Center_Name__c = insRentl.slcdCenter;
            update objTWh[0];
            
            Centre_Users__c cusr = [SELECT ID FROM Centre_Users__c];
            cusr.User_Name__c = u.id;
            cusr.Centre_Name__c = accCenter.id;
            //cusr.PersonEmail = 's@g.com';
            update cusr;
            
            Program__c pgm = TestUtil.createProgram('Active', 'Music Exploration', true);
            
            Qualification__c quf = TestUtil.createQualification(objTeacher.id,pgm.id,'',true);
            /*
              Map<string,string> entrdDataMap=TestUtil.createData(); 
        Enrolment__c objEnr=[select Id, Name, Package__r.Name, Student__r.Name, Teacher__r.Name, Parent__r.Name, 
                             Parent__r.PersonEmail, Trial_Date__c,Type__c,Stage__c from Enrolment__c 
                             where id=:entrdDataMap.get('objEnrol')];
        objEnr.Type__c='Trial';
        objEnr.Stage__c='Attended';
        objEnr.Parent__r.PersonEmail='testEmail@gmail.com';
        update objEnr; 
           */
            
            Package__c pkg = TestUtil.createPackage(pgm.id, accCenter.id, '30', true);
            Enrolment__c enrl = testUtil.createEnrolment(accCenter.id, objTeacher.id, cutmrAcc.id, pkg.id, true);
            enrl.name = 'test'; 
            enrl.Trial_Date__c = Date.valueOf(String.valueOf('2020-02-03'));
            
           // enrl.Parent__r.Personemail = 'test@g.com';
            update enrl;
            System.debug('enrl date'+enrl.Trial_Date__c);
            
            test.startTest();
             InstrumentRental_IpadCntrl.EnrolmentModel enrlMdlWrp = new  InstrumentRental_IpadCntrl.EnrolmentModel(enrl,'test');
           
            insRentl.getCenters();
            insRentl.slcdParId = accCenter.id;
            insRentl.checkAtHome();
            insRentl.setTrialInsetrument();
            insRentl.backBtnCmp2();
            insRentl.nextBtnCmp2();
            insRentl.backBtnCmp3();
            insRentl.nextBtnCmp3();
            insRentl.newCstmr();
            insRentl.backCstmrSearchPage();
            insRentl.backBtnCmp4();
            insRentl.nextBtnCmp4();
            insRentl.backBtnCmp5();
            insRentl.fetchPreWeekSlot();
            insRentl.fetchNextWeekSlot();
            insRentl.processDuration();
            insRentl.processExistingStu();
            insRentl.slcdTeacher();
            insRentl.fetchInstrument();
            insRentl.fetchTeacherDetails();
            insRentl.saveTrialData();
            pkg.Active__c = true;
            pkg.Location__c = insRentl.slcdCenter;
            pkg.Type__c = 'Trial';
            pkg.Duration__c = '45';
            pkg.RecordTypeId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Item').getRecordTypeId(); 
            update pkg;
              insRentl.parentAcc = cutmrAcc;
             insRentl.saveTrialData();
           // insRentl.validateSlcdSlot();
            InstrumentRental_IpadCntrl.fetchEnrolments('test','SGD');
            test.stopTest();
        }
    }
}