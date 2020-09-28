/*
 *  
 */
public without Sharing class ConvertToAdhoc implements IConvertFifthLesson{
    String lessonId, caseId;
    Boolean caseFlag;
    List<Enrolment__c> enrolmentList = new List<Enrolment__c>();
    Country__c countryObj; // commented by nishi:24-aug-2020:Organisation wise charge as per new logic
   Organisation__c organisationObj;
    String stripeId;

    public ConvertToAdhoc(String lessonId, String caseId, Boolean caseFlag) {
        this.lessonId = lessonId;
        this.caseId = caseId;
         countryObj = new Country__c(); // commented by nishi:24-aug-2020:Organisation wise charge as per new logic
        organisationObj = new Organisation__c();
        this.caseFlag = caseFlag;
    }

    public String convertFifthLesson(){
        Map<String, Package__c> adhocPackageMap = new Map <String, Package__c>();
        Boolean isSuccess = FALSE;
        String caseIdToReturn = '';
        List<Booking__c> adhocList = new List<Booking__c>();
        List<Booking__c> adhocListToInsert = new List<Booking__c>();
        List<Fifth_Lesson__c> fifthLessons = new List<Fifth_Lesson__c>();
        Boolean isOssia = FALSE;
        if(String.isNotBlank(lessonId)){
            //system.debug('@@@lessonId'+lessonId);
            fifthLessons = AureusCalendarControllerHelper.fetchFifthLessson(new Set<String>{lessonId});
            //system.debug('@@fifthLessons'+fifthLessons);
            for(Fifth_Lesson__c fifthLesson : fifthLessons){
                enrolmentList.add(fifthLesson.Enrolment__r);
                countryObj = fifthLesson.Enrolment__r.center__r.Country__r;// commented by nishi:17-aug-2020: for related to Ossia Organisation Center  then we manage facility fees
                organisationObj = fifthLesson.Enrolment__r.center__r.Organisation__r;
                //Start:added by nishi:24-aug-2020:Organisation wise charge as per new logic
                if(string.isnotBlank(fifthLesson.Center__c) && string.isnotBlank(fifthLesson.Center__r.Organisation__c) 
                    && string.isnotBlank(fifthLesson.Center__r.Organisation__r.Name) && fifthLesson.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                        isOssia = true;
                }
                 //end:added by nishi:24-aug-2020:Organisation wise charge as per new logic
            }
			//System.debug('@@@fifthLessons'+fifthLessons);
            if(fifthLessons.size() > 0){
                stripeId = fifthLessons[0].Parent__r.Stripe_Customer_Id__c;
                Invoice__c objectOfInvoice = new Invoice__c();
                Package__c packageObj = new Package__c();
                List<Invoice_Line_Item__c> listOfInvoiceLineItem = new List<Invoice_Line_Item__c>();
                Decimal total; Decimal gst = 0;
                //Decimal facilityTotal; Decimal facilitygst = 0;
                adhocPackageMap = fetchAdhocLessons(enrolmentList);

                adhocList = AureusCalendarControllerHelper.createBookingFromFifthLesson(fifthLessons, 'adhoc'); 
				////System.debug('@@adhocList'+adhocList);
                ////System.debug('@@adhocPackageMapValues'+fifthLessons[0].Enrolment__r.Center__c);
                ////System.debug('@@adhocPackageMapValues'+fifthLessons[0].Enrolment__r.Center__c);
                ////System.debug('@@adhocPackageMap'+adhocPackageMap.containsKey(fifthLessons[0].Enrolment__r.Center__c + '-'+ fifthLessons[0].Enrolment__r.Package__r.Duration__c));
                if(adhocList.size() > 0 && adhocPackageMap.containsKey(fifthLessons[0].Enrolment__r.Center__c + '-'+ fifthLessons[0].Enrolment__r.Package__r.Duration__c)){

                    packageObj = adhocPackageMap.get(fifthLessons[0].Enrolment__r.Center__c + '-'+ fifthLessons[0].Enrolment__r.Package__r.Duration__c);
                    adhocList[0].Package__c = packageObj.Id;
                    
                    objectOfInvoice = new Invoice__c(Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                    Invoice_Date__c =system.today(), Parent_Account__c = adhocList[0].Parent__c, Center__c = adhocList[0].Center__c);
                                   
                    if(String.isNotBlank(packageObj.Id)){
                        total = packageObj.unit_Fee__c;
                    }
                    if(total > 0 && countryObj.Tax_Rate__c > 0){
                        gst = total * (countryObj.Tax_Rate__c / 100);
                        total += gst;
                        total = BillingUtility.roundOffAmount(total);
                    }
                    
                     //Start:added by nishi: nishi:24-aug-2020:Organisation wise charge as per new logic
                    // if(isOssia){
                    //     if(String.isNotBlank(packageObj.Id)){
                    //         facilitytotal = (packageObj.facility_Fee__c/4);
                    //     }
                    //     if(facilitytotal > 0 && countryObj.Tax_Rate__c > 0){
                    //         facilitygst = facilitytotal * (countryObj.Tax_Rate__c / 100);
                    //         facilitytotal += facilitygst;
                    //         facilitytotal = BillingUtility.roundOffAmount(facilitytotal);
                    //     }
                    //     total +=facilitytotal;
                    //     gst +=facilitygst;
                    // }
                     //end:added by nishi: 17-aug-2020: for is ossia center Adhoc type booking created then we added facility Fee
					////System.debug('@@@objectOfInvoice'+objectOfInvoice);
                    ////System.debug('@@@stripeId'+stripeId);
                    ////System.debug('@@@total'+total);
                    ////System.debug('@@@countryObj.Currency_Code__c'+countryObj.Currency_Code__c);
                    ////System.debug('@@@countryObj.Id'+countryObj.Id);
                    if(objectOfInvoice != NULL && total > 0 && String.isNotBlank(stripeId) &&  String.isNotBlank(organisationObj.Id)){ // Start:comment by nishi:24-aug-2020:Organisation wise charge as per new logic String.isNotBlank(countryObj.Id)){
                        BillingUtility.StripeCharge objStripeCharge = new BillingUtility.StripeCharge();
				        // Start:comment by nishi:24-aug-2020:Organisation wise charge as per new logic    
                        //objStripeCharge = AureusCalendarController.updateInvoice(objectOfInvoice, total, stripeId, countryObj.Currency_Code__c, countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c);
                        // end:comment by nishi:24-aug-2020:Organisation wise charge as per new logic
                        objStripeCharge = AureusCalendarController.updateInvoice(objectOfInvoice, total, stripeId, organisationObj.Country__r.Currency_Code__c, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c);
                        
                        //System.debug('@@@objStripeCharge'+objStripeCharge);
                        insert adhocList;
                        if(objStripeCharge.statusCode == 200 && objStripeCharge.paid){
                            objectOfInvoice.Status__c=ConstantsClass.paidStatus;
                        }else{
                            objectOfInvoice.Status__c=ConstantsClass.dueStatus ;
                        }
                        insert objectOfInvoice;
                        
                        
                        //system.debug('$$$$objectOfInvoice --'+objectOfInvoice);
                        //objectOfInvoice = [SELECT Id,Name,Parent_Account__c,Total_Amount__c FROM Invoice__c WHERE Id=: objectOfInvoice.Id];
                        
                        if(String.isNotBlank(objectOfInvoice.id)){
                            for(Integer i = 0; i < adhocList.size(); i++){
                                decimal gstAmount = 0;
                                if(packageObj.unit_Fee__c != null &&  packageObj.unit_Fee__c > 0 && BillingUtility.roundOffAmount(countryObj.Tax_Rate__c) != null && BillingUtility.roundOffAmount(countryObj.Tax_Rate__c) > 0 ){
                                    gstAmount = BillingUtility.roundOffAmount(packageObj.unit_Fee__c) *(BillingUtility.roundOffAmount(countryObj.Tax_Rate__c) / 100);
                               }
                                listOfInvoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,
                                                                                Amount__c= BillingUtility.roundOffAmount(packageObj.unit_Fee__c),
                                                                                GST_Amount__c = gstAmount, 
                                                                                package__c=packageObj.Id, 
                                                                                Booking__c = adhocList[i].Id, month__c = adhocList[i].Booking_Date__c));
                                //Start:added by nishi: 17-aug-2020: for is ossia center Adhoc type booking created then we added facility Fee
                                // if(isOssia){
                                //     gstAmount = 0;
                                //     if(packageObj.facility_Fee__c != null && BillingUtility.roundOffAmount(countryObj.Tax_Rate__c) != null && 
                                //     BillingUtility.roundOffAmount(countryObj.Tax_Rate__c) > 0 && packageObj.facility_Fee__c > 0){
                                //         gstAmount = BillingUtility.roundOffAmount(packageObj.facility_Fee__c/4) *(BillingUtility.roundOffAmount(countryObj.Tax_Rate__c) / 100);
                                //     }
                                //     listOfInvoiceLineItem.add(new Invoice_Line_Item__c(invoice__c = objectOfInvoice.id,
                                //                                     Amount__c= BillingUtility.roundOffAmount(packageObj.facility_Fee__c/4),
                                //                                     GST_Amount__c = gstAmount, 
                                //                                     package__c=packageObj.Id, 
                                //                                     Booking__c = adhocList[i].Id, month__c = adhocList[i].Booking_Date__c,
                                //                                     Remarks__c = 'Facility Fee'));
                                // }
                                 //End:added by nishi: 17-aug-2020: for is ossia center Adhoc type booking created then we added facility Fee
                            }
                            ////System.debug('@@@ BillingUtility.roundOffAmount(packageObj.unit_Fee__c)'+ BillingUtility.roundOffAmount(packageObj.unit_Fee__c));
                            ////System.debug('@@GST_Amount__c'+BillingUtility.roundOffAmount(packageObj.unit_Fee__c) *(BillingUtility.roundOffAmount(countryObj.Tax_Rate__c) / 100));
                        }


                        if(listOfInvoiceLineItem.size() > 0){
                            insert listOfInvoiceLineItem;
                        }

                        objectOfInvoice = [SELECT Id,Name,Total_Amount__c,Parent_Account__c,Parent_Account__r.personContactId, status__c FROM Invoice__c WHERE Id =: objectOfInvoice.Id];
                        ////System.debug('@@objectOfInvoice'+objectOfInvoice);
                        if(String.isNotBlank(objectOfInvoice.Id)){
                            BillingUtility.createAttachment(new set<string>{objectOfInvoice.id});
                            //BillingUtility.createInvoiceAttachment(new List<Invoice__c>{objectOfInvoice});
                        }
                        ////System.debug('@@@listOfInvoiceLineItem'+listOfInvoiceLineItem);
                        if(objStripeCharge.statusCode == 200 && objStripeCharge.paid && adhocList.size() > 0){
                            Payment__c objPayment = BillingUtility.fillPayment(objectOfInvoice.Parent_Account__c, objectOfInvoice.Id, total, ConstantsClass.successStatus); 
                            objPayment.Transaction_ID__c = objStripeCharge.Id;
                            objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                            insert objPayment;

                            // start:comment by nishi:24-aug-2020:Organisation wise charge as per new logic
                            // if(String.isNotBlank(countryObj.Id)){
                            //     BillingUtility.updateCharge(objStripeCharge.Id,objectOfInvoice.Name, countryObj.Stripe_Base_Url__c, countryObj.Stripe_Secret_Key__c);    
                            // }
                            // end:comment by nishi:24-aug-2020:Organisation wise charge as per new logic
                            if(String.isNotBlank(organisationObj.Id)){
                                BillingUtility.updateCharge(objStripeCharge.Id,objectOfInvoice.Name, organisationObj.Stripe_Base_Url__c, organisationObj.Stripe_Secret_Key__c);    
                            }

                            // added by jatin: 31-Dec-2019 : for adhoc invoice to push on the sage
                             SageIntacctIntegrationUtility.adhocInvoice(objectOfInvoice.id);
                        }else{
                            Stripe_Payment_Log__c iLog = new Stripe_Payment_Log__c();
                            if(objStripeCharge.error != null){
                                iLog.Status__c = 'Failure';
                                iLog.Invoice__c = objectOfInvoice.Id;
                                
                                iLog.Message__c = objStripeCharge.error.message;
                                iLog.Type__c = objStripeCharge.error.stripeType;
                                
                                if(String.isNotBlank(objStripeCharge.error.charge)){
                                    iLog.ChargeId__c = objStripeCharge.error.charge;
                                }
                                if(String.isNotBlank(objStripeCharge.error.decline_code)){
                                    iLog.Code__c = objStripeCharge.error.decline_code;
                                }
                                INSERT iLog;
                            }
                            
                        }
                    }
                }  

            }
            ////System.debug('@@@adhocList[0].Id'+adhocList[0].Id);
            if(string.isNotBlank(adhocList[0].Id)){
                Fifth_Lesson__c lessonObj = new Fifth_Lesson__c();
                lessonObj.Id = lessonId;
                lessonObj.isActive__c = FALSE;
                lessonObj.Booking__c = adhocList[0].Id;
                update lessonObj;
                ////System.debug('@@lessonObj'+lessonObj);
                if(caseFlag){
                    Case caseObj = AureusCalendarControllerHelper.createCase(caseId, adhocList[0].Id, 'Ad-hoc');
                    if(caseObj != NULL && String.isNotBlank(caseObj.id)){
                        caseIdToReturn = caseObj.Id;
                    }
                }else{
                    caseIdToReturn = adhocList[0].Id;
                }
            }
        }
        ////System.debug('@@caseIdToReturn'+caseIdToReturn);
        return caseIdToReturn;
    }

    private Map<String, Package__c> fetchAdhocLessons(List<Enrolment__c> enrolmentList){
        Set<String> setOfCentre = new Set<String>();
        Set<String> setOfDuration = new Set<String>();
        Map<String, Package__c> mapOfAdhocPackage = new Map<String, Package__c>();

        for(Enrolment__c enrolObj : enrolmentList){
            setOfCentre.add(enrolObj.Center__c);
            setOfDuration.add(enrolObj.package__r.Duration__c);
        }

        if(setOfCentre.size() > 0 && setOfDuration.size() > 0){
            for(Package__c packageObj : [SELECT Id, Location__c, Duration__c, unit_Fee__c/*,facility_Fee__c*/ FROM Package__c 
                                         WHERE Active__c = TRUE AND Type__c = 'Adhoc' AND Location__c IN :setOfCentre AND 
                                         Duration__c IN :setOfDuration]){
                mapOfAdhocPackage.put(packageObj.Location__c + '-' + packageObj.Duration__c, packageObj);
            } 
        }

        return mapOfAdhocPackage;
    }

}