/*
  Name  :   AccountTrigger
  Author:  Rajesh
  Date   : 20th July 2019
  Description : This trigger is used to create case when person account sync with Pardot 
 */
trigger AccountTrigger on Account (after insert, after update) {
    List<Account> filterParAcList = new List<Account>();
    
    for(Account ac: Trigger.new){
        //Added by Rajesh on 30th Oct 2019, Add B2BMA Integration user condtion as per discussion with Prashant. To solve duplicate insertion case(sales enquiry) record
        if(ac.LastModifiedById == Label.B2BMA_Integration_UserId && String.isNotBlank(ac.PI_to_SF_Sync__pc) && ac.PI_to_SF_Sync__pc.equalsIgnoreCase('true') && (Trigger.isInsert || 
                                    (Trigger.isUpdate && ac.PI_to_SF_Sync__pc != Trigger.oldMap.get(ac.Id).PI_to_SF_Sync__pc))){
            filterParAcList.add(ac);
        }
    }
    
    if(filterParAcList.size() > 0)
        AccountTriggerHelper.createCaseForPIsyncAccounts(filterParAcList);
    
    //Sanjay Hrms 
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            List<Account> accList = new List<Account>();
            //@Juneid 12 Aug 2020, This list store the Account that have unique code and personContactId
            List<Account>accountsContainsReferal = new List<Account>();
            
            for(Account acc: trigger.new){
                if(acc.Employee_Status__c == 'Probation' || acc.Employee_Status__c == 'Confirm'){
                    if(acc.Joining_Date__c == NULL){
                        acc.addError(label.EmpStatusJoiningDateMandatory);
                    }
                    else if(acc.Employee_Duty_Type__c == NULL){
                        acc.addError(label.EmpStatusDutyTypeMandatory);
                    }
                    else{
                        if(acc.Job_Title__c != NULL)
                            accList.add(acc);
                    }
                }
                //@Juneid 12 Aug Checking for refferal code
                if(acc.PersonContactId != Null && acc.Unique_Referral_Code__c !=Null){
                    accountsContainsReferal.add(acc);
                }
            }
            System.debug(accList);
            if(!accList.isEmpty())
                AureusHRManagementUtil.createEntitlementsForAccount(accList, 'insert');
            
            //@Juneid 12 Aug , Calling helper Method
            if(accountsContainsReferal.size() > 0)
               AccountTriggerHelper.contactRefrelCodeUpdate(accountsContainsReferal);
           
        } 
        else if(Trigger.isUpdate){
            List<Account> accList = new List<Account>();
            Map<Id, Id> mapAccToRMId = new Map<Id, Id>();
            Map<Id, Id> mapAccToRMId2 = new Map<Id, Id>();
            List<Account> accForProbationList = new List<Account>();
            
            for(Account acc: trigger.new){
                if((acc.Employee_Status__c == 'Probation' || acc.Employee_Status__c == 'Confirm') && trigger.oldmap.get(acc.Id).Employee_Status__c != acc.Employee_Status__c && trigger.oldmap.get(acc.Id).Employee_Status__c == 'Draft'){
                    if(acc.Joining_Date__c == NULL){
                        acc.addError(label.EmpStatusJoiningDateMandatory);
                    }
                    else if(acc.Employee_Duty_Type__c == NULL){
                        acc.addError(label.EmpStatusDutyTypeMandatory);
                    }
                    else{
                        if(acc.Job_Title__c != NULL)
                            accList.add(acc);
                    }
                }
                
                if(acc.Onboarding_Stage__c == 'Completed' && trigger.oldmap.get(acc.Id).Onboarding_Stage__c != acc.Onboarding_Stage__c){
                    if(acc.Joining_Date__c == NULL){
                        acc.addError(label.JoiningDateOnboardingProcessError);
                    }
                    else if(acc.Employee_Duty_Type__c== NULL){
                        acc.addError(label.EmployeeDutyTypeOnboardingProcessError);
                    }
                    else if(acc.Reporting_Manager__c == NULL){
                        acc.addError(label.ReportingManagerOnboardingProcessError);
                    }
                }
                
                if(acc.Probation_End_Date__c != null && trigger.oldmap.get(acc.Id).Probation_End_Date__c != acc.Probation_End_Date__c){
                    accForProbationList.add(acc);
                }
                
                if(trigger.oldmap.get(acc.Id).Reporting_Manager__c != acc.Reporting_Manager__c){
                    mapAccToRMId.put(acc.Id, acc.Reporting_Manager__c);
                }
                
                if(trigger.oldmap.get(acc.Id).Reporting_Manager_2__c != acc.Reporting_Manager_2__c){
                    mapAccToRMId2.put(acc.Id, acc.Reporting_Manager_2__c);
                }
            }
            
            System.debug(accList);
            if(!accList.isEmpty())
                AureusHRManagementUtil.createEntitlementsForAccount(accList, 'update');
            if(!mapAccToRMId.isEmpty() || !mapAccToRMId2.isEmpty())
                AureusHRManagementUtil.updateReportingManager(mapAccToRMId, mapAccToRMId2);
            if(!accForProbationList.isEmpty())
                AureusHRManagementUtil.createTaskToTakeActionForProbation(accForProbationList);
        }
    }
}