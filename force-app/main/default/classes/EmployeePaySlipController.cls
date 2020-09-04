public class EmployeePaySlipController{

    public Payout__c payout {get;set;}
    public Payslip payslip{get;set;}
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
    public EmployeePaySlipController(ApexPages.StandardController stdpayout) {
        try{
            payout = new Payout__c();
            this.payout.Id = stdpayout.getId();
            if(payout != null){
                // query all fields
                payout = getpayoutRecord();
                payslip = new Payslip(payout);
            }
        }catch(exception e){}
    }
    
    public payout__c getpayoutRecord(){
        List<payout__c> payoutList = [SELECT Id, Name, CreatedDate, CreatedById, Month__c, CDAC_Contribution__c, Year__c, Salary__c, Total_Amount__c, Employee_CPF_Amount__c,Employer_CPF_Amount__c, Total_CPF__c, Total_Payable__c, Employee_Name__c, CDAC__c, MBMF__c, SINDA__c, EUCF__c,Payment_Mode__c,
                                        Employee_Name__r.Name, Employee_Name__r.Joining_Date__c, Employee_Name__r.Employee_Code__c,Employee_Name__r.Termination_Date__c, Employee_Name__r.PersonDepartment, Employee_Name__r.AccountNumber,
                                        Employee_Name__r.Job_Title__c, Employee_Name__r.Department__c,Employee_Name__r.Bank_Detail__r.Name, Employee_Name__r.Branch_Code__c, Employee_Name__r.Beneficiary_Name__c, Employee_Name__r.Bank_Account_No__c
                                        FROM payout__c WHERE Id = : payout.Id];
        if(!payoutList.isEmpty()){
            return payoutList.get(0);
        }
        return new Payout__c();
    }
    
    // Wrapper class for payslip
    public class Payslip{
        // header fields
        public Date fromDate {get;set;}
        public date toDate {get;set;}
        public date yearStartDate {get;set;}
        // Employee details
        public String employeeId {get;set;}
        public String employeeName {get;set;}
        public Date hireDate {get;set;}
        public String modeofPayment {get;set;}
        public String department {get;set;}
        public String jobTitle {get;set;}
        public Date terminationDate {get;set;}
        public String beneficiaryName {get;set;}
        public String bankName {get;set;}
        public String accountNumber {get;set;}
        public Decimal amount {get;set;}
        
        public String pMonth {get;set;}
        public String pYear {get;set;}
        public Decimal basicSalary {get;set;}
        public Decimal totalAllowances {get;set;}
        public List<TypeAmount> totalAllowancesList {get;set;}
        public Decimal otherAdditionalPayments {get;set;}
        public List<TypeAmount> additionalPaymentList {get;set;}
        public Decimal nonCPFPayments {get;set;}
        public List<TypeAmount> nonCPFPaymentList {get;set;}
        public Decimal totalOvertimeHoursWorked {get;set;}
        public Decimal totalOvertimePay {get;set;}
        
        public Decimal totalDeductions {get;set;}
        public List<TypeAmount> totalDeductionList {get;set;}
        Private Map<String,String> employerDeductionListMap = new Map<String,String>{
            'CDAC__c'=>'CDAC Contribution',
            'SINDA__c'=>'SINDA Contribution',
            'MBMF__c'=>'MBMF Contribution',
            'EUCF__c'=>'EUCF Contribution',
            'Employee_CPF_Amount__c' => 'Employee CPF Contribution'
        };
        
        public Decimal totalReimbursements {get;set;}
        public Decimal netpay {get;set;}
        public Decimal totalEmployerContribution {get;set;}
        public List<TypeAmount> employerContributionList {get;set;}
        Private Map<String,String> employerContributionListMap = new Map<String,String>{
            'CDAC__c' =>'CDAC Contribution',
            'Employer_CPF_Amount__c'=>'Employer CPF Contribution'
        };
        
        public Decimal gross {get;set;} 
        public Decimal donationAmount {get;set;} 
        public Decimal employeeCPFAmount {get;set;} 
        public Decimal employerCPFAmount {get;set;} 
        
        public String orgCurrency {get;set;}
        
        public Payslip(payout__c payout){
            this.orgCurrency = UserInfo.getDefaultCurrency();
            this.fromDate = date.newInstance(Integer.valueOf(payout.Year__c),monthMap.get(payout.Month__c),1);
            this.toDate = fromDate.addMonths(1).addDays(-1);
            this.yearStartDate = date.newInstance(Integer.valueOf(payout.Year__c),1,1);
            
            // Employee
            this.employeeId = payout.Employee_Name__r.Employee_Code__c;
            this.employeeName = payout.Employee_Name__r.Name;
            this.hireDate = payout.Employee_Name__r.Joining_Date__c;
            this.modeofPayment = payout.Payment_Mode__c;
            this.department = payout.Employee_Name__r.Department__c;
            this.jobTitle = payout.Employee_Name__r.Job_Title__c;
            this.terminationDate = payout.Employee_Name__r.Termination_Date__c;
            this.beneficiaryName = payout.Employee_Name__r.Beneficiary_Name__c;
            this.bankName = payout.Employee_Name__r.Bank_Detail__r.Name;
            this.accountNumber = payout.Employee_Name__r.AccountNumber != null ? 'XXX-XXXXX'+payout.Employee_Name__r.AccountNumber.right(4) : '';
            this.amount = payout.Total_Payable__c;
            
            //Payout
            basicSalary = payout.Salary__c;
            this.totalAllowances = 0.00;
            this.totalAllowancesList = new List<TypeAmount>();
            Map<String, Decimal> owMap = new Map<String, Decimal>();
            
            this.otherAdditionalPayments = 0.00;
            this.additionalPaymentList = new List<TypeAmount>();
            Map<String, Decimal> awMap = new Map<String, Decimal>();
            
            
            this.nonCPFPayments = 0.00;
            this.nonCPFPaymentList = new List<TypeAmount>();
            Map<String, Decimal> nonMap = new Map<String, Decimal>();
            for(PayItem__c pi : [Select Id, Amount__c, CPF__c, Effective_Date__c,Payitem__r.Name, End_Date__c, Notes__c, Payitem__c, Name, Payout__c, Processed__c, Prorate__c, System_Generated__c FROM PayItem__c WHERE Payout__c =: payout.Id AND Amount__c != null]){
                if(pi.CPF__c != null && pi.CPF__c.equalsignorecase('OW')){
                    if(!owMap.containsKey(pi.Payitem__r.Name)){
                        owMap.put(pi.Payitem__r.Name,0);
                    }
                    Decimal tow = owMap.get(pi.Payitem__r.Name);
                    tow += pi.Amount__c;
                    owMap.put(pi.Payitem__r.Name,tow );
                }else if(pi.CPF__c != null && pi.CPF__c.equalsignorecase('AW')){
                    if(!awMap.containsKey(pi.Payitem__r.Name)){
                        awMap.put(pi.Payitem__r.Name,0);
                    }
                    Decimal taw = awMap.get(pi.Payitem__r.Name);
                    taw += pi.Amount__c;
                    awMap.put(pi.Payitem__r.Name,taw );
                }else if(pi.CPF__c != null && pi.CPF__c.equalsignorecase('Non-CPF')){
                    if(!nonMap.containsKey(pi.Payitem__r.Name)){
                        nonMap.put(pi.Payitem__r.Name,0);
                    }
                    Decimal tnon = nonMap.get(pi.Payitem__r.Name);
                    tnon += pi.Amount__c;
                    nonMap.put(pi.Payitem__r.Name, tnon);
                }
            }
            for(String key : owMap.keySet()){
                this.totalAllowancesList.add(new TypeAmount(key ,owMap.get(key)));
                this.totalAllowances += owMap.get(key);
            } 
            for(String key : awMap.keySet()){
                this.additionalPaymentList.add(new TypeAmount(key ,awMap.get(key)));
                this.otherAdditionalPayments += awMap.get(key);
            }   
            for(String key : nonMap.keySet()){
                this.nonCPFPaymentList.add(new TypeAmount(key ,nonMap.get(key)));
                this.nonCPFPayments += nonMap.get(key);
            }          
            
            // Overtime
            this.totalOvertimeHoursWorked = 0.00;
            this.totalOvertimePay = 0.00;
            
            // total deduction
            this.totalDeductions = 0.00;
            this.totalDeductionList = new List<TypeAmount>();
            sObject sObj = (sObject) payout;
            for(String key: employerDeductionListMap.keyset()){
                Decimal val = sObj.get(key) != null ? (Decimal) sObj.get(key) : 0.00;
                if(val > 0){
                    this.totalDeductions += val;
                    this.totalDeductionList.add(new TypeAmount(employerDeductionListMap.get(key),val));    
                }
            }
            
            // Employer contribution
            this.totalEmployerContribution = 0.00;
            this.employerContributionList = new List<TypeAmount>();
            for(String key: employerContributionListMap.keyset()){
                Decimal val = sObj.get(key) != null ? (Decimal) sObj.get(key) : 0.00;
                if(val > 0){
                    this.totalEmployerContribution += val;
                    this.employerContributionList.add(new TypeAmount(employerContributionListMap.get(key),val));    
                }
            }
            
            this.totalReimbursements = 0.00;
            this.netpay = payout.Total_Payable__c;
            
            // Year to Data
            this.gross = 0.00;
            this.donationAmount = 0.00;
            this.employeeCPFAmount = 0.00;
            this.employerCPFAmount = 0.00;
            Integer currentMonthNumber = monthMap.containsKey(Payout.Month__c) ? monthMap.get(Payout.Month__c) : 0;
            for(Payout__c pay : [SELECT Id, CDAC__c,MBMF__c,EUCF__c,Month__c,Employee_CPF_Amount__c,Employer_CPF_Amount__c,SINDA__c,Salary__c,Total_OW_Amount__c,Total_AW_Amount__c,Total_Non_CPF_Amount__c  FROM Payout__c WHERE Employee_Name__c = : payout.Employee_Name__c AND Year__c = : payout.Year__c]){
                
                Integer recordMonthNumber = monthMap.containsKey(pay.Month__c) ? monthMap.get(pay.Month__c) : 12;   
                if(recordMonthNumber <= currentMonthNumber ){
                    gross += pay.Salary__c != null ? pay.Salary__c : 0.00;
                    gross += pay.Total_OW_Amount__c != null ? pay.Total_OW_Amount__c : 0.00;
                    gross += pay.Total_AW_Amount__c != null ? pay.Total_AW_Amount__c : 0.00;
                    gross += pay.Total_Non_CPF_Amount__c != null ? pay.Total_Non_CPF_Amount__c : 0.00;
                    
                    donationAmount += pay.CDAC__c != null ? pay.CDAC__c : 0.00;
                    donationAmount += pay.SINDA__c != null ? pay.SINDA__c : 0.00;
                    donationAmount += pay.EUCF__c != null ? pay.EUCF__c : 0.00;
                    donationAmount += pay.MBMF__c != null ? pay.MBMF__c : 0.00;
                    
                    employeeCPFAmount += pay.Employee_CPF_Amount__c != null ? pay.Employee_CPF_Amount__c : 0.00;
                    employerCPFAmount += pay.Employer_CPF_Amount__c != null ? pay.Employer_CPF_Amount__c: 0.00;
                }
            }
            this.donationAmount = donationAmount > 0 ? donationAmount * -1 : donationAmount ;
            this.employeeCPFAmount = employeeCPFAmount > 0 ? employeeCPFAmount * -1 : donationAmount ;
        }
    }
    // Wrapper for multiple values 
    public class TypeAmount{
        public String type {get;set;}
        public Decimal amount {get;set;}
        
        public TypeAmount(String type, Decimal amount){
            this.type = type;
            this.amount = amount;
        }
    }
}