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


class ElementHandler {
  constructor(links) {
    this.iframes = {};

    for (let i = 0; i < links.length; i++) {
      this.iframes[links[i]] = document.createElement("iframe");
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

  
  setOnIframeLoad(url,callback){
    const { domain, relativePath, anchor } = this.parseURL(url);
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
        if(iframe.contentDocument || iframe.contentWindow.document)
          callback(iframe);// Return the iframe
        else callback(null);
      });

      iframe.className = "iframe-container";
      iframe.style.display = 'none';
      iframe.src = domain + relativePath;
      document.body.appendChild(iframe);

    }else{
      if(iframe.contentDocument || iframe.contentWindow.document){
        callback(iframe);
        return;
      }else callback(null);
    }

  }

  setOnGetElemByClassCallback(url,className,callback) {
    const { domain, relativePath, anchor } = this.parseURL(url);

    const iframe = this.iframes[relativePath];
    if(!iframe) {
      console.log(`iframe not found for the given path: ${relativePath}`);
    }
    
    // Check if the iframe is alredy loaded
    const loaded = iframe.contentDocument && iframe.contentDocument.readyState === 'complete';

    if(!loaded) {
      iframe.addEventListener('load', () => {
        extractAndInjectCSS(iframe);
        const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
        if(iframeDoc){
          console.log("Getting the element from iframe on load.");
          elems = iframeDoc.getElementsByClassName(className)
          if(elems.length > 0)
            callback(Array.from(elems).map(el => this.renameIdsRecursively(el.cloneNode(true))));
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
          console.log(`Getting the elements of class ${className} from iframe after load.`);
          elem = iframeDoc.getElementsByClassName(className);
          if(elems.length > 0)
            callback(Array.from(elems).map(el => this.renameIdsRecursively(el.cloneNode(true))));
          else callback(null);
      }
    }
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
        extractAndInjectCSS(iframe);
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


const elemHandler = new ElementHandler(postsLinks);
const elements = document.getElementsByTagName('repeat-element');

for(const refElem of elements){
  elemHandler.SetOnGetElementCallback(refElem.getAttribute("url"), (elem) => {
    clone = elem.cloneNode(true);
    // Set the clone to visible
    clone.style.display = 'block'; 
    // Display the clone
    refElem.insertAdjacentElement('afterend', clone);
  }
  );
}


// Show a popup on hover
document.querySelectorAll('a.popup').forEach(element => {
  element.addEventListener('mouseover', (e) => {
    const link = event.target.closest('a');
    if(!link || !link.hash) return;
    elemHandler.SetOnGetElementCallback(link.href,(elem) => {
      
      const ref = event.target.getBoundingClientRect();
      const scrollTop = window.scrollY || document.documentElement.scrollTop;
      const scrollLeft = window.scrollX || document.documentElement.scrollLeft;

      document.body.appendChild(elem);
      elem.classList.remove('overlay');
      elem.style.display = 'block';
      elem.style.position = 'absolute';
      elem.style.top = `${ref.top + scrollTop - elem.offsetHeight-10}px`;
      elem.style.left = `${ref.left + scrollLeft}px`;
    });

    console.log('Hovered over:', e.target);
  });

  element.addEventListener('mouseleave', (e) => {
    const link = event.target.closest('a');
    if(!link || !link.hash) return;
    document.getElementById(`${link.hash.slice(1)}-repeat`).remove();
  });

});

