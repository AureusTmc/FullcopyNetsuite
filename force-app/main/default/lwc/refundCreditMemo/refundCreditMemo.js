import { LightningElement, api, track } from "lwc";
import fetchCreditMemoDetails from "@salesforce/apex/RefundCreditMemoController.getCreditMemoDetails";
import RefundCreditMemoRec from "@salesforce/apex/RefundCreditMemoController.refundCreditMemo";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
//CH01 12 Oct 2020 Karan Singh : Incase of Refund, message should be -> ex "$20 refunded successfully via Stripe."
//CH02 15 OCt 2020 : Refund a Credit Memo (other than stripe) : Incase the user had made payment without stripe as cash,cheque etc then in that case
//                   it will not hit the stripe api and there are changes in the api instead.
//                    Also changes in the refund toast message in Js.
//CH03 16 Oct 2020 : Add Card Number and Card tyoe in the UI In case of Refund method is Card on file 
//                      and payment method will be change from cheque to bank 
export default class RefundCreditMemo extends LightningElement {
  @api recordId;
  @track creditMemoWrap;
  showModal = false;
  confirmationMessage = "";
  showConfirmBox = false;
  isLoaded = false;
  showCardDetails = false; //CH03 : show the card details in card of Card-on-file only

  //CH02 Start : this will show the user the refund payment mode, it is read only
@track refundOptions = [
  { label: "Card-on-file", value: "Cardonfile", disabled: true, checked : false },
  { label: "Bank Cheque", value: "Bank Cheque", disabled: true,checked : false },
  ];
//CH02 End

//CH03 Start : this will show the user the Card Details, it is read only
@track cardDetails = [
  { label: "XXXX-XXXX", value: "cardNumber", disabled: true, checked : false },
  { label: "X-Card", value: "cardType", disabled: true,checked : false },
  ];
//CH03 End

  showModalBox(event) {
    if (this.showModal) {
      this.showModal = false;
    } else {
      this.showCardDetails = false;     //CH03
      this.error = "";
      this.remarks = "";
      this.confirmationMessage = "";

      fetchCreditMemoDetails({ creditMemoId: this.recordId })
        .then((result) => {
          console.log(JSON.stringify(result));
          this.creditMemoWrap = result;

          if (this.creditMemoWrap.isError) {
            const event = new ShowToastEvent({
              title: "Error",
              message: "Error : " + this.creditMemoWrap.isError,
              variant: "error",
              mode: "dismissable"
            });
            this.dispatchEvent(event);
          } else {
            this.showModal = true;

            //CH02
            if(  this.creditMemoWrap.isStripePayment ){
              
              this.refundOptions[0].checked = true;
              this.refundOptions[0].disabled = false;

              this.refundOptions[1].checked = false;
              this.refundOptions[1].disabled = true;

              //CH03 : Enabling Card detals
              this.cardDetails[0].label = this.creditMemoWrap.cardNumber;
              this.cardDetails[0].checked = true;
              this.cardDetails[0].disabled = false;

              this.cardDetails[1].label = this.creditMemoWrap.cardType;
              this.cardDetails[1].checked = true;
              this.cardDetails[1].disabled = false;
              this.showCardDetails = true;
              //CH03 END

            }else{

              this.refundOptions[0].checked = false;
              this.refundOptions[0].disabled = true;

              this.refundOptions[1].checked = true;
              this.refundOptions[1].disabled = false;
              this.showCardDetails = false;     //CH03
              
            }
            //CH02
          }
        })
        .catch((error) => {
          console.log(error);
          this.showModal = false;
          const event = new ShowToastEvent({
            title: "Error",
            message: "Error : " + error.body.message,
            variant: "error",
            mode: "dismissable"
          });
          this.dispatchEvent(event);
        });
    } //END OF show modal if
  }

  handleRemarkChange(event) {
    this.creditMemoWrap.userRemarks = event.target.value;
  }

  handleAmountChange(event) {
    this.creditMemoWrap.userEnterAMount = event.target.value;
  }

  showConfirmBoxfun(event) {
    let isErrorFound = false;
    let userAmnt = this.template.querySelector(".userAmount");
    let userRemarks = this.template.querySelector(".userRemarks");

    //if user entered not a number
    if ( !this.creditMemoWrap.userEnterAMount) {
      
      userAmnt.setCustomValidity("Please input valid amount.");
      userAmnt.reportValidity();
      isErrorFound = true;
    } else if( isNaN(this.creditMemoWrap.userEnterAMount)){
        userAmnt.setCustomValidity("Please input valid amount.");
        userAmnt.reportValidity();
        isErrorFound = true;
    }
    else if ( this.creditMemoWrap.userEnterAMount > this.creditMemoWrap.creditMemoAmnt) {

        userAmnt.setCustomValidity(
            "Entered amount cannot be greater than " + this.creditMemoWrap.creditMemoAmnt);
          userAmnt.reportValidity();
          isErrorFound = true;
    }
    else if (Number(this.creditMemoWrap.userEnterAMount) <= 0) {
      userAmnt.setCustomValidity(
        "Entered amount cannot be lesser or equal to 0 "
      );
      userAmnt.reportValidity();
      isErrorFound = true;
    } else {
      userAmnt.setCustomValidity("");
      userAmnt.reportValidity();
    }

    if ( !this.creditMemoWrap.userRemarks || !this.creditMemoWrap.userRemarks.trim()    ) {
      userRemarks.setCustomValidity("Enter a valid reason.");
      userRemarks.reportValidity();
      isErrorFound = true;
    } else {
      userRemarks.setCustomValidity("");
      userRemarks.reportValidity();
    }

   
    if (!isErrorFound) {
      this.showConfirmBox = !this.showConfirmBox;

      this.confirmationMessage =
        "This will refund " +
        this.creditMemoWrap.creditCurrcyCode +
        " " +
        this.creditMemoWrap.userEnterAMount +
        " amount. Do you want to continue?"; //CH02 changed message ->" amount via stripe. Do you want to continue?";
    }
  } //end of showConfirmBoxfun

  callRefundProcess(event) {
    this.isLoaded = true;
    console.log(JSON.stringify(this.creditMemoWrap));

    RefundCreditMemoRec({
        objCreditMemoJSON:  JSON.stringify(this.creditMemoWrap),
    })
      .then((result) => {
        this.isLoaded = false;

        console.log(result);
        
        if (result === "Success") {
            const event = new ShowToastEvent({
              title: "Success",
              message: this.creditMemoWrap.creditCurrcyCode + ' ' + this.creditMemoWrap.userEnterAMount +' refunded successfully.',//CH02 : Changed Message -> "successfully via Stripe."// Ch01 -> "Credit Memo Created",
              variant: "success",
              mode: "dismissable"
            });
            this.dispatchEvent(event);
          } else {
            const event = new ShowToastEvent({
              title: "Error",
              message: "UnExpected Error : " + result,
              variant: "error",
              mode: "dismissable"
            });
            this.dispatchEvent(event);
          }
          this.showModal = false;
          this.isLoaded = false;
          this.showConfirmBox = false;
      })
      .catch((error) => {
        console.log(error);
        const event = new ShowToastEvent({
          title: "Error",
          message: "Unexpected Error : " + error.body.message,
          variant: "error",
          mode: "dismissable"
        });
        this.dispatchEvent(event);
        this.showModal = false;
        this.isLoaded = false;
        this.showConfirmBox = false;
      });
  } //end of callRefundProcess
}
