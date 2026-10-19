// Tiny HTTP bridge: receives Grafana webhook (JSON), sends SMS via Twilio API.
// Reads credentials from environment variables.
const http = require("http");
const https = require("https");

const { TWILIO_SID, TWILIO_TOKEN, TWILIO_FROM, TWILIO_TO } = process.env;
const PORT = process.env.BRIDGE_PORT || 9001;

if (!TWILIO_SID || !TWILIO_TOKEN || !TWILIO_FROM || !TWILIO_TO) {
  console.error("Missing required TWILIO_* environment variables");
  process.exit(1);
}

function sendSMS(body) {
  const data = new URLSearchParams({ From: TWILIO_FROM, To: TWILIO_TO, Body: body }).toString();
  const req = https.request({
    hostname: "api.twilio.com",
    path: `/2010-04-01/Accounts/${TWILIO_SID}/Messages.json`,
    method: "POST",
    auth: `${TWILIO_SID}:${TWILIO_TOKEN}`,
    headers: { "Content-Type": "application/x-www-form-urlencoded", "Content-Length": data.length },
  }, (res) => {
    let body = "";
    res.on("data", (c) => body += c);
    res.on("end", () => console.log(`Twilio response ${res.statusCode}: ${body}`));
  });
  req.on("error", (e) => console.error("Twilio request failed:", e.message));
  req.write(data);
  req.end();
}

function formatAlert(payload) {
  const alerts = payload.alerts || [];
  return alerts.map((a) => {
    const status = a.status === "resolved" ? "RESOLVED" : "ALERT";
    const name = (a.labels && a.labels.alertname) || "Unknown";
    const summary = (a.annotations && a.annotations.summary) || "";
    return `${status}: ${name}${summary ? " - " + summary : ""}`;
  }).join("\n");
}

const server = http.createServer((req, res) => {
  if (req.method !== "POST") { res.writeHead(405); res.end(); return; }
  let body = "";
  req.on("data", (c) => body += c);
  req.on("end", () => {
    try {
      const payload = JSON.parse(body);
      const message = formatAlert(payload);
      if (message) {
        console.log(`Sending SMS: ${message}`);
        sendSMS(message);
      }
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end('{"ok":true}');
    } catch (e) {
      console.error("Parse error:", e.message);
      res.writeHead(400);
      res.end('{"error":"bad request"}');
    }
  });
});

server.listen(PORT, "127.0.0.1", () => console.log(`Grafana-Twilio bridge listening on 127.0.0.1:${PORT}`));
