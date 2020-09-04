public class FileUploadController {
    
    @AuraEnabled
    public static Map<Id,List<String>> recordList(String recordId){
        List<String> attListStr;
        Map<Id,List<String>> strMap; 
        List<Attachment> attList;
        
        attListStr=new List<String>();
        strMap = new Map<Id,List<String>>();
        attList=[Select Id, ContentType, BodyLength, Name, Parent.Name, Parent.Type from Attachment where ParentId =:recordId];
        
        for(Attachment a : attList){
            Double s ;
            Double dec=0.0;
            Integer ir = a.BodyLength;
            String fvalue;
            if(a != null && a.BodyLength != null)
                s = (a.BodyLength/1024);
            if(s>1000){
                Decimal mb = Decimal.valueOf(ir);
                mb = mb.divide((1024*1024),2);
                fvalue=string.valueOf(mb) + 'MB';
            }else{
                fvalue = (a.BodyLength/1024)+'KB';
            }
            String nameField = a.Name;
            if(nameField.Contains('.'))
                attListStr.add(nameField.substringBefore('.'));
            //strMap.put(a.Id,nameField.substringBefore('.'));
            List<String> strList = new List<String>();
            strList.add(nameField);
            strList.add(fvalue);
            strMap.put(a.Id,strList);
        }
        return strMap;
    }
    @AuraEnabled
    public static Map<Id,List<String>> deleteRecordID(String recId, String recordId) {
        Attachment attFile = new Attachment();
        attFile=[Select Id,Parent.Type from Attachment where Id=:recId];
        Delete attFile;
        return recordList(recordId);
    }
    
    @AuraEnabled
    public static Map<Id,List<String>> saveFile(Id parentId, String fileName, String base64Data, String contentType) {
        
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        Attachment attFile = new Attachment();
        
        attFile.ParentId = parentId; 
        System.debug(parentId);
        attFile.body = EncodingUtil.base64Decode(base64Data);
        attFile.name = filename;
        attFile.ContentType =contentType;
        Insert attFile;
        return recordList(parentId);
    }
}