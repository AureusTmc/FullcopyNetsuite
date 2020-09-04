public class CPFSubmissionFileController{
    Public transient string fileName{get;set;}
    Public transient string strFile{get;set;}
    Public transient integer month{get;set;}
    Public transient integer year{get;set;}
    private Organisation__c organisation = new Organisation__c (); 
    
    public CPFSubmissionFileController(){
        string strmonth = Apexpages.currentPage().getParameters().get('month');
        string stryear = Apexpages.currentPage().getParameters().get('year');
        string pOrg = Apexpages.currentPage().getParameters().get('org');
        
        if(String.isNotBlank(pOrg)){
            List<Organisation__c > orgList = [SELECT Id, Name, CPF_Advice_Code__c, CPF_Payment_Type__c, UEN__c FROM Organisation__c WHERE Id = : pOrg];
            if(orgList.size() > 0) organisation = orgList.get(0);
        }
        
        if(strmonth!=null && strmonth.trim().length()>0){
            month = Integer.valueOf(strMonth);
        }else{
            month = system.today().month();
        }
        
        if(stryear!=null && stryear.trim().length()>0){
            year = Integer.valueOf(stryear);
        }else{
            year = system.today().year();
        }
        
        Date relevantMonthDate = Date.newInstance(year,month,1);
        
        Integer empRecordCount = 0;
        string uen = organisation.UEN__c ;
        string paymentType = organisation.CPF_Payment_Type__c;
        string serialNo = '01';
        string adviceCode = organisation.CPF_Advice_Code__c;
        
        string csn = uen+paymentType+serialNo;
        
        Datetime tempDT = datetime.newInstance(year,month,1,0,0,0);
        
        fileName = csn + tempDT.format('MMM') + year+adviceCode+'.DTL';
        
        string fileCreationDate = system.now().format('YYYYMMdd');
        string fileCreationTime = system.now().format('HHmmss');
        
        string relevantMonth = ((Datetime)relevantMonthDate).format('YYYYMM');
        
        
        string strUEN = uen;
        for(Integer i=1;i<=(10-uen.trim().length());i++){
            strUEN += ' ';
        }
        
        //Header : Start
        string strheader = 'F'+' '+strUEN+paymentType+serialNo+' '+adviceCode+fileCreationDate+fileCreationTime+'FTP.DTL';
        for(integer i=1;i<=(103 + 6);i++){//+6 covering FileID
            strheader += ' ';
        }
        
        empRecordCount++;
        //Header : Stop
        
        strFile = strheader + '\r\n';
        
        strheader = null;
        
        Decimal totalCPFAmount = 0;
        Decimal totalCDACAmount = 0;
        Decimal totalEUCFAmount = 0;
        Decimal totalMBMFAmount = 0;
        Decimal totalSINDAAmount = 0;
        Decimal totalSDLAmount = 0;
        
        Integer cpfDonorCount = 0;
        Integer CDACDonorCount = 0;
        Integer EUCFDonorCount = 0;
        Integer MBMFDonorCount = 0;
        Integer SINDADonorCount = 0;
        Integer SDLDonorCount = 0;
        
        List<Payout__c> payoutList = [Select Id,Salary__c,Total_OW_Amount__c,Total_AW_Amount__c,Total_CPF__c,CDAC__c,EUCF__c,MBMF__c,SINDA__c,SDL__c,Employee_Name__r.Tax_Number__c,Employee_Name__r.Name,Employee_Name__r.Firstname,Employee_Name__r.Lastname,Employee_Name__r.Joining_Date__c,Employee_Name__r.Last_Working_Date__c,Employee_Name__r.ID_Type__c from Payout__c where Employee_Name__r.Tax_Number__c!=null and year__c=:(year+'') and Month__c=:((Datetime)relevantMonthDate).format('MMMM') AND Employee_Name__r.Organisation__c = : pOrg];
        if(payoutList.size()>0){
            for(Payout__c payout: payoutList){
                if(payout.Total_CPF__c>0){
                    totalCPFAmount += payout.Total_CPF__c;
                    cpfDonorCount++;
                }
                If(payout.CDAC__c>0){
                    totalCDACAmount += payout.CDAC__c;
                    CDACDonorCount++;
                }
                If(payout.EUCF__c>0){
                    totalEUCFAmount += payout.EUCF__c;
                    EUCFDonorCount++;
                }
                If(payout.MBMF__c>0){
                    totalMBMFAmount += payout.MBMF__c;
                    MBMFDonorCount++;
                }
                If(payout.SINDA__c>0){
                    totalSINDAAmount += payout.SINDA__c;
                    SINDADonorCount++;
                }
                If(payout.SDL__c>0){
                    totalSDLAmount += payout.SDL__c;
                    SDLDonorCount++;
                }
            }
        }
        system.debug('totalCPFAmount ** '+totalCPFAmount+ ' && '+cpfDonorCount);
        system.debug('totalCDACAmount ** '+totalCDACAmount + ' && '+CDACDonorCount);
        system.debug('totalEUCFAmount ** '+totalEUCFAmount + ' && '+EUCFDonorCount);
        system.debug('totalMBMFAmount ** '+totalMBMFAmount + ' && '+MBMFDonorCount);
        system.debug('totalSINDAAmount  ** '+totalSINDAAmount + ' && '+SINDADonorCount);
        system.debug('totalSDLAmount  ** '+totalSDLAmount  + ' && '+SDLDonorCount);
        
        //totalCPFAmount = totalCPFAmount.round(System.RoundingMode.HALF_UP);
		totalCPFAmount = totalCPFAmount.setScale(2);
        totalCDACAmount = totalCDACAmount.setScale(2);
        totalEUCFAmount = totalEUCFAmount.setScale(2);
        totalMBMFAmount = totalMBMFAmount.setScale(2); 
        totalSINDAAmount = totalSINDAAmount.setScale(2);
		totalSDLAmount = totalSDLAmount.setScale(2);
        //totalSDLAmount = totalSDLAmount.round(System.RoundingMode.DOWN);
        
        system.debug('totalCPFAmount ** '+totalCPFAmount+ ' && '+cpfDonorCount);
        system.debug('totalCDACAmount ** '+totalCDACAmount + ' && '+CDACDonorCount);
        system.debug('totalEUCFAmount ** '+totalEUCFAmount + ' && '+EUCFDonorCount);
        system.debug('totalMBMFAmount ** '+totalMBMFAmount + ' && '+MBMFDonorCount);
        system.debug('totalSINDAAmount  ** '+totalSINDAAmount + ' && '+SINDADonorCount);
        system.debug('totalSDLAmount  ** '+totalSDLAmount  + ' && '+SDLDonorCount);
        
        //Start : CPF Contribution summary record
        string tempStrCPF = string.valueOf(totalCPFAmount).replace('.','');
		
        string strCPFAmount = '';
        for(Integer i=1;i<=(12-tempStrCPF.length());i++){
            strCPFAmount += '0';
        }
        strCPFAmount = strCPFAmount + tempStrCPF;
        string strDonorCountForCPF = '0000000';
        system.debug('strCPFAmount '+strCPFAmount);
        string strSummary = 'F'+'0'+strUEN+paymentType+serialNo+' '+adviceCode+relevantMonth+'01'+strCPFAmount+strDonorCountForCPF;
        
        for(Integer i=1;i<=103;i++){
            strSummary += ' ';
        }
        
        strSummary += '\r\n';
        empRecordCount++;
        //End : CPF Contribution summary record
        
        //Start : MBMF Contribution summary record
        string tempStrMBMF = string.valueOf(totalMBMFAmount).replace('.','');
        string strMBMFAmount = '';
        for(Integer i=1;i<=(12-tempStrMBMF.length());i++){
            strMBMFAmount += '0';
        }
        strMBMFAmount =strMBMFAmount + tempStrMBMF;
        string strDonorCountForMBMF = '';
        
        for(Integer i=1;i<=(7-string.valueOf(MBMFDonorCount).length());i++){
            strDonorCountForMBMF += '0';
        }
        strDonorCountForMBMF = strDonorCountForMBMF + string.valueOf(MBMFDonorCount);
        system.debug('strMBMFAmount '+strMBMFAmount);
        strSummary += 'F'+'0'+strUEN+paymentType+serialNo+' '+adviceCode+relevantMonth+'02'+strMBMFAmount+strDonorCountForMBMF;
        
        for(Integer i=1;i<=103;i++){
            strSummary += ' ';
        }
        
        strSummary += '\r\n';
        empRecordCount++;
        //End : MBMF Contribution summary record
        
        //Start : SINDA Contribution summary record
        string tempStrSINDA = string.valueOf(totalSINDAAmount).replace('.','');
        string strSINDAAmount = '';
        for(Integer i=1;i<=(12-tempStrSINDA.length());i++){
            strSINDAAmount += '0';
        }
        strSINDAAmount =strSINDAAmount + tempStrSINDA;
        string strDonorCountForSINDA = '';
        
        for(Integer i=1;i<=(7-string.valueOf(SINDADonorCount).length());i++){
            strDonorCountForSINDA += '0';
        }
        strDonorCountForSINDA = strDonorCountForSINDA + string.valueOf(SINDADonorCount);
        system.debug('strSINDAAmount '+strSINDAAmount);
        strSummary += 'F'+'0'+strUEN+paymentType+serialNo+' '+adviceCode+relevantMonth+'03'+strSINDAAmount+strDonorCountForSINDA;
        
        for(Integer i=1;i<=103;i++){
            strSummary += ' ';
        }
        
        strSummary += '\r\n';
        empRecordCount++;
        //End : SINDA Contribution summary record
        
        //Start : CDAC Contribution summary record
        string tempStrCDAC = string.valueOf(totalCDACAmount).replace('.','');
        string strCDACAmount = '';
        for(Integer i=1;i<=(12-tempStrCDAC.length());i++){
            strCDACAmount += '0';
        }
        strCDACAmount =strCDACAmount + tempStrCDAC;
        string strDonorCountForCDAC = '';
        
        for(Integer i=1;i<=(7-string.valueOf(CDACDonorCount).length());i++){
            strDonorCountForCDAC += '0';
        }
        strDonorCountForCDAC = strDonorCountForCDAC + string.valueOf(CDACDonorCount);
        system.debug('strCDACAmount'+strCDACAmount);
        strSummary += 'F'+'0'+strUEN+paymentType+serialNo+' '+adviceCode+relevantMonth+'04'+strCDACAmount+strDonorCountForCDAC;
        
        for(Integer i=1;i<=103;i++){
            strSummary += ' ';
        }
        
        strSummary += '\r\n';
        empRecordCount++;
        //End : CDAC Contribution summary record
        
        //Start : EUCF Contribution summary record
        string tempStrEUCF = string.valueOf(totalEUCFAmount).replace('.','');
        string strEUCFAmount = '';
        for(Integer i=1;i<=(12-tempStrEUCF.length());i++){
            strEUCFAmount += '0';
        }
        strEUCFAmount =strEUCFAmount + tempStrEUCF;
        string strDonorCountForEUCF = '';
        
        for(Integer i=1;i<=(7-string.valueOf(EUCFDonorCount).length());i++){
            strDonorCountForEUCF += '0';
        }
        system.debug('strEUCFAmount '+strEUCFAmount);
        strDonorCountForEUCF = strDonorCountForEUCF + string.valueOf(EUCFDonorCount);
        strSummary += 'F'+'0'+strUEN+paymentType+serialNo+' '+adviceCode+relevantMonth+'05'+strEUCFAmount+strDonorCountForEUCF;
        
        for(Integer i=1;i<=103;i++){
            strSummary += ' ';
        }
        
        strSummary += '\r\n';
        empRecordCount++;
        //End : EUCF Contribution summary record
        
        //Start : SDL Contribution summary record
        //string tempStrSDL = string.valueOf(totalSDLAmount).replace('.','');
		string tempStrSDL = string.valueOf(Integer.valueOf(totalSDLAmount))+'00';
        string strSDLAmount = '';
        for(Integer i=1;i<=(12-tempStrSDL.length());i++){
            strSDLAmount += '0';
        }
        strSDLAmount =strSDLAmount + tempStrSDL;
        string strDonorCountForSDL = '0000000';
        system.debug('strSDLAmount'+strSDLAmount);
        strSummary += 'F'+'0'+strUEN+paymentType+serialNo+' '+adviceCode+relevantMonth+'11'+strSDLAmount+strDonorCountForSDL;
        
        for(Integer i=1;i<=103;i++){
            strSummary += ' ';
        }
        
        strSummary += '\r\n';
        empRecordCount++;
        //End : SDL Contribution summary record
        
        strFile += strSummary;
        
        strSummary = null;
        
        //Start : Employee Contribution detail record
        
        if(payoutList.size()>0){
            string strDetail = '';
            
            for(Payout__c payout: payoutList){
				if(payout.Employee_Name__r.ID_Type__c=='Permanent Resident' || payout.Employee_Name__r.ID_Type__c=='Citizen'){
					string employeeName = (payout.Employee_Name__r.Firstname!=null?payout.Employee_Name__r.Firstname+' ':'') + payout.Employee_Name__r.Lastname;
					string empName = (employeeName.trim().length()>22?employeeName.substring(0,21):employeeName);
					empName = empName.trim();
					if(empName.trim().length()<22){
						for(Integer i=1;i<=(22-empName.trim().length());i++){
							empName += ' ';
						}
					}
					
					string employmentStatus = 'E';
					If(payout.Employee_Name__r.Joining_Date__c!=null && payout.Employee_Name__r.Joining_Date__c.month()==month && payout.Employee_Name__r.Joining_Date__c.year()==year && payout.Employee_Name__r.Last_Working_Date__c!=null && payout.Employee_Name__r.Last_Working_Date__c.month()==month && payout.Employee_Name__r.Last_Working_Date__c.year()==year){
						employmentStatus = 'O';
					}else If(payout.Employee_Name__r.Joining_Date__c!=null && payout.Employee_Name__r.Joining_Date__c.month()==month && payout.Employee_Name__r.Joining_Date__c.year()==year){
						employmentStatus = 'N';
					}else if(payout.Employee_Name__r.Last_Working_Date__c!=null && payout.Employee_Name__r.Last_Working_Date__c.month()==month && payout.Employee_Name__r.Last_Working_Date__c.year()==year){
						employmentStatus = 'L';
					}
					
					//Start : CPF detail contribution
					if(payout.Total_CPF__c>0){
						system.debug('payout.Total_CPF__c ** '+payout.Total_CPF__c);
						Integer intCPFAmount = Integer.valueOf(payout.Total_CPF__c);
						
						string tempStrCPFAmt = string.valueOf(payout.Total_CPF__c.setScale(2)).replace('.','');
						
						string strCPFDetailAmount = '';
						
						for(Integer i=1;i<=12-(tempStrCPFAmt.length());i++){
							strCPFDetailAmount += '0';
						}
						strCPFDetailAmount += tempStrCPFAmt;
						
						decimal ordinaryWages = ((payout.Salary__c!=null?payout.Salary__c:0) + (payout.Total_OW_Amount__c!=null?payout.Total_OW_Amount__c:0)).setScale(2);
						
						string tempOrdinaryWages = string.valueOf(ordinaryWages).replace('.','');
						
						string strOrdinaryWages = '';
						for(Integer i=1;i<=(10-tempOrdinaryWages.length());i++){
							strOrdinaryWages += '0';
						}
						strOrdinaryWages += tempOrdinaryWages;
						
						decimal additionalWages = (payout.Total_AW_Amount__c!=null?payout.Total_AW_Amount__c.setScale(2):0);
						
						string tempAdditionalWages = string.valueOf(additionalWages).replace('.','');
						
						string stradditionalWages = '';
						for(Integer i=1;i<=(10-tempAdditionalWages.length());i++){
							stradditionalWages += '0';
						}
						stradditionalWages += tempAdditionalWages;
						
						strDetail += 'F'+'1'+strUEN+paymentType+serialNo+' '+adviceCode+relevantMonth+'01'+payout.Employee_Name__r.Tax_Number__c+strCPFDetailAmount+strOrdinaryWages+stradditionalWages+employmentStatus+empName;
						
						for(Integer i=1;i<=58;i++){
							strDetail += ' ';
						}
						strDetail += '\r\n';
						empRecordCount++;
					}
					//End : CPF detail contribution
					
					//Start : MBMF detail contribution
					if(payout.MBMF__c > 0){
						system.debug('payout.MBMF__c ** '+payout.MBMF__c );
						string tempStrDetailMBMF = string.valueOf(payout.MBMF__c.setScale(2)).replace('.','');
						
						string strMBMFDetailAmount = '';
						
						for(Integer i=1;i<=12-(tempStrDetailMBMF.length());i++){
							strMBMFDetailAmount += '0';
						}
						strMBMFDetailAmount += tempStrDetailMBMF;
						
						string strOrdinaryWages = '0000000000';
						string stradditionalWages = '0000000000';    
						strDetail += 'F'+'1'+strUEN+paymentType+serialNo+' '+adviceCode+relevantMonth+'02'+payout.Employee_Name__r.Tax_Number__c+strMBMFDetailAmount+strOrdinaryWages+stradditionalWages+' '+empName;
						
						for(Integer i=1;i<=58;i++){
							strDetail += ' ';
						}
						strDetail += '\r\n';
						empRecordCount++;
					}
					//End : MBMF detail contribution
					
					//Start : SINDA detail contribution
					if(payout.SINDA__c > 0){
						system.debug('payout.SINDA__c ** '+payout.SINDA__c );
						string tempStrDetailSINDA = string.valueOf(payout.SINDA__c.setScale(2)).replace('.','');
					
						string strSINDADetailAmount = '';
						
						for(Integer i=1;i<=12-(tempStrDetailSINDA.length());i++){
							strSINDADetailAmount += '0';
						}
						strSINDADetailAmount += tempStrDetailSINDA;
						
						string strOrdinaryWages = '0000000000';
						string stradditionalWages = '0000000000';    
						strDetail += 'F'+'1'+strUEN+paymentType+serialNo+' '+adviceCode+relevantMonth+'03'+payout.Employee_Name__r.Tax_Number__c+strSINDADetailAmount+strOrdinaryWages+stradditionalWages+' '+empName;    
						
						for(Integer i=1;i<=58;i++){
							strDetail += ' ';
						}
						strDetail += '\r\n';
						empRecordCount++;
					}
					//End : SINDA detail contribution
					
					//Start : CDAC detail contribution
					if(payout.CDAC__c > 0){
						system.debug('payout.CDAC__c ** '+payout.CDAC__c);
						string tempStrDetailCDAC = string.valueOf(payout.CDAC__c.setScale(2)).replace('.','');
						
						string strCDACDetailAmount = '';
						
						for(Integer i=1;i<=12-(tempStrDetailCDAC.length());i++){
							strCDACDetailAmount += '0';
						}
						strCDACDetailAmount += tempStrDetailCDAC;
						
						string strOrdinaryWages = '0000000000';
						string stradditionalWages = '0000000000';    
						strDetail += 'F'+'1'+strUEN+paymentType+serialNo+' '+adviceCode+relevantMonth+'04'+payout.Employee_Name__r.Tax_Number__c+strCDACDetailAmount+strOrdinaryWages+stradditionalWages+' '+empName;    
						
						for(Integer i=1;i<=58;i++){
							strDetail += ' ';
						}
						strDetail += '\r\n';
						empRecordCount++;
					}
					//End : CDAC detail contribution
					
					//Start : EUCF detail contribution
					if(payout.EUCF__c > 0){
						system.debug('payout.EUCF__c ** '+payout.EUCF__c);
						string tempSetDetailEUCF = string.valueOf(payout.EUCF__c.setScale(2)).replace('.','');
							
						string strEUCFDetailAmount = '';
						
						for(Integer i=1;i<=12-(tempSetDetailEUCF.length());i++){
							strEUCFDetailAmount += '0';
						}
						strEUCFDetailAmount += tempSetDetailEUCF;
						
						string strOrdinaryWages = '0000000000';
						string stradditionalWages = '0000000000';    
						strDetail += 'F'+'1'+strUEN+paymentType+serialNo+' '+adviceCode+relevantMonth+'05'+payout.Employee_Name__r.Tax_Number__c+strEUCFDetailAmount+strOrdinaryWages+stradditionalWages+' '+empName;
						
						for(Integer i=1;i<=58;i++){
							strDetail += ' ';
						}
						strDetail += '\r\n';
						empRecordCount++;
					}
					//End : EUCF detail contribution
                }
            }
            
            strFile += strDetail;
            
            strDetail = null;
        }
        //End : Employee Contribution detail record
        
        //Start : Footer
        empRecordCount++;
        string strEmpRecordCount = '';
        for(Integer i=1;i<=7-string.valueOf(empRecordCount).length();i++){
            strEmpRecordCount += '0';
        }
        strEmpRecordCount += string.valueOf(empRecordCount);
        
        //decimal totalContributionAmount = totalCPFAmount+totalCDACAmount+totalEUCFAmount+totalMBMFAmount+totalSINDAAmount+totalSDLAmount;
		decimal totalContributionAmount = totalCPFAmount+totalCDACAmount+totalEUCFAmount+totalMBMFAmount+totalSINDAAmount+Integer.valueOf(totalSDLAmount);
        totalContributionAmount = totalContributionAmount.setScale(2);
        string tempStrContributionAmount = string.valueOf(totalContributionAmount).replace('.','');
        string strContributionAmount = '';
        for(Integer i=1;i<=(15-tempStrContributionAmount.length());i++){
            strContributionAmount += '0';
        } 
        strContributionAmount = strContributionAmount + tempStrContributionAmount;
        string strFooter = 'F'+'9'+strUEN+paymentType+serialNo+' '+adviceCode+strEmpRecordCount+strContributionAmount;
        
        for(Integer i=1;i<=108;i++){
            strFooter += ' ';
        }
            
        //End : Footer
        
        strFile += strFooter; 
        
        payoutList = null;
        strFooter = null;
        
        system.debug('END ******************************** ');
        system.debug('totalCPFAmount ** '+totalCPFAmount+ ' && '+cpfDonorCount);
        system.debug('totalCDACAmount ** '+totalCDACAmount + ' && '+CDACDonorCount);
        system.debug('totalEUCFAmount ** '+totalEUCFAmount + ' && '+EUCFDonorCount);
        system.debug('totalMBMFAmount ** '+totalMBMFAmount + ' && '+MBMFDonorCount);
        system.debug('totalSINDAAmount  ** '+totalSINDAAmount + ' && '+SINDADonorCount);
        system.debug('totalSDLAmount  ** '+totalSDLAmount  + ' && '+SDLDonorCount);
    }
}