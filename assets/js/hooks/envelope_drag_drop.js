// Envelope-specific drag and drop hook that extends the generic DragDrop hook
// Adds cross-category dragging support for envelopes

import DragDrop from "./drag_drop.js";

export default {
  mounted() {
    // Initialize the base DragDrop functionality
    DragDrop.mounted.call(this);

    // Store reference to original sortable onEnd
    const originalOnEnd = this.sortable.options.onEnd;

    // Override onEnd to handle cross-category envelope moves
    this.sortable.option("onEnd", (evt) => {
      // Remove dragging class
      evt.item.classList.remove("dragging");
      
      // Check if position changed or category changed
      if (evt.oldIndex !== evt.newIndex || evt.from !== evt.to) {
        const envelopeId = evt.item.dataset.envelopeId;
        const targetCategoryId = evt.to.dataset.categoryId;
        
        // Get neighboring envelopes in the target position
        const envelopes = Array.from(evt.to.children);
        const prevId = evt.newIndex > 0 ? 
          envelopes[evt.newIndex - 1].dataset.envelopeId : null;
        const nextId = evt.newIndex < envelopes.length - 1 ? 
          envelopes[evt.newIndex + 1].dataset.envelopeId : null;
        
        // Disable sorting during save
        this.sortable.option("disabled", true);
        
        // Show saving indicator
        evt.item.classList.add("opacity-50");
        evt.item.classList.add("pointer-events-none");
        
        // Store references for potential reversion
        this.lastMovedItem = evt.item;
        this.lastFromContainer = evt.from;
        this.lastToContainer = evt.to;
        this.lastOriginalIndex = evt.oldIndex;
        
        this.pushEvent("reposition_envelope", {
          envelope_id: envelopeId,
          target_category_id: targetCategoryId,
          prev_envelope_id: prevId,
          next_envelope_id: nextId
        }, (reply) => {
          // Re-enable sorting
          this.sortable.option("disabled", false);
          evt.item.classList.remove("opacity-50");
          evt.item.classList.remove("pointer-events-none");
          
          if (reply && reply.error) {
            // Revert position on error
            this.revertCrossCategoryPosition();
          }
        });
      } else {
        // Call original onEnd behavior if no position change
        if (originalOnEnd) {
          originalOnEnd(evt);
        }
      }
    });
    
    // Configure for cross-category dragging
    this.sortable.option("group", {
      name: "envelopes",
      pull: true,
      put: true
    });
  },
  
  // Enhanced revert function for cross-category moves
  revertCrossCategoryPosition() {
    if (this.lastMovedItem && this.lastFromContainer && this.lastToContainer) {
      // If moved to different category, move back to original
      if (this.lastFromContainer !== this.lastToContainer) {
        const originalChildren = Array.from(this.lastFromContainer.children);
        
        if (this.lastOriginalIndex >= originalChildren.length) {
          this.lastFromContainer.appendChild(this.lastMovedItem);
        } else {
          const referenceNode = originalChildren[this.lastOriginalIndex];
          this.lastFromContainer.insertBefore(this.lastMovedItem, referenceNode);
        }
      } else {
        // Same category - use base revert logic
        this.revertPosition();
      }
      
      // Clean up references
      this.lastMovedItem = null;
      this.lastFromContainer = null;
      this.lastToContainer = null;
      this.lastOriginalIndex = null;
    }
  },

  // Inherit other methods from DragDrop
  revertPosition() {
    return DragDrop.revertPosition.call(this);
  },

  destroyed() {
    return DragDrop.destroyed.call(this);
  }
};
