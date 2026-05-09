import urllib.request, json, time

body = json.dumps({
    "model": "command-r7b-arabic",
    "messages": [{"role": "user", "content": "Reply with the single word: ready"}],
    "stream": False,
    "options": {"num_predict": 5}
}).encode()

req = urllib.request.Request(
    "http://localhost:11434/api/chat",
    data=body,
    headers={"Content-Type": "application/json"},
    method="POST"
)

print("Sending request...")
t = time.time()
with urllib.request.urlopen(req, timeout=300) as r:
    data = json.loads(r.read())
    elapsed = time.time() - t
    print(f"Time: {elapsed:.1f}s")
    print(f"Reply: {data['message']['content']}")
    print("SUCCESS — model is working!")
