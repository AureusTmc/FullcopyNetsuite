public class FetchBalanceTransactionsQueueable implements Queueable, Database.AllowsCallouts {
    private String stripePayoutId;
    private String starting_afterId = '';
    private Id payoutId;
    private Integer limitOfRecords;
    private String apiKey;
    private Stripe_Payout_Log__c payoutObj;
    private Id paymentTransactionRcTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByDeveloperName().get('Payment_Transaction').getRecordTypeId();
    private Id refundPaymentRcTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByDeveloperName().get('Refund').getRecordTypeId();
    
    //Constructor used first to invoke queueable
    public FetchBalanceTransactionsQueueable(Id payoutId, Integer limitOfRecords){
        this.payoutId = payoutId;
        List<Stripe_Payout_Log__c> stripePayoutLogList = [SELECT Id, Stripe_Payout_Id__c, Organisation__r.Country__r.Stripe_Secret_Key__c, Status__c FROM Stripe_Payout_Log__c WHERE Id=: payoutId];

        if(stripePayoutLogList != NULL && stripePayoutLogList.size()>0){
            this.payoutObj = stripePayoutLogList[0];
            this.stripePayoutId = stripePayoutLogList[0].Stripe_Payout_Id__c;
            this.apiKey = stripePayoutLogList[0].Organisation__r.Country__r.Stripe_Secret_Key__c;
        }
        this.limitOfRecords = limitOfRecords;
    }
    
    //Constructor used to chain jobs, accepts last id of limited retrieved records
    public FetchBalanceTransactionsQueueable(Id payoutId, Integer limitOfRecords, String starting_afterId){
        this.payoutId = payoutId;
        List<Stripe_Payout_Log__c> stripePayoutLogList = [SELECT Id, Stripe_Payout_Id__c, Organisation__r.Country__r.Stripe_Secret_Key__c, Status__c FROM Stripe_Payout_Log__c WHERE Id=: payoutId];
        if(stripePayoutLogList != NULL && stripePayoutLogList.size()>0){
            this.payoutObj = stripePayoutLogList[0];
            this.stripePayoutId = stripePayoutLogList[0].Stripe_Payout_Id__c;
            this.apiKey = stripePayoutLogList[0].Organisation__r.Country__r.Stripe_Secret_Key__c;
        }
        this.limitOfRecords = limitOfRecords;
        this.starting_afterId = starting_afterId;
    }
    
    public void execute(QueueableContext context){
        System.debug('apiKey '+apiKey);
        if(String.isNotBlank(apiKey)){
            System.debug('apiKey '+apiKey);
            String baseurl = 'https://api.stripe.com';
            String transactionUrl = baseurl+'/v1/balance_transactions';
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            if(starting_afterId != ''){
                request.setEndpoint(transactionUrl+'?payout='+stripePayoutId+'&limit='+limitOfRecords+'&starting_after='+starting_afterId);
                System.debug('called with starting after id');
            }
            else{
                request.setEndpoint(transactionUrl+'?payout='+stripePayoutId+'&limit='+limitOfRecords);
                System.debug('called without starting after id');
            }
            request.setMethod('GET');
            
            Blob headerValue = Blob.valueOf(apiKey);
            String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
            request.setHeader('Authorization', authorizationHeader);
            
            HttpResponse response = http.send(request);
            System.debug('response '+response.getBody());
            System.debug(response.getStatusCode());
            if(response.getStatusCode() == 200){
                String respStr = response.getBody();
                respStr = cleanJson(respStr);
                BalanceTransactionWrapper balTransaction = (BalanceTransactionWrapper) System.JSON.deserialize(respStr, BalanceTransactionWrapper.class);
                system.debug('@@balTransaction'+balTransaction);
                
                if(balTransaction != NULL && balTransaction.data != null){ //if any record exists
                    String endingObjId = balTransaction.data.get(balTransaction.data.size()-1).id; //store last object's id for future use
                    Map<String, Decimal> mapTransactionToFee = new Map<String, Decimal>();
                    Map<String, Decimal> mapRefundToFee = new Map<String, Decimal>();
                    
                    for(DataWrapper data: balTransaction.data){
                        if(data.source != null && data.stripeType != null){
                            Map<String, Decimal> mapTypeToFee = new Map<String, Decimal>();
                            if(data.stripeType == 'charge'){
                                if(data.fee > 0){ //stripe fee must always be negative in this case
                                    data.fee = data.fee * -1;
                                }
                                
                                Decimal fee = data.fee/100;
                                mapTransactionToFee.put(data.source, fee);
                            }
                            else if(data.stripeType == 'refund'){
                                if(data.fee < 0){ //stripe fee must always be positive in this case
                                    data.fee = data.fee * -1;
                                }
                                
                                Decimal fee = data.fee/100;
                                mapRefundToFee.put(data.source, fee);
                            }
                        }
                    }
                    
                    //update Payment records on the basis of source, as received from http response
                    if(!mapTransactionToFee.isEmpty() || !mapRefundToFee.isEmpty()){
                        List<Payment__c> paymentList = [SELECT Id, Stripe_Payout_Id__c, Stripe_fees__c, Transaction_ID__c, RecordTypeId, Refund_Id__c FROM Payment__c WHERE (Transaction_ID__c IN: mapTransactionToFee.KeySet() OR Refund_Id__c IN: mapRefundToFee.KeySet()) AND (RecordTypeId =: paymentTransactionRcTypeId OR RecordTypeId =: refundPaymentRcTypeId)];
                        System.debug(paymentList);
                        if(paymentList != NULL && paymentList.size()>0){
                            for(Payment__c paymentObj: paymentList){
                                paymentObj.Stripe_Payout_Id__c = payoutId;
                                if(!mapTransactionToFee.isEmpty() && mapTransactionToFee.containsKey(paymentObj.Transaction_ID__c)){
                                    paymentObj.Stripe_fees__c = mapTransactionToFee.get(paymentObj.Transaction_ID__c);
                                }
                                else if(!mapRefundToFee.isEmpty() && mapRefundToFee.containsKey(paymentObj.Refund_Id__c)){
                                    paymentObj.Stripe_fees__c = mapRefundToFee.get(paymentObj.Refund_Id__c);
                                }
                            }
                            
                            update paymentList;
                        }
                    }
                    
                    if(balTransaction.has_more){ //if more records exist
                        //Chain another job that will fetch records after the last record retrieved
                        System.enqueueJob(new FetchBalanceTransactionsQueueable(payoutId, limitOfRecords, endingObjId));
                    }
                    else{
                        System.debug('has more false');
                        payoutObj.Status__c = 'Processed in SF';
                        System.debug(payoutObj);
                        update payoutObj;
                    }
                }
            }
        }
    }
    
    //this method is used to correct JSON such that it can be deserialized with apex
    public static String cleanJson(String json){
        json = json.replaceAll('"currency":', '"stripeCurrency":');
        json = json.replaceAll('"type":', '"stripeType":');
        
        return json;
    }
    
    public class BalanceTransactionWrapper{
        public List<DataWrapper> data;
        public Boolean has_more;
    }
    
    public class DataWrapper{
        public String id;
        public Decimal amount;
        public String stripeCurrency;
        public String description;
        public Decimal fee;
        public List<FeeDetailsWrapper> fee_details;
        public String source;
        public String stripeType;
    }
    
    public class FeeDetailsWrapper{
        public Decimal amount;
        public String stripeCurrency;
        public String description;
        public String stripeType; 
    }
}