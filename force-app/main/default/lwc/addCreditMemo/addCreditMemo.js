import { LightningElement, api } from "lwc";

export default class AddCreditMemo extends LightningElement {
  @api recordId;
  value = "";
  showModal = false;

  showModalBox(event) {
    if (this.showModal) {
      this.showModal = false;
    } else {
      this.showModal = true;
    }
  }
  get options() {
    return [
      { label: "Refund Memo", value: "RM" },
      { label: "Credit Memo (Future Adj)", value: "CM_FD" },
      {
        label: "Credit Memo (Invoice Cancellation)",
        value: "CM_IC",
        disabled: true
      }
    ];
  }
}
