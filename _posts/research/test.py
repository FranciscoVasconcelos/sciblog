'''
This script is used to ilustrate how data can be easily written to a .msgpack file with the use of a python runner script.
The runner reads the `data_out` variable and writes it to a .msgpack file located at a cloned location. 
This cloned location is the current directory where we replace _posts with _posts.msgpack
'''

data_out = [
  {
    "type": "bar",
    "data": {
      "labels": ["A", "B", "C"],
      "datasets": [
        { "label": "Dataset 1", "data": [10, 20, 30], "backgroundColor": "rgba(54, 162, 235, 0.6)" }
      ]
    },
    "options": { "responsive": True }
  },
  {
    "type": "line",
    "data": {
      "labels": ["Jan", "Feb", "Mar"],
      "datasets": [
        { "label": "Dataset 2", "data": [5, 15, 25], "borderColor": "rgba(255,99,132,1)" }
      ]
    },
    "options": { "responsive": True }
  }
]

