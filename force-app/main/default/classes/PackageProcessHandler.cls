/*    
        Name            :    PackageProcessHandler
        Date            :    28th March 2019
        Author          :    Arpit Vijayvergiya
        Description     :    This is handler class for package Proccessing.

*/
public class PackageProcessHandler{
    public Invoice__c objInvoice;
    public List<PackageProcessInterface> listOfPackageProcess;
    
    public PackageProcessHandler(Invoice__c objInvoice , List<Subscription_Line_Item__c> listOfSubLineItems, Date firstDate,Date LastDate){
        listOfPackageProcess = new List<PackageProcessInterface>();
        this.objInvoice = objInvoice;
        String pendingStatus = ConstantsClass.enrollmentProcessPendingStatus;
        String upgradeType = ConstantsClass.enrollmentProcessUpgradeType;
        String downgradeType = ConstantsClass.enrollmentProcessDowngradeType;
        String cancelType = ConstantsClass.enrollmentProcessCancelType;
        String enromentChangeType = ConstantsClass.enrollmentProcessChanged; 
        String enromentChangeCenterType = ConstantsClass.enrollmentProcessChangedCenter; 
        for(Subscription_Line_Item__c objSubLineItems : listOfSubLineItems){
            if(String.isNotBlank(objSubLineItems.Enrolment__c) && String.isNotBlank(objSubLineItems.Enrolment__r.Package_Process_type__c)
                && String.isNotBlank(objSubLineItems.Enrolment__r.Package_Process_Status__c) && 
                objSubLineItems.Enrolment__r.Package_Process_Status__c == pendingStatus && objSubLineItems.Enrolment__r.effective_date__c != NULL &&
                  (/*objSubLineItems.Enrolment__r.effective_date__c >= firstDate &&*/ objSubLineItems.Enrolment__r.effective_date__c <= lastDate)){
                if(objSubLineItems.Enrolment__r.Package_Process_type__c == upgradeType){
                    listOfPackageProcess.add(new PackageUpgradeController(objSubLineItems));
                }else if(objSubLineItems.Enrolment__r.Package_Process_type__c == downgradeType){
                    listOfPackageProcess.add(new PackageDowngradeController(objSubLineItems));
                }else if(objSubLineItems.Enrolment__r.Package_Process_type__c == cancelType){
                    listOfPackageProcess.add(new PackageCancellationController(objSubLineItems));
                }else if(objSubLineItems.Enrolment__r.Package_Process_type__c == enromentChangeType){
                    listOfPackageProcess.add(new EnrolmentChangeHandler(objSubLineItems));
                }else if(objSubLineItems.Enrolment__r.Package_Process_type__c == enromentChangeCenterType){
                    listOfPackageProcess.add(new EnrolmentChangeCenterHandler(objSubLineItems));
                }
            }else{
                // this is for normal invoiceType
                listOfPackageProcess.add(new RegularInvoiceHandler(objSubLineItems,firstDate,lastDate));
            }
        }
    }
}