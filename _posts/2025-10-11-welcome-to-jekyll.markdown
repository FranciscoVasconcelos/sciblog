---
layout: post
title:  "Fuck you Jekyll!"
date:   2025-10-11 11:16:18 +0100
categories: jekyll update
acronym: P
---


{% envcreate lemma 1 %}

{% ref sec:here %}

{% ref def:this:coco %}

This → {% ref some-label %} is a link to a section on other page

This is a link to an equation {% ref eq:pi:3 %}

{% section "this is a section" level=0 label=sec:here %}
{% section "this is another section" level=1 label=sec:ther %}

{% envlabel lemma lemma:this:theorem true %}
This is a lemma for einstein
$$
E=mc^2
$$

some other equation with a new tag 

{% equation eq:pi:3 %}
\pi = \sum_k \pi_k^{\theta_k}
{% endequation %}

{% endenvlabel %}

{% equation eq:wtf %}
\pi = \sum_k \frac{\pi_k^{\theta_k}}{\rho_k}
{% endequation %}

{% envproof lemma:this:theorem %}
This is a proof for the lemma 


$$
A = \int\sum_k a_k(x)v_k(x,y)dx
$$
{% endenvproof %}


