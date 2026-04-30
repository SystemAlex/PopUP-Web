const DEFAULT_SETTINGS = {
  url: "https://example.com/",
  width: 480,
  height: 720,
  useActiveTab: false,
};

// Reglas para permitir que cualquier sitio se cargue en un iframe
const RULE_ID = 1;
chrome.declarativeNetRequest.updateDynamicRules({
  removeRuleIds: [RULE_ID],
  addRules: [
    {
      id: RULE_ID,
      priority: 1,
      action: {
        type: "modifyHeaders",
        responseHeaders: [
          { header: "X-Frame-Options", operation: "remove" },
          { header: "Content-Security-Policy", operation: "remove" },
          { header: "Frame-Options", operation: "remove" },
        ],
      },
      condition: {
        resourceTypes: ["sub_frame"],
      },
    },
  ],
});

chrome.runtime.onInstalled.addListener((details) => {
  // Guardar configuración inicial
  chrome.storage.sync.get(DEFAULT_SETTINGS, (items) => {
    chrome.storage.sync.set(sanitizeSettings(items));
  });

  // Si es la primera instalación, abrir instrucciones
  if (details.reason === "install") {
    chrome.tabs.create({
      url: chrome.runtime.getURL("instructions.html"),
    });
  }
});

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message?.type === "open-popup-window") {
    handleOpenPopup(message.payload, sendResponse);
    return true;
  }
  return false;
});

function sanitizeSettings(input) {
  return {
    url: normalizeUrl(input.url ?? DEFAULT_SETTINGS.url),
    width: clampDimension(input.width, DEFAULT_SETTINGS.width),
    height: clampDimension(input.height, DEFAULT_SETTINGS.height),
    useActiveTab: Boolean(input.useActiveTab),
  };
}

function normalizeUrl(rawUrl) {
  const value = String(rawUrl ?? "").trim();
  if (!value) throw new Error("Ingresa una URL.");
  try {
    const url = value.includes("://")
      ? new URL(value)
      : new URL(`https://${value}`);
    return assertSupportedUrl(url);
  } catch (_error) {
    throw new Error("URL inválida.");
  }
}

function clampDimension(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.min(1600, Math.max(320, parsed));
}

function assertSupportedUrl(url) {
  if (!["http:", "https:"].includes(url.protocol)) {
    throw new Error("Solo se permiten URLs http o https.");
  }
  return url.toString();
}

function handleOpenPopup(payload, sendResponse) {
  try {
    const settings = sanitizeSettings(payload ?? {});
    chrome.windows.create(
      {
        url: settings.url,
        type: "popup",
        width: settings.width,
        height: settings.height,
        focused: true,
      },
      (popupWindow) => {
        if (chrome.runtime.lastError) {
          sendResponse({ ok: false, error: chrome.runtime.lastError.message });
          return;
        }

        // Usar el título de la pestaña para identificar la ventana de forma legible
        const cleanTitle = (payload.title || "Ventana")
          .replace(/"/g, "'")
          .substring(0, 50);
        const targetTabId = popupWindow.tabs[0].id; // Obtener el ID de la pestaña dentro de la nueva ventana

        // Inyectar un script para establecer un título único en la ventana
        chrome.scripting.executeScript(
          {
            target: { tabId: targetTabId },
            function: (id) => {
              document.title = `PopUp WEB - ${id}`;
            },
            args: [cleanTitle],
          },
          () => {
            if (chrome.runtime.lastError) {
              console.error(
                "Error inyectando script para establecer título:",
                chrome.runtime.lastError.message,
              );
            }
            // Enviar el ID único de vuelta al popup.js
            sendResponse({
              ok: true,
              windowId: popupWindow?.id ?? null,
              uniqueTitleId: cleanTitle,
            });
          },
        );
      },
    );
  } catch (error) {
    sendResponse({
      ok: false,
      error: error instanceof Error ? error.message : "Error al abrir popup.",
    });
  }
}
