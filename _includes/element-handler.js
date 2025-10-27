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
      renameIdsRecursively(child, suffix);
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

const niggaLinks = ["/jekyll/update/2025/10/11/goodbye-to-jekyll.html","/jekyll/update/2025/10/11/welcome-to-jekyll.html"];
elemHandler = new ElementHandler(niggaLinks);

const balloonsDict = {};

new HoverTagKeyListener('a', 'Space', (refElem) => {
  // console.log("Hovering and pressing space");
  // console.log(el.href);
    
  console.log("Niggaaaaa");
  // Get the balloon from the dictionary
  comicBalloon = balloonsDict[refElem.href];
  // if not found
  if(!comicBalloon){
    // create new balloon
    comicBalloon = new ComicBalloon();
    // Add the ballon to the dictionary
    balloonsDict[refElem.href] = comicBalloon;
  }
  
  // create get element callback 
  callback = (elem) => {
    console.log(elem);
    
    // comicBalloon.addBalloon(refElem, elem, { position: "top" });
    // refElem is the reference 
    // elem is the content that I want to display
    comicBalloon.ShowContent(refElem,elem);
  }
  elemHandler.SetOnGetElementCallback(refElem.href,callback);
  // comicBalloon.addBalloon(targetElement, myElement, { position: 'top' });
});

// ComicBalloon API Class - Accepts DOM Elements
class ComicBalloon {
    constructor() {
        this.balloonContainer = null;
        this.currentElement = null;
        this.isBalloonVisible = false;
        this.balloons = new Map(); // Store balloon configurations
        this.init();
    }

    init() {
        // Create balloon container
        this.balloonContainer = document.createElement('div');
        this.balloonContainer.className = 'balloon-container';
        // this.balloonContainer.innerHTML = `
        //     <div class="balloon">
        //     </div>
        // `;
        document.body.appendChild(this.balloonContainer);

        // Balloon event listeners
        // this.balloonContainer.addEventListener('mouseenter', () => {
        //     this.isBalloonVisible = true;
        // });

        // this.balloonContainer.addEventListener('mouseleave', (e) => {
        //     if (!this.isMovingToTrigger(e)) {
        //         this.hideBalloon();
        //     }
        // });
    }
    
    ShowContent(refElem,contentElem){
      console.log("Adding content as child");
      this.balloonContainer.appendChild(contentElem);
      // this.balloonContainer.
      
      // Show the ballon
      this.balloonContainer.style.display = 'block';
      this.balloonContainer.style.zIndex = 1000; 
      this.balloonContainer.style.opacity = '1';
      this.balloonContainer.style.visibility = 'visible';
      
      // Set the position of the balloonContainer 
      this.updatePositionForElement(contentElem,'top');
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

        // Store balloon configuration
        this.balloons.set(element, config);

        // Add event listeners to element
        element.addEventListener('mouseenter', (e) => this.showBalloon(e));
        element.addEventListener('mouseleave', (e) => this.handleElementLeave(e));
        element.addEventListener('mousemove', (e) => this.updatePosition(e));

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

        return this; // For method chaining
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

        console.log("Show the fucking ballooooooonnnnn");
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
        
        this.updatePosition(event);
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

    updatePosition(event) {
        if (!this.currentElement) return;

        const balloonRect = this.balloonContainer.getBoundingClientRect();
        const elementRect = this.currentElement.getBoundingClientRect();
        const config = this.balloons.get(this.currentElement);
        const position = config.position;

        this.updatePositionForElement(this.currentElement, position);
    }

    updatePositionForElement(element, position) {
        const balloonRect = this.balloonContainer.getBoundingClientRect();
        const elementRect = element.getBoundingClientRect();
        
      // console.log(elementRect);



        // let x, y;
        //
        // switch (position) {
        //     case 'top':
        //         x = elementRect.right + (elementRect.width / 2) - (balloonRect.width / 2);
        //         y = elementRect.bottom - balloonRect.height - 20;
        //         break;
        //     case 'bottom':
        //         x = elementRect.left + (elementRect.width / 2) - (balloonRect.width / 2);
        //         y = elementRect.bottom + 20;
        //         break;
        //     case 'left':
        //         x = elementRect.left - balloonRect.width - 20;
        //         y = elementRect.top + (elementRect.height / 2) - (balloonRect.height / 2);
        //         break;
        //     case 'right':
        //         x = elementRect.right + 20;
        //         y = elementRect.top + (elementRect.height / 2) - (balloonRect.height / 2);
        //         break;
        // }
        //
        // const padding = 10;
        // x = Math.max(padding, Math.min(x, window.innerWidth - balloonRect.width - padding));
        // y = Math.max(padding, Math.min(y, window.innerHeight - balloonRect.height - padding));
        //
        // this.balloonContainer.style.left = x + 'px';
        // this.balloonContainer.style.top = y + 'px';
        this.balloonContainer.style.position = "fixed";
        this.balloonContainer.style.right = `${window.innerWidth - elementRect.right}px`;
        this.balloonContainer.style.bottom = `${window.innerHeight - elementRect.bottom}px`;
        // this.balloonContainer.style.top = elementRect.top + "px";
        console.log(this.balloonContainer.style);
        console.log(this.balloonContainer.getBoundingClientRect());
        // console.log(`inner height=${window.innerHeight}`);
        // console.log(`bottom=${elementRect.bottom}`);
    }

    updateTailPosition(position) {
        const tail = this.balloonContainer.querySelector('.balloon-tail');
        tail.className = 'balloon-tail ' + position;
    }
}


