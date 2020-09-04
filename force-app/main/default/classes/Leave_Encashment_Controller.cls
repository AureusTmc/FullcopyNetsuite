public class Leave_Encashment_Controller {      
    
    @AuraEnabled
    public static string CreateLeaveEncashment(String PayoutId, String days){        
        try{
            if(PayoutId!=null && days!=null){
                List<Payout__c> LstPayOut = [SELECT Id,Employee_Name__c,Year__c,Month__c  FROM Payout__c WHERE Id=:PayoutId];
                Leave_Encashment_Controller le = new Leave_Encashment_Controller();                
                date EffectiveDt = date.newInstance(integer.valueof(LstPayOut[0].Year__c),le.MonthsMap(LstPayOut[0].Month__c)+1, 1).adddays(-1);
                List<Payitem_Master__c> itemMasterLst = [SELECT Id FROM Payitem_Master__c WHERE Name='Leave Encashment'];
                if(LstPayOut[0].Employee_Name__c!=null){
                    List<Account> LstAccount = [SELECT Id,Name ,(SELECT Id,Working_Days_in_a_Week__c  FROM Employee_Work_Week__r WHERE Effective_Date__c<=:EffectiveDt ORDER BY Effective_Date__c DESC),
                                                (SELECT Id,Basic_Salary__c FROM Salary_Details__r  WHERE Status__c='Active' AND Effective_Date__c<=:EffectiveDt ORDER BY Effective_Date__c DESC) FROM Account WHERE Id=:LstPayOut[0].Employee_Name__c];                    
                    if(LstAccount[0].Employee_Work_Week__r.size()>0 && LstAccount[0].Salary_Details__r.size()>0){
                        if(LstAccount[0].Employee_Work_Week__r[0].Working_Days_in_a_Week__c!=null && LstAccount[0].Salary_Details__r[0].Basic_Salary__c!=null){
                            if(itemMasterLst.size()>0){
                                Decimal value = ((12 * LstAccount[0].Salary_Details__r[0].Basic_Salary__c)/(52 * LstAccount[0].Employee_Work_Week__r[0].Working_Days_in_a_Week__c)) * decimal.valueOf(days);                                  
                                PayItem__c pItemObj = new PayItem__c();
                                pItemObj.Type__c='Amount';
                                pItemObj.Payout__c = PayoutId;
                                pItemObj.Payitem__c=itemMasterLst[0].Id;
                                pItemObj.Value__c=value;
                                insert pItemObj;                                
                                return 'Success';
                            }                    
                        }
                        throw new AuraHandledException( 'Please define the salary and work week of an employee.');                         
                    }
                    throw new AuraHandledException( 'Please define the salary and work week of an employee.');                     
                }
                throw new AuraHandledException( 'Please select the employee.');           
            }
            throw new AuraHandledException( 'ERROR : Something went wrong.');
        }catch(exception e){                       
            throw new AuraHandledException(e.getMessage());          
        }
    }
    
    Public Integer MonthsMap(String month){
        Map<String,Integer> MonthMap = new Map<String,Integer>();
        MonthMap.put('JANUARY', 1);
        MonthMap.put('FEBRUARY', 2);
        MonthMap.put('MARCH', 3);
        MonthMap.put('APRIL', 4);
        MonthMap.put('MAY', 5);
        MonthMap.put('JUNE', 6);
        MonthMap.put('JULY', 7);
        MonthMap.put('AUGUST', 8);
        MonthMap.put('SEPTEMBER', 9);
        MonthMap.put('OCTOBER', 10);
        MonthMap.put('NOVEMBER', 11);
        MonthMap.put('DECEMBER', 12);
        return MonthMap.get(month.toUpperCase());
    }
}