import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "results"]
  static values = {
    url: String,
    selectedId: Number
  }

  connect() {
    if (this.hasHiddenTarget && this.selectedIdValue && !this.hiddenTarget.value) {
      this.hiddenTarget.value = this.selectedIdValue
    }
    this.hideResults()
  }

  search() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()
    if (this.hasHiddenTarget) {
      this.hiddenTarget.value = ""
    }
    if (query.length === 0) {
      this.hideResults()
      return
    }

    this.timeout = setTimeout(() => this.fetchResults(query), 150)
  }

  fetchResults(query) {
    if (!this.urlValue) return
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("query", query)

    fetch(url, { headers: { Accept: "application/json" } })
      .then(response => response.ok ? response.json() : [])
      .then(json => this.renderResults(json))
      .catch(() => this.hideResults())
  }

  renderResults(cities) {
    if (!this.hasResultsTarget) return
    if (!cities.length) {
      this.resultsTarget.innerHTML = '<div class="px-3 py-2 text-sm text-gray-500">該当する都市がありません</div>'
      this.showResults()
      return
    }

    this.resultsTarget.innerHTML = cities.map(city => (
      `<button type="button" class="flex w-full items-center justify-between px-3 py-2 text-left text-sm hover:bg-gray-50"
               data-action="click->city-autocomplete#select"
               data-city-autocomplete-id-param="${city.id}"
               data-city-autocomplete-name-param="${this.escapeHtml(city.display_name)}">
         <span>${this.escapeHtml(city.display_name)}</span>
         <span class="text-xs text-gray-500">${this.escapeHtml(city.country_code || "")}</span>
       </button>`
    )).join("")
    this.showResults()
  }

  select(event) {
    const { id, name } = event.params
    if (this.hasHiddenTarget) {
      this.hiddenTarget.value = id
    }
    this.inputTarget.value = name
    this.hideResults()
  }

  clearSelection() {
    if (this.hasHiddenTarget) {
      this.hiddenTarget.value = ""
    }
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
    }
    this.hideResults()
  }

  scheduleHide() {
    clearTimeout(this.hideTimeout)
    this.hideTimeout = setTimeout(() => this.hideResults(), 150)
  }

  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add("hidden")
    }
  }

  showResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove("hidden")
    }
  }

  escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll("\"", "&quot;")
      .replaceAll("'", "&#39;")
  }

}
