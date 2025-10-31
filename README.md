# Scientific Blog


Creating a plugin for writing blogs instead of pdf documents. The goal is to be able to easily reference contents in other posts as well as creating and managing sections, subsections. 

We also care about referencing and labeling:
 - Theorems,Lemmas,Propositions
 - Exercises
 

Automatic styling and javascript for hidden boxes:
 - toggle show/hide proofs
 - toggle show/hide solutions



In the future I will want to implement easy ways to write code and add it to each post.



### IMPORTANT 

As of now (11/10/2025) the Brave browser cannot render mathjax...
I am using firefox and chromium (which work fine)

### Content Types

 - Overlay (appears on top of the main content overlaying it) => Click to show
 - Inline/Inplace (Appears within the main content inplace) => Can be hidden by default
 - Side (Appears to the side e.g. side-note) => Clik to display next to the clicked element
 - Popup (appears as a Popup) => Hover to display content

Inplace, side and popup need a link to be displayed.

**Popup**

 - [] Add javascript at the end of the html page: add the element to the comicBallon class.
 
**Overlay**
 - [] Javascript to change the syle of the element
 - [] Add that javascript to the end of the html page


display-mode: inplace/overlay/side/popup (default: inplace)

If the display-mode is set in the general configuration file then I only need to change the CSS style for the case of the overlay. 

Change the style of all the elements 
```js
function applyStyles(element, styles) {
    Object.entries(styles).forEach(([property, value]) => {
        element.style[property] = value;
    });
}

// Usage:
const #{envname}Box = document.querySelector('.#{envname}-box');
if (#{envname}) {
    applyStyles(lemmaBox, {
        display: 'none',
        position: 'fixed',
        top: '50%',
        left: '50%',
        transform: 'translate(-50%, -50%)',
        zIndex: '1000',
        width: '90%',
        maxWidth: '1000px',
        animation: 'fadeIn 0.4s ease-out'
    });
}
```
I could also just append to the style. Create class overlay 

```css
.overlay{

}
```

For the ballon/popup need to add all the elements of that class to the balloon 

```js
    document.getElementById("#{anchor}");
```

Add all elements
```js
elems = document.getElementsByClassName("#{envname}-box");
elems.forEach((elem)=>{
    comicBallon.addBalloon(elem);
});
```


