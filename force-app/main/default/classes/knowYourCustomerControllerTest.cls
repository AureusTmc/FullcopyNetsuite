@istest
public class knowYourCustomerControllerTest {
    @testSetup static void initDataForTest(){
        Account objCustmr=TestUtil.createAccount('Customer',True,true);
    }
    
    public static testMethod void test1(){
        String parentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();  
        Account objCustmr =[Select id from Account where recordType.name='Customer'];
        Account childone = new Account();
        childone.Parent__c = objCustmr.id;
        childone.lastname = 'childone';
        childone.RecordTypeId = parentRecordTypeId;
        insert childone;
        
        Account childtwo = new Account();
        childtwo.lastname = 'childtwo';
        childtwo.Parent__c = objCustmr.id;
        childtwo.personbirthdate = system.today();
        childtwo.RecordTypeId = parentRecordTypeId;
        insert childtwo; 
        
        PageReference pageRef = Page.knowYourCustomerPage; // Add your VF page Name here
        
        pageRef.getParameters().put('id', String.valueOf(objCustmr.Id));
        pageRef.getParameters().put('postalcode', '1234567');
        Test.setCurrentPage(pageRef);
        knowYourCustomerController knowYourCustomerCtrlObj=new knowYourCustomerController();
        
        //StudentWrapper StudentWrapperObj=new StudentWrapper();
        
        knowYourCustomerCtrlObj.getAccoungGenderPicklist();
        knowYourCustomerCtrlObj.getAccoungNationalityPicklist();
        knowYourCustomerCtrlObj.getAccoungBillCntryPicklist();
        knowYourCustomerCtrlObj.getSchoolPicklist();
        knowYourCustomerCtrlObj.updateDetail();
        knowYourCustomerCtrlObj.fetchFullAddress();
        
    }
    
}