
/*********************Handle styling of cloned content functions**************************************/
function extractAndInjectCSS(iframe) {
  const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
  const styles = [];
  const cssContainer = document.createElement('div');

  const styleSheets = iframeDoc.styleSheets;
  for (let i = 0; i < styleSheets.length; i++) {
    try {
      const sheet = styleSheets[i];
      if (sheet.href) {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = sheet.href;
        styles.push(link.outerHTML);
      } else if (sheet.cssRules) {
        let cssText = '';
        for (let j = 0; j < sheet.cssRules.length; j++) {
          cssText += sheet.cssRules[j].cssText + '\n';
        }
        if (cssText) styles.push(`<style>${cssText}</style>`);
      }
    } catch(e) {}
  }

  iframeDoc.querySelectorAll('style').forEach(tag => {
    styles.push(tag.outerHTML);
  });

  const cssContent = styles.join('\n');
  if (cssContent) {
    cssContainer.innerHTML = cssContent;
    document.head.appendChild(cssContainer);
  }
}

function copyElementWithMathML(element, iframeDoc) {
  // Clone the element deeply
  const clone = element.cloneNode(true);
  
  // Find all MathML elements and ensure they have the correct namespace
  const mathElements = clone.querySelectorAll('math, math *');
  
  mathElements.forEach(el => {
    if (!el.namespaceURI || el.namespaceURI !== 'http://www.w3.org/1998/Math/MathML') {
      // Re-create with proper namespace
      const newEl = document.createElementNS('http://www.w3.org/1998/Math/MathML', el.tagName.toLowerCase());
      
      // Copy attributes
      for (let attr of el.attributes) {
        newEl.setAttribute(attr.name, attr.value);
      }
      
      // Copy children
      while (el.firstChild) {
        newEl.appendChild(el.firstChild);
      }
      
      // Replace old element
      el.parentNode.replaceChild(newEl, el);
    }
  });
  
  return clone;
}

function copyMathMLStyles(iframeDoc) {
  const styleSheets = iframeDoc.styleSheets;
  let mathMLStyles = '';
  
  for (let i = 0; i < styleSheets.length; i++) {
    try {
      const rules = styleSheets[i].cssRules || styleSheets[i].rules;
      
      for (let j = 0; j < rules.length; j++) {
        const rule = rules[j];
        
        if (rule.type === CSSRule.STYLE_RULE) {
          // Look for MathML-related selectors
          if (rule.selectorText && 
              (rule.selectorText.includes('math') || 
               rule.selectorText.includes('mrow') ||
               rule.selectorText.includes('mfrac') ||
               rule.selectorText.includes('msup') ||
               rule.selectorText.includes('msub') ||
               rule.selectorText.includes('mi') ||
               rule.selectorText.includes('mo') ||
               rule.selectorText.includes('mn'))) {
            mathMLStyles += rule.cssText + '\n';
          }
        }
      }
    } catch (e) {
      continue;
    }
  }
  
  // Add the styles to the main page
  if (mathMLStyles) {
    const styleEl = document.createElement('style');
    styleEl.textContent = mathMLStyles;
    document.head.appendChild(styleEl);
  }
}

function ensureMathMLStyles() {
  // Check if MathML styles exist
  const mathTest = document.createElementNS('http://www.w3.org/1998/Math/MathML', 'math');
  mathTest.innerHTML = '<mrow><mi>x</mi></mrow>';
  mathTest.style.position = 'absolute';
  mathTest.style.visibility = 'hidden';
  document.body.appendChild(mathTest);
  
  const needsStyles = window.getComputedStyle(mathTest).display === 'inline';
  document.body.removeChild(mathTest);
  
  if (needsStyles) {
    const style = document.createElement('style');
    style.textContent = `
      math {
        display: inline-block;
        text-align: center;
      }
      mrow {
        display: inline-block;
      }
      mfrac {
        display: inline-block;
        vertical-align: -0.5em;
        text-align: center;
      }
      mfrac > * {
        display: block;
      }
      mfrac > :first-child {
        border-bottom: 1px solid currentColor;
        padding-bottom: 0.2em;
      }
      mfrac > :last-child {
        padding-top: 0.2em;
      }
      msup, msub, msubsup {
        display: inline-block;
        vertical-align: baseline;
      }
      msup > :last-child, msubsup > :nth-child(2) {
        font-size: 0.7em;
        vertical-align: super;
      }
      msub > :last-child, msubsup > :last-child {
        font-size: 0.7em;
        vertical-align: sub;
      }
      mi, mo, mn {
        display: inline;
      }
      mo {
        padding: 0 0.2em;
      }
    `;
    document.head.appendChild(style);
  }
}

