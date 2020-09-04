public class PayrollBatchSetupController{
public Payroll_Batch__c payrollBatch ;
public String payrollBatchId {get;set;}
public String status {get;set;}
public static Map<String,Integer> monthMap = new Map<String,Integer>{
    'January'=>1,
    'February'=>2,
    'March'=>3,
    'April'=>4,
    'May'=>5,
    'June'=>6,
    'July'=>7,
    'August'=>8,
    'September'=>9,
    'October'=>10,
    'November'=>11,
    'December'=>12
};
public String lastMonthName {get;set;}
public Id LastMonthPbId {get;set;}

    public PayrollBatchSetupController(ApexPages.StandardController stdController) {
        this.payrollBatch = (Payroll_Batch__c) stdController.getRecord();
        selectedYear = DateTime.now().format('yyyy');
        if(this.payrollBatch.Id != null){
            List<Payroll_Batch__c> pbItems = [SELECT Id, Name, Month__c,Organisation__c, Status__c, Year__c FROM Payroll_Batch__c WHERE Id = : this.payrollBatch.Id];
            if(!pbItems.isEmpty()){
                this.payrollBatch = pbItems.get(0); 
            }
            payrollBatchId = this.payrollBatch.Id;
            selectedOrganisations = this.payrollBatch.Organisation__c;
            selectedMonth = this.payrollBatch.Month__c;
            selectedYear = this.payrollBatch.Year__c;
            status  = this.payrollBatch.Status__c;
        }
        
        String lastMonth = DateTime.now().addMonths(-1).format('MMMMM');
        String lstMonthYear = DateTime.now().addMonths(-1).format('yyyy');
        for(Payroll_Batch__c pb: [SELECT Id,Name,Month__c FROM Payroll_Batch__c WHERE Month__c = : lastMonth AND Year__c = : lstMonthYear AND Status__c != 'Closed']){
            LastMonthPbId = pb.Id;
            lastMonthName = pb.Month__c;
        }
    }
    public PageReference reDirectTo(){
        if(String.isNotBlank(payrollBatchId)){
            return new PageReference ('/'+payrollBatchId);
        }else{
            return new PageReference ('/'+getObjectPreFix('Payroll_Batch__c'));
        }
    }
    
    public String getObjectPreFix(String apiName){
        Schema.DescribeSObjectResult result = Schema.getGlobalDescribe().get(apiName).getDescribe();
        return result.getKeyPrefix();
    }
    public static Map<Id,Payout__c> getSelectedEmployee(String bId){
        Map<Id,Payout__c> returnValues = new Map<Id,Payout__c>();
        if(String.isNotBlank(bId)){
            for(Payout__c pay: [SELECT Id,Employee_Name__c, Payroll_Batch__c,Payment_Mode__c FROM Payout__c WHERE Payroll_Batch__c =: bId]){
                returnValues.put(pay.Employee_Name__c, pay);
            }
        }
        return returnValues;
    }
    public String selectedMonth {get;set;}
    public List<SelectOption> getMonths{
        get{
            List<SelectOption> options = new List<SelectOption>();
            if(String.isNotBlank(payrollBatchId)){
                for(Payroll_Batch__c pb: [SELECT Id,Name,Month__c FROM Payroll_Batch__c WHERE Id =: payrollBatch.Id]){
                    options.add(new SelectOption(pb.Month__c,pb.Month__c));
                }
            }else{
                options.add(new SelectOption(DateTime.now().format('MMMMM'),DateTime.now().format('MMMMM')));
            }
            return options;
        }set;
    }
    public String selectedYear{get;set;}
    public List<SelectOption> getYearPickListValuesIntoList{
        get{
            List<SelectOption> pickListValuesList= new List<SelectOption>();
            Schema.DescribeFieldResult fieldResult = Payroll_Batch__c.Year__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
               pickListValuesList.add(new SelectOption(pickListVal.getLabel(),pickListVal.getLabel()));
            }     
            return pickListValuesList;
        }set;
    }
    public String getPaymentModePickListValuesIntoList{
            get{
                String pickListValuesList = '';
                Schema.DescribeFieldResult fieldResult = Payout__c.Payment_Mode__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for( Schema.PicklistEntry pickListVal : ple){
                   if(String.isNotBlank(pickListValuesList)) pickListValuesList += ',';
                   pickListValuesList += pickListVal.getLabel();
                }     
                return pickListValuesList;
            }set;
    }
    public String selectedOrganisations {get;set;}
    public List<SelectOption> getOrganisations {
        get{
            List<SelectOption> options = new List<SelectOption>();
            for(Organisation__c og : [SELECT Id, Name FROM Organisation__c]){
                options.add(new SelectOption(og.Id,og.Name));
            }
            return options;
        }
        set;
    }
    public static void changeLastMonthStatus(String LastMonthPbId ){
        if(String.isNotBlank(LastMonthPbId)){
            Payroll_Batch__c pb = new Payroll_Batch__c (
                Id = LastMonthPbId ,
                Status__c = 'Closed'
            );
            update pb;
            List<Payout__c> payouts = [SELECT Id,Status__c FROM Payout__c WHERE Payroll_Batch__c = : LastMonthPbId AND Status__c != 'Closed'];
            for(Payout__c p : payouts){
                p.Status__c = 'Closed';
            }
            if(!payouts.isEmpty()){
                update payouts;
            }
        }
    }
    
    @RemoteAction
    public static String getRunBatch(String data, String organisation, String month, String year, String bId, String LastMonthPbId){
        if(String.isNotBlank(LastMonthPbId)) changeLastMonthStatus(LastMonthPbId );
        
        // validate duplicate payroll batch
        List<Payroll_Batch__c> btList = [SELECT Id FROM Payroll_Batch__c WHERE Organisation__c = : organisation AND Month__c =: month AND Year__c =: year];
        if(btList.size() > 0 && String.isBlank(bId)){
            return 'Payroll is already generated for the selected month.Please use the existing payroll record to make further changes.';
        }
        
        // Remove linking of payout and payroll batch
        if(String.isNotBlank(bId)){
            List<Payout__c > unlinkPayout = new List<Payout__c>(); 
            for(Payout__c pay : [SELECT Id,Payroll_Batch__c FROM Payout__c WHERE Payroll_Batch__c = : bId]){
                pay.Payroll_Batch__c = null;
                unlinkPayout.add(pay);
            }
            update unlinkPayout;
            //Database.update(unlinkPayout,false);
        }
    
        List<RemoteResult> runList = string.isNotBlank(data) ? (List<RemoteResult>)JSON.deserialize(data, List<RemoteResult>.class) : new List<RemoteResult>();
        List<Payout__c> payoutList = new List<Payout__c >();
        Set<Id> employeeIdSet = new Set<Id>();
        for(RemoteResult dta : runList){
            if(String.isNotBlank(dta.payoutId)) payoutList.add(new Payout__c (Id = dta.payoutId, Payment_Mode__c = dta.paymentMode));    
            employeeIdSet.add(dta.employee.Id);
        }
        if(!payoutList.isEmpty()){
            update payoutList;
        }
        
        Payroll_Batch__c payrollBatch = new Payroll_Batch__c();
        if(String.isNotBlank(bId)) payrollBatch.Id = bId;
        if(String.isBlank(bId)) payrollBatch.Organisation__c = organisation;
        payrollBatch.Month__c = month;
        payrollBatch.Year__c = year;
        payrollBatch.Status__c = 'Processed';
        upsert payrollBatch;
        
        Date processDate = date.newInstance(Integer.valueOf(year),monthMap.get(month),1);
        Database.executeBatch(new createEmployeePayoutBatch(processDate, employeeIdSet,payrollBatch), 200);
        return '';
    }
    
    @RemoteAction
    public static List<RemoteResult> getFilterRemoteResult(String organisation, String month, String year, String bId) {
        Date startDate = null;
        Date endDate = null;
        if(String.isNotBlank(year) && String.isNotBlank(month)){
            startDate = date.newInstance(Integer.valueOf(year),monthMap.get(month),1);
            endDate = date.newInstance(Integer.valueOf(year),monthMap.get(month),Date.DaysInMonth(Integer.valueOf(year),monthMap.get(month)));
        }        
        Map<Id,Payout__c> allPayoutOfCurrentMonth = new Map<Id,Payout__c>();
        for(Payout__c pay: [SELECT Id,Employee_Name__c, Payroll_Batch__c,Payment_Mode__c FROM Payout__c WHERE Month__c =: month AND Year__c = : year]){
            allPayoutOfCurrentMonth.put(pay.Employee_Name__c, pay);
        }
        List<RemoteResult> remoteResult= new List<RemoteResult>();
        String qry = 'SELECT Id, Name, Employee_Status__c FROM Account ';
        String whr = 'Employee_Status__c IN (\'Probation\',\'Confirm\') AND RecordType.Name IN (\'Employee\',\'Teacher\') '; 
        if(String.isNotBlank(organisation)){
            whr += ' AND Organisation__c =: organisation ';
        }
        if(startDate != null && endDate != null){
            whr += ' AND (Joining_Date__c = NULL OR Joining_Date__c <=: endDate) AND (Last_Working_Date__c = NULL OR Last_Working_Date__c >=: startDate) ';
        }
        if(String.isNotBlank(whr)) qry += 'WHERE '+whr ;
        Map<Id,Payout__c> selectedEmployee = getSelectedEmployee(bId);
        
		system.debug('query==='+qry);
		
        for(Account emp : Database.query(qry)){
            
            Boolean isChecked = false; 
            Payout__c  payout = new Payout__c();
            if(selectedEmployee.containsKey(emp.Id)){
                isChecked = true; 
                payout = selectedEmployee.containsKey(emp.Id) ? selectedEmployee.get(emp.Id) : new Payout__c();
            }
            if(allPayoutOfCurrentMonth.containsKey(emp.Id)){
                payout = allPayoutOfCurrentMonth.get(emp.Id);
            }
            remoteResult.add(new RemoteResult(emp, isChecked, payout, bId));
        }
        return remoteResult;
    }
    public class RemoteResult{
        public Boolean isChecked ;
        public Account employee ;
        public String paymentMode ;
        public String payoutId ;
        public RemoteResult(Account employee, Boolean isChecked, Payout__c payout, String payrollBatchId){
            this.paymentMode = 'Bank Disk';
            this.employee = employee;
            this.isChecked = isChecked;
            if(payout != null){
                this.payoutId = payout.Id;
                if(String.isNotBlank(payout.Payment_Mode__c) && String.IsNotBlank(payrollBatchId)) this.paymentMode = payout.Payment_Mode__c;
            }
        }
    }
}