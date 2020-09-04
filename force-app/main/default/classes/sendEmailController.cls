public with Sharing class sendEmailController{
    private List<EmailTemplate> emailTemplateList;
    public String templateName{get;Set;}
    public Account acc{get;set;}
    public Static String bookingId{get;set;}
    
    public sendEmailController(){
        
        acc = new Account();
        emailTemplateList = new List<EmailTemplate>();
        emailTemplateList = [SELECT Id, Name, Subject, body, FolderName FROM EmailTemplate WHERE IsActive = true AND Folder.Name= 'Aureus Email Calender'];
    }
    public List<SelectOption> getEmailTemplates(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('' , ''));
        for(EmailTemplate et : emailTemplateList){
            options.add(new SelectOption(et.id , et.Name));
        }
        return options;
    }
    @RemoteAction
    public static String templatePreview(String templateId, String bookingId){
        System.debug('bookingId' + bookingId);
        List<EmailTemplate> selectedEmailTemplate = new List<EmailTemplate>();
        if(String.isNotBlank(templateId)){
            selectedEmailTemplate = [select id, body, HtmlValue, TemplateType, Subject, BrandTemplateId FROM EmailTemplate WHERE IsActive = true AND id =: templateId];
        }
        
        
        templateWrapper tw = new templateWrapper();
        if(!selectedEmailTemplate.isEmpty()){
            tw.templateBody = '';
            tw.subject = '';
            tw.header = '';
            tw.id = selectedEmailTemplate[0].id;
            if(string.isNotBlank(selectedEmailTemplate[0].BrandTemplateId)){
                List<BrandTemplate> header = [SELECT Id,Value FROM BrandTemplate WHERE Id = : selectedEmailTemplate[0].BrandTemplateId];
                system.debug('##### '+header);
                if(!header.isEmpty()){
                   tw.header =  header[0].value;
                }
            }
            if(String.isNotBlank(tw.id) && String.isNotBlank(bookingId)){
                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(tw.id, bookingId, bookingId);
                
                if(selectedEmailTemplate[0].TemplateType == 'text'){
                    tw.templateBody = email.getPlainTextBody();
                }else{
                    tw.templateBody = email.getHtmlBody();
                }
                tw.type = selectedEmailTemplate[0].TemplateType;
                tw.subject = email.getSubject();
            }
            return JSON.Serialize(tw);
        }
        return '';
    }
    
    public class templateWrapper{
        public String subject;
        public String templateBody;
        public String header;
        public String id;
        public String type;
    }
}