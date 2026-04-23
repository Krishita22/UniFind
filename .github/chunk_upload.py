import sys
import urllib.parse
import base64

chunk_path = sys.argv[1]
dest = sys.argv[2]
chunk_num = sys.argv[3]

with open(chunk_path, "rb") as f:
    data = base64.b64encode(f.read()).decode()

body = urllib.parse.urlencode({
    "secret": "unifind_deploy_2026",
    "action": "chunk",
    "path": dest,
    "chunk": chunk_num,
    "data": data,
})

with open("/tmp/chunk_body.txt", "w") as f:
    f.write(body)
