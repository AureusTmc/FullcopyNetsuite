@isTest
public class searchTrialIpadCntrlTest {
    
    testMethod static void invoksearchTrial(){
        Country__c countryObj = new Country__c();
        countryObj.Name='SG';
        countryObj.Country_Name__c='Singapore';
        countryObj.Tax_Rate__c=7.00;
        insert countryObj;
        
        Organisation__c organisation = new Organisation__c(
            Name = 'Aureus Academy Singapore',
            Bank_Account_Number__c = '647743343001',
            Bank_Name__c = 'OVERSEA-CHINESE BANKING CORP GROUP',
            Branch_Code__c = '001',
            CPF_Advice_Code__c = '01',
            CPF_Payment_Type__c = 'PTE',
            Country__c =countryObj.Id,
            Sage_Company__c = 'AGP');
        insert organisation;
        
        //String userName = UserInfo.getUserName();
        /* Account objCentr=TestUtil.createAccount('Centre',False,false);
objCentr.Organisation__c = organisation.Id;
insert      objCentr;   */
        
        
        
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
        objCentre.Organisation__c = organisation.Id;
        Insert objCentre;
        Centre_Users__c cenUserObj = new Centre_Users__c();
        cenUserObj.User_Name__c=UserInfo.getUserId();
        cenUserObj.Centre_Name__c=objCentre.Id;
        insert cenUserObj;
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