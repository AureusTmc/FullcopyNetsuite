public class UpdateEnrolmentNoCLass {
    
    public static void updatetotalEnrolment(List<Enrolment__c> enrolList){
        set<Id> Ids = new set<Id>();
        List<Account> accountList = new List<Account>();
        List<Account> accList= new List<Account>();
        for(Enrolment__c enrObj:enrolList){
            if(enrObj.Center__c != null){
                Ids.add(enrObj.Center__c);
            }
        }
        system.debug('----->'+Ids);
        accountList=[select Id,Total_Enrolment__c,(select Id from Enrolments3__r where Type__c='Regular' and (Stage__c ='Enrolled' or ( Stage__c='Cancelled' and Package_Process_Type__c='Cancellation' and Package_Process_Status__c='Pending')) )  from Account where Id in:Ids];
        
        for(Account accObj:accountList){
            system.debug('====>'+accObj.Enrolments3__r.size());
            accObj.Total_Enrolment__c=accObj.Enrolments3__r.size();
            accList.add(accObj);
        }
        
        try{
            if(accList.size()>0){
                update accList;
            }   
        }Catch(Exception e){
            System.debug('Exception :'+e.getMessage());
        }
    }

}