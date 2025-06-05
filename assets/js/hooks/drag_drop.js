// Generic drag and drop hook using SortableJS
// Based on https://fly.io/phoenix-files/liveview-drag-and-drop/
// Can be used with any schema that needs repositioning

import Sortable from "../../vendor/sortable.js";

export default {
  mounted() {
    // Get configuration from data attributes
    const itemIdAttribute = this.el.dataset.itemIdAttribute || "itemId";
    const repositionEvent = this.el.dataset.repositionEvent || "reposition_item";
    const deletionEvent = this.el.dataset.deletionEvent || "item_deleted";
    const idField = this.el.dataset.idField || "item_id";
    const prevIdField = this.el.dataset.prevIdField || "prev_item_id";
    const nextIdField = this.el.dataset.nextIdField || "next_item_id";
    
    this.sortable = new Sortable(this.el, {
      animation: 150,
      delay: 100,
      dragClass: "opacity-50",
      ghostClass: "bg-base-200",
      handle: ".drag-handle",
      disabled: false,
      forceFallback: true,
      
      onStart: (evt) => {
        // Store original index in case we need to revert
        this.originalIndex = evt.oldIndex;
        this.draggedItem = evt.item;
        // Add dragging class for additional styling if needed
        evt.item.classList.add("dragging");
      },
      
      onEnd: (evt) => {
        // Remove dragging class
        evt.item.classList.remove("dragging");
        
        if (evt.oldIndex !== evt.newIndex) {
          const itemId = evt.item.dataset[itemIdAttribute];
          const items = Array.from(evt.to.children);
          
          // Get adjacent item IDs
          const prevId = evt.newIndex > 0 ? 
            items[evt.newIndex - 1].dataset[itemIdAttribute] : null;
          const nextId = evt.newIndex < items.length - 1 ? 
            items[evt.newIndex + 1].dataset[itemIdAttribute] : null;
          
          // Disable sorting during save
          this.sortable.option("disabled", true);
          
          // Show saving indicator
          evt.item.classList.add("opacity-50");
          evt.item.classList.add("pointer-events-none");
          
          // Build event payload dynamically
          const payload = {
            [idField]: itemId,
            [prevIdField]: prevId,
            [nextIdField]: nextId
          };
          
          // Push event to LiveView
          this.pushEventTo(this.el, repositionEvent, payload, (reply) => {
            // Re-enable sorting
            this.sortable.option("disabled", false);
            evt.item.classList.remove("opacity-50");
            evt.item.classList.remove("pointer-events-none");
            
            if (reply && reply.error) {
              // Revert position on error
              this.revertPosition();
            }
          });
        }
      }
    });
    
    // Handle WebSocket disconnection events
    this.handleEvent("websocket_disconnected", () => {
      // Disable drag and drop during disconnection
      this.sortable.option("disabled", true);
      // Add visual indicator
      this.el.classList.add("opacity-75");
    });
    
    this.handleEvent("websocket_reconnected", () => {
      // Re-enable drag and drop
      this.sortable.option("disabled", false);
      // Remove visual indicator
      this.el.classList.remove("opacity-75");
    });
    
    // Handle item deletion during drag
    this.handleEvent(deletionEvent, (payload) => {
      const deletedId = payload[idField];
      if (this.draggedItem && this.draggedItem.dataset[itemIdAttribute] === deletedId) {
        // Force cancel the current drag operation
        this.sortable.option("disabled", true);
        this.sortable.option("disabled", false);
        // Clean up references
        this.draggedItem = null;
        this.originalIndex = null;
      }
    });
  },
  
  revertPosition() {
    if (this.draggedItem && this.originalIndex !== undefined) {
      // Move item back to original position
      const parent = this.el;
      const children = Array.from(parent.children);
      const currentIndex = children.indexOf(this.draggedItem);
      
      if (currentIndex !== this.originalIndex) {
        if (this.originalIndex >= children.length) {
          parent.appendChild(this.draggedItem);
        } else {
          const referenceNode = children[this.originalIndex];
          if (currentIndex < this.originalIndex) {
            // Moving down - insert after reference
            parent.insertBefore(this.draggedItem, referenceNode.nextSibling);
          } else {
            // Moving up - insert before reference
            parent.insertBefore(this.draggedItem, referenceNode);
          }
        }
      }
    }
  },
  
  destroyed() {
    if (this.sortable) {
      this.sortable.destroy();
    }
  }
};
