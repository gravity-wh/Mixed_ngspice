import sys, json
stdout_file = sys.argv[1]
json_file = sys.argv[2]
try:
    with open(stdout_file) as f:
        text = f.read()
    idx = text.find('--- JSON SUMMARY ---')
    if idx >= 0:
        json_str = text[idx:].split('\n', 2)[-1].strip()
        data = json.loads(json_str)
        with open(json_file, 'w') as jf:
            json.dump(data, jf)
        print(data.get('verdict', 'ERROR'))
    else:
        print('ERROR')
except Exception as e:
    print('ERROR')
