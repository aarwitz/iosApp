import re

path = "EliteProAIDemo 2/AppStore.swift"
with open(path, 'r') as f:
    content = f.read()

original_len = len(content)

# 1. Remove the demo conversations block
# Starts at "        // Demo conversations" and ends before "        // Demo communities"
content, n1 = re.subn(
    r'        // Demo conversations\s*\n        self\.conversations = \[.*?\n        \]\n',
    '        // Conversations loaded from API\n        self.conversations = []\n',
    content,
    flags=re.DOTALL
)
print(f"Conversations block removed: {n1} replacement(s)")

# 2. Remove demo friends block
# Ends with ] + Self.generateBulkFriends(count: 230) 
content, n2 = re.subn(
    r'        // Demo friends.*?\n        self\.friends = \[.*?\] \+ Self\.generateBulkFriends\(count: \d+\)\n',
    '        // Friends loaded from API\n        self.friends = []\n',
    content,
    flags=re.DOTALL
)
print(f"Friends block removed: {n2} replacement(s)")

# 3. Remove demo discoverableFriends block
content, n3 = re.subn(
    r'        // Demo discoverable friends.*?\n        self\.discoverableFriends = \[.*?\n        \]\n',
    '        // Discoverable users loaded from API\n        self.discoverableFriends = []\n',
    content,
    flags=re.DOTALL
)
print(f"DiscoverableFriends block removed: {n3} replacement(s)")

print(f"Original length: {original_len} chars")
print(f"New length: {len(content)} chars")
print(f"Removed: {original_len - len(content)} chars")

with open(path, 'w') as f:
    f.write(content)

print("Done!")
