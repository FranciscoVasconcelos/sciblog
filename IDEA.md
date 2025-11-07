



I want to be able to easily integrate python code in my html blog

- There should be no extra effort 

Strategies:
- Generate the data needed store in some *nice* format then read the file and use a JavaScript library to display the content
- Use python running directly on the browser with PyScript. 
    + Problems:
        - Reloading the page reexecutes the code, which is bad for slow running code
    + Advantages
        - Running locally displays the exact same plots as running in the browser (what you see is what you get)


How can I avoid having to run the code multiple times in the browser until I reach a nice plot?

Where should I define the styling/propeties/options of the plot? Should I define in the python script? Or in the markdown file?

- Define the data and its options in the python script. 
- Write to a `*.bson` file 
- Within JavaScript load that file and use `Plotly.js` or `chart.js` to plot the stuff in the browser.

- The script generates a single `.bson` file with all the data and options and the user optionally includes that data using a Jekyll tag. 


- To do side-by-side plots I need to use multiple divs and a **CSS** `flexbox`

- Need to remenber to save the data in a `.bson` file.

## Side-by-side plots 

To do plots in a grid I will need to automate the html layout. 

- Ruby script to insert the divs with flexbox 
- JavaScript to read the specified file and display using `chart.js` or `plotly.js` 



{% include-python path/to/code.py %}

<!-- {% endinclude-python %} -->


### TODO 

- Ruby script:
    + Generate `JavaScript`
        * Read the `.bson` file 
    + Generate `HTML`
        * Plots on a grid
        * Estimate the percentage from the given column number 


```css
.plot-container {
    flex: 1 1 #{100/cols-2}%;
    height: 300px;
}

.grid-container {
    display: flex;
    flex-wrap: wrap;
    gap: 10px; /* Space between plots */
}
```

# Python Code Strategy

To easily incorporate python code plots/charts into my blog I will need to generate and save the data for the 

To write the data to a `.msgpack` do the following: 

```python
import msgpack

# Data structure to write
data = [...]
    
# Write to MessagePack file
with open('charts.msgpack', 'wb') as f:
    msgpack.pack(data, f)

print("Data successfully written to charts.msgpack")

# Optional: Read it back to verify
with open('charts.msgpack', 'rb') as f:
    loaded_data = msgpack.unpack(f)
    print("\nVerification - Data read back:")
    print(loaded_data)
```


Should I create a special script that writes in the correct place...

I want to write to `_posts.msgpack/relative/path/to/code/` => Replace `_posts`, with `_posts.msgpack` in the path of the python script [ ]


The goal is to create a script that replaces python and writes the data to the correct directory



# TODO `runner.py`

- Make the runner available as an executable by adding it to the path when we enter the directory:

Execute this after entering the directory
```shell
export PATH="./bin:$PATH"
```
