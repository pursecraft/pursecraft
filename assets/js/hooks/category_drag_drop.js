// Category-specific drag and drop hook that extends the generic DragDrop hook
// Adds automatic category collapse/expand during drag operations

import DragDrop from "./drag_drop.js";

export default {
  mounted() {
    // Initialize the base DragDrop functionality
    DragDrop.mounted.call(this);

    // Store reference to original sortable onStart and onEnd
    const originalOnStart = this.sortable.options.onStart;
    const originalOnEnd = this.sortable.options.onEnd;

    // Override onStart to add category collapse
    this.sortable.option("onStart", (evt) => {
      // Call original onStart behavior
      if (originalOnStart) {
        originalOnStart(evt);
      }

      // Collapse all categories when drag starts (client-side only)
      this.collapseAllCategories();
    });

    // Override onEnd to add category expand
    this.sortable.option("onEnd", (evt) => {
      // Call original onEnd behavior first
      if (originalOnEnd) {
        originalOnEnd(evt);
      }

      // Expand all categories when drag ends (client-side only)
      this.expandAllCategories();
    });
  },

  collapseAllCategories() {
    // Find all category content divs and toggle icons
    const categoryContents = this.el.querySelectorAll('[id^="category-content-"]');
    const toggleIcons = this.el.querySelectorAll('[id^="toggle-icon-"]');

    categoryContents.forEach(content => {
      // Store original height for restoration
      const originalHeight = content.scrollHeight;
      content.setAttribute('data-original-height', originalHeight);

      // Set up transition and collapse
      content.style.transition = 'max-height 200ms ease-in-out, opacity 200ms ease-in-out';
      content.style.overflow = 'hidden';
      content.style.maxHeight = originalHeight + 'px';

      // Force reflow then collapse
      content.offsetHeight;
      content.style.maxHeight = '0px';
      content.style.opacity = '0';
    });

    toggleIcons.forEach(icon => {
      // Add transition for icon rotation
      icon.style.transition = 'transform 200ms ease-in-out';
      icon.classList.add('-rotate-90');
    });
  },
  
  expandAllCategories() {
    // Find all category content divs and toggle icons
    const categoryContents = this.el.querySelectorAll('[id^="category-content-"]');
    const toggleIcons = this.el.querySelectorAll('[id^="toggle-icon-"]');

    categoryContents.forEach(content => {
      // Restore original height
      const originalHeight = content.getAttribute('data-original-height') || 'auto';
      content.style.maxHeight = originalHeight + 'px';
      content.style.opacity = '1';

      // Clean up after animation completes
      setTimeout(() => {
        content.style.transition = '';
        content.style.overflow = '';
        content.style.maxHeight = '';
        content.style.opacity = '';
        content.removeAttribute('data-original-height');
      }, 200);
    });

    toggleIcons.forEach(icon => {
      icon.classList.remove('-rotate-90');
      // Clean up icon transition
      setTimeout(() => {
        icon.style.transition = '';
      }, 200);
    });
  },

  // Inherit other methods from DragDrop
  revertPosition() {
    return DragDrop.revertPosition.call(this);
  },

  destroyed() {
    return DragDrop.destroyed.call(this);
  }
};
