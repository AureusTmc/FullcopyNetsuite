public with sharing class AddCreditMemoController {
  @AuraEnabled(cacheable=true)
  public static creditMemoWrap getCreditMemoDetails(Id invId) {
    return null;
  } 
  public class creditMemoWrap {
    String invoiceAmount;
    String existCreditAmount;
    String userEnteredAmount;
    String invoiceId;
    list<Invoice_Line_Item__c> listInvLineItems;
  }
}