@isTest
public class PublicHolidayProcessTest {

    static testMethod void invokeBatch(){
        Firebase_Settings__c sett = new Firebase_Settings__c();
        sett.Enable_Logs__c =true;
        sett.Name ='setting';
        sett.Enable_Notifications__c=true;
        sett.API_Key__c = 'Whatever';
        sett.Enable_Logs__c = false;
        sett.Endpoint__c = 'Endpoint__c';
        insert sett;
        
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
        
       /* Organisation__c org = new Organisation__c(Name='Test',Country__c=cntry.Id);
        insert org;*/
         // update 21 09 2020 @nishi jain 
        
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = cntry.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        Insert organisationRecord;

        
        Public_Holiday__c pubholObj= new Public_Holiday__c(Name='Test',Organisation_Status__c='Closed',Public_Holiday_Date__c=system.today().addDays(7),
                                                  Execution_Date__c=system.today(),Status__c='Pending for execution',Country__c=cntry.Id,Organisation__c=organisationRecord.Id);
        insert pubholObj;
        
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,false);
         objCentr.name='Aureus Forum';
        objCentr.Country__c =cntry.Id;
        objCentr.Organisation__c=organisationRecord.Id;
        objCentr.Location__c='Aureus Forum';
        insert objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,false);
        objCentr.CentreName_Cust__c='Aureus Forum';
        objtechr.Employee_Duty_Type__c='Duty';
        insert objtechr;
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        // creating the enrolment
        insert objENrol;
        
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Regular',False);
        ObjBook.Enrolment__c=objEnrol.id;
        objBook.Center__c=objCentr.Id;
        objBook.Status__c='Pending';
        objBook.Canceled_Date__c= system.today();
        //objBook.Category__c='Placeholder';
        objBook.Booking_Date__c=System.today().addDays(7);
        // creating the booking 
        insert objBook;
        
        list<Fifth_Lesson__c> fifthList= new list<Fifth_Lesson__c>();
        for(Integer i=0;i<=1;i++){
            Fifth_Lesson__c objfif = new Fifth_Lesson__c();
            objfif.Teacher_Account__c=objtechr.Id;
            objfif.Booking_Date__c=System.today().addDays(7);
            objfif.Center__c=objCentr.Id;
            objfif.IsActive__c=true;
            fifthList.add(objfif);
        }
        insert fifthList;
        
        PublicHolidayProcessScheduler objSch=new PublicHolidayProcessScheduler();
        objSch.execute(Null);
    }
    
    static testMethod void invokeBatchTwo(){
        Firebase_Settings__c sett = new Firebase_Settings__c();
        sett.Enable_Logs__c =true;
        sett.Name ='setting';
        sett.Enable_Notifications__c=true;
        sett.API_Key__c = 'Whatever';
        sett.Enable_Logs__c = false;
        sett.Endpoint__c = 'Endpoint__c';
        insert sett;
        
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
        
       /* Organisation__c org = new Organisation__c(Name='Test',Country__c=cntry.Id);
        insert org;*/
        
        // update 21 09 2020 @nishi jain 
        // 
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = cntry.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        Insert organisationRecord;
        
        Public_Holiday__c pubholObj= new Public_Holiday__c(Name='Test',Organisation_Status__c='Open',Public_Holiday_Date__c=system.today().addDays(7),
                                                  Execution_Date__c=system.today(),Status__c='Pending for execution',Country__c=cntry.Id,Organisation__c=organisationRecord.Id);
        insert pubholObj;
        
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.name='Aureus Forum';
        objCentr.Country__c =cntry.Id;
        objCentr.Organisation__c=organisationRecord.Id;
        objCentr.Location__c='Aureus Forum';
        insert objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,false);
        objtechr.Employee_Duty_Type__c='Duty';
        objCentr.CentreName_Cust__c='Aureus Forum';
        insert objtechr;
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        // creating the enrolment
        insert objENrol;
        
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Regular',False);
        ObjBook.Enrolment__c=objEnrol.id;
        objBook.Center__c=objCentr.Id;
        objBook.Status__c='Pending';
        objBook.Canceled_Date__c= system.today();
        //objBook.Category__c='Placeholder';
        objBook.Booking_Date__c=System.today().addDays(7);
        // creating the booking 
        insert objBook;
        list<Fifth_Lesson__c> fifthList= new list<Fifth_Lesson__c>();
        for(Integer i=0;i<=1;i++){
            Fifth_Lesson__c objfif = new Fifth_Lesson__c();
            objfif.Teacher_Account__c=objtechr.Id;
            objfif.Booking_Date__c=System.today().addDays(7);
            objfif.Center__c=objCentr.Id;
            objfif.IsActive__c=true;
            fifthList.add(objfif);
        }
       
        insert fifthList;
        PublicHolidayProcessScheduler objSch=new PublicHolidayProcessScheduler();
        objSch.execute(Null);
    }
}