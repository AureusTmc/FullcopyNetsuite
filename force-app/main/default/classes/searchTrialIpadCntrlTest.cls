@isTest
public class searchTrialIpadCntrlTest {

    testMethod static void invoksearchTrial(){
        //String userName = UserInfo.getUserName();
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        Country__c countryObj = new Country__c();
        countryObj.Name='SG';
        countryObj.Country_Name__c='Singapore';
        countryObj.Tax_Rate__c=7.00;
        insert countryObj;
            
        
        Centre_Users__c cenUserObj = new Centre_Users__c();
        cenUserObj.User_Name__c=UserInfo.getUserId();
        cenUserObj.Centre_Name__c=objCentr.Id;
        insert cenUserObj;
     /*   Account objCentre=TestUtil.createAccount('Centre',False,false);
        objCentre.CentreName_Cust__c='Aureus Academy - 112 Katong';
        objCentre.Country__c=countryObj.Id; 
        insert objCentre;
       */
        String recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        Account objCentre = TestUtil.createAccount('Centre',false,FALSE);
        objCentre.Country__c = countryObj.Id;
        objCentre.recordTypeId = recordType;
        objCentre.Centre_Status__c = 'Active';
        Insert objCentre;
        
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
       // Account objCentr=TestUtil.createAccount('Centre',False,true);
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentre.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentre.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Attended';
        objEnrol.Trial_Date__c=system.today();
        
        insert objENrol;
        searchTrialIpadCntrl searchTrialObj = new searchTrialIpadCntrl();
        searchTrialObj.getCenters();
        searchTrialObj.getEnrolments();
        searchTrialObj.addDate();
        searchTrialObj.subDate();
        searchTrialObj.redirectToEnrolment();
        searchTrialIpadCntrl.fetchEnrolments('Aur','Singapore');
        
    }
}