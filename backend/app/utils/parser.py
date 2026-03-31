import re

def simple_parse(text):
    amount = re.findall(r'\d+', text)
    return {
        "amount": int(amount[0]) if amount else 0,
        "category": "Others"
    }