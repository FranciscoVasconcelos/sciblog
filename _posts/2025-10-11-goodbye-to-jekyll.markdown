---
layout: post
title:  "Welcome to Jekyll!"
date:   2025-10-11 11:16:18 +0100
categories: jekyll update
acronym: P
---

<script>
{% include box.js %}
</script>


<!-- Create theorem env labeled by section -->
{% envcreate theorem 0 solution %}

<!-- Create definition env labeled by subsection -->
{% envcreate definition 1 %}



{% include mathjax.html %}

{% section TEST 0 %}

<!-- Create a theorem  -->
{% envlabel theorem theo:this:theorem true %}
This is a theorem for einstein
$$
e=mc^2
$$
{% endenvlabel %}



$$
\pi = 3
$$


{% section subsection 1 %}

<!-- Create a definition  -->
{% envlabel definition def:this:coco %}
We define the coco

$$
c = \sum_i \theta_i\eta_i\label{the:coco:eq}
$$


{% endenvlabel %}



{% ref theo:this:theorem %}
{% ref def:this:coco %}


{% envproof theorem theo:this:theorem %}
This is a crappy proof of the theorem. Use $\eqref{the:coco:eq}$ to show that 

$$
A = \sqrt{\sum_i\sum_j f_i(a_i,\beta_j)}
$$
{% endenvproof %}





