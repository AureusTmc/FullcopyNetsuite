trigger PayoutTrigger on Payout__c (after insert, after update) {
    if(!AureusHRUtility.calledOnce){
        AureusHRUtility.calledOnce = true;
        Set<Id> payoutIds = new Set<Id>();
        for(Payout__c py:Trigger.New){
            payoutIds.add(py.Id);
        }
        
        List<Payout__c> payoutList = [Select id,Total_Amount__c,Employee_CPF_Amount__c,SDL__c,SINDA__c,CDAC__c,EUCF__c,MBMF__c,Total_Payable__c from Payout__c where Id in:payoutIds];
        for(Payout__c py: payoutList){
            py.Total_Payable__c = (py.Total_Amount__c>0?py.Total_Amount__c:0) - (py.Employee_CPF_Amount__c>0?py.Employee_CPF_Amount__c:0) - (py.SINDA__c>0?py.SINDA__c:0) - (py.CDAC__c>0?py.CDAC__c:0) - (py.EUCF__c>0?py.EUCF__c:0) - (py.MBMF__c>0?py.MBMF__c:0);                    
        }
        update payoutList;
    }
}