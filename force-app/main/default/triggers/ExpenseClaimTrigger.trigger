trigger ExpenseClaimTrigger on Expense_Claim__c (Before Update, After Update){
    public static Boolean isFirstTime = true;
    
    if(isFirstTime){
        isFirstTime = false;
        
        if(Trigger.isBefore){
            if(Trigger.isUpdate){
                Set<Id> approvedExpClaim = new Set<Id>();
                Set<Id> rejectedExpClaim = new Set<Id>();
                
                for(Expense_Claim__c expClaim: Trigger.new){
                    if(expClaim.Status__c == 'Approved' && Trigger.oldMap.get(expClaim.Id).Status__c != expClaim.Status__c){
                        approvedExpClaim.add(expClaim.Id);
                    }
                    else if(expClaim.Status__c == 'Rejected' && Trigger.oldMap.get(expClaim.Id).Status__c != expClaim.Status__c){
                        rejectedExpClaim.add(expClaim.Id);
                    }
                }
                
                List<Expense_Item__c> expItemList = [SELECT Id, Status__c, Expense_Claim__c, Amount__c FROM Expense_Item__c WHERE (Expense_Claim__c IN: approvedExpClaim OR Expense_Claim__c IN: rejectedExpClaim)];
                
                Map<Id, Decimal> mapExpClaimToApprovedAmt = new Map<Id, Decimal>();
                Map<Id, Decimal> mapExpClaimToAppliedAmt = new Map<Id, Decimal>();
                
                for(Expense_Item__c expItem: expItemList){                
                    Decimal appliedAmt = 0;
                    
                    if(mapExpClaimToAppliedAmt.containsKey(expItem.Expense_Claim__c)){
                        appliedAmt = mapExpClaimToAppliedAmt.get(expItem.Expense_Claim__c);
                    }
                    if(expItem.Amount__c != NULL)
                        appliedAmt += expItem.Amount__c;
                    mapExpClaimToAppliedAmt.put(expItem.Expense_Claim__c, appliedAmt);
                    System.debug(expItem.Expense_Claim__c);
                    System.debug(expItem.Status__c);
                    
                    if(approvedExpClaim.contains(expItem.Expense_Claim__c) && (expItem.Status__c == 'Draft' || expItem.Status__c == 'Pending' || expItem.Status__c == 'Approved')){
                        expItem.Status__c = 'Approved';
                        
                        Decimal approvedAmt = 0;
                        if(mapExpClaimToApprovedAmt.containsKey(expItem.Expense_Claim__c)){
                            approvedAmt = mapExpClaimToApprovedAmt.get(expItem.Expense_Claim__c);
                        }
                        if(expItem.Amount__c != NULL){
                            approvedAmt += expItem.Amount__c;
                        }
                        mapExpClaimToApprovedAmt.put(expItem.Expense_Claim__c, approvedAmt);
                    }else if(rejectedExpClaim.contains(expItem.Expense_Claim__c)){
                        expItem.Status__c = 'Rejected';
                    }
                    
                }
                
                System.debug(mapExpClaimToApprovedAmt);
                System.debug(mapExpClaimToAppliedAmt); 
                
                for(Expense_Claim__c expClaim: Trigger.new){
                    If(expClaim.Currency_Code__c=='SGD' && mapExpClaimToApprovedAmt.containsKey(expClaim.Id)){
                        expClaim.Converted_Amount__c= mapExpClaimToApprovedAmt.get(expClaim.Id);
                    }
                    if(mapExpClaimToAppliedAmt.containsKey(expClaim.Id) && mapExpClaimToApprovedAmt.containsKey(expClaim.Id)){
                        if(mapExpClaimToAppliedAmt.get(expClaim.Id) != mapExpClaimToApprovedAmt.get(expClaim.Id) && mapExpClaimToApprovedAmt.get(expClaim.Id) > 0){
                            expClaim.Status__c = 'Partial Approved';
                        }
                    }
                }
            }
        }
        if(Trigger.isAfter){
            if(Trigger.isUpdate){
                Set<Id> approvedExpClaim = new Set<Id>();
                Set<Id> rejectedExpClaim = new Set<Id>();
                
                for(Expense_Claim__c expClaim: Trigger.new){
                    if((expClaim.Status__c == 'Approved' || expClaim.Status__c == 'Partial Approved') && Trigger.oldMap.get(expClaim.Id).Status__c != expClaim.Status__c){
                        approvedExpClaim.add(expClaim.Id);
                    }else if(expClaim.Status__c == 'Rejected' && Trigger.oldMap.get(expClaim.Id).Status__c != expClaim.Status__c){
                        rejectedExpClaim.add(expClaim.Id);
                    }
                }
                
                List<Expense_Item__c> expItemList = [SELECT Id, Status__c, Expense_Claim__c FROM Expense_Item__c WHERE (Expense_Claim__c IN: approvedExpClaim OR Expense_Claim__c IN: rejectedExpClaim)];
                
                for(Expense_Item__c expItem: expItemList){
                    if(approvedExpClaim.contains(expItem.Expense_Claim__c) && (expItem.Status__c == 'Draft' || expItem.Status__c == 'Pending')){
                        expItem.Status__c = 'Approved';
                    }else if(rejectedExpClaim.contains(expItem.Expense_Claim__c)){
                        expItem.Status__c = 'Rejected';
                    }
                }
                
                if(!expItemList.isEmpty()){
                    update expItemList;
                }
            }
        }
    }
}