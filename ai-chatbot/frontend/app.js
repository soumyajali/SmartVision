/**
 * SMART VISION AI CHATBOT - FRONTEND CLIENT APPLICATION
 * Supports real-time Server-Sent Events (SSE) streaming, ChatML conversation persistence,
 * multi-turn dialogue, markdown & code block copy, and local RAG document grounding.
 */

(() => {
  // Application State
  const state = {
    currentSessionId: null,
    sessions: [],
    messages: [],
    systemPrompt: "You are an intelligent, friendly, and articulate AI assistant. Answer questions accurately, explain concepts step by step, and write clean, commented code.",
    temperature: 0.7,
    maxTokens: 512,
    useRag: false,
    isGenerating: false,
    abortController: null,
    ragDocuments: []
  };

  const SYSTEM_PRESETS = {
    general: "You are an intelligent, friendly, and articulate AI assistant. Answer questions accurately, explain concepts step by step, and write clean, commented code.",
    coder: "You are an expert Senior Full-Stack and ML Engineer. Provide optimal, clean, secure, and production-ready code with concise explanations and unit tests.",
    math: "You are an expert mathematician and logic tutor. Solve problems strictly step-by-step, explain each equation, verify arithmetic calculations, and provide the final answer clearly.",
    analyst: "You are a precise research analyst. When documents are provided, base answers strictly on the retrieved context, avoid unsubstantiated claims, and cite sources accurately."
  };

  // DOM Elements
  const DOM = {
    sidebar: document.getElementById("sidebar"),
    openSidebarBtn: document.getElementById("openSidebarBtn"),
    closeSidebarBtn: document.getElementById("closeSidebarBtn"),
    newChatBtn: document.getElementById("newChatBtn"),
    sessionsList: document.getElementById("sessionsList"),
    clearAllHistoryBtn: document.getElementById("clearAllHistoryBtn"),
    modelStatusBadge: document.getElementById("modelStatusBadge"),
    modelBadgeText: document.getElementById("modelBadgeText"),
    ragCountPill: document.getElementById("ragCountPill"),
    activeChatTitle: document.getElementById("activeChatTitle"),
    ragToggleCheckbox: document.getElementById("ragToggleCheckbox"),
    chatScrollContainer: document.getElementById("chatScrollContainer"),
    emptyHero: document.getElementById("emptyHero"),
    messagesStream: document.getElementById("messagesStream"),
    chatForm: document.getElementById("chatForm"),
    chatInput: document.getElementById("chatInput"),
    sendBtn: document.getElementById("sendBtn"),
    attachDocBtn: document.getElementById("attachDocBtn"),
    // RAG Modal
    openRagBtn: document.getElementById("openRagBtn"),
    closeRagModalBtn: document.getElementById("closeRagModalBtn"),
    ragModalOverlay: document.getElementById("ragModalOverlay"),
    fileDropzone: document.getElementById("fileDropzone"),
    fileInput: document.getElementById("fileInput"),
    ragDocTableBody: document.getElementById("ragDocTableBody"),
    clearAllDocsBtn: document.getElementById("clearAllDocsBtn"),
    ragTestInput: document.getElementById("ragTestInput"),
    runTestSearchBtn: document.getElementById("runTestSearchBtn"),
    ragTestResults: document.getElementById("ragTestResults"),
    // Settings Modal
    navSettingsBtn: document.getElementById("navSettingsBtn"),
    openSettingsBtn: document.getElementById("openSettingsBtn"),
    closeSettingsModalBtn: document.getElementById("closeSettingsModalBtn"),
    settingsModalOverlay: document.getElementById("settingsModalOverlay"),
    systemPromptInput: document.getElementById("systemPromptInput"),
    temperatureSlider: document.getElementById("temperatureSlider"),
    tempValueDisplay: document.getElementById("tempValueDisplay"),
    maxTokensSlider: document.getElementById("maxTokensSlider"),
    maxTokensDisplay: document.getElementById("maxTokensDisplay"),
    saveSettingsBtn: document.getElementById("saveSettingsBtn")
  };

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================

  async function init() {
    setupEventListeners();
    setupTextareaAutoResize();
    await checkHealth();
    await loadSessions();
    await loadRagDocuments();
    loadLocalSettings();
  }

  // ==========================================================================
  // EVENT LISTENERS
  // ==========================================================================

  function setupEventListeners() {
    // Sidebar & Navigation
    DOM.openSidebarBtn?.addEventListener("click", () => DOM.sidebar.classList.add("open"));
    DOM.closeSidebarBtn?.addEventListener("click", () => DOM.sidebar.classList.remove("open"));
    DOM.newChatBtn?.addEventListener("click", createNewChat);
    DOM.clearAllHistoryBtn?.addEventListener("click", clearAllSessions);

    // Keyboard Shortcuts (Cmd+K / Ctrl+K for New Chat)
    window.addEventListener("keydown", (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        createNewChat();
      }
    });

    // Chat Form Submission
    DOM.chatForm?.addEventListener("submit", (e) => {
      e.preventDefault();
      handleSendMessage();
    });

    // Chat Input Enter Key
    DOM.chatInput?.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        handleSendMessage();
      }
    });

    // Suggestion Cards in Empty Hero
    document.querySelectorAll(".suggestion-card").forEach(card => {
      card.addEventListener("click", () => {
        const prompt = card.getAttribute("data-prompt");
        if (prompt) {
          DOM.chatInput.value = prompt;
          handleSendMessage();
        }
      });
    });

    // RAG Toggle
    DOM.ragToggleCheckbox?.addEventListener("change", (e) => {
      state.useRag = e.target.checked;
    });

    // RAG Modal Controls
    DOM.openRagBtn?.addEventListener("click", () => openModal(DOM.ragModalOverlay));
    DOM.attachDocBtn?.addEventListener("click", () => openModal(DOM.ragModalOverlay));
    DOM.closeRagModalBtn?.addEventListener("click", () => closeModal(DOM.ragModalOverlay));
    DOM.fileDropzone?.addEventListener("click", () => DOM.fileInput.click());
    DOM.fileInput?.addEventListener("change", handleFileUpload);
    DOM.clearAllDocsBtn?.addEventListener("click", handleClearAllDocs);
    DOM.runTestSearchBtn?.addEventListener("click", handleTestSearch);
    DOM.ragTestInput?.addEventListener("keydown", (e) => {
      if (e.key === "Enter") handleTestSearch();
    });

    // File Drag & Drop
    DOM.fileDropzone?.addEventListener("dragover", (e) => {
      e.preventDefault();
      DOM.fileDropzone.classList.add("dragover");
    });
    DOM.fileDropzone?.addEventListener("dragleave", () => {
      DOM.fileDropzone.classList.remove("dragover");
    });
    DOM.fileDropzone?.addEventListener("drop", (e) => {
      e.preventDefault();
      DOM.fileDropzone.classList.remove("dragover");
      if (e.dataTransfer.files.length > 0) {
        uploadFile(e.dataTransfer.files[0]);
      }
    });

    // Settings Modal Controls
    DOM.navSettingsBtn?.addEventListener("click", openSettingsModal);
    DOM.openSettingsBtn?.addEventListener("click", openSettingsModal);
    DOM.closeSettingsModalBtn?.addEventListener("click", () => closeModal(DOM.settingsModalOverlay));
    DOM.saveSettingsBtn?.addEventListener("click", saveSettings);

    // Sliders Real-Time Values
    DOM.temperatureSlider?.addEventListener("input", (e) => {
      DOM.tempValueDisplay.textContent = e.target.value;
    });
    DOM.maxTokensSlider?.addEventListener("input", (e) => {
      DOM.maxTokensDisplay.textContent = e.target.value;
    });

    // Persona Presets
    document.querySelectorAll(".preset-pills .pill-btn").forEach(pill => {
      pill.addEventListener("click", () => {
        document.querySelectorAll(".preset-pills .pill-btn").forEach(p => p.classList.remove("active"));
        pill.classList.add("active");
        const presetKey = pill.getAttribute("data-preset");
        if (SYSTEM_PRESETS[presetKey]) {
          DOM.systemPromptInput.value = SYSTEM_PRESETS[presetKey];
        }
      });
    });

    // Modal Background Clicks
    [DOM.ragModalOverlay, DOM.settingsModalOverlay].forEach(overlay => {
      overlay?.addEventListener("click", (e) => {
        if (e.target === overlay) closeModal(overlay);
      });
    });
  }

  function openModal(modal) {
    if (modal) modal.classList.add("open");
  }

  function closeModal(modal) {
    if (modal) modal.classList.remove("open");
  }

  function setupTextareaAutoResize() {
    DOM.chatInput?.addEventListener("input", function() {
      this.style.height = "auto";
      this.style.height = Math.min(this.scrollHeight, 180) + "px";
    });
  }

  // ==========================================================================
  // BACKEND API CLIENT & HEALTH
  // ==========================================================================

  async function checkHealth() {
    try {
      const res = await fetch("/api/health");
      if (!res.ok) return;
      const data = await res.json();
      const engine = data.model_engine || {};
      const loraTag = engine.lora_active ? "LoRA Active" : "Base Model";
      const dev = engine.device?.toUpperCase() || "CPU";
      DOM.modelBadgeText.textContent = `Qwen2.5-0.5B (${dev}) · ${loraTag}`;
      if (DOM.ragCountPill) {
        DOM.ragCountPill.textContent = data.rag_status?.indexed_documents || 0;
      }
    } catch (e) {
      console.warn("Health check notice:", e);
      DOM.modelBadgeText.textContent = "Qwen2.5-0.5B (Local)";
    }
  }

  // ==========================================================================
  // SESSIONS MANAGEMENT
  // ==========================================================================

  async function loadSessions() {
    try {
      const res = await fetch("/api/sessions");
      if (!res.ok) return;
      const data = await res.json();
      state.sessions = data.sessions || [];
      renderSessionsList();
    } catch (e) {
      console.error("Could not load sessions:", e);
    }
  }

  function renderSessionsList() {
    if (!DOM.sessionsList) return;
    DOM.sessionsList.innerHTML = "";

    if (state.sessions.length === 0) {
      DOM.sessionsList.innerHTML = `<div style="padding: 0.6rem; font-size: 0.8rem; color: var(--text-dim);">No previous chats</div>`;
      return;
    }

    state.sessions.forEach(s => {
      const item = document.createElement("div");
      item.className = `session-item ${s.session_id === state.currentSessionId ? "active" : ""}`;
      item.innerHTML = `
        <span class="session-title-text" title="${escapeHtml(s.title)}">${escapeHtml(s.title)}</span>
        <div class="session-actions">
          <button class="session-action-btn delete-btn" title="Delete conversation">🗑️</button>
        </div>
      `;

      item.querySelector(".session-title-text").addEventListener("click", () => switchSession(s.session_id));
      item.querySelector(".delete-btn").addEventListener("click", (e) => {
        e.stopPropagation();
        deleteSession(s.session_id);
      });

      DOM.sessionsList.appendChild(item);
    });
  }

  async function switchSession(sessionId) {
    if (state.isGenerating) return;
    state.currentSessionId = sessionId;
    try {
      const res = await fetch(`/api/sessions/${sessionId}`);
      if (!res.ok) return;
      const data = await res.json();
      DOM.activeChatTitle.textContent = data.title || "Chat";
      state.messages = data.messages || [];
      renderMessagesStream();
      renderSessionsList();
      DOM.sidebar.classList.remove("open");
    } catch (e) {
      console.error("Failed to load session:", e);
    }
  }

  async function createNewChat() {
    if (state.isGenerating) return;
    state.currentSessionId = null;
    state.messages = [];
    DOM.activeChatTitle.textContent = "New Conversation";
    renderMessagesStream();
    renderSessionsList();
    DOM.chatInput.focus();
    DOM.sidebar.classList.remove("open");
  }

  async function deleteSession(sessionId) {
    try {
      await fetch(`/api/sessions/${sessionId}`, { method: "DELETE" });
      if (state.currentSessionId === sessionId) {
        createNewChat();
      }
      await loadSessions();
    } catch (e) {
      console.error("Failed to delete session:", e);
    }
  }

  async function clearAllSessions() {
    if (!confirm("Are you sure you want to clear all chat history?")) return;
    try {
      await fetch("/api/sessions", { method: "DELETE" });
      createNewChat();
      await loadSessions();
    } catch (e) {
      console.error("Failed to clear sessions:", e);
    }
  }

  // ==========================================================================
  // CHAT STREAMING & MESSAGING
  // ==========================================================================

  function renderMessagesStream() {
    if (!DOM.messagesStream || !DOM.emptyHero) return;

    if (state.messages.length === 0) {
      DOM.emptyHero.style.display = "block";
      DOM.messagesStream.innerHTML = "";
      return;
    }

    DOM.emptyHero.style.display = "none";
    DOM.messagesStream.innerHTML = "";

    state.messages.forEach((msg, idx) => {
      appendMessageToDOM(msg.role, msg.content, msg.metrics, msg.citations, false);
    });
    scrollToBottom();
  }

  function appendMessageToDOM(role, content, metrics = null, citations = null, isStreaming = false) {
    DOM.emptyHero.style.display = "none";
    const msgWrapper = document.createElement("div");
    msgWrapper.className = `message-wrapper ${role}`;

    const avatarIcon = role === "user" ? "👤" : "✨";
    const senderTitle = role === "user" ? "You" : "Smart Vision AI";

    let citationsHtml = "";
    if (citations && citations.length > 0) {
      citationsHtml = `
        <div class="citations-box">
          <div class="citations-header">📚 Retrieved Knowledge Citations (${citations.length})</div>
          <div class="citations-list">
            ${citations.map(c => `
              <div class="citation-card">
                <div class="citation-card-title">
                  <span>[${c.source_num}] ${escapeHtml(c.filename)}</span>
                  <span style="color: var(--accent-cyan);">Score: ${c.relevance_score}</span>
                </div>
                <div class="citation-excerpt">"${escapeHtml(c.excerpt)}"</div>
              </div>
            `).join("")}
          </div>
        </div>
      `;
    }

    let telemetryHtml = "";
    if (metrics) {
      const tps = metrics.tokens_per_second || 0;
      const sec = metrics.latency_seconds || 0;
      const count = metrics.generated_tokens || 0;
      const loraTag = metrics.lora_active ? " · LoRA" : "";
      telemetryHtml = `
        <div class="telemetry-pill">
          <span>⚡ ${tps} tok/s</span>
          <span>⏱️ ${sec}s</span>
          <span>🔤 ${count} tokens${loraTag}</span>
        </div>
      `;
    }

    msgWrapper.innerHTML = `
      <div class="message-avatar">${avatarIcon}</div>
      <div class="message-content-box">
        <div class="message-header-row">
          <span class="sender-name">${senderTitle}</span>
          <button class="message-action-btn copy-msg-btn" title="Copy text">📋</button>
        </div>
        <div class="message-text">${formatMarkdown(content)}${isStreaming ? '<span class="typing-cursor"></span>' : ''}</div>
        ${citationsHtml}
        <div class="message-footer-bar">
          ${telemetryHtml}
        </div>
      </div>
    `;

    // Copy full response listener
    msgWrapper.querySelector(".copy-msg-btn")?.addEventListener("click", function() {
      navigator.clipboard.writeText(content).then(() => {
        this.textContent = "✅";
        setTimeout(() => this.textContent = "📋", 1800);
      });
    });

    // Syntax highlight all code blocks inside this message
    attachCodeBlockHandlers(msgWrapper);

    DOM.messagesStream.appendChild(msgWrapper);
    scrollToBottom();
    return msgWrapper;
  }

  async function handleSendMessage() {
    const rawInput = DOM.chatInput.value.trim();
    if (!rawInput || state.isGenerating) return;

    // Reset input
    DOM.chatInput.value = "";
    DOM.chatInput.style.height = "auto";
    state.isGenerating = true;
    DOM.sendBtn.disabled = true;

    // If new session without ID, create session first
    if (!state.currentSessionId) {
      try {
        const titleSnippet = rawInput.length > 28 ? rawInput.substring(0, 28) + "..." : rawInput;
        const sRes = await fetch("/api/sessions", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title: titleSnippet, system_prompt: state.systemPrompt })
        });
        if (sRes.ok) {
          const sData = await sRes.json();
          state.currentSessionId = sData.session_id;
          DOM.activeChatTitle.textContent = titleSnippet;
          await loadSessions();
        }
      } catch (e) {
        console.warn("Could not pre-create session:", e);
      }
    }

    // Append user message
    state.messages.push({ role: "user", content: rawInput });
    appendMessageToDOM("user", rawInput);

    // Prepare stream request payload
    const payload = {
      messages: state.messages.map(m => ({ role: m.role, content: m.content })),
      session_id: state.currentSessionId,
      system_prompt: state.systemPrompt,
      temperature: state.temperature,
      max_tokens: state.maxTokens,
      use_rag: state.useRag,
      rag_top_k: 3
    };

    // Create placeholder assistant bubble with streaming cursor
    let accumulatedText = "";
    let capturedCitations = [];
    let assistantBubble = appendMessageToDOM("assistant", "", null, null, true);
    let textContainer = assistantBubble.querySelector(".message-text");

    try {
      state.abortController = new AbortController();
      const response = await fetch("/api/chat/stream", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
        signal: state.abortController.signal
      });

      if (!response.ok || !response.body) {
        throw new Error(`Server returned HTTP ${response.status}`);
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = "";

      while (true) {
        const { value, done } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split("\n\n");
        buffer = lines.pop(); // keep partial chunk

        for (const line of lines) {
          if (line.startsWith("data: ")) {
            const rawJson = line.substring(6).trim();
            if (!rawJson) continue;
            try {
              const data = JSON.parse(rawJson);
              if (data.event === "delta") {
                accumulatedText += data.delta;
                textContainer.innerHTML = formatMarkdown(accumulatedText) + '<span class="typing-cursor"></span>';
                attachCodeBlockHandlers(assistantBubble);
                scrollToBottom();
              } else if (data.event === "citations") {
                capturedCitations = data.citations || [];
              } else if (data.event === "done") {
                // Finalize assistant bubble
                const finalMetrics = data.metrics || {};
                textContainer.innerHTML = formatMarkdown(accumulatedText);
                attachCodeBlockHandlers(assistantBubble);

                // Add to persistent state
                state.messages.push({
                  role: "assistant",
                  content: accumulatedText,
                  metrics: finalMetrics,
                  citations: capturedCitations
                });

                // Re-render finalized footer
                const footerBar = assistantBubble.querySelector(".message-footer-bar");
                if (footerBar && finalMetrics.tokens_per_second) {
                  footerBar.innerHTML = `
                    <div class="telemetry-pill">
                      <span>⚡ ${finalMetrics.tokens_per_second} tok/s</span>
                      <span>⏱️ ${finalMetrics.latency_seconds}s</span>
                      <span>🔤 ${finalMetrics.generated_tokens} tokens</span>
                    </div>
                  `;
                }

                if (capturedCitations.length > 0) {
                  const citContainer = document.createElement("div");
                  citContainer.className = "citations-box";
                  citContainer.innerHTML = `
                    <div class="citations-header">📚 Retrieved Knowledge Citations (${capturedCitations.length})</div>
                    <div class="citations-list">
                      ${capturedCitations.map(c => `
                        <div class="citation-card">
                          <div class="citation-card-title">
                            <span>[${c.source_num}] ${escapeHtml(c.filename)}</span>
                            <span style="color: var(--accent-cyan);">Score: ${c.relevance_score}</span>
                          </div>
                          <div class="citation-excerpt">"${escapeHtml(c.excerpt)}"</div>
                        </div>
                      `).join("")}
                    </div>
                  `;
                  assistantBubble.querySelector(".message-content-box").insertBefore(citContainer, footerBar);
                }
              }
            } catch (err) {
              console.warn("Error parsing SSE JSON event:", err);
            }
          }
        }
      }
    } catch (e) {
      if (e.name === "AbortError") {
        textContainer.innerHTML = formatMarkdown(accumulatedText + "\n\n*(Generation stopped by user)*");
      } else {
        console.error("Streaming error, falling back to standard endpoint:", e);
        try {
          const fallbackRes = await fetch("/api/chat", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload)
          });
          const fbData = await fallbackRes.json();
          textContainer.innerHTML = formatMarkdown(fbData.response);
          state.messages.push({
            role: "assistant",
            content: fbData.response,
            metrics: fbData.metrics,
            citations: fbData.citations
          });
        } catch (fbErr) {
          textContainer.innerHTML = `<span style="color: var(--accent-rose);">Error generating response: ${escapeHtml(e.message)}</span>`;
        }
      }
    } finally {
      state.isGenerating = false;
      DOM.sendBtn.disabled = false;
      state.abortController = null;
      loadSessions();
    }
  }

  function scrollToBottom() {
    if (DOM.chatScrollContainer) {
      DOM.chatScrollContainer.scrollTop = DOM.chatScrollContainer.scrollHeight;
    }
  }

  // ==========================================================================
  // MARKDOWN & SYNTAX HIGHLIGHTING
  // ==========================================================================

  function formatMarkdown(text) {
    if (!text) return "";
    try {
      if (window.marked) {
        return marked.parse(text);
      }
    } catch (e) {
      console.warn("Marked parse error:", e);
    }
    return escapeHtml(text).replace(/\n/g, "<br>");
  }

  function attachCodeBlockHandlers(container) {
    container.querySelectorAll("pre code").forEach(block => {
      // Check if already highlighted
      if (!block.classList.contains("hljs-done")) {
        if (window.hljs) {
          hljs.highlightElement(block);
          block.classList.add("hljs-done");
        }
      }

      // Add header bar with language and Copy button if not present
      const pre = block.parentElement;
      if (pre && !pre.querySelector(".code-header-bar")) {
        const langMatch = block.className.match(/language-(\w+)/);
        const langName = langMatch ? langMatch[1] : "code";

        const headerBar = document.createElement("div");
        headerBar.className = "code-header-bar";
        headerBar.innerHTML = `
          <span>${langName}</span>
          <button type="button" class="copy-code-btn">Copy</button>
        `;

        headerBar.querySelector(".copy-code-btn").addEventListener("click", function() {
          navigator.clipboard.writeText(block.innerText).then(() => {
            this.textContent = "Copied!";
            setTimeout(() => this.textContent = "Copy", 1800);
          });
        });

        pre.insertBefore(headerBar, block);
      }
    });
  }

  function escapeHtml(str) {
    if (!str) return "";
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  // ==========================================================================
  // RAG DOCUMENT KNOWLEDGE BASE
  // ==========================================================================

  async function loadRagDocuments() {
    try {
      const res = await fetch("/api/rag/documents");
      if (!res.ok) return;
      const data = await res.json();
      state.ragDocuments = data.documents || [];
      renderRagDocumentsTable();
      if (DOM.ragCountPill) {
        DOM.ragCountPill.textContent = state.ragDocuments.length;
      }
    } catch (e) {
      console.error("Failed to load RAG documents:", e);
    }
  }

  function renderRagDocumentsTable() {
    if (!DOM.ragDocTableBody) return;
    DOM.ragDocTableBody.innerHTML = "";

    if (state.ragDocuments.length === 0) {
      DOM.ragDocTableBody.innerHTML = `<tr><td colspan="4" class="empty-table-msg">No documents indexed yet. Upload a file above.</td></tr>`;
      return;
    }

    state.ragDocuments.forEach(doc => {
      const tr = document.createElement("tr");
      tr.innerHTML = `
        <td style="font-weight: 500; color: #ffffff;">📄 ${escapeHtml(doc.filename)}</td>
        <td>${doc.word_count?.toLocaleString() || 0}</td>
        <td><span class="rag-count-pill">${doc.chunks_count || 0}</span></td>
        <td>
          <button class="session-action-btn delete-doc-btn" data-id="${doc.doc_id}" title="Remove document">🗑️</button>
        </td>
      `;

      tr.querySelector(".delete-doc-btn").addEventListener("click", () => deleteRagDocument(doc.doc_id));
      DOM.ragDocTableBody.appendChild(tr);
    });
  }

  async function handleFileUpload(e) {
    const file = e.target.files[0];
    if (file) {
      await uploadFile(file);
      DOM.fileInput.value = "";
    }
  }

  async function uploadFile(file) {
    const formData = new FormData();
    formData.append("file", file);

    const dropzoneText = DOM.fileDropzone.querySelector(".dropzone-text");
    const originalText = dropzoneText.textContent;
    dropzoneText.textContent = `Indexing ${file.name}...`;

    try {
      const res = await fetch("/api/rag/upload", {
        method: "POST",
        body: formData
      });
      if (!res.ok) {
        const err = await res.json();
        alert(`Upload error: ${err.detail || "Failed to process file"}`);
      } else {
        await loadRagDocuments();
      }
    } catch (e) {
      alert(`Upload error: ${e.message}`);
    } finally {
      dropzoneText.textContent = originalText;
    }
  }

  async function deleteRagDocument(docId) {
    try {
      await fetch(`/api/rag/documents/${docId}`, { method: "DELETE" });
      await loadRagDocuments();
    } catch (e) {
      console.error("Failed to delete document:", e);
    }
  }

  async function handleClearAllDocs() {
    if (!confirm("Are you sure you want to remove all indexed documents from the knowledge base?")) return;
    try {
      await fetch("/api/rag/documents", { method: "DELETE" });
      await loadRagDocuments();
    } catch (e) {
      console.error("Failed to clear documents:", e);
    }
  }

  async function handleTestSearch() {
    const query = DOM.ragTestInput.value.trim();
    if (!query) return;

    DOM.ragTestResults.innerHTML = `<div style="font-size: 0.8rem; color: var(--text-dim);">Searching knowledge base...</div>`;

    try {
      const res = await fetch("/api/rag/query", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query, top_k: 3 })
      });
      const data = await res.json();
      const matches = data.matches || [];

      if (matches.length === 0) {
        DOM.ragTestResults.innerHTML = `<div style="font-size: 0.8rem; color: var(--text-dim);">No matching excerpts found for "${escapeHtml(query)}".</div>`;
        return;
      }

      DOM.ragTestResults.innerHTML = matches.map((m, idx) => `
        <div class="citation-card">
          <div class="citation-card-title">
            <span>#${idx + 1} ${escapeHtml(m.filename)} (Section ${m.chunk_index + 1})</span>
            <span style="color: var(--accent-cyan);">Score: ${m.score}</span>
          </div>
          <div class="citation-excerpt">"${escapeHtml(m.text.substring(0, 160))}..."</div>
        </div>
      `).join("");
    } catch (e) {
      DOM.ragTestResults.innerHTML = `<div style="color: var(--accent-rose); font-size: 0.8rem;">Search error: ${escapeHtml(e.message)}</div>`;
    }
  }

  // ==========================================================================
  // SETTINGS & PERSONAS
  // ==========================================================================

  function openSettingsModal() {
    DOM.systemPromptInput.value = state.systemPrompt;
    DOM.temperatureSlider.value = state.temperature;
    DOM.tempValueDisplay.textContent = state.temperature;
    DOM.maxTokensSlider.value = state.maxTokens;
    DOM.maxTokensDisplay.textContent = state.maxTokens;
    openModal(DOM.settingsModalOverlay);
  }

  function saveSettings() {
    state.systemPrompt = DOM.systemPromptInput.value.trim() || SYSTEM_PRESETS.general;
    state.temperature = parseFloat(DOM.temperatureSlider.value);
    state.maxTokens = parseInt(DOM.maxTokensSlider.value, 10);

    localStorage.setItem("smartvision_chatbot_settings", JSON.stringify({
      systemPrompt: state.systemPrompt,
      temperature: state.temperature,
      maxTokens: state.maxTokens
    }));

    closeModal(DOM.settingsModalOverlay);
  }

  function loadLocalSettings() {
    try {
      const saved = localStorage.getItem("smartvision_chatbot_settings");
      if (saved) {
        const parsed = JSON.parse(saved);
        if (parsed.systemPrompt) state.systemPrompt = parsed.systemPrompt;
        if (parsed.temperature !== undefined) state.temperature = parsed.temperature;
        if (parsed.maxTokens) state.maxTokens = parsed.maxTokens;
      }
    } catch (e) {
      console.warn("Could not load local settings:", e);
    }
  }

  // Run app on DOM ready
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
