---
layout: post
title:  "Welcome to Jekyll!"
date:   2025-10-11 11:16:18 +0100
categories: jekyll update
acronym: P
section_with_acronym: true
---



{% envoptions equation 2 %}

<!-- Create theorem env labeled by section 
This add the css files -->
{% envcreate theorem 0 solution %}

<!-- Create definition env labeled by subsection -->
{% envcreate definition 1 %}





This → {% ref some-label %} is a link to a section 



{% section "A section with spaces" level=0 %}

{% section firstsubsection level=1 label=first-label %}
<!-- Create a theorem  -->
{% envlabel theorem theo:this:theorem true %}
This is a theorem for einstein
$$
e=mc^2
$$

some other equation with a new tag 

{% equation eq:pi:3 %}
\pi = \sum_k \pi_k^{\theta_k}
{% endequation %}

{% endenvlabel %}


# **bold header**



{% section "This is a named section with spaces" level=1 label=ugly-section %}

<!-- Create a definition  -->
{% envlabel definition def:this:coco true %}

This is a definition labeled by subsection

We define the coco

$$
c = \sum_i \theta_i\eta_i\label{the:coco:eq}
$$


{% endenvlabel %}



{% ref theo:this:theorem %}
{% ref def:this:coco %}


{% envproof theorem theo:this:theorem %}
This is a crappy proof of the theorem. Use $\eqref{the:coco:eq}$ to show that 

{% equation %}
A = \sqrt{\sum_i\sum_j f_i(a_i,\beta_j)}
{% endequation %}

some text here. 
{% equation %}
\pi = \sum_k \pi_k^{\theta_k}
{% endequation %}
And if I add <a href="www.fuck.com">this</a>


{% endenvproof %}


{% section othersubsection level=1 label=some-label %}
{% section other-other-subsection level=2 label=some-other-label %}

{% ref eq:pi:3 %}


{% ref sec:here %}


[Link to a page]({% link _posts/2025-10-11-welcome-to-jekyll.markdown %})
