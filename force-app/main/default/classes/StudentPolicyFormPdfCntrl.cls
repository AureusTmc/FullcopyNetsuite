public class StudentPolicyFormPdfCntrl {
    public Date dt{get;set;}
    public String parName{get;set;}
    public String attId{get;set;}
    
    public StudentPolicyFormPdfCntrl(){		   
        dt = System.today();
        
        string invId = Apexpages.currentPage().getParameters().get('Id');     
        
        if(String.isNotBlank(invId)){
            List<Invoice__c> invList = [Select Id, Name, Parent_Account__c, Parent_Account__r.Name, 
                                        (Select Id, Enrolment__c, Subscription_Line_Item__r.Enrolment__c, Discount_Amount__c
                                             from Invoice_Line_Items__r LIMIT 1)
                                        FROM Invoice__c 
                                        WHERE Id=:invId LIMIT 1]; 
            if(invList.size() > 0){
                parName = invList.get(0).Parent_Account__r.Name;
                
                if(invList.get(0).Invoice_Line_Items__r.size() > 0){
                    Invoice_Line_Item__c invLItem = invList.get(0).Invoice_Line_Items__r.get(0);
                    
                    String enrId = invLItem.Enrolment__c != null ? invLItem.Enrolment__c :  invLItem.Subscription_Line_Item__r.Enrolment__c;
                    List<Attachment> attList = [SELECT Id,Name FROM Attachment WHERE ParentId =: enrId AND Name=:ConstantsClass.defAttSignName LIMIT 1];
                    if(attList.size() > 0)
                        attId = attList.get(0).Id;
                }
            }
        }
    }
    
    
}