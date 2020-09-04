/*
Name        :    CustomExpenseItemPageController
Date        :    30 September 2019
Author      :
*/
public class CustomExpenseItemPageController{
    private Id currentExpClaimId;
    public List<ExpItem> expItemList{get;set;}
    public Integer relatedCount {get;set;}
    
    public CustomExpenseItemPageController(ApexPages.StandardController controller){
        relatedCount = 0;
        currentExpClaimId = ApexPages.CurrentPage().getparameters().get('id');
        fetchExpItems();
    }
    
    public void fetchExpItems(){
        List<Expense_Item__c> expItems = [SELECT Id, Expense_Type__r.Name, Expense_Date__c, Supplier__r.Name, Amount__c, GST_Amount__c, Status__c, Finance_Remarks__c, Remarks__c,  Other_Supplier__c, Receipt_Status__c, Invoice_Receipt_Number__c, (SELECT Id FROM Attachments LIMIT 1) FROM Expense_Item__c WHERE Expense_Claim__c =: currentExpClaimId];
        expItemList = new List<ExpItem>();
        
        if(expItems != NULL){
            relatedCount = expItems.size();
            Integer idx = 1;
            for(Expense_Item__c expItem: expItems){
                ExpItem expItemObj = new ExpItem(expItem, idx, expItem.Expense_Date__c, expItem.Expense_Type__r.Name, expItem.Supplier__r.Name, expItem.Amount__c, expItem.GST_Amount__c, expItem.Remarks__c, expItem.Finance_Remarks__c);
                expItemObj.approvalAction = false;
                if(expItem.Status__c != 'Rejected'){
                    expItemObj.approvalAction = true;
                }
                if(expItem.Attachments.size()>0){
                    expItemObj.attachPath = '/servlet/servlet.FileDownload?file='+ expItem.Attachments[0].Id;
                }
                expItemList.add(expItemObj);
                
                //Sanjay : Added a counter for serial no.
                idx++;
            }
        }
        System.debug(expItemList);
    }
    
    //check if the current user is in the Finance Queue
    public Boolean getIsCurrentUserApprover(){
        Id currUserId = UserInfo.getUserId();
        
        /*List<ProcessInstance> processInstanceList = new List<ProcessInstance>();
        
        processInstanceList = [SELECT Id, TargetObjectId, Status FROM ProcessInstance WHERE TargetObjectId =:currentExpClaimId AND (Status = 'Started' OR Status = 'Pending')];
        if(!processInstanceList.isEmpty()){
            List<ProcessInstanceWorkitem> processInstStepList = new List<ProcessInstanceWorkitem>();
            processInstStepList = [SELECT Id, ProcessInstanceId, OriginalActorId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId =: processInstanceList[0].Id];
            
            if(!processInstStepList.isEmpty()){
                if(processInstStepList[0].OriginalActorId == currUserId){ //original actor returns approver id
                    return true;
                }
            }
        }
        return false;*/
        
        List<Group> queueList = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Finance Queue'];
        
        if(queueList != NULL && queueList.size()>0){
            List<Id> financeUserIdList = new List<Id>();
            for(GroupMember grpMember: [SELECT UserOrGroupId FROM GroupMember WHERE GroupId =:queueList[0].Id]){
                financeUserIdList.add(grpMember.UserOrGroupId);
            }
            system.debug('Test==='+financeUserIdList);
            system.debug('Test1==='+currUserId);
            if(financeUserIdList.contains(currUserId)){
                return true;
            }
        }
        
        return false;
    }
    
    public List<SelectOption> getExpenseTypePL(){
        List<SelectOption> options = new List<SelectOption>();
        
        List<Expense_Type__c> expTypeList = [SELECT Id, Name, GL_Code__c FROM Expense_Type__c];
        expTypeList.sort();
        for(Expense_Type__c expType: expTypeList){
            options.add(new SelectOption(expType.Id, expType.GL_Code__c + '-' + expType.Name));
        }
        
        return options;
    }
    
    public List<SelectOption> getSupplierPL(){
        List<SelectOption> options = new List<SelectOption>();
        
        List<Supplier__c> supplierList = [SELECT Id, Name FROM Supplier__c];
        supplierList.sort();
        options.add(new SelectOption('', '--None--'));
        for(Supplier__c supplierObj: supplierList){
            options.add(new SelectOption(supplierObj.Id, supplierObj.Name));
        }
        
        return options;
    }
    
    public void saveChanges(){
        List<Expense_Item__c> updateExpItemList = new List<Expense_Item__c>();
        if(expItemList != NULL && !expItemList.isEmpty()){
            System.debug(expItemList);
            for(ExpItem expItemWrappedObj: expItemList){
                expItemWrappedObj.realExpItem.Finance_Remarks__c = expItemWrappedObj.financeRemarks;
                expItemWrappedObj.realExpItem.Amount__c = expItemWrappedObj.amount;
                expItemWrappedObj.realExpItem.GST_Amount__c = expItemWrappedObj.gst;
                
                if(expItemWrappedObj.approvalAction){
                    expItemWrappedObj.realExpItem.Status__c = 'Approved';
                }
                else{
                    expItemWrappedObj.realExpItem.Status__c = 'Rejected';
                }
                
                updateExpItemList.add(expItemWrappedObj.realExpItem);
            }
            System.debug(updateExpItemList);
            
            try{
                if(!updateExpItemList.isEmpty())
                    update updateExpItemList;
            }
            catch(Exception e){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage().split('first error:')[1]);
                ApexPages.addMessage(myMsg);
            }
        }
    }
    
    public class ExpItem{
        public Expense_Item__c realExpItem{get;set;}
        public Integer indexNo{get;set;}
        public Date expDate{get;set;}
        public String expType{get;set;}
        public String supplier{get;set;}
        public Decimal amount{get;set;}
        public Decimal gst{get;set;}
        public Boolean approvalAction{get;set;}
        public String empRemarks{get;set;}
        public String financeRemarks{get;set;}
        public String attachPath{get;set;}
               
        public ExpItem(Expense_Item__c realExpItem, Integer indexNo, Date expDate, String expType, String supplier, Decimal amount, Decimal gst, String empRemarks, String financeRemarks){
            this.realExpItem = realExpItem;
            this.indexNo = indexNo;
            this.expDate = expDate;
            this.expType = expType;
            this.supplier = supplier;
            this.amount = amount;
            this.gst = gst;
            this.empRemarks = empRemarks;
            this.financeRemarks = financeRemarks;
        }
    }
}