function copyAllMatchingStylesToPage(element){
  const styleId = 'copied-styles-' + Date.now();
  
  function styleExists(cssText) {
    const existingStyles = doc.querySelectorAll('style');
    for (let style of existingStyles) {
      if (style.textContent.trim() === cssText.trim()) {
        return true;
      }
    }
    return false;
  }
  
  const doc = element.ownerDocument;
  const allElements = [element, ...element.querySelectorAll('*')];
  
  let cssText = '';
  
  // Loop through all stylesheets in the document
  for(let i = 0; i < doc.styleSheets.length; i++) {
    const styleSheet = doc.styleSheets[i];
    
    try {
      const rules = styleSheet.cssRules || styleSheet.rules;
      
      for(let j = 0; j < rules.length; j++) {
        const rule = rules[j];
        
        if(rule.type === CSSRule.STYLE_RULE) {
          const selector = rule.selectorText;
          
          // Check if this rule matches any of our elements
          for(let el of allElements) {
            try {
              if(el.matches(selector)) {
                cssText += rule.cssText + '\n';
                break;
              }
            } catch (e) {
              // Invalid selector for matches(), skip
              continue;
            }
          }
        }
      }
      
    } catch (e) {
      // Cross-origin stylesheet, skip
      console.warn('Cannot access stylesheet:', styleSheet.href || 'inline');
      continue;
    }
  }
  
  // Add to main document if not exists
  if (cssText && !styleExists(cssText)) {
    const styleEl = document.createElement('style');
    styleEl.id = styleId;
    styleEl.textContent = cssText;
    document.head.appendChild(styleEl);
    console.log('Styles added to page');
    return styleEl;
  } else {
    console.log('No matching styles or styles already exist');
    return null;
  }
}

function renameIdsRecursively(element, suffix = "-repeat") {
  if(element.id) element.id += suffix;
  
  // Rename the onclick functions
  if(element.onclick){
    const onclickValue = element.getAttribute('onclick');
    if(onclickValue.includes('toggleContent')){
      const newOnclickValue = onclickValue.replace(
        /toggleContent\('([^']+)'\)/,
        (_, captured) => `toggleContent('${captured}-repeat')`
      );
      element.setAttribute('onclick',newOnclickValue);
    }
  }
  // Recursive call for each child
  Array.from(element.children).forEach(child => renameIdsRecursively(child, suffix));
  return element;
}

function parseURL(url) {
  try {
    const urlObj = new URL(url, window.location.origin);
    return {
      domain: urlObj.origin,
      relativePath: urlObj.pathname + urlObj.search,
      anchor: urlObj.hash ? urlObj.hash.slice(1) : ''
    };
  } catch(e) {
    return { error: 'Invalid URL', message: e.message };
  }
}


class IframesHandler{
  constructor(links) {
    this.iframes = {};

    for (let i = 0; i < links.length; i++) {
      this.iframes[links[i]] = document.createElement("iframe");
    }
  }


    
  getElement(doc,id){
    /* Returns the element with changesd id of all childs */
    console.log(`Getting element with id ${id} from ${doc}`);
    elem = doc.getElementById(id);
    if(!elem) {
      console.log(`Element with id ${id} does not exist`);
      return null;
    }
    /* Change the id and return a clone */
    return renameIdsRecursively(elem.cloneNode(true));
  }

  
  setOnIframeLoad(relativePath,callback){
    // Check if is the current webpage
    if(window.location.pathname === relativePath){
      // return this webpage frame
      callback(document);
      return;
    }
    const iframe = this.iframes[relativePath];
    if(!iframe) {
      console.log(`iframe not found for the given path: ${relativePath}`);
      callback(null);
      return;
    }
    
    // Check if the iframe is alredy loaded
    const loaded = iframe.contentDocument && iframe.contentDocument.readyState === 'complete';

    if(!loaded) {
      // Load the iframe
      iframe.addEventListener('load', () => {
        extractAndInjectCSS(iframe);
        const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
        if(iframeDoc){
          callback(iframeDoc);// Return the iframe
        }
        else callback(null);
      });

      iframe.className = "iframe-container";
      iframe.style.display = 'none';
      iframe.src = relativePath;
      document.body.appendChild(iframe);

    }else{
      const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
      if(iframeDoc){
        callback(iframeDoc);
        return;
      }else callback(null);
    }

  }

  
  setOnGetElementCallback(relativePath,id,callback) {
    // Check if this element exists in this webpage
    let elem = document.getElementById(id);
    if(elem){
      console.log("Found element inside this webpage");
      // Return a clone
      callback(renameIdsRecursively(elem.cloneNode(true)));
      return;
    }
    this.setOnIframeLoad(relativePath,(iframeDoc) => {
      let elem = iframeDoc.getElementById(id);
      if(!elem)
        callback(renameIdsRecursively(elem.cloneNode(true)));
      else callback(null);
    });
  }

