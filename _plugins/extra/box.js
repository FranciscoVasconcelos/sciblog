class HashNavigation {
    constructor() {
        this.currentHash = '';
        this.init();
    }
    
    init() {
        // Handle initial hash on page load
        this.handleHash(window.location.hash);
        
        // Listen for hash changes
        window.addEventListener('hashchange', () => this.handleHash(window.location.hash));
        
        // Listen for history navigation (back/forward)
        window.addEventListener('popstate', () => this.handleHash(window.location.hash));
        
        // Optional: intercept link clicks for custom behavior
        document.addEventListener('click', (e) => this.handleLinkClick(e));
    }
    

    handleLinkClick(event) {
        const link = event.target.closest('a');
        
      
        if (!link || !link.hash) return;
        
        const isSamePage = link.hostname === window.location.hostname &&
                           link.pathname === window.location.pathname;
          
        if (isSamePage) {
            event.preventDefault(); // Always prevent default
            event.stopPropagation(); // Prevent event from bubbling up
            this.handleHash(link.hash, true); // true = from click
            handleSideNotes(event.target);
        }
    }

        
    handleHash(hash, fromClick = false) {
        if (!hash) return;
        console.log("handling hash!");
        
        // Always process, even if same hash (when from click)
        if (fromClick || hash === window.location.hash) {
            if (fromClick) {
                // Update URL without adding to history
                window.history.replaceState(null, '', hash);
            }
            
            const targetElement = this.getElementFromHash(hash);
            if (targetElement) {
                this.navigateToElement(targetElement);
                // Reset animation
                targetElement.style.animation = 'none';
                setTimeout(() => {targetElement.style.animation = 'flash 2.5s';}, 10);
            }
        }
    }    

    getElementFromHash(hash) {
        try {
            const id = decodeURIComponent(hash.substring(1));
            return document.getElementById(id);
        } catch (error) {
            console.warn('Error finding element for hash:', hash, error);
            return null;
        }
    }
    
    navigateToElement(targetElement) {
        // First expand all necessary parent containers
        this.expandAllParentContainers(targetElement);
        // Then scroll to the element
        setTimeout(() => {
            targetElement.scrollIntoView({ 
                behavior: 'smooth', 
                block: 'start',
                inline: 'nearest'
            });
            this.highlightElement(targetElement);
        }, 100); // Small delay to allow DOM updates
    }
    
    expandAllParentContainers(element) {
        let current = element;
        const containersToExpand = [];
        
        // First pass: identify all containers that need expanding
        while (current && current !== document.body) {
            if (this.isCollapsibleContainer(current) && this.isCollapsed(current)) {
                containersToExpand.push(current);
            }
            current = current.parentElement;
        }
        
        // Second pass: expand containers from top down
        containersToExpand.reverse().forEach(container => {
            this.expandContainer(container);
        });
    }
    
    isCollapsibleContainer(element) {
        // Adjust these selectors based on your actual container classes/structure
        return element.matches('div, theorem-box, .collapsible, .accordion, .toggle-container, [data-collapsible], .dropdown, .tab-content, .collapsible-content, .content-box, .derivation-content' ) ||
               element.classList.contains('collapsed') ||
               element.getAttribute('data-state') === 'collapsed';
    }
    
    isCollapsed(element) {
        return element.classList.contains('collapsed') ||
               element.getAttribute('aria-expanded') === 'false' ||
               element.getAttribute('data-state') === 'collapsed' ||
               element.style.display === 'none' ||
               element.style.visibility === 'hidden' ||
               element.offsetHeight === 0;
    }
    
    expandContainer(container) {
        console.log('Expanding container:', container);
        
        // Remove collapsed classes/states
        container.classList.remove('collapsed', 'hidden', 'closed');
        container.classList.add('expanded', 'open', 'active');
        
        // Update attributes
        container.setAttribute('aria-expanded', 'true');
        container.setAttribute('data-state', 'expanded');
        
        // Show the container
        container.style.display = '';
        container.style.visibility = '';
        container.style.height = '';
        container.style.opacity = '';
        
        // Dispatch custom event for any listeners
        container.dispatchEvent(new CustomEvent('expand', { bubbles: true }));
        
        // If this is part of an accordion, close siblings
        this.handleAccordionBehavior(container);
    }
    
    handleAccordionBehavior(container) {
        // If container is part of an accordion where only one can be open
        const accordion = container.closest('.accordion, [data-accordion]');
        if (accordion) {
            const siblings = accordion.querySelectorAll('.accordion-item, [data-accordion-item]');
            siblings.forEach(sibling => {
                if (sibling !== container && this.isCollapsibleContainer(sibling)) {
                    this.collapseContainer(sibling);
                }
            });
        }
    }
    
    collapseContainer(container) {
        container.classList.add('collapsed', 'hidden');
        container.classList.remove('expanded', 'open', 'active');
        container.setAttribute('aria-expanded', 'false');
        container.setAttribute('data-state', 'collapsed');
    }
    
    highlightElement(element) {
        const originalTransition = element.style.transition;
        element.style.transition = 'background-color 0.5s ease';
        element.style.backgroundColor = '#fffbdd';
        
        setTimeout(() => {
            element.style.backgroundColor = '';
            setTimeout(() => {
                element.style.transition = originalTransition;
            }, 500);
        }, 2000);
    }}

function toggleContent(id) {
    const content = document.getElementById(id);
    content.style.display = 'none';
}


/********************** Functions to handle side notes ******************/
function resolveOverlaps(elements, minGap = 0) {
  // Filter out hidden elements and map the rest
  const visibleItems = Array.from(elements)
    .filter(el => getComputedStyle(el).display !== 'none')
    .map(el => ({
      el,
      top: parseFloat(getComputedStyle(el).top) || 0,
      height: el.offsetHeight
    }))
    .sort((a, b) => a.top - b.top);
  
  console.log(visibleItems);

  if (visibleItems.length === 0) return;

  // First visible element stays where it is
  let lastBottom = visibleItems[0].top + visibleItems[0].height;
  visibleItems[0].el.style.top = visibleItems[0].top + 'px';

  // Adjust subsequent visible elements
  for (let i = 1; i < visibleItems.length; i++) {
    const desiredTop = visibleItems[i].top;
    const minAllowedTop = lastBottom + minGap;
    const newTop = Math.max(desiredTop, minAllowedTop);

    visibleItems[i].el.style.top = newTop + 'px';
    lastBottom = newTop + visibleItems[i].height;
  }
}

function handleSideNotes(target){
  const container = document.getElementById('side-notes-container');
  const scrollTop = window.scrollY || document.documentElement.scrollTop;
  // Put the side-note in the correct vertical position
  let elem = document.getElementById(target.hash.slice(1));
  if(container.contains(elem)){ // check if elem is child of container
    let ref = target.getBoundingClientRect();
    elem.style.top = `${ref.top + scrollTop - elem.offsetHeight}px`;
    elem.style.position = "absolute";
  }
  resolveOverlaps(container.children);
}

window.addEventListener('resize', function() {
  const container = document.getElementById('side-notes-container');
  resolveOverlaps(container.children);
});

// Set the side-notes as invisible
const container = document.getElementById('side-notes-container');
Array.from(container.children).forEach(elem =>{
  elem.style.display = 'none';
});


// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new HashNavigation();
});



