trigger AccountMainTrigger on Account (before insert, before update) {
    
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        Boolean isEmployeeCodeActivated = false;
        Integer employeeCodeNo = 0;
        try{isEmployeeCodeActivated = Boolean.valueOf(Label.Is_Employee_Code_Activated);}catch(Exception e){ isEmployeeCodeActivated = false;}
        
        Id employeeRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        Id teacherRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        
        List<Account> lastEmployeeList = [SELECT Id, Employee_Code__c FROM Account Where (RecordTypeId =: employeeRecordTypeId or RecordTypeId=:teacherRecordTypeId) AND Employee_Code__c != null ORDER BY Employee_Code__c DESC LIMIT 1];
        
        if(lastEmployeeList != null && !lastEmployeeList.isEmpty()){
            String lastEmployeeCodeGenerated = lastEmployeeList.get(0).Employee_Code__c ;
            if(lastEmployeeCodeGenerated.indexOf('-') != -1){
                employeeCodeNo = Integer.valueOf(lastEmployeeCodeGenerated.split('-').get(1));
                employeeCodeNo = employeeCodeNo + 1;
            }
        }
        Map<Id,Account> oldMap = trigger.oldMap;
        for(Account employee : trigger.new){
            if(oldMap != null && oldMap.get(employee.Id).Employee_Code__c != null){
                employee.Employee_Code__c = oldMap.get(employee.Id).Employee_Code__c;
            }
            if(employeeRecordTypeId == employee.RecordTypeId && isEmployeeCodeActivated){
                if(String.isBlank(employee.Employee_Code__c) && (employee.Employee_Status__c.equalsignorecase('Probation') || employee.Employee_Status__c.equalsignorecase('Confirm'))){
                    String code = employeeCodeNo+'';
                    if(code.length() < 2) code = '00'+code;
                    else if(code.length() < 3) code = '0'+code;
                    
                    employee.Employee_Code__c = 'Emp-'+code;
                    employeeCodeNo = employeeCodeNo + 1;
                }
            }
        }
    }
}