@isTest
private class RecallLeaveRequestOnCancelTest {

    private static testMethod void doTest() {
        
        Test.startTest();
        String recordTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByName().get('Paid Leave').getRecordTypeId();
        Date startDate = Date.newInstance(2020, 01, 13);
        Date endDate = Date.newInstance(2020, 01, 15);
        Leave_Request__c leaveReqObj = new Leave_Request__c(Leave_Start_Date__c = startDate,Leave_End_Date__c = endDate,status__c = 'Draft',recordtypeid = recordTypeId);
        insert leaveReqObj;
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();  
        req.setComments('Submitting approval request using in test');        
        req.setObjectId(leaveReqObj.id);        
        Approval.ProcessResult result = Approval.process(req);  
        List<String> leaveIds = new List<String>();
        leaveIds.add(leaveReqObj.id);
        RecallLeaveRequestOnCancel.recallLeaveRequest(leaveIds);
        //Leave_Request__c updateLeave = new Leave_Request__c(id=leaveReqObj.id,status__c='Cancelled');
        //update updateLeave;        
        //System.assert(updateLeave.status__c=='Cancelled');
        Test.stopTest();

    }
}