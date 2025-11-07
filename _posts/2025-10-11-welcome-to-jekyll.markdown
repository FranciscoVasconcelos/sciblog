---
layout: side-notes
title:  "Fuck you Jekyll!"
date:   2025-10-11 11:16:18 +0100
categories: jekyll update
acronym: P
---

<!-- <style> -->
<!-- </style> -->

{% ref sec:here %}

{% ref def:this:coco %}

This → {% ref some-label popup=true %} is a link to a section on other page

This is a link to an equation {% ref eq:pi:3 %}

{% section "this is a section" level=0 label=sec:here %}
{% section "this is another section" level=1 label=sec:ther %}


{% equation eq:wtf %}
\pi = \sum_k \frac{\pi_k^{\theta_k}}{\rho_k}
{% endequation %}

{% envproof lemma:this:theorem %}
This is a proof for the lemma 


$$
A = \int\sum_k a_k(x)v_k(x,y)dx
$$
{% endenvproof %}

**These are equations on a grid:**
{% gridequations ncols=2 %}
\begin{split}
E = mc^2\\\EE = mc^2
\end{split},\\F = ma,\\a^2 + b^2 = c^2,\\a^2 + b^2 = c^2
{% endgridequations %}

This is some text with{% note %} This is the text of the side note. With an equation $E=mc^2$ This is the text of the side note. With an equation $E=mc^2$ This is the text of the side note. With an equation $E=mc^2$ {% endnote %} This is some textThis is some textThis is some textThis is some textThis is some textThis is some textThis is some textThis is some textThis is some text
This is some text with{% note %} This is the text of the side note. With an equation $E=mc^2$ {% endnote %}

**This is some repeated note:**
<repeat-element> math-ref-note-Q-2 </repeat-element>

Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.



some text{% note %} Let us try another fucking side note. I want to see if this goes away 
{% theorem theo:7666 %}
This is a theorem inside of a side note. This is some equation inside a theorem inside a side note 

{% equation eq:9999 %}
A = \int \mathcal{L}(\phi,\dot{\phi})\ dt
{% endequation %}

{% endtheorem %}
{% endnote %}


test some other text{% note %} This is an inline note numbered by the entire document {% endnote %}


{% lemma lemma:this:theorem true %}
This is a lemma for einstein
$$
E=mc^2
$$

some other equation with a new tag 

{% equation eq:pi:3 %}
\pi = \sum_k \pi_k^{\theta_k}
{% endequation %}

{% endlemma %}


This is a link with a popup attached: {% ref lemma:this:theorem popup=true %}

{% includetex here %}


**This is a repeated theorem from another page**
{% repeat theo:this:theorem %}


{% includemsgpack test.msgpack cols=2 %}
