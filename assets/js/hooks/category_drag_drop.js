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
      content.style.display = 'none';
    });
    
    toggleIcons.forEach(icon => {
      icon.classList.add('-rotate-90');
    });
  },
  
  expandAllCategories() {
    // Find all category content divs and toggle icons
    const categoryContents = this.el.querySelectorAll('[id^="category-content-"]');
    const toggleIcons = this.el.querySelectorAll('[id^="toggle-icon-"]');
    
    categoryContents.forEach(content => {
      content.style.display = '';
    });
    
    toggleIcons.forEach(icon => {
      icon.classList.remove('-rotate-90');
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