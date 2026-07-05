const $ = id => document.getElementById(id);
let state = { caps: null, plan: null, manifest: null, activeJobId: null };

function log(msg) {
  const line = `[${new Date().toLocaleTimeString()}] ${msg}`;
  console.log(line);
  $("log").textContent = `${line}\n${$("log").textContent}`.slice(0, 9000);
}

async function api(path, options = {}) {
  const res = await fetch(path, { headers: { "Content-Type": "application/json" }, ...options });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

function escapeHtml(s) {
  return String(s ?? "").replace(/[&<>'"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"}[c]));
}

function renderCaps(caps) {
  state.caps = caps;
  const modes = caps.generationModes || [];
  $("mode").innerHTML = modes.map(m => `<option value="${m.id}" ${m.available ? "" : "disabled"}>${m.label}${m.available ? "" : " — unavailable"}</option>`).join("");
  const preferred = modes.find(m => m.id === "wan-video" && m.available)
    || modes.find(m => m.id === "animatediff" && m.available)
    || modes.find(m => m.id === "comfy-api-workflow" && m.available)
    || modes.find(m => m.id === "blender-procedural" && m.available);
  if (preferred) $("mode").value = preferred.id;
  const comfy = caps.comfy || {};
  const available = modes.filter(m => m.available).map(m => m.label).join(", ") || "None";
  const unavailable = modes.filter(m => !m.available).map(m => `${m.label}: ${m.reason}`).join("<br>");
  $("capsSummary").innerHTML = `
    <p><strong>GPU:</strong> ${escapeHtml(caps.gpu?.raw || "unknown")}</p>
    <p><strong>Comfy API ready:</strong> <span class="${comfy.apiReady ? "good" : "bad"}">${comfy.apiReady ? "yes" : "no"}</span></p>
    <p><strong>Detected custom nodes:</strong> ${escapeHtml((comfy.customNodes || []).join(", ") || "none")}</p>
    <p><strong>Detected model files:</strong> ${(comfy.modelFiles || []).length}</p>
    <p><strong>Local workflow JSON files:</strong> ${(comfy.workflowsLocal || []).length}</p>
    <p><strong>Available generation modes:</strong> ${escapeHtml(available)}</p>
    ${unavailable ? `<p class="warn"><strong>Unavailable modes:</strong><br>${unavailable}</p>` : ""}
  `;
  $("capsRaw").textContent = caps.inventoryRaw || JSON.stringify(caps, null, 2);
}

async function refreshCaps() {
  $("status").textContent = "Checking GPU...";
  log("Refreshing real GPU/ComfyUI capabilities...");
  try {
    const caps = await api("/api/capabilities");
    renderCaps(caps);
    $("status").textContent = "GPU inventory loaded";
    log("Capabilities loaded.");
  } catch (err) {
    $("status").textContent = "Capability check failed";
    log(`Capability check failed: ${err.message || err}`);
  }
}

async function startComfy() {
  log("Starting/testing remote ComfyUI API through SSH tunnel...");
  try {
    const result = await api("/api/start-comfy", { method: "POST", body: "{}" });
    log(`ComfyUI ready: ${result.ok ? "yes" : "no"}`);
    $("capsRaw").textContent = JSON.stringify(result, null, 2);
    await refreshCaps();
  } catch (err) {
    log(`Start ComfyUI failed: ${err.message || err}`);
  }
}

async function checkWanStatus() {
  log("Checking Wan node/model status...");
  try {
    const result = await api("/api/wan/status");
    $("capsRaw").textContent = JSON.stringify(result, null, 2);
    log(`Wan status: ${result.reason || "see raw inventory"}`);
    alert(`Wan status\n\nNodes found: ${result.availableNodes}\n\n${result.reason}\n\n${result.recommendedNext}`);
  } catch (err) {
    log(`Wan status failed: ${err.message || err}`);
  }
}

function setProgress(progress, text) {
  $("progressBar").style.width = `${Math.max(0, Math.min(100, Number(progress) || 0))}%`;
  $("progressText").textContent = text || "Working...";
}

function renderPlan(plan) {
  state.plan = plan;
  $("generate").disabled = false;
  $("planJson").textContent = JSON.stringify(plan, null, 2);
  $("planSummary").innerHTML = `
    <p><strong>Detected type:</strong> ${escapeHtml(plan.detectedType)}</p>
    <p><strong>Recommended chunks:</strong> ${plan.recommendedChunks} × ${plan.chunkSeconds}s = about ${plan.totalApproxSeconds}s</p>
    <p><strong>Production subject:</strong> ${escapeHtml(plan.productionPrompt?.subject || "")}</p>
    <p><strong>Best current mode:</strong> ${escapeHtml(plan.modelControls?.recommendedModeNow || "")}</p>
    <p><strong>Resolution:</strong> generate ${escapeHtml(plan.resolutionControls?.generation)} → final ${escapeHtml(plan.resolutionControls?.final)}</p>
    <p><strong>Sampler:</strong> ${escapeHtml(JSON.stringify(plan.samplerSettings))}</p>
    ${(plan.capabilityWarning || []).length ? `<p class="warn"><strong>Capability warnings:</strong><br>${plan.capabilityWarning.map(escapeHtml).join("<br>")}</p>` : ""}
  `;
  $("chunksOut").innerHTML = (plan.chunks || []).map(c => `
    <div class="chunk">
      <h3>${c.index}. ${escapeHtml(c.title)} — ${c.durationSeconds}s</h3>
      <p><strong>Purpose:</strong> ${escapeHtml(c.purpose)}</p>
      <p>${escapeHtml(c.prompt)}</p>
    </div>
  `).join("");
}

async function createPlan() {
  const payload = {
    prompt: $("prompt").value,
    chunks: $("chunks").value,
    chunkSeconds: Number($("chunkSeconds").value),
    aspect: $("aspect").value,
  };
  log("Analyzing prompt and creating production plan...");
  $("outputs").innerHTML = "No videos generated yet for this new plan.";
  $("manifest").textContent = "";
  setProgress(0, "Planning...");
  try {
    const plan = await api("/api/plan", { method: "POST", body: JSON.stringify(payload) });
    renderPlan(plan);
    log(`Plan ready: ${plan.recommendedChunks} chunks.`);
  } catch (err) {
    log(`Plan failed: ${err.message || err}`);
  }
}

function renderOutputs(manifest) {
  state.manifest = manifest;
  $("manifest").textContent = JSON.stringify(manifest, null, 2);
  const outs = manifest.outputs || [];
  $("outputs").innerHTML = outs.length ? outs.map(o => {
    const isVideo = /\.(mp4|webm|mov|mkv)$/i.test(o.filename || o.url || "");
    const isImage = /\.(png|jpg|jpeg|webp|gif)$/i.test(o.filename || o.url || "");
    const media = isVideo ? `<video controls src="${escapeHtml(o.url)}"></video>` : isImage ? `<img src="${escapeHtml(o.url)}" alt="${escapeHtml(o.filename)}">` : `<pre>${escapeHtml(JSON.stringify(o, null, 2))}</pre>`;
    return `<div class="video-card">${media}<p><strong>${escapeHtml(o.filename || "output")}</strong></p><p><a href="${escapeHtml(o.url)}" download>Download</a></p></div>`;
  }).join("") : `<p class="warn">No local outputs returned yet. Check manifest.</p>`;
}

async function pollJob(jobId) {
  state.activeJobId = jobId;
  for (;;) {
    const status = await api(`/api/jobs/${jobId}`);
    setProgress(status.progress, `${status.status}: ${status.message}`);
    $("manifest").textContent = JSON.stringify(status, null, 2);
    if (status.events?.length) {
      const last = status.events[status.events.length - 1];
      log(`${status.progress}% ${last.message}`);
    }
    if (status.status === "done" || status.status === "failed") {
      if (status.manifest) renderOutputs(status.manifest);
      log(`Job ${status.status}: ${status.message}`);
      return status;
    }
    await new Promise(r => setTimeout(r, 2500));
  }
}

async function generate() {
  if (!state.plan) return alert("Create a production plan first.");
  const currentPrompt = ($("prompt").value || "").trim();
  const plannedPrompt = (state.plan.inputPrompt || "").trim();
  if (currentPrompt !== plannedPrompt) {
    alert("Your prompt changed after the plan was created. Click 'Analyze prompt + create production plan' again before generating, so the video uses the current prompt.");
    return;
  }
  const mode = $("mode").value || "blender-procedural";
  if (!confirm(`Generate ${state.plan.recommendedChunks} separate video set(s) using mode: ${mode}?`)) return;
  $("generate").disabled = true;
  setProgress(0, "Submitting job...");
  $("outputs").innerHTML = "Generating fresh outputs for this prompt...";
  $("manifest").textContent = "";
  log(`Generating video sets using ${mode}. This can take several minutes...`);
  try {
    const job = await api("/api/generate", { method: "POST", body: JSON.stringify({ mode, plan: state.plan }) });
    log(`Job queued: ${job.jobId}`);
    await pollJob(job.jobId);
  } catch (err) {
    log(`Generation failed: ${err.message || err}`);
    alert(`Generation failed:\n${err.message || err}`);
  } finally {
    $("generate").disabled = false;
  }
}

async function boot() {
  try {
    const health = await api("/api/health");
    $("status").textContent = `${health.app} online`;
    log("COMFYBranch backend online.");
  } catch (err) {
    $("status").textContent = "Backend offline";
    log(`Health failed: ${err.message || err}`);
  }
  $("refreshCaps").addEventListener("click", refreshCaps);
  $("startComfy").addEventListener("click", startComfy);
  $("wanStatus").addEventListener("click", checkWanStatus);
  $("plan").addEventListener("click", createPlan);
  $("generate").addEventListener("click", generate);
  await refreshCaps();
}

boot();