class ElementHandler {
  constructor(links) {
    this.iframes = {};

    for (let i = 0; i < links.length; i++) {
      this.iframes[links[i]] = document.createElement("iframe");
    }
  }

  extractAndInjectCSS(iframe) {
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

  parseURL(url) {
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
  
  getElement(doc,id){
    /* Returns the element with changesd id of all childs */
    console.log(`Getting element with id ${id} from ${doc}`);
    elem = doc.getElementById(id);
    if(!elem) {
      console.log(`Element with id ${id} does not exist`);
      return null;
    }
    /* Change the id and return a clone */
    return this.renameIdsRecursively(elem.cloneNode(true));
  }

  SetOnGetElementCallback(url,callback) {
    const { domain, relativePath, anchor } = this.parseURL(url);
    // Check if this element exists in this webpage
    // let elem = this.getElement(document,anchor);
    let elem = document.getElementById(anchor);
    if(elem){
      console.log("Found element inside this webpage");
      // Return a clone
      callback(this.renameIdsRecursively(elem.cloneNode(true)));
      return true;
    }

    const iframe = this.iframes[relativePath];
    if(!iframe) {
      console.log(`iframe not found for the given path: ${relativePath}`);
    }
    
    // Check if the iframe is alredy loaded
    const loaded = iframe.contentDocument && iframe.contentDocument.readyState === 'complete';

    if(!loaded) {
      iframe.addEventListener('load', () => {
        this.extractAndInjectCSS(iframe);
        const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
        if(iframeDoc){
          console.log("Getting the element from iframe on load.");
          elem = iframeDoc.getElementById(anchor);
          if(elem) callback(this.renameIdsRecursively(elem.cloneNode(true)));
          else callback(null);
        }
      });

      iframe.className = "iframe-container";
      iframe.style.display = 'none';
      iframe.src = domain + relativePath;
      document.body.appendChild(iframe);

    }else {
      const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
      if(iframeDoc){
          console.log("Getting the element from iframe after load.");
          elem = iframeDoc.getElementById(anchor);
          if(elem) callback(this.renameIdsRecursively(elem.cloneNode(true)));
          else callback(null);
      }
    }
  }
  renameIdsRecursively(element, suffix = "-repeat") {
    if(element.id) element.id += suffix;

    Array.from(element.children).forEach(child => {
      this.renameIdsRecursively(child, suffix);
    });
    return element;
  }
}


class HoverTagKeyListener {
    constructor(tagName, key, callback) {
        this.tagName = tagName.toUpperCase();
        this.key = key;
        this.callback = callback;
        this.isKeyDown = false;
        this.hoveredElement = null;
        this.init();
    }

    init() {
        document.addEventListener('mouseover', (e) => {
            if (e.target.tagName === this.tagName) {
                this.hoveredElement = e.target;
                this.check();
            }
        });

        document.addEventListener('mouseout', (e) => {
            if (this.hoveredElement === e.target) {
                this.hoveredElement = null;
            }
        });

        document.addEventListener('keydown', (e) => {
            if(e.code === this.key && e.ctrlKey){
                this.isKeyDown = true;
                this.check();
            }
        });

        document.addEventListener('keyup', (e) => {
            if (e.code === this.key) {
                this.isKeyDown = false;
            }
        });
    }

    check() {
        if (this.hoveredElement && this.isKeyDown) {
            this.callback(this.hoveredElement);
        }
    }
}



// ComicBalloon API Class - Accepts DOM Elements
class ComicBalloon {
    constructor() {
        this.balloonContainer = null;
        this.currentElement = null;
        this.isBalloonVisible = false;
        this.balloons = new Map();
        this.scrollHandler = this.handleScroll.bind(this);
        this.resizeHandler = this.handleResize.bind(this);
        this.init();
    }

    init() {
        // Create balloon container - using fixed positioning
        this.balloonContainer = document.createElement('div');
        this.balloonContainer.className = 'balloon-container';
        this.balloonContainer.innerHTML = `
            <div class="balloon">
                <div class="balloon-content"></div>
                <div class="balloon-tail"></div>
            </div>
        `;
        document.body.appendChild(this.balloonContainer);

        // Add scroll and resize listeners
        window.addEventListener('scroll', this.scrollHandler, { passive: true });
        window.addEventListener('resize', this.resizeHandler, { passive: true });

        // Balloon event listeners
        this.balloonContainer.addEventListener('mouseenter', () => {
            this.isBalloonVisible = true;
        });

        this.balloonContainer.addEventListener('mouseleave', (e) => {
            if (!this.isMovingToTrigger(e)) {
                this.hideBalloon();
            }
        });
    }

    // Handle scroll events to update balloon position
    handleScroll() {
        if (this.isBalloonVisible && this.currentElement) {
            this.updatePositionForCurrentElement();
        }
    }

    // Handle resize events
    handleResize() {
        if (this.isBalloonVisible && this.currentElement) {
            this.updatePositionForCurrentElement();
        }
    }

    // Update position for current element
    updatePositionForCurrentElement() {
        const config = this.balloons.get(this.currentElement);
        if (config) {
            this.updatePositionForElement(this.currentElement, config.position);
        }
    }

    // API Method: Add balloon to element with DOM element content
    addBalloon(element, contentElement, options = {}) {
        const config = {
            contentElement: contentElement,
            position: options.position || 'top',
            showDelay: options.showDelay || 0,
            hideDelay: options.hideDelay || 0,
            ...options
        };

        console.log(element);
        console.log(contentElement);

        // Store balloon configuration
        this.balloons.set(element, config);

        // Add event listeners to element
        element.addEventListener('mouseenter', (e) => this.showBalloon(e));
        element.addEventListener('mouseleave', (e) => this.handleElementLeave(e));
        element.addEventListener('mousemove', (e) => this.updatePositionFromEvent(e));

        // Add balloon indicator
        element.style.position = 'relative';
        if (!element.querySelector('.balloon-indicator')) {
            const indicator = document.createElement('span');
            indicator.className = 'balloon-indicator';
            indicator.innerHTML = '🎈';
            indicator.style.position = 'absolute';
            indicator.style.top = '-5px';
            indicator.style.right = '-5px';
            indicator.style.fontSize = '12px';
            element.appendChild(indicator);
        }

        return this;
    }

    // API Method: Remove balloon from element
    removeBalloon(element) {
        if (this.balloons.has(element)) {
            this.balloons.delete(element);
            
            // Remove indicator
            const indicator = element.querySelector('.balloon-indicator');
            if (indicator) {
                indicator.remove();
            }
            
            // Clear event listeners
            element.replaceWith(element.cloneNode(true));
        }
        return this;
    }

    // API Method: Update balloon content with new DOM element
    updateBalloon(element, newContentElement) {
        if (this.balloons.has(element)) {
            this.balloons.get(element).contentElement = newContentElement;
            
            // Update if currently visible
            if (this.currentElement === element && this.isBalloonVisible) {
                const contentContainer = this.balloonContainer.querySelector('.balloon-content');
                contentContainer.innerHTML = '';
                contentContainer.appendChild(newContentElement.cloneNode(true));
            }
        }
        return this;
    }

    // API Method: Show balloon programmatically
    showBalloonOnElement(element) {
        if (this.balloons.has(element)) {
            const config = this.balloons.get(element);
            this.currentElement = element;
            this.isBalloonVisible = true;
            
            const contentContainer = this.balloonContainer.querySelector('.balloon-content');
            contentContainer.innerHTML = '';
            contentContainer.appendChild(config.contentElement.cloneNode(true));
            
            this.updateTailPosition(config.position);
            
            this.balloonContainer.style.opacity = '1';
            this.balloonContainer.style.visibility = 'visible';
            this.balloonContainer.classList.add('visible');
            
            this.updatePositionForElement(element, config.position);
        }
    }

    // API Method: Hide balloon programmatically
    hideBalloon() {
        this.isBalloonVisible = false;
        this.balloonContainer.style.opacity = '0';
        this.balloonContainer.style.visibility = 'hidden';
        this.balloonContainer.classList.remove('visible');
        this.currentElement = null;
    }

    // API Method: Clear all balloons
    clearAllBalloons() {
        this.balloons.clear();
        this.hideBalloon();
        
        // Remove all indicators
        document.querySelectorAll('.balloon-indicator').forEach(indicator => {
            indicator.remove();
        });
        
        return this;
    }

    // Internal methods
    showBalloon(event) {
        const element = event.currentTarget;
        if (!this.balloons.has(element)) return;

        const config = this.balloons.get(element);
        this.currentElement = element;
        this.isBalloonVisible = true;
        
        const contentContainer = this.balloonContainer.querySelector('.balloon-content');
        contentContainer.innerHTML = '';
        contentContainer.appendChild(config.contentElement.cloneNode(true));
        
        this.updateTailPosition(config.position);
        
        this.balloonContainer.style.opacity = '1';
        this.balloonContainer.style.visibility = 'visible';
        this.balloonContainer.classList.add('visible');
        
        this.updatePositionFromEvent(event);
    }

    updatePositionFromEvent(event) {
        if (!this.currentElement) return;
        const config = this.balloons.get(this.currentElement);
        this.updatePositionForElement(this.currentElement, config.position);
    }

    handleElementLeave(event) {
        if (this.isMovingToBalloon(event)) return;
        this.hideBalloon();
    }

    isMovingToBalloon(event) {
        const relatedTarget = event.relatedTarget;
        return relatedTarget && this.balloonContainer.contains(relatedTarget);
    }

    isMovingToTrigger(event) {
        const relatedTarget = event.relatedTarget;
        return relatedTarget && this.currentElement && this.currentElement.contains(relatedTarget);
    }

    // FIXED: Proper positioning with scroll support
    updatePositionForElement(element, position) {
        const balloonRect = this.balloonContainer.getBoundingClientRect();
        const elementRect = element.getBoundingClientRect();
        
        // Get viewport dimensions
        const viewportWidth = window.innerWidth;
        const viewportHeight = window.innerHeight;
        
        // Calculate position based on viewport coordinates (which include scroll)
        let x, y;

        switch (position) {
            case 'top':
                x = elementRect.left + (elementRect.width / 2) - (balloonRect.width / 2);
                y = elementRect.top - balloonRect.height - 20;
                break;
            case 'bottom':
                x = elementRect.left + (elementRect.width / 2) - (balloonRect.width / 2);
                y = elementRect.bottom + 20;
                break;
            case 'left':
                x = elementRect.left - balloonRect.width - 20;
                y = elementRect.top + (elementRect.height / 2) - (balloonRect.height / 2);
                break;
            case 'right':
                x = elementRect.right + 20;
                y = elementRect.top + (elementRect.height / 2) - (balloonRect.height / 2);
                break;
        }

        // Keep balloon within viewport with proper padding
        const padding = 10;
        x = Math.max(padding, Math.min(x, viewportWidth - balloonRect.width - padding));
        y = Math.max(padding, Math.min(y, viewportHeight - balloonRect.height - padding));

        // Apply the positions - since we're using fixed positioning,
        // we use the viewport-relative coordinates directly
        this.balloonContainer.style.left = x + 'px';
        this.balloonContainer.style.top = y + 'px';
        console.log("Ballon Container Rekt");
        console.log(this.balloonContainer.getBoundingClientRect());
    }

    updateTailPosition(position) {
        const tail = this.balloonContainer.querySelector('.balloon-tail');
        tail.className = 'balloon-tail ' + position;
    }

    // Clean up event listeners
    destroy() {
        window.removeEventListener('scroll', this.scrollHandler);
        window.removeEventListener('resize', this.resizeHandler);
        this.clearAllBalloons();
    }

}

// const niggaLinks = ["/jekyll/update/2025/10/11/goodbye-to-jekyll.html","/jekyll/update/2025/10/11/welcome-to-jekyll.html"];
const elemHandler = new ElementHandler(postsLinks);
const comicBalloon = new ComicBalloon();

new HoverTagKeyListener('a', 'Space', (refElem) => {
    // console.log("Hovering and pressing space");
    // console.log(el.href);
    
    // console.log("Niggaaaaa");
    console.log("Reference Element:");
    console.log(refElem);

    callback = (elem) => {
      console.log("Get the element callback...");
      console.log(elem);
      console.log(refElem);
      elem.style.display = 'block';
      comicBalloon.addBalloon(refElem, elem, { position: "top" });
      comicBalloon.showBalloonOnElement(refElem);
    }
    elemHandler.SetOnGetElementCallback(refElem.href,callback);
  // comicBalloon.addBalloon(targetElement, myElement, { position: 'top' });
});

const elements = document.getElementsByTagName('repeat-element');

for(const refElem of elements){
  elemHandler.SetOnGetElementCallback(refElem.getAttribute("url"), (elem) => {
    refElem.insertAdjacentElement('afterend', elem);
  }
  );
}
