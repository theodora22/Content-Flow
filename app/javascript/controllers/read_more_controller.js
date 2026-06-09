import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "button", "gradient", "item"]

  connect() {
    this.handleResize = this.checkOverflow.bind(this)
    // Run after a short delay to ensure fonts and layout are fully rendered
    setTimeout(() => this.checkOverflow(), 100)
    window.addEventListener('resize', this.handleResize)
  }

  disconnect() {
    window.removeEventListener('resize', this.handleResize)
  }

  checkOverflow() {
    if (this.isExpanded) return;

    // Check if content actually exceeds the collapsed height
    // We compare scrollHeight to clientHeight to reliably detect overflow.
    if (this.contentTarget.scrollHeight <= this.contentTarget.clientHeight + 1) {
      // Temporarily disabled hiding logic to debug visibility
      // this.buttonTarget.classList.add('hidden')
      // if (this.hasGradientTarget) {
      //   this.gradientTarget.classList.add('hidden')
      // }
    } else {
      this.buttonTarget.classList.remove('hidden')
      if (this.hasGradientTarget) {
        this.gradientTarget.classList.remove('hidden')
      }
    }
  }

  toggle() {
    if (this.isExpanded) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  expand() {
    this.isExpanded = true;
    
    // Store the flex-constrained height so we can smoothly animate back to it later
    this.collapsedHeight = this.contentTarget.clientHeight;
    
    // Set current explicit height to start the CSS transition
    this.contentTarget.style.maxHeight = `${this.collapsedHeight}px`;
    void this.contentTarget.offsetHeight; // force reflow
    
    // Prepare items for stagger animation
    // Only animate items that are mostly hidden by the collapsed height
    const hiddenItems = this.hasItemTarget ? this.itemTargets.filter(item => {
      // offsetTop is relative to the offsetParent (which is likely the contentTarget or relative wrapper)
      return item.offsetTop >= this.collapsedHeight - 60; 
    }) : [];

    hiddenItems.forEach(item => {
      item.style.transition = "none"
      item.style.transform = `translateY(-30px)`
      item.style.opacity = "0"
    })
    
    // Animate to full height
    const fullHeight = this.contentTarget.scrollHeight;
    this.contentTarget.style.maxHeight = `${fullHeight}px`;
    
    // Update button to "see less" and arrow up with smooth rotation
    const span = this.buttonTarget.querySelector('span')
    const img = this.buttonTarget.querySelector('img')
    if (span) span.innerText = "see less"
    if (img) {
      img.style.transition = "transform 0.7s ease-in-out"
      img.style.transform = "rotate(-90deg)"
    }
    
    if (this.hasGradientTarget) {
      this.gradientTarget.classList.add("opacity-0")
    }
    
    // Trigger the item stagger animations
    requestAnimationFrame(() => {
      hiddenItems.forEach((item, index) => {
        setTimeout(() => {
          item.style.transition = "transform 1.4s cubic-bezier(0.22, 0, 0.6, 1), opacity 0.8s ease"
          item.style.transform = "translateY(0)"
          item.style.opacity = "1"
        }, index * 150)
      })
    })
    
    // Clean up after animation finishes (700ms)
    setTimeout(() => {
      this.contentTarget.style.maxHeight = "none"
      
      // Remove the fixed height on the parent to allow page scrolling
      const pageContainer = this.element.closest('[style*="height: calc(100vh - 64px)"]') || this.element.closest('[data-controller$="-edit"]')
      if (pageContainer) {
        pageContainer.style.height = "auto"
        pageContainer.style.minHeight = "calc(100vh - 64px)"
      }
      
      let current = this.element.parentElement
      while (current && current !== document.body) {
        if (current.classList.contains('overflow-hidden') && current.classList.contains('flex-1')) {
          current.classList.remove('overflow-hidden')
          current.dataset.wasOverflowHidden = "true"
        }
        current = current.parentElement
      }
      this.element.classList.remove('overflow-hidden')
      this.element.dataset.wasOverflowHidden = "true"
    }, 700)
  }

  collapse() {
    this.isExpanded = false;
    
    // Find items that will be hidden
    const hiddenItems = this.hasItemTarget ? this.itemTargets.filter(item => {
      return item.offsetTop >= (this.collapsedHeight || 256) - 60; 
    }) : [];

    // Animate them falling away as it collapses
    hiddenItems.forEach((item) => {
      item.style.transition = "transform 0.5s cubic-bezier(0.22, 0, 0.6, 1), opacity 0.3s ease"
      item.style.transform = `translateY(30px)`
      item.style.opacity = "0"
    })
    
    // Re-apply max height from full height
    const fullHeight = this.contentTarget.scrollHeight;
    this.contentTarget.style.maxHeight = `${fullHeight}px`;
    void this.contentTarget.offsetHeight; // force reflow
    
    // Target height is whatever we saved earlier when it was constrained by flex
    const targetHeight = this.collapsedHeight || 256; 
    this.contentTarget.style.maxHeight = `${targetHeight}px`;
    
    // Update button to "see more" and arrow down with smooth rotation
    const span = this.buttonTarget.querySelector('span')
    const img = this.buttonTarget.querySelector('img')
    if (span) span.innerText = "see more"
    if (img) img.style.transform = "rotate(90deg)"
    
    if (this.hasGradientTarget) {
      this.gradientTarget.classList.remove("opacity-0")
    }

    // Scroll back to top of container smoothly immediately so they follow the animation
    this.element.scrollIntoView({ behavior: "smooth", block: "start" })
    
    // After animation finishes, restore all the flex constraints
    setTimeout(() => {
      // Reset item styles so they are ready for the next expand
      hiddenItems.forEach(item => {
        item.style.transition = ""
        item.style.transform = ""
        item.style.opacity = ""
      })
      
      const pageContainer = this.element.closest('[style*="height: auto"]') || this.element.closest('[data-controller$="-edit"]')
      if (pageContainer) {
        pageContainer.style.height = "calc(100vh - 64px)"
        pageContainer.style.minHeight = ""
      }
      
      let current = this.element.parentElement
      while (current && current !== document.body) {
        if (current.dataset.wasOverflowHidden === "true") {
          current.classList.add('overflow-hidden')
          delete current.dataset.wasOverflowHidden
        }
        current = current.parentElement
      }
      if (this.element.dataset.wasOverflowHidden === "true") {
        this.element.classList.add('overflow-hidden')
        delete this.element.dataset.wasOverflowHidden
      }

      this.contentTarget.style.maxHeight = null;
    }, 700)
  }
}