  setOnGetElemsByClassName(relativePath,className,callback) {
    this.setOnIframeLoad(relativePath,(iframeDoc) => {
      let elems = iframeDoc.getElementsByClassName(className);

      if(elems)
        callback(Array.from(elems)
          .filter(el => !el.id.endsWith('-repeat'))
          .map(el => renameIdsRecursively(el.cloneNode(true)))
        );
      else callback([]);
    });
  }

}

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

// Render charts inside of the parent container
async function RenderChart(filename, parentId, numberCols) {
    // Ensure Chart.js and MessagePack are available
    if (typeof Chart === 'undefined') {
        throw new Error("Chart.js is required but not found.");
    }
    if (typeof MessagePack === 'undefined' && typeof msgpack === 'undefined') {
        throw new Error("MessagePack library is required but not found.");
    }

    // Use whichever global variable exists
    const MsgPack = MessagePack || msgpack;

    try {
        // Fetch the MessagePack file as binary data
        const response = await fetch(filename);
        const arrayBuffer = await response.arrayBuffer();

        // Decode MessagePack data
        const decodedData = MsgPack.decode(new Uint8Array(arrayBuffer));

        // Expecting decodedData to be an array of chart definitions
        if (!Array.isArray(decodedData)) {
            throw new Error("Expected MessagePack to contain an array of chart configurations.");
        }

        // Get parent element
        const parent = document.getElementById(parentId);
        if (!parent) {
            throw new Error(`No element found with id "${parentId}".`);
        }

        // Iterate through each chart definition
        decodedData.forEach((chartConfig, index) => {
            // Create a container for the chart
            const container = document.createElement('div');
            container.style.flex = `1 1 ${100/numberCols-2}%`;
            container.style.display = 'flex';
            container.style.maxWidth = '100%';
            container.style.height = '300px';
            container.style.position = 'relative';

            const content = parent.querySelector('.box').querySelector('.content');

            const canvas = document.createElement('canvas');
            canvas.id = `msgpack-chart-${index}`;
            container.appendChild(canvas);
            content.appendChild(container);
            
            // Create chart instance
            new Chart(canvas, {
                type: chartConfig.type || 'line',
                data: chartConfig.data,
                options: {...(chartConfig.options || {}),
                            maintainAspectRatio: false}
            });
        });
    } catch (err) {
        console.error("Failed to render MessagePack charts:", err);
    }
}

/* Renders MessagePack data as an HTML table */
function renderMessagePackTable(uint8Array, container) {
  // Decode the MessagePack data
  const data = MessagePack.decode(uint8Array);
  
  // Validate that data is an array
  if (!Array.isArray(data)) {
    container.textContent = 'Expected an array of objects in the MessagePack data.';
    return;
  }
  
  // Validate that array is not empty
  if (data.length === 0) {
    container.textContent = 'No data to display.';
    return;
  }
  
  // Create table element
  const table = document.createElement('table');
  table.border = '1';
  table.cellPadding = '5';
  
  // Extract headers from first object
  const headers = Object.keys(data[0]);
  
  // Create header row
  const headerRow = document.createElement('tr');
  headers.forEach(key => {
    const th = document.createElement('th');
    th.textContent = key[0].toUpperCase() + key.slice(1);;
    headerRow.appendChild(th);
  });
  table.appendChild(headerRow);
  
  // Create data rows
  data.forEach(row => {
    const tr = document.createElement('tr');
    headers.forEach(key => {
      const td = document.createElement('td');
      td.textContent = row[key];
      tr.appendChild(td);
    });
    table.appendChild(tr);
  });

  const content = container.querySelector('.box').querySelector('.content');
  content.appendChild(table);
}


