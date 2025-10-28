---
layout: default
title: Page with Side Notes
---

    <style>
        body {
            font-family: 'Georgia', serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 20px;
            background: #fafafa;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            position: relative;
        }

        .content {
            max-width: 650px;
            margin: 0 auto;
            padding: 40px 20px;
            background: white;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        h1 {
            font-size: 2.5em;
            margin-bottom: 0.5em;
            color: #2c3e50;
        }

        p {
            margin-bottom: 1.5em;
        }

        /* Side note styling */
        .sidenote {
            float: right;
            clear: right;
            margin-right: -280px;
            width: 240px;
            font-size: 0.9em;
            line-height: 1.4;
            padding: 10px 15px;
            background: #f8f9fa;
            border-left: 3px solid #3498db;
            color: #555;
        }

        /* Reference number in main text */
        .sidenote-ref {
            position: relative;
            top: -0.5em;
            font-size: 0.8em;
            color: #3498db;
            cursor: pointer;
            font-weight: bold;
            padding: 0 2px;
        }

        /* Mobile responsive */
        @media (max-width: 1100px) {
            .sidenote {
                float: none;
                margin: 1.5em 0;
                margin-right: 0;
                width: auto;
            }
        }

        @media (max-width: 768px) {
            .content {
                padding: 20px 15px;
            }

            h1 {
                font-size: 2em;
            }
        }

        /* Alternative inline note style */
        .inline-note {
            display: inline-block;
            padding: 5px 10px;
            background: #fff3cd;
            border-left: 3px solid #ffc107;
            margin: 0.5em 0;
            font-size: 0.95em;
        }
    </style>
    <div class="container">
        <div class="content">
            <h1>Understanding Side Notes</h1>
            
            <p>
                Side notes are a powerful way to provide additional context without interrupting the main narrative flow.<span class="sidenote-ref">1</span>
                <span class="sidenote">This technique has been used in academic publishing for centuries, most notably in Edward Tufte's books on information design.</span>
                They allow readers to dive deeper into specific topics while maintaining the ability to follow the primary argument.
            </p>

            <p>
                When implementing side notes in web design, there are several approaches to consider.<span class="sidenote-ref">2</span>
                <span class="sidenote">The CSS float property is used here, but modern layouts could also use CSS Grid or flexbox for more complex arrangements.</span>
                The key is ensuring that the notes are visually connected to their reference points but don't disrupt reading flow.
            </p>

            <p>
                In Jekyll, you can create reusable components for side notes using includes or custom Liquid tags.<span class="sidenote-ref">3</span>
                <span class="sidenote">For example: <code>\{\% include sidenote.html ref="1" text="Your note here" \%\}</code></span>
                This makes it easy to maintain consistency across your site.
            </p>

            <p>
                Another common pattern is the inline note, which appears within the content area itself:
                <span class="inline-note">
                    <strong>Note:</strong> This style works better for shorter annotations that don't require margin space.
                </span>
                This approach is more mobile-friendly and requires less horizontal space.
            </p>

            <p>
                The responsive design ensures that on smaller screens, side notes collapse into the main content area.<span class="sidenote-ref">4</span>
                <span class="sidenote">Below 1100px viewport width, the notes stack inline with the content to ensure readability on tablets and phones.</span>
                This maintains readability across all device sizes without sacrificing the enhanced experience on larger displays.
            </p>
        </div>
    </div>
