public class BankExpenseFileController{
    Public transient String fileName{get;set;}
    Public transient String strFile{get;set;}
    /*Public transient Integer month{get;set;}
    Public transient Integer year{get;set;}*/
    private Organisation__c organisation = null; 
    
    public BankExpenseFileController(){
    }
    
    public void generateFile(){
        String pOrg = Apexpages.currentPage().getParameters().get('org');
        string strUploadDate = Apexpages.currentPage().getParameters().get('uploadDate');
        
        date uploadDate = system.today().addDays(1);
        if(strUploadDate!=null && strUploadDate.trim().length()>0){
            try{
                uploadDate = Date.valueOf(strUploadDate);
            }catch(exception e){}
        }
        datetime uploadDatetime = Datetime.newInstance(uploadDate, Time.newInstance(0, 0, 0, 0));
        
        if(String.isNotBlank(pOrg)){
            List<Organisation__c > orgList = [SELECT Id, Name, Bank_Account_Number__c, Bank_Name__c, Branch_Code__c FROM Organisation__c WHERE Id = : pOrg];
            if(orgList.size() > 0) organisation = orgList.get(0);
        }
        
        fileName = 'Bank Expense File.txt';
        
        strFile = '';
        if(organisation != null){
            //Bank Name
            strFile += generateFormatedString(organisation.Bank_Name__c, false, 58, ' ');
            //Fillers (&)
            strFile += generateFormatedString('', false, 24, '&');
            
            // change header row
            strFile = strFile + '\r\n';
            
            //Bank Account
            strFile += generateFormatedString(organisation.Bank_Account_Number__c, false, 20, ' ');
            //Branch Code
            strFile += generateFormatedString(organisation.Branch_Code__c, false, 3, ' ');
            //Company Name
            strFile += generateFormatedString(organisation.Name, false, 20, ' ');
            //Today's Date
            strFile += generateFormatedString(uploadDatetime.format('yyyyMMdd'), false, 8, ' ');
            //Blanks
            strFile += generateFormatedString('', false, 31, ' ');
            
            // change sun header row
            strFile = strFile + '\r\n';
            
            //String mString = dateOfRecords.format('MMMM');
            //String yString = dateOfRecords.format('yyyy');
            Integer sequence = 50000;
            
            List<Expense_Claim__c> expClaimList = [SELECT Id, Department__c, Organisation__c, Employee__c, Remarks__c, Status__c, 
                Submit_Date__c, Submit_For_Approval_Expense_Claim__c, Applied_Amount__c, Approved_Amount__c, Exp_Bank_File_Generated__c, 
                Currency_Code__c, Name, Employee__r.Bank_Detail__r.Bank_Code__c, Employee__r.Bank_Detail__r.Branch_Code__c,Employee__r.Bank_Detail__c, 
                Employee__r.AccountNumber, Employee__r.Beneficiary_Name__c, Employee__r.Tax_Number__c,Converted_Amount__c FROM Expense_Claim__c 
                WHERE Organisation__c =: pOrg AND Exp_Bank_File_Generated__c = FALSE AND Status__c in ('Approved','Partial Approved') and Converted_Amount__c>0 and Employee__r.AccountNumber!=null 
                and Employee__r.Bank_Detail__c!=null];
            
            if(expClaimList != NULL && expClaimList.size()>0){
                Map<Id,List<Expense_Claim__c>> employeeToExpClaimMap = new Map<Id,List<Expense_Claim__c>>();
                for(Expense_Claim__c expClaim: expClaimList){
                    List<Expense_Claim__c> tempList= new List<Expense_Claim__c>();
                    If(employeeToExpClaimMap.containsKey(expClaim.Employee__c)){
                        tempList = employeeToExpClaimMap.get(expClaim.Employee__c);
                    }
                    tempList.add(expClaim);
                    employeeToExpClaimMap.put(expClaim.Employee__c,tempList);
                    expClaim.Exp_Bank_File_Generated__c = true;
                }
                for(Id empId : employeeToExpClaimMap.keyset()){
                    Expense_Claim__c expClaim = employeeToExpClaimMap.get(empId)[0];
                    String recordString = '';
                    //Sequence
                    recordString += generateFormatedString(sequence+'', false, 5, ' ');
                    //Bank Code
                    recordString += generateFormatedString(expClaim.Employee__r.Bank_Detail__r.Bank_Code__c, false, 4, ' ');
                    //Branch Code
                    recordString += generateFormatedString(expClaim.Employee__r.Bank_Detail__r.Branch_Code__c, false, 3, ' ');
                    //Account Numner
                    recordString += generateFormatedString(expClaim.Employee__r.AccountNumber, false, 11, ' ');
                    //Name
                    recordString += generateFormatedString(expClaim.Employee__r.Beneficiary_Name__c, false, 20, ' ');
                    //Number
                    recordString += generateFormatedString('21' , false, 5, ' ');
                    //NRIC Tax Number
                    recordString += generateFormatedString(expClaim.Employee__r.Tax_Number__c, false, 21, ' ');
                    //Amount
                    decimal totalAmount = 0;
                    for(Expense_Claim__c ec:employeeToExpClaimMap.get(empId)){
                        totalAmount += ec.Converted_Amount__c;
                    }
                    String temp = totalAmount!= null?totalAmount.setScale(2)+'' : '';
                    
                    recordString += generateFormatedString(temp , true, 11, '0');
                    //Blank
                    recordString += generateFormatedString('' , false, 2, ' ');
                    recordString = recordString + '\r\n';
                    
                    strFile += recordString;
                    
                    sequence = sequence + 1;
                }
            }
            
            if(expClaimList != NULL && !expClaimList.isEmpty()){
                update expClaimList;
            }
        }
    }
    
