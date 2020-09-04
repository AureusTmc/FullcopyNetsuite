public class RecallLeaveRequestOnCancel {
    @InvocableMethod
    public static void recallLeaveRequest(List<String> LeaveIds){
        system.debug('leave id = '+LeaveIds);
        if(Approval.islocked(LeaveIds[0])){
            ProcessInstanceWorkitem[] workItems = [ SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: LeaveIds[0] AND ProcessInstance.Status = 'Pending' ]; 
            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();  
            pwr.setAction('Removed');
            pwr.setWorkItemId(workItems[0].id);        
            Approval.ProcessResult result = Approval.process(pwr);
            //Leave_Request__c leaveRecord = [select id,status__c from leave_request__c where status__c = 'Draft' AND id =: ]
            
            Leave_Request__c leaveObject = new Leave_Request__c(id=LeaveIds[0],status__c='Cancelled');
            
            update leaveObject;
        }
    }
}