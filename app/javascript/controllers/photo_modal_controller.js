import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "image", "closeButton", "prevButton", "nextButton", "counter"]

  connect() {
    this.urls = []
    this.currentIndex = 0
  }

  open(event) {
    const { photoUrl, photoAlt, photoModalUrlsValue, photoModalIndexValue } = event.currentTarget.dataset

    if (!photoUrl) return

    this.urls = this.parseUrls(photoModalUrlsValue, photoUrl)
    this.currentIndex = this.parseIndex(photoModalIndexValue)

    this.updateImage(photoAlt)
    this.updateControls()

    this.modalTarget.classList.remove("hidden")
    this.modalTarget.setAttribute("aria-hidden", "false")
    document.body.classList.add("overflow-hidden")

    if (this.hasCloseButtonTarget) {
      this.closeButtonTarget.focus()
    }
  }

  close() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
      this.modalTarget.setAttribute("aria-hidden", "true")
    }

    if (this.hasImageTarget) {
      this.imageTarget.removeAttribute("src")
      this.imageTarget.alt = ""
    }

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = ""
    }

    document.body.classList.remove("overflow-hidden")

    this.urls = []
    this.currentIndex = 0
  }

  handleKeydown(event) {
    if (!this.isOpen()) return

    if (event.key === "Escape") {
      this.close()
      return
    }

    if (event.key === "ArrowLeft") {
      this.prev()
      return
    }

    if (event.key === "ArrowRight") {
      this.next()
    }
  }

  prev() {
    if (this.currentIndex <= 0) return

    this.currentIndex -= 1
    this.updateImage()
    this.updateControls()
  }

  next() {
    if (this.currentIndex >= this.urls.length - 1) return

    this.currentIndex += 1
    this.updateImage()
    this.updateControls()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  updateImage(photoAlt) {
    if (!this.urls.length) return

    this.imageTarget.src = this.urls[this.currentIndex]
    if (photoAlt !== undefined) {
      this.imageTarget.alt = photoAlt || ""
    }
  }

  updateControls() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.currentIndex + 1} / ${this.urls.length}`
    }

    this.setButtonState(this.prevButtonTarget, this.currentIndex <= 0)
    this.setButtonState(this.nextButtonTarget, this.currentIndex >= this.urls.length - 1)
  }

  setButtonState(button, disabled) {
    if (!button) return

    button.disabled = disabled
    button.classList.toggle("opacity-40", disabled)
    button.classList.toggle("pointer-events-none", disabled)
  }

  parseUrls(serializedUrls, fallbackUrl) {
    if (serializedUrls) {
      try {
        const parsed = JSON.parse(serializedUrls)
        if (Array.isArray(parsed) && parsed.length > 0) {
          return parsed
        }
      } catch (_) {
        // Fall back to single URL
      }
    }

    return fallbackUrl ? [fallbackUrl] : []
  }

  parseIndex(serializedIndex) {
    if (!this.urls.length) return 0

    const parsed = Number.parseInt(serializedIndex, 10)
    if (Number.isNaN(parsed)) return 0

    return Math.min(Math.max(parsed, 0), this.urls.length - 1)
  }

  isOpen() {
    return this.hasModalTarget && !this.modalTarget.classList.contains("hidden")
  }
}
