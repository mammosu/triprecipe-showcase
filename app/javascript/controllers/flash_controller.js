import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static classes = [ "active" ]

  connect() {
    this.element.classList.add(...this.activeClasses)

    // Remove the class after a short delay to create a flash effect
    setTimeout(() => {
      this.element.classList.remove(...this.activeClasses)
    }, 2000)
  }
}
