Public class GenerateBankFileController{
    public string month{get;set;}
    public string year{get;set;}
    public string organisation{get;set;}
    Public date uploadDate{get;set;}
    
    Public GenerateBankFileController(){
        month = system.now().format('M');
        year = system.now().format('yyyy');
    }
    
    public pageReference generate(){
        return new pageReference('/apex/BankFile?month='+month+'&year='+year+'&org='+organisation+'&uploadDate='+uploadDate);
    }
    public List<Selectoption> getOrganisationList(){
        List<Selectoption> orgList = new List<Selectoption>();
        for(Organisation__c org : [SELECT Id, Name FROM Organisation__c]){
            orgList.add(new SelectOption(org.Id,org.Name));
        }
        return orgList;
    }
    public List<Selectoption> getMonthList(){
        List<Selectoption> monthList = new List<Selectoption>();
        monthList.add(new SelectOption('1','January'));
        monthList.add(new SelectOption('2','February'));
        monthList.add(new SelectOption('3','March'));
        monthList.add(new SelectOption('4','April'));
        monthList.add(new SelectOption('5','May'));
        monthList.add(new SelectOption('6','June'));
        monthList.add(new SelectOption('7','July'));
        monthList.add(new SelectOption('8','August'));
        monthList.add(new SelectOption('9','September'));
        monthList.add(new SelectOption('10','October'));
        monthList.add(new SelectOption('11','November'));
        monthList.add(new SelectOption('12','December'));
        return monthList;
    }
    
    Public List<SelectOption> getYearList(){
        List<SelectOption> yearList = new List<SelectOption>();
        
        for(Integer i=(system.today().year()-1);i<=(system.today().year()+8);i++){
            yearList.add(new SelectOption(''+i,''+i));    
        }
        return yearList;
    }
}