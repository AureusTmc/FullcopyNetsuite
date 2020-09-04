public class EmployeeStatusPathController {
    
    @AuraEnabled
    public static void updateEmployee(String employeeId, string status){
        Account acc = new Account();
        acc.Id = employeeId;
        acc.Employee_Status__c = status;
        update acc;
        system.debug('acc==='+acc);
    }
}