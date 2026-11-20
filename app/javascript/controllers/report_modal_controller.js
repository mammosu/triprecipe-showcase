import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop"]

  connect() {
    this.restoreBodyOverflow = null
    this.lastActiveElement = null
  }

  open() {
    this.show()
    this.focusFirstElement()
  }

  close() {
    this.hide()
    this.restoreFocus()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.isOpen()) {
      this.close()
    }
  }

  show() {
    if (!this.hasBackdropTarget) return

    this.backdropTarget.classList.remove("hidden")
    this.backdropTarget.classList.add("flex")
    this.backdropTarget.setAttribute("aria-hidden", "false")
    this.disableBodyScroll()
  }

  hide() {
    if (!this.hasBackdropTarget) return

    this.backdropTarget.classList.add("hidden")
    this.backdropTarget.classList.remove("flex")
    this.backdropTarget.setAttribute("aria-hidden", "true")
    this.enableBodyScroll()
  }

  isOpen() {
    return this.hasBackdropTarget && !this.backdropTarget.classList.contains("hidden")
  }

  focusFirstElement() {
    this.lastActiveElement = document.activeElement
    const focusable = this.focusableElements()
    const target = focusable[0] || this.backdropTarget
    if (target) target.focus()
  }

  restoreFocus() {
    if (this.lastActiveElement && typeof this.lastActiveElement.focus === "function") {
      this.lastActiveElement.focus()
    }
    this.lastActiveElement = null
  }

  focusableElements() {
    if (!this.hasBackdropTarget) return []
    const selector = [
      "a[href]",
      "button:not([disabled])",
      "textarea:not([disabled])",
      "input:not([disabled])",
      "select:not([disabled])",
      "[tabindex]:not([tabindex='-1'])"
    ].join(",")
    return Array.from(this.backdropTarget.querySelectorAll(selector))
  }

  disableBodyScroll() {
    if (this.restoreBodyOverflow) return
    const body = document.body
    const previous = body.style.overflow
    body.style.overflow = "hidden"
    this.restoreBodyOverflow = () => {
      body.style.overflow = previous
    }
  }

  enableBodyScroll() {
    if (!this.restoreBodyOverflow) return
    this.restoreBodyOverflow()
    this.restoreBodyOverflow = null
  }
}
