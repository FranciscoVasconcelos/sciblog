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

  SetOnGetElement(refElem, callback) {
    const url = refElem.getAttribute("url");
    const { domain, relativePath, anchor } = this.parseURL(url);

    if (callback(document, anchor, refElem)) return;

    const iframe = this.iframes[relativePath];
    if (!iframe) return;

    const loaded = iframe.contentDocument && iframe.contentDocument.readyState === 'complete';

    if (!loaded) {
      iframe.addEventListener('load', () => {
        this.extractAndInjectCSS(iframe);
        const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
        callback(iframeDoc, anchor, refElem);
      });

      iframe.className = "iframe-container";
      iframe.style.display = 'none';
      iframe.src = domain + relativePath;
      document.body.appendChild(iframe);

    } else {
      const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
      callback(iframeDoc, anchor, refElem);
    }
  }

  renameIdsRecursively(element, suffix = "-repeat") {
    if (element.id) element.id += suffix;

    Array.from(element.children).forEach(child => {
      this.renameIdsRecursively(child, suffix);
    });
  }

  displayInsideElem(iframeDoc, id, refElem) {
    const elem = iframeDoc.getElementById(id);
    if (!elem) return false;

    const clone = elem.cloneNode(true);
    refElem.appendChild(clone);
    this.renameIdsRecursively(clone);

    return true;
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
            if (e.code === this.key) {
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

new HoverTagKeyListener('a', 'Space', (el) => {
    console.log("Overing and pressing space");
    console.log(el);
});

