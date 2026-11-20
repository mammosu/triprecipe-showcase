import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const name = this.initialTabName()
    if (name) {
      this.activate(name)
    }
  }

  show(event) {
    const name = event.currentTarget.dataset.tabsName
    this.activate(name)
    this.persistTabParam(name)
    this.persistTabSelection(name)
  }

  activate(name) {
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.tabsName === name
      tab.classList.toggle("tr-primary-bg", active)
      tab.classList.toggle("text-white", active)
      tab.classList.toggle("tr-border-strong", active)
    })
    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.tabsName !== name
    })
  }

  initialTabName() {
    const url = new URL(window.location.href)
    const param = url.searchParams.get("tab")
    if (param && this.tabTargets.some((tab) => tab.dataset.tabsName === param)) {
      return param
    }
    const stored = this.loadStoredTabSelection()
    if (stored && this.tabTargets.some((tab) => tab.dataset.tabsName === stored)) {
      return stored
    }
    return this.tabTargets[0]?.dataset.tabsName
  }

  persistTabParam(name) {
    const url = new URL(window.location.href)
    url.searchParams.set("tab", name)
    window.history.replaceState({}, "", url)
  }

  persistTabSelection(name) {
    sessionStorage.setItem(this.storageKey(), name)
  }

  loadStoredTabSelection() {
    return sessionStorage.getItem(this.storageKey())
  }

  storageKey() {
    const key = this.element.dataset.tabsKey || window.location.pathname
    return `tabs:${key}`
  }
}
