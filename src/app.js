import express from "express";

export const app = express();
const version = process.env.APP_VERSION || "dev";

export function add(a, b) {
  return a + b;
}

app.get("/", (req, res) => {
  res.send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Personal Portfolio — ITSD 85 CI/CD Lab</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      min-height: 100vh;
      padding: 2rem 1.25rem;
      font-family: system-ui, -apple-system, sans-serif;
      background: #0f172a;
      color: #f8fafc;
      line-height: 1.6;
    }
    .container {
      max-width: 760px;
      margin: 0 auto;
      display: grid;
      gap: 1.25rem;
    }
    .card {
      padding: 1.75rem;
      border-radius: 16px;
      background: #1e293b;
      border: 1px solid #334155;
      box-shadow: 0 12px 30px rgba(0, 0, 0, 0.25);
    }
    .hero { text-align: center; }
    .badge {
      display: inline-block;
      margin-bottom: 0.9rem;
      padding: 0.3rem 0.85rem;
      border-radius: 999px;
      background: #0f172a;
      color: #38bdf8;
      font-size: 0.8rem;
      word-break: break-all;
    }
    h1 { font-size: 1.85rem; margin-bottom: 0.35rem; }
    .subtitle { color: #94a3b8; font-size: 1rem; margin-bottom: 1rem; }
    .nav { display: flex; justify-content: center; gap: 1rem; flex-wrap: wrap; }
    .nav a {
      padding: 0.5rem 1rem;
      border-radius: 8px;
      background: #0ea5e9;
      color: #0f172a;
      font-weight: 600;
      font-size: 0.9rem;
      text-decoration: none;
    }
    .nav a.secondary {
      background: #0f172a;
      color: #e2e8f0;
      border: 1px solid #334155;
    }
    h2 { font-size: 1.1rem; margin-bottom: 0.75rem; color: #38bdf8; }
    p { color: #cbd5e1; font-size: 0.95rem; }
    .tags { display: flex; flex-wrap: wrap; gap: 0.5rem; }
    .tag {
      padding: 0.35rem 0.75rem;
      border-radius: 8px;
      background: #0f172a;
      border: 1px solid #334155;
      font-size: 0.85rem;
      color: #e2e8f0;
    }
    .projects { display: grid; gap: 0.85rem; }
    .project {
      padding: 1rem;
      border-radius: 10px;
      background: #0f172a;
      border: 1px solid #334155;
    }
    .project h3 { font-size: 1rem; margin-bottom: 0.25rem; }
    .footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 0.5rem;
      color: #94a3b8;
      font-size: 0.85rem;
      padding: 0.5rem 0.25rem;
    }
    .footer a { color: #38bdf8; text-decoration: none; }
    .footer a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="container">
    <header class="card hero">
      <p class="badge">ITSD 85 CI/CD Lab · Deployed version: ${version}</p>
      <h1>Your Name</h1>
      <p class="subtitle">Software Development Student · Web &amp; DevOps Enthusiast</p>
      <div class="nav">
        <a href="#projects">Projects</a>
        <a class="secondary" href="#contact">Contact</a>
      </div>
    </header>

    <section class="card" id="about">
      <h2>About Me</h2>
      <p>
        I build clean web applications and automate their testing and deployment using
        Git, GitHub Actions, Docker, and Linux servers.
      </p>
    </section>

    <section class="card" id="skills">
      <h2>Skills</h2>
      <div class="tags">
        <span class="tag">JavaScript</span>
        <span class="tag">Node.js &amp; Express</span>
        <span class="tag">HTML &amp; CSS</span>
        <span class="tag">Git &amp; GitHub Actions</span>
        <span class="tag">Docker &amp; Compose</span>
        <span class="tag">Ubuntu Linux</span>
      </div>
    </section>

    <section class="card" id="projects">
      <h2>Projects</h2>
      <div class="projects">
        <article class="project">
          <h3>Automated CI/CD Web Pipeline</h3>
          <p>Zero-cost pipeline that lints, tests, containerizes, and deploys every merge to main.</p>
        </article>
        <article class="project">
          <h3>REST Health &amp; Math API</h3>
          <p>Lightweight Express service with automated node:test checks and Docker health monitoring.</p>
        </article>
      </div>
    </section>

    <section class="card" id="contact">
      <h2>Contact</h2>
      <p>Email: <a href="mailto:you@example.com" style="color:#38bdf8;text-decoration:none">you@example.com</a> · GitHub: <a href="https://github.com" style="color:#38bdf8;text-decoration:none">github.com/your-username</a></p>
    </section>

    <footer class="footer">
      <span>Status: <strong style="color:#4ade80">Online</strong></span>
      <a href="/health">/health JSON</a>
    </footer>
  </div>
</body>
</html>`);
});

app.get("/health", (req, res) => {
  res.json({ status: "ok", version });
});

app.get("/api/add", (req, res) => {
  const a = Number(req.query.a);
  const b = Number(req.query.b);
  if (Number.isNaN(a) || Number.isNaN(b)) {
    return res.status(400).json({ error: "a and b must be numbers" });
  }
  res.json({ result: add(a, b) });
});
