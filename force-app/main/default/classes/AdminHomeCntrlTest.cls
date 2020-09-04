@isTest
public class AdminHomeCntrlTest {

    testMethod static void invokeAdminHomeMethod(){
        Account objCentr=TestUtil.createAccount('Centre',False,true);
       
        Centre_Users__c cenUserObj = new Centre_Users__c();
        cenUserObj.User_Name__c=UserInfo.getUserId();
        cenUserObj.Centre_Name__c=objCentr.Id;
        insert cenUserObj;
        
        AdminHomeCntrl adminObj = new AdminHomeCntrl();
        
    }
}