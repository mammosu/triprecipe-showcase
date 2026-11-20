import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scroll_to_top"
export default class extends Controller {
  scroll() {
    window.scrollTo({ top: 0, behavior: "smooth" })
  }
}
