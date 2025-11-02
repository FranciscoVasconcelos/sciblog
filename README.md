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

 - [x] Added the `popup` class to the reference link to the 
    + [x] Javascript that adds an event listener for elements of class popup

 
**Overlay**
 - [x] Added a `overlay` class to the `<div>` 
    + [x] Added a CSS style for `overlay`


display-mode: inplace/overlay/side/popup (default: inplace)


The user can make a link to have a pop-up appears on hover. Just use the ref tag with `popup=true` passed as an argument: 

```markdown
{% ref label:to:something popup=true %}
```


