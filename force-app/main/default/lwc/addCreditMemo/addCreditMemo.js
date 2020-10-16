import { LightningElement, api, track } from "lwc";
import fetchCreditMemoDetails from "@salesforce/apex/AddCreditMemoController.getCreditMemoDetails";
import createCreditMemoRec from "@salesforce/apex/AddCreditMemoController.createCreditMemo";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

//CH01 9&12 Oct 2020 Karan Singh : Incase of Refund, message should be -> ex "$20 refunded successfully via Stripe."
//CH02 12 Oct 2020 : removing the creteria as if already credit memo existed , then it should not create another Credit memo.
//                    Instead check the invoice's Line Item Amount >  Invoice CM_Created__c amount, then it will allow to create the Credit Memo
//CH03 15 OCt 2020 : Refund a Credit Memo (other than stripe) : Incase the user had made payment without stripe as cash,cheque etc then in that case
//                   it will not hit the stripe api and there are changes in the api instead.
//                    Also changes in the refund toast message in Js.
//CH04 16 Oct 2020 : Add Card Number and Card tyoe in the UI In case of Refund method is Card on file

export default class AddCreditMemo extends LightningElement {
  @api recordId;
  @track creditMemoWrap;
  value = "";
  showModal = false;
  remarks = "";
  confirmationMessage = "";
  showConfirmBox = false;
  isLoaded = false;
  isRefundMemoSelected = false; //CH03 : if the refund memo selected then show the payment option.
  showCardDetails = false; //CH04 : show the card details in card of Card-on-file only
  
  // prettier-ignore
  @track options = [
{ label: "Refund Memo", value: "Refund Memo", disabled: true, checked : false },
{ label: "Credit Memo (Future Adj)", value: "Credit Memo (Future Adj)", disabled: true,checked : false },
{ label: "Credit Memo (Invoice Cancellation)", value: "Credit Memo (Invoice Cancellation)", disabled: true,checked : false }
];
//CH03 Start : this will show the user the refund payment mode, it is read only
@track refundOptions = [
  { label: "Card-on-file", value: "Cardonfile", disabled: true, checked : false },
  { label: "Bank Cheque", value: "Bank Cheque", disabled: true,checked : false },
  ];
//CH03 End

//CH04 Start : this will show the user the Card Details, it is read only
@track cardDetails = [
  { label: "XXXX-XXXX", value: "cardNumber", disabled: true, checked : false },
  { label: "X-Card", value: "cardType", disabled: true,checked : false },
  ];
//CH04 End

  showModalBox(event) {
    if (this.showModal) {
      this.showModal = false;
    } else {
      this.isRefundMemoSelected = false; //CH03
      this.showCardDetails = false;     //CH04

      this.error = "";
      this.remarks = "";
      this.confirmationMessage = "";
      fetchCreditMemoDetails({ invId: this.recordId })
        .then((result) => {
          console.log(JSON.stringify(result));
          this.creditMemoWrap = result;

          if (this.creditMemoWrap.existCreditMemo) {
            const event = new ShowToastEvent({
              title: "Error",
              message:
                "Already Created Credit Memo for this Invoice : " +
                this.creditMemoWrap.existCreditMemo,
              variant: "error",
              mode: "dismissable"
            });
            this.dispatchEvent(event);
          } else if( this.creditMemoWrap.invoiceAmount == 0){

            const event = new ShowToastEvent({
              title: "Error",
              message:
                "Invoice does not have sufficient amount for adding credit memo",
              variant: "error",
              mode: "dismissable"
            });
            this.dispatchEvent(event);

          }else {
            this.showModal = true;
            this.options.forEach((opt) => {
              if (
                opt.value === "Credit Memo (Future Adj)" &&
                this.creditMemoWrap.invoiceStatus === "Paid"
              ) {
                opt.checked = true;
                opt.disabled = false;
                this.value = opt.value;
              } else if (
                opt.value === "Refund Memo" &&
                this.creditMemoWrap.invoiceStatus === "Paid"
              ) {
                opt.checked = false;
                opt.disabled = false;
              } else if (
                opt.value === "Credit Memo (Invoice Cancellation)" &&
                this.creditMemoWrap.invoiceStatus === "Due"
              ) {
                opt.checked = true;
                opt.disabled = false;
                this.value = opt.value;
              }
            });

            //CH03
            if(  this.creditMemoWrap.isStripePayment ){
              
              this.refundOptions[0].checked = true;
              this.refundOptions[0].disabled = false;

              this.refundOptions[1].checked = false;
              this.refundOptions[1].disabled = true;

              //CH04 : Enabling Card detals
              this.cardDetails[0].label = this.creditMemoWrap.cardNumber;
              this.cardDetails[0].checked = true;
              this.cardDetails[0].disabled = false;

              this.cardDetails[1].label = this.creditMemoWrap.cardType;
              this.cardDetails[1].checked = true;
              this.cardDetails[1].disabled = false;
              //CH04 END

            }else{

              this.refundOptions[0].checked = false;
              this.refundOptions[0].disabled = true;

              this.refundOptions[1].checked = true;
              this.refundOptions[1].disabled = false;
              this.showCardDetails = false;     //CH04
              
            }
            //CH03
          }
        })
        .catch((error) => {
          console.log(error);
          this.showModal = false;
          this.error = error;
        });
    }
  }

