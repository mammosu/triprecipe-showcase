import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "labelOpen", "labelClose", "iconOpen", "iconClose"]

  toggle(event) {
    event.preventDefault()
    this.menuTarget.classList.toggle("hidden")
    this.labelOpenTarget.classList.toggle("hidden")
    this.labelCloseTarget.classList.toggle("hidden")
    this.iconOpenTarget.classList.toggle("hidden")
    this.iconCloseTarget.classList.toggle("hidden")

    const expanded = !this.menuTarget.classList.contains("hidden")
    event.currentTarget.setAttribute("aria-expanded", String(expanded))
  }
}
