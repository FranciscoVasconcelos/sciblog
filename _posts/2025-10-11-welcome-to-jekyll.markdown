---
layout: post
title:  "Fuck you Jekyll!"
date:   2025-10-11 11:16:18 +0100
categories: jekyll update
acronym: F
---

{% include mathjax.html %}

{% section TEST 0 %}

{% equation eq:test:ref %}
e=mc^2
{% endequation %}


{% section TEST 1 %}
{% section TEST 1 %}

{% equation eq:test:ref:2 %}
\pi^3 = 3
{% endequation %}

{% section TEST 2 %}

{% section FUCK 0%}

{% equation eq:test:ref:3 %}
e^3 = 7
{% endequation %}


<!-- If I want to do equations without labels just use mathjax normally with $$ equartion \notag$$ -->


I need counters for multiple envs:
 - sections
 - theorems
 - definitions
 - equations 
 - etc...
 
I want to be able to label by section, subsection, subsubsection, by page, etc... -> Enable options as a tag or as variables in the page variables


Use a command like so to label equations by section
\{\% label_by section equation \%\}



The other post does not have the variables available. 


Let us see how references {% ref eq:test:ref:3 %} work when we are writing {% ref eq:test:ref:9999 %} them together with text. 
