@RestResource(urlMapping='/accounttype/*')

global class AccountTypeApi {  
    @HttpGet
    global static String getAccountType() {
       RestRequest req = RestContext.request;
        String personId = req.params.get('id');
        Account accObj = new Account();
        accObj = [SELECT Id, RecordType.Name FROM Account Where Id=:personId];
        return String.valueOf(JSON.serialize(accObj.RecordType.Name));  
    }   
}