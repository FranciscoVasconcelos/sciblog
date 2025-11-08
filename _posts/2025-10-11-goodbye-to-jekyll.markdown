---
layout: post
title:  "Welcome to Jekyll!"
date:   2025-10-11 11:16:18 +0100
categories: jekyll update
acronym: P
section_with_acronym: true
---



This → {% ref some-label %} is a link to a section 




<!-- Create a theorem  -->
{% theorem theo:this:theorem true %}
This is a theorem for einstein
$$
e=mc^2
$$

some other equation with a new tag 

{% equation eq:pi:5 %}
\pi = \sum_k \pi_k^{\theta_k}
{% endequation %}

{% endtheorem %}

{% align labels="eq:pi:777;eq:theta" %}
\pi = \sum_k \pi_k^{\theta_k}\\\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
{% endalign %}



{% section "A section with spaces" level=0 %}
{% section "Anoter section with spaces" level=0 %}

{% section firstsubsection level=1 label=first-label %}

# **bold header**



{% section "This is a named section with spaces" level=1 label=ugly-section %}

<!-- Create a definition  -->
{% definition def:this:coco false %}

This is a definition labeled by subsection

We define the coco

$$
c = \sum_i \theta_i\eta_i\label{the:coco:eq}
$$


{% enddefinition %}



{% ref theo:this:theorem %}
{% ref def:this:coco %}


{% envproof theo:this:theorem %}
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
{% section other-other-subsubsection level=3 %}

{% ref eq:pi:3 %}


{% ref sec:here %}



{% theorem theo:this:theorem:other true %}
This is a theorem for einstein
$$
e^x = \sum_{k=0}^\infty \frac{x^k}{k!}
$$

some other equation with a new tag 

{% equation eq:pi:7 %}
f(x) = \sum_k a_k x^k
{% endequation %}

{% endtheorem %}

{% envproof theo:this:theorem:other %}
This is a crappy proof of the theorem. Use $\eqref{the:coco:eq}$ to show that 

{% subequations %}

{% equation %}
B = \sum_\ell \sqrt{\sum_i\sum_j f_i(\frac{a_i}{s_\ell},\beta_j)}^3
{% endequation %}

some text here. 
{% equation eq:wtf:2 %}
\pi = \sum_k \pi_k^{\theta_k}
{% endequation %}

{% endsubequations %}

{% endenvproof %}

{% ref section-P-1. %}

This is a repeated theorem:
{% repeat theo:this:theorem %}

This is a repeated equation:
{% repeat eq:pi:3 %}


{% proofref theo:this:theorem %}

{% includetex %}

{% ref eq:wtf:2 %}

{% includetable table.msgpack %}

<!-- <prooflabel> math-ref-theo:this:theorem:proof</prooflabel> -->
