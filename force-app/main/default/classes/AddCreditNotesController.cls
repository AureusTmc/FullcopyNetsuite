public with sharing class AddCreditNotesController {
    @AuraEnabled
    public static String  getReasonListValues(String parentAccId) {
        List<ReasonPicklist> pickListValuesList= new List<ReasonPicklist>();
        Schema.DescribeFieldResult fieldResult = Customer_Adhoc_Discount__c.Reason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            ReasonPicklist reasonObj = new ReasonPicklist();
            reasonObj.label=pickListVal.getLabel();
            reasonObj.value=pickListVal.getvalue();
            pickListValuesList.add(reasonObj);
        }     
        return getParentAccount(pickListValuesList,parentAccId);
        
    } 
    public static String  getParentAccount( List<ReasonPicklist> pickListValuesList, String parentAccId){
        Account objectOfAccount = [SELECT Parent__c, Parent__r.Name, Name ,Id  FROM Account
                                   WHERE Id =: parentAccId];
        PaymentReason reasonObj = new PaymentReason();
        reasonObj.listOfReasonPicklistValues = pickListValuesList;
        if(objectOfAccount.Parent__c != null){
            reasonObj.accountName = objectOfAccount.Parent__r.Name;
            reasonObj.accountId = objectOfAccount.Parent__c;
        }else{
            reasonObj.accountName = objectOfAccount.Name;
            reasonObj.accountId = objectOfAccount.Id;
        }
        List<PermissionSetAssignment> listofPermissionSetAssignment = [SELECT Id FROM PermissionSetAssignment 
                                                                       WHERE AssigneeId = :Userinfo.getUserId() 
                                                                       AND PermissionSet.Name = 'Enable_Finance_User'];
        if(listofPermissionSetAssignment.size() > 0){
            reasonObj.userAccess = true;
        }else{
            reasonObj.userAccess = false;
        }   
        return  JSON.serialize(reasonObj);
    }
    @AuraEnabled
    public static String createPayment(String amount,String accountId,String reason,String otherReason){
        Customer_Adhoc_Discount__c objectOfPayment = new Customer_Adhoc_Discount__c(Discount_Amount__c = amount != null ? Decimal.valueOf(amount): 0,
                                                    Parent__c = accountId,
                                                    Reason__c = reason,
                                                    Remark__c = otherReason,
                                                    Discount_Date__c = Date.today(),
                                                    Status__c ='Pending' 
                                                    );
        try{
            Insert objectOfPayment;
            return 'SUCCESS';
        }catch(exception e){
            return e.getMessage();
        }
    }
    public class ReasonPicklist{
        public String label{get;set;}
        public String value{get;set;}
    }
    public class PaymentReason{
        public List<ReasonPicklist> listOfReasonPicklistValues{get;set;}
        public String accountName{get;set;}
        public String accountId{get;set;}
        public Boolean userAccess{get;set;}
    }
}