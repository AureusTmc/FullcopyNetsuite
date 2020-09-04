@isTest
public class PublicHolidayTest {

    static testMethod void invokeTiggerMethod(){
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
        
        Organisation__c org = new Organisation__c(Name='Test',Country__c=cntry.Id);
        insert org;
        
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c =cntry.Id;
        objCentr.Organisation__c=org.Id;
        insert objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,false);
        objtechr.Employee_Duty_Type__c='Non-Duty';
        objtechr.Organisation__c=org.Id;
        insert objtechr;
        Datetime dt = DateTime.newInstance(system.today().addDays(7), Time.newInstance(0, 0, 0, 0));
        String dayOfWeek=dt.format('E');
        Teacher_Working_Hour__c tw = new Teacher_Working_Hour__c();
        tw.Active__c = true;
        tw.Break_Time__c=false;
        tw.Teacher_Name__c=objtechr.id;
        tw.Center_Name__c=objCentr.Id;
        tw.Working_Day__c=dayOfWeek;
        tw.Start_Time__c=Time.newInstance(7,0,0,0);
        tw.End_Time__c=Time.newInstance(23,0,0,0);
        
        insert tw;
        
        Public_Holiday__c pubholObj= new Public_Holiday__c(Name='Test',Organisation_Status__c='Closed',Public_Holiday_Date__c=system.today().addDays(7),
                                                           Execution_Date__c=system.today(),Status__c='Pending for execution',Country__c=cntry.Id,Organisation__c=org.Id);
        insert pubholObj;
       // List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objtechr.id,objCentr.Id,true,False,7);
    }
    
     static testMethod void invokeTiggerMethod2(){
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
        
        Organisation__c org = new Organisation__c(Name='Test',Country__c=cntry.Id);
        insert org;
        
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c =cntry.Id;
         objCentr.Organisation__c=org.Id;
        insert objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,false);
        objtechr.Employee_Duty_Type__c='Duty';
         objtechr.Organisation__c=org.Id;
        insert objtechr;
        Datetime dt = DateTime.newInstance(system.today().addDays(7), Time.newInstance(0, 0, 0, 0));
        String dayOfWeek=dt.format('E');
        Teacher_Working_Hour__c tw = new Teacher_Working_Hour__c();
        tw.Active__c = true;
        tw.Break_Time__c=false;
        tw.Teacher_Name__c=objtechr.id;
        tw.Center_Name__c=objCentr.Id;
        tw.Working_Day__c=dayOfWeek;
        tw.Start_Time__c=Time.newInstance(7,0,0,0);
        tw.End_Time__c=Time.newInstance(23,0,0,0);
        
        insert tw;
        
        Public_Holiday__c pubholObj= new Public_Holiday__c(Name='Test',Organisation_Status__c='Open',Public_Holiday_Date__c=system.today().addDays(7),
                                                           Execution_Date__c=system.today(),Status__c='Pending for execution',Country__c=cntry.Id,Organisation__c=org.Id);
        insert pubholObj;
         pubholObj.Status__c='Draft';
         update pubholObj;
       // List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objtechr.id,objCentr.Id,true,False,7);
    }
}