    public void TestgenerateFile(){
        /*String strmonth = Apexpages.currentPage().getParameters().get('month');
        String stryear = Apexpages.currentPage().getParameters().get('year');*/
        String pOrg = Apexpages.currentPage().getParameters().get('org');
        //year = system.today().year();
        //month = system.today().month();
        
        if(String.isNotBlank(pOrg)){
            List<Organisation__c > orgList = [SELECT Id, Name, Bank_Account_Number__c, Bank_Name__c, Branch_Code__c FROM Organisation__c WHERE Id = : pOrg];
            if(orgList.size() > 0) organisation = orgList.get(0);
        }
        
        /*if(strmonth!=null && strmonth.trim().length()>0){
            month = Integer.valueOf(strMonth);
        }
        if(stryear!=null && stryear.trim().length()>0){
            year = Integer.valueOf(stryear);
        }*/
        
        //Datetime dateOfRecords = datetime.newInstance(year,month,1,0,0,0);
        //fileName = 'Bank Expense File ('+dateOfRecords.format('MMMM')+'-'+dateOfRecords.format('YYYY')+').txt';
        fileName = 'Bank Expense File.txt';
        
        strFile = '';
        if(organisation != null){
            
            //Bank Name
            strFile += generateFormatedString(organisation.Bank_Name__c, false, 58, ' ');
            //Fillers (&)
            strFile += generateFormatedString('', false, 24, '&');
            
            // change header row
            strFile = strFile + '\r\n';
            
            //Bank Account
            strFile += generateFormatedString(organisation.Bank_Account_Number__c, false, 20, ' ');
            //Branch Code
            strFile += generateFormatedString(organisation.Branch_Code__c, false, 3, ' ');
            //Company Name
            strFile += generateFormatedString(organisation.Name, false, 20, ' ');
            //Today's Date
            strFile += generateFormatedString(DateTime.now().format('yyyyMMdd'), false, 8, ' ');
            //Blanks
            strFile += generateFormatedString('', false, 31, ' ');
            
            // change sun header row
            strFile = strFile + '\r\n';
            
            //String mString = dateOfRecords.format('MMMM');
            //String yString = dateOfRecords.format('YYYY');
            Integer sequence = 50000;
            
            List<Expense_Claim__c> expClaimList = [SELECT Id, Department__c, Organisation__c, Employee__c, Remarks__c, Status__c, 
                Submit_Date__c, Submit_For_Approval_Expense_Claim__c, Applied_Amount__c, Approved_Amount__c, Exp_Bank_File_Generated__c, 
                Currency_Code__c, Name, Employee__r.Bank_Detail__r.Bank_Code__c, Employee__r.Bank_Detail__r.Branch_Code__c, 
                Employee__r.AccountNumber, Employee__r.Beneficiary_Name__c, Employee__r.Tax_Number__c FROM Expense_Claim__c 
                WHERE Organisation__c =: pOrg AND Exp_Bank_File_Generated__c = FALSE AND Status__c = 'Approved'];
            
            if(expClaimList != NULL && expClaimList.size()>0){
                for(Expense_Claim__c expClaim: expClaimList){
                    String recordString = '';
                    //Sequence
                    recordString += generateFormatedString(sequence+'', false, 5, ' ');
                    //Bank Code
                    recordString += generateFormatedString(expClaim.Employee__r.Bank_Detail__r.Bank_Code__c, false, 4, ' ');
                    //Branch Code
                    recordString += generateFormatedString(expClaim.Employee__r.Bank_Detail__r.Branch_Code__c, false, 3, ' ');
                    //Account Numner
                    recordString += generateFormatedString(expClaim.Employee__r.AccountNumber, false, 11, ' ');
                    //Name
                    recordString += generateFormatedString(expClaim.Employee__r.Beneficiary_Name__c, false, 20, ' ');
                    //Number
                    recordString += generateFormatedString('22' , false, 5, ' ');
                    //NRIC Tax Number
                    recordString += generateFormatedString(expClaim.Employee__r.Tax_Number__c, false, 21, ' ');
                    //Amount
                    String temp = expClaim.Approved_Amount__c!= null ? expClaim.Approved_Amount__c.setScale(2)+'' : '';
                    recordString += generateFormatedString(temp , true, 11, '0');
                    //Blank
                    recordString += generateFormatedString('' , false, 2, ' ');
                    recordString = recordString + '\r\n';
                    
                    if(expClaim.Employee__c != null && String.isNotBlank(expClaim.Employee__r.Bank_Detail__r.Bank_Code__c) && 
                    String.isNotBlank(expClaim.Employee__r.Bank_Detail__r.Branch_Code__c) && 
                    String.isNotBlank(expClaim.Employee__r.AccountNumber) && 
                    String.isNotBlank(expClaim.Employee__r.Beneficiary_Name__c) && 
                    expClaim.Approved_Amount__c != null && expClaim.Approved_Amount__c > 0){
                        strFile += recordString;
                        expClaim.Exp_Bank_File_Generated__c = TRUE;
                    }
                }
                sequence = sequence + 1;
            }
            
            if(expClaimList != NULL && !expClaimList.isEmpty()){
                update expClaimList;
            }
        }
    }
    
    public String generateFormatedString(String str, Boolean isNumeric, Integer uptoChar, String paddedWith){
        if(str == null ) str = '';
        if(isNumeric){
            if(str.indexOf('.') != -1){
                str = str.remove('.');
            }
            str = str.leftPad(uptoChar, paddedWith);
        }else{
            Integer length = str.length();
            if(length > uptoChar) return str.substring(0,uptoChar);
            str = str.rightPad(uptoChar, paddedWith);
        }
        return str;
    }
    public pageReference redirectTo(){
        return new pageReference('/apex/GenerateExpenseBankFile');
    }
}