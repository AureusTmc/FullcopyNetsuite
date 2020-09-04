/*
        Name        :    CCExpirationNotificationBatch 
        Date        :    02/Aug/2019
        Author      :  
        Description :    This batch class is used to send reminder parent card CC is expire
      
*/
global class CCExpirationNotificationBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    private Integer noOfDays;
    public CCExpirationNotificationBatch (Integer days){
        this.noOfDays= days;
    } 
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date preDate = system.today().addDays(noOfDays);
        String year = String.valueOf(preDate.year());
        String dateFormat = preDate.Month()+'/'+ year.substring(2,4);
        system.debug('dateFormat'+dateFormat);
        return Database.getQueryLocator([select id,name,Expiry_Date__c,FCM_Token__c,Card_Number__c,Card_Type__c 
                                        FROM Account
                                        WHERE Expiration__c=: dateFormat 
                                        AND Card_Number__c!=null 
                                        AND FCM_Token__c !=null 
                                        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accountList){
       system.debug('accountList'+accountList);
       List<Mobile_Notification__c> listOfMobileNotification = new List<Mobile_Notification__c>();
        for(Account accountObj: accountList){
                 String  title =  'Your Payment on file '+accountObj.Card_Type__c+' x ' +accountObj.Card_Number__c+' is expiring soon.';
                 String  bodymsg = 'Please update your billing details by going to your account and adding a new card.';
                 String to = accountObj.FCM_Token__c;
                Mobile_Notification__c log = FirebaseNotificationHelper.sendNotificationBatch(accountObj.id, to, title, bodymsg);
                if(log != null) listOfMobileNotification.add(log); 
              
               
        }
        system.debug('listOfMobileNotification'+listOfMobileNotification);
        if(listOfMobileNotification.size() > 0 && listOfMobileNotification!= Null){
            insert listOfMobileNotification;
        }
        
    }

    global void finish(Database.BatchableContext BC){
       
    }
    
}