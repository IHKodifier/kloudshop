import re
with open(r'e:\Non_Office\Dev_Space\vibe_skool\kloudShop\specifications\BKP-06-schema-inventory.md', 'r', encoding='utf-8') as f:
    content = f.read()
content = re.sub(
    r'\|\s*`06o-index-strategy\.md`\s*\|\s*⏳ Awaiting\s*\|\s*All tables\s*\|\s*CREATE INDEX DDL \+ prose[^|]*\|', 
    '| `06o-index-strategy.md`               | ✅ Generated      | All tables  | CREATE INDEX DDL + prose, audit completed with 3 missing state machine indexes identified. |', 
    content
)
with open(r'e:\Non_Office\Dev_Space\vibe_skool\kloudShop\specifications\BKP-06-schema-inventory.md', 'w', encoding='utf-8') as f:
    f.write(content)
