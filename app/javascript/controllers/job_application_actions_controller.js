import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["forward", "mayBe", "reject"]

  hideAll() {
    this.forwardTarget.hidden = true
    this.mayBeTarget.hidden = true
    this.rejectTarget.hidden = true
  }

  showForward() {
    this.hideAll()
    this.forwardTarget.hidden = false
  }

  showMaybe() {
    this.hideAll()
    this.mayBeTarget.hidden = false
  }

  showReject() {
    this.hideAll()
    this.rejectTarget.hidden = false
  }
}