  showConfirmModalBox(event) {
    /*instead of output , it will be read only field
  if (isNaN(this.userEnteredAmount)) {
    let userAmnt = this.template.querySelector(".userAmount");
    userAmnt.setCustomValidity("Please input valid amount.");
    userAmnt.reportValidity();
    return;
  } */
    if (!this.remarks || !this.remarks.trim()) {
      let userRemarks = this.template.querySelector(".userRemarks");
      userRemarks.setCustomValidity("Enter a valid reason.");
      userRemarks.reportValidity();

      return;
    }
    /*instead of output , it will be read only field
  if (Number(this.userEnteredAmount) > this.creditMemoWrap.invoiceAmount) {
    return;
  } else if (Number(this.userEnteredAmount) < 0) {
    return;
  }*/

    if (this.showConfirmBox) {
      this.showConfirmBox = false;
    } else {
      this.showConfirmBox = true;
    }

    if (this.value === "Refund Memo") {
      
      this.confirmationMessage ="This will create a Credit memo ( " +this.value +" ) and also refund "+ this.creditMemoWrap.invoiceCurrcyCode+" "+this.creditMemoWrap.invoiceAmount +
    " amount. Do you want to continue?";
    //" amount via stripe. Do you want to continue?"; Chnegd the above messae : CH03

    } else {
      
      this.confirmationMessage =
      "This will create a " + this.value + " of amount "+ this.creditMemoWrap.invoiceCurrcyCode+" "+ this.creditMemoWrap.invoiceAmount +". Do you want to continue?";
    }
  }

  createCreditMemo(event) {
    this.isLoaded = true;
    console.log(JSON.stringify(this.creditMemoWrap));
    createCreditMemoRec({
      creditWrapJson: JSON.stringify(this.creditMemoWrap),
      creditMode: this.value,
      remarks: this.remarks
    })
      .then((result) => {
        this.isLoaded = false;

        if (result === "success") {

          //CH01 Start -  added this creteria
          if( this.value == "Refund Memo" ){

            const event = new ShowToastEvent({
              title: "Success",
              message: this.creditMemoWrap.invoiceCurrcyCode + ' ' + this.creditMemoWrap.invoiceAmount +' refunded successfully.', //CH03 : Removed this " via Stripe." 
              variant: "success",
              mode: "dismissable"
            });
            this.dispatchEvent(event);

          }//CH01 end
          else{

            const event = new ShowToastEvent({
              title: "Success",
              message: "Credit Memo Created",
              variant: "success",
              mode: "dismissable"
            });
            this.dispatchEvent(event);

          }
          
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
          message: "UnExpected Error : " + error.body.message,
          variant: "error",
          mode: "dismissable"
        });
        this.dispatchEvent(event);
        this.showModal = false;
        this.isLoaded = false;
        this.showConfirmBox = false;
      });
  }
  /*
  handleAmountChange(event) {
    try {
      this.userEnteredAmount = Number(event.target.value);
    } catch (err) {
      console.log(err.message);
      this.error = err.message;
    }
  }*/
  handleRemarkChange(event) {
    this.remarks = event.target.value;
  }
  handleChange(event) {
    this.value = event.target.dataset.value;
    this.options.forEach((opt) => {
      if (opt.value === this.value) {
        opt.checked = true;
      } else {
        opt.checked = false;
      }
      //CH03 Start : only show refund optionin case of refund memo only
      if( this.value == "Refund Memo"){
        this.isRefundMemoSelected = true;

        //CH04 Start
        if( this.refundOptions[0].checked )
        this.showCardDetails = true;      //CH04
        //CH04 END
      }else{
        this.isRefundMemoSelected = false;
        this.showCardDetails = false;     //CH04
      }
      //CH03 END
    });
    
  }
}