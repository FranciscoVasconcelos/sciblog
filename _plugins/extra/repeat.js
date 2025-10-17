  const IframesDict = {};
  console.log(postsLinks);

  for(let i = 0; i < postsLinks.length; i++){
    const iframe = document.createElement("iframe");
    IframesDict[postsLinks[i]] = iframe;
  }

  function parseURL(url) {
  try {
    const urlObj = new URL(url);
    const domain = urlObj.origin;
    const relativePath = urlObj.pathname + urlObj.search;
    const anchor = urlObj.hash ? urlObj.hash.slice(1) : '';
    
    return {domain,relativePath,anchor};
  } catch (e) {
    return {
      error: 'Invalid URL',
      message: e.message
    };
  }
}
    

    function extractAndInjectCSS(iframe) {

        const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
        const styles = [];
        const cssContainer = document.createElement('div');
        
        // Get all stylesheets from the iframe
        const styleSheets = iframeDoc.styleSheets;
        for (let i = 0; i < styleSheets.length; i++) {
            try {
                const sheet = styleSheets[i];
                
                // If it's an external stylesheet, create a link tag
                if (sheet.href) {
                    const link = document.createElement('link');
                    link.rel = 'stylesheet';
                    link.href = sheet.href;
                    styles.push(link.outerHTML);
                } 
                // If it's an inline style, get the CSS rules
                else if (sheet.cssRules) {
                    let cssText = '';
                    for (let j = 0; j < sheet.cssRules.length; j++) {
                        cssText += sheet.cssRules[j].cssText + '\n';
                    }
                    if (cssText) {
                        styles.push(`<style>${cssText}</style>`);
                    }
                }
            } catch (e) {
                // Can't access cross-origin stylesheets
                console.warn('Could not access stylesheet:', e);
            }
        }
        
        // Get all inline style tags
        const styleTags = iframeDoc.querySelectorAll('style');
        styleTags.forEach(tag => {
            styles.push(tag.outerHTML);
        });
        
        cssContent = styles.join('\n');
        if(cssContent){
          cssContainer.innerHTML = cssContent;
          document.head.appendChild(cssContainer);
        }
    }

  function renameIdsRecursively(element, suffix = "-repeat") {
    // Rename the current element's ID if it exists
    if (element.id) {
      element.id = element.id + suffix;
    }
  
    // Recursively process all children
    Array.from(element.children).forEach(child => {
      renameIdsRecursively(child, suffix);
    });
  }
  
  
    function displayElementAfter(iframe,anchor,refElem){
        // get element with id=anchor from iframe
        const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
        elem = iframeDoc.getElementById(anchor);
        // Rename all ids of descendants
        renameIdsRecursively(elem,suffix="-repeat");
          

        const content = document.createElement('div');
        content.innerHTML = elem.outerHTML;
        refElem.insertAdjacentElement('afterend', content);
    }

  function getElement(refElem){
    const url = refElem.getAttribute("url");
    const origin = window.location.origin;
    let { domain, relativePath, anchor } = parseURL(url);
 
    if(typeof domain === 'undefined'){
      domain = origin;
      [relativePath,anchor] = url.split("#");
    }

    // Ignore if key does not exists
    if((typeof IframesDict[relativePath]) === 'undefined') return;
    
    iframe = IframesDict[relativePath];
    loaded = (iframe.contentDocument && iframe.contentDocument.readyState === 'complete');
    if(!loaded){
      iframe.addEventListener('load',function() {
        extractAndInjectCSS(iframe);
        getElement(refElem);
      });

      iframe.className = "iframe-container";
      iframe.style.display = 'none'; // Make the iframe invisible
      iframe.src = domain + relativePath;

      document.body.appendChild(iframe);
    }else{
      displayElementAfter(iframe,anchor,refElem);
    }

  }
    const elements = document.getElementsByTagName('repeat-element');

    for(const elem of elements){
      getElement(elem);
    }
