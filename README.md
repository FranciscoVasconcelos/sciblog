# Scientific Blog

I have been writing my Scientific/Math notes on latex, in particular using Overleaf. However I tend to write a lot and the documents start to become ever so long and ever so many which means it becomes very difficult to organise all documents together. Another reason I have decided to use html is that it is very easy to incorporate running code, I can easily incorporate plots and graphical content. This way I can incorporate both theory and applications in the same place, which makes the conception of ideias into pratical applications much more spontaneous. 

The ability to write cross-referencing posts permits me to organise my notes easily, being able to reference or repeat anything I have written before. Adding to those features another feature is the ability to have side-content and/or hidable content that we can easily introduce by either changing the config file or by adding arguments to the corresponding tag.

## Features 

- Latex rendering to HTML (using a `ruby` script that converts Latex to Liquid tags/blocks)
- Automatic numbering of sections, subsections, ...
- Customisable environments using the config file (`_config.yml`)
- Repeatable content (use the `repeat` tag).
- Post cross-referencing (the user can reference anything of any post from any post, use the `ref` tag) 
- `fetch.html` and `split.html` webpages injected into the blog posts
- Ability to easily hide and show content
- Side content for adding notes 
- Different content types: `display-mode: inplace/overlay/side` (default: `inplace`)
    + *Overlay* (Appears in the middle of the screen its position fixed)
    + *Inplace* (Appears at the location of the liquid tag)
    + *Side* (Content can be put on the side)
    + *Pop-up* (Links can be made to show pop-up on hover) set `popup=true` 

**`Fetch.html`** 
Has a sidebar with buttons to fetch certain elements by the names defined in the config file.

**`Split.html`** 
The user can look at two posts at the same time. The link clicks are intercepted and both pages scroll to the link's content. Clicking the middle mouse button on a link will folow that link in all pages except the current (i.e. the one where the cursor has clicked the link)

**Links with Popups**
```html
    {% ref label:to:something popup=true %}
```

**Repeat Content**
```HTML
    {% repeat label:to:content popup=true %}
```
or 
```tex
    \repeat{label:to:content}[popup=true]
```

## TODO 

- [ ] On hover links with popup the layout/style of all the content gets fucked (It does not happen when the element is in the current page)
    (solution?) Use the same layout for all posts!

- [ ] Use the bibliography jekyll library to reference books, articles, journals, etc...

- [ ] (split) Add option to follow links like open in new tab 
    + Consider that I have the same open page on both sides of split. I want that when I click on a link only one of the pages follows that link. 
    + Either:
        - Ignore follow link of page of clicked link or 
        - Ignore follow link of rightmost or leftmost page
        - Intercept mouse button middle click 

- [ ] Nicer pop-up?
- [ ] Default configuration file.
- [ ] Repeatable sections and subsections? 
- [x] Hide envs on deselect envs in `fetch.html`

- [x] Prevent the new tab to open when I press a link with middle mouse button
- [ ] Second repeats will have the same id (Do I want that???)

- [ ] Using `Chart.js` and flex boxes the content gets all fucked up. It does not adjust automatically.
- [ ] Include msgpack tag is being called with path=> `_posts/research/2025-11-07-my-research-note.md/#excerpt` and filename=> `test.msgpack`
**Cloudflare**
- [ ] Side content is not being rendered in the right place.
- [ ] The table is also not being rendered. 
- [ ] Clicking a link to the own page refreshes it. And the ram gets more used by the webpage!
- [ ] The website is eating much more ram making the computer slow. 

- [x] Rendering sections from iframes is ommiting text specifically `{% ref some-label popup=true %}` does not show 'of theorem'


### IMPORTANT 

As of 11/10/2025 the Brave browser cannot render mathjax...
I am using firefox and chromium (which work fine)