/* Loads a MessagePack file from a file path (via fetch) and renders it as an HTML table */
async function RenderTable(filePath, containerId) {
  const container = document.getElementById(containerId);

  try {
    // Fetch the MessagePack file as an ArrayBuffer
    const response = await fetch(filePath);
    if (!response.ok) {
      container.textContent = `Failed to load file: ${response.statusText}`;
      return;
    }

    const arrayBuffer = await response.arrayBuffer();
    const uint8Array = new Uint8Array(arrayBuffer);

    // Render the decoded data as a table
    renderMessagePackTable(uint8Array, container);
  } catch (error) {
    container.textContent = `Error loading file: ${error.message}`;
  }
}

const iframesHandler = new IframesHandler(postsLinks);
const elements = document.getElementsByTagName('repeat-element');

window.addEventListener('resize', function() {
  const container = document.getElementById('side-notes-container');
  if (container !== null && container !== undefined)   
    resolveOverlaps(container.children);
});

// Set the side-notes as invisible
const container = document.getElementById('side-notes-container');
if (container !== null && container !== undefined)   
  Array.from(container.children).forEach(elem =>{
    elem.style.display = 'none';
  });


// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new HashNavigation();
});


for(const refElem of elements){
  const { domain, relativePath, anchor } = parseURL(refElem.getAttribute("url"));
  iframesHandler.setOnIframeLoad(relativePath,(iframeDoc) => {
    elem = iframeDoc.getElementById(anchor);
    clone = renameIdsRecursively(elem.cloneNode(true));
    clone.style.display = 'block'; 
    // Display the clone
    refElem.insertAdjacentElement('afterend', clone);
  });
}


// Show a popup on hover
document.querySelectorAll('a.popup').forEach(element => {
  let leave = true;
  element.addEventListener('mouseover', (e) => {
    const link = event.target.closest('a');
    if(!link || !link.hash) return;
    const { domain, relativePath, anchor } = parseURL(link.href);
    // console.log(relativePath);
    leave = false;
    iframesHandler.setOnIframeLoad(relativePath,(iframeDoc) => {
      let elem = iframeDoc.getElementById(anchor); 
      let clone = null;
      if(/^H[1-6]$/.test(elem.tagName)) {
        clone = getSectionFragment(elem);
        const bgColor = window.getComputedStyle(iframeDoc.body).backgroundColor;
        clone.style.backgroundColor = bgColor;
        clone.style.padding = '10px';
      }
      else clone = renameIdsRecursively(elem.cloneNode(true));
      // copyAllMatchingStylesToPage(elem);
      // Create a clone and rename the ids
      
      
      const ref = link.getBoundingClientRect();
      const scrollTop = window.scrollY || document.documentElement.scrollTop;
      const scrollLeft = window.scrollX || document.documentElement.scrollLeft;
      
      if(!leave){
        document.body.appendChild(clone);
        clone.classList.remove('overlay');
        clone.style.display = 'block';
        clone.style.position = 'absolute';
        clone.style.top = `${ref.top + scrollTop - clone.offsetHeight-10}px`;
        clone.style.left = `${ref.left + scrollLeft}px`;
      }
    });
  });

  element.addEventListener('mouseleave', (e) => {
    const link = event.target.closest('a');
    if(!link || !link.hash) return;
    elem = document.getElementById(`${link.hash.slice(1)}-repeat`);
    if(elem) elem.remove();
    leave = true;
  });

});

/* It takes a reference to a heading element (like an h2) and collects
 * everything from after that element up to (but not including) the next 
 * heading of equal or higher level. 
 * */
function getSectionFragment(headingEl) {
  const baseLevel = parseInt(headingEl.tagName.slice(1), 10);
  const frag = document.createDocumentFragment();
  let node = headingEl.nextElementSibling;
  let div = document.createElement('div');
  let headingClone = headingEl.cloneNode(true);
  headingClone.id = `${headingClone.id}-head-clone`;
  frag.appendChild(headingClone);

  while (node) {
    if(/^H[1-6]$/.test(node.tagName)) {
      const level = parseInt(node.tagName.slice(1), 10);
      if (level <= baseLevel) break;
    }
    console.log(node);
    frag.appendChild(renameIdsRecursively(node.cloneNode(true)));
    node = node.nextElementSibling;
  }
  div.appendChild(frag);
  div.id = `${headingEl.id}-repeat`
  return div;
}

