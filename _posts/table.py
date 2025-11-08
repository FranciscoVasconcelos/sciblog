
import msgpack

# Example table data — a list of dictionaries
data_out = [
    {"id": 1, "name": "Alice", "age": 30, "country": "USA"},
    {"id": 2, "name": "Bob", "age": 25, "country": "UK"},
    {"id": 3, "name": "Charlie", "age": 35, "country": "Canada"},
]

# # File path for output
# output_file = "table.msgpack"
#
# # Write data to MessagePack file
# with open(output_file, "wb") as f:
#     packed = msgpack.packb(table_data, use_bin_type=True)
#     f.write(packed)
#
# print(f"MessagePack table written to: {output_file}")
