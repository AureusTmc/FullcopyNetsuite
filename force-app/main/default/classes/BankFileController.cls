public class BankFileController{
    Public transient String fileName{get;set;}
    Public transient String strFile{get;set;}
    Public transient Integer month{get;set;}
    Public transient Integer year{get;set;}
    private Organisation__c organisation = null; 
    public BankFileController(){
    
        String strmonth = Apexpages.currentPage().getParameters().get('month');
        String stryear = Apexpages.currentPage().getParameters().get('year');
        String pOrg = Apexpages.currentPage().getParameters().get('org');
        string strUploadDate = Apexpages.currentPage().getParameters().get('uploadDate');
        
        date uploadDate = system.today().addDays(1);
        if(strUploadDate!=null && strUploadDate.trim().length()>0){
            try{
            	uploadDate = Date.valueOf(strUploadDate);
            }catch(exception e){}
        }
        datetime uploadDatetime = Datetime.newInstance(uploadDate, Time.newInstance(0, 0, 0, 0));
        
        year = system.today().year();
        month = system.today().month();
        
        if(String.isNotBlank(pOrg)){
            List<Organisation__c > orgList = [SELECT Id, Name, Bank_Account_Number__c, Bank_Name__c, Branch_Code__c FROM Organisation__c WHERE Id = : pOrg];
            if(orgList.size() > 0) organisation = orgList.get(0);
        }
        
        if(strmonth!=null && strmonth.trim().length()>0){
            month = Integer.valueOf(strMonth);
        }
        if(stryear!=null && stryear.trim().length()>0){
            year = Integer.valueOf(stryear);
        }
        
        Datetime dateOfRecords = datetime.newInstance(year,month,1,0,0,0);
        fileName = 'Bank File ('+dateOfRecords.format('MMMM')+'-'+dateOfRecords.format('yyyy')+').txt';
        
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
            //strFile += generateFormatedString(DateTime.now().format('YYYYMMdd'), false, 8, ' ');
            strFile += generateFormatedString(uploadDatetime.format('YYYYMMdd'), false, 8, ' ');
            //Blanks
            strFile += generateFormatedString('', false, 31, ' ');
            
            // change sun header row
            strFile = strFile + '\r\n';
            
            String mString = dateOfRecords.format('MMMM');
            String yString = dateOfRecords.format('YYYY');
            Integer sequence = 50000;
            for(Payout__c payout: [SELECT Id, Name,Employee_Name__r.Bank_Detail__r.Bank_Code__c, Employee_Name__r.Beneficiary_Name__c, Employee_Name__r.Bank_Detail__r.Name, Employee_Name__r.Bank_Detail__r.Branch_Name__c, Employee_Name__r.Bank_Detail__r.Branch_Code__c, Total_Payable__c, Employee_Name__r.Tax_Number__c, Employee_Name__r.Branch_Code__c, Employee_Name__r.AccountNumber, Employee_Name__r.Name, Employee_Name__r.Identification_Number__c FROM Payout__c WHERE Payment_Mode__c = 'Bank Disk' AND Month__c =: mString  AND Year__c = : yString AND Employee_Name__r.Organisation__c = : pOrg]){
                String recordString = '';
                //Sequence
                recordString += generateFormatedString(sequence+'', false, 5, ' ');
                //Bank Code
                recordString += generateFormatedString(payout.Employee_Name__r.Bank_Detail__r.Bank_Code__c, false, 4, ' ');
                //Branch Code
                recordString += generateFormatedString(payout.Employee_Name__r.Bank_Detail__r.Branch_Code__c, false, 3, ' ');
                //Account Numner
                recordString += generateFormatedString(payout.Employee_Name__r.AccountNumber, false, 11, ' ');
                //Name
                recordString += generateFormatedString(payout.Employee_Name__r.Beneficiary_Name__c, false, 20, ' ');
                //Number
                recordString += generateFormatedString('22' , false, 5, ' ');
                //NRIC Tax Number
                recordString += generateFormatedString(payout.Employee_Name__r.Tax_Number__c , false, 21, ' ');
                //Amount
                String temp = payout.Total_Payable__c != null ? payout.Total_Payable__c.setScale(2)+'' : '';
                recordString += generateFormatedString(temp , true, 11, '0');
                //Blank
                recordString += generateFormatedString('' , false, 2, ' ');
                recordString = recordString + '\r\n';
                
                if(payout.Employee_Name__r != null && String.isNotBlank(payout.Employee_Name__r.Bank_Detail__r.Bank_Code__c) && String.isNotBlank(payout.Employee_Name__r.Bank_Detail__r.Branch_Code__c) && String.isNotBlank(payout.Employee_Name__r.AccountNumber) && String.isNotBlank(payout.Employee_Name__r.Beneficiary_Name__c) && payout.Total_Payable__c != null && payout.Total_Payable__c > 0){
                    strFile += recordString;
                }
            }
            sequence = sequence + 1;
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
        return new pageReference('/apex/GenerateBankFile');
    }
}