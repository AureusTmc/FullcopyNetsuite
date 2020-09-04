({
	genratePDF : function(component) {
        var invoiceId = component.get("v.recordId");
        window.open($A.get("$Label.c.Aureus_Site")+'/SubscriptionInvoicePDFClone?id='+invoiceId, '_blank');
        
	}
   
})