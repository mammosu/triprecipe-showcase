import { Controller } from "@hotwired/stimulus"

// Handles copying text (e.g., share URLs) to the clipboard and giving visual feedback
export default class extends Controller {
  static targets = [ "button", "preview" ]

  static values = {
    url: String,
    defaultLabel: { type: String, default: "リンクをコピー" },
    copiedLabel: { type: String, default: "コピーしました" }
  }

  connect() {
    this.resetButtonLabel()
  }

  copy() {
    const text = this.urlValue || this.previewTarget?.textContent?.trim()
    if (!text) return

    if (navigator.clipboard?.writeText) {
      navigator.clipboard
        .writeText(text)
        .then(() => this.showCopied())
        .catch(() => this.fallbackCopy(text))
    } else {
      this.fallbackCopy(text)
    }
  }

  fallbackCopy(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.setAttribute("readonly", "")
    textarea.style.position = "fixed"
    textarea.style.left = "-9999px"
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand("copy")
    document.body.removeChild(textarea)
    this.showCopied()
  }

  showCopied() {
    if (!this.hasButtonTarget) return

    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = this.copiedLabelValue

    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.buttonTarget.disabled = false
      this.resetButtonLabel()
    }, 2000)
  }

  resetButtonLabel() {
    if (!this.hasButtonTarget) return

    this.buttonTarget.textContent = this.defaultLabelValue
  }
}
