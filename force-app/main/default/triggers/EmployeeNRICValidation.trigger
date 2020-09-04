trigger EmployeeNRICValidation on Account (before insert,before update) {
    for(Account acc:Trigger.new){
        If(trigger.isInsert || acc.Identification_Number__c!=Trigger.oldMap.get(acc.Id).Identification_Number__c || acc.Tax_Number__c!=Trigger.oldMap.get(acc.Id).Tax_Number__c){
            If((acc.Id_Type__c=='Permanent Resident' || acc.Id_Type__c=='Citizen') &&  acc.Identification_Number__c!=null && acc.Identification_Number__c.trim().length()>0){
                Boolean idNumberValid = AureusHRUtility.nricValidation(acc.Identification_Number__c);
                If(!idNumberValid){
                    acc.addError('Please enter a valid Identification number');
                }
            }
            If(acc.Tax_Number__c!=null && acc.Tax_Number__c.trim().length()>0){
                Boolean taxNumberValid = AureusHRUtility.nricValidation(acc.Tax_Number__c);
                If(!taxNumberValid){
                    acc.addError('Please enter a valid tax number');
                } 
            }
        }
    